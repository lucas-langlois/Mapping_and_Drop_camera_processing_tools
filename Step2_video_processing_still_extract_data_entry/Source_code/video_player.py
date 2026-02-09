"""
MP4 Video Player with Frame Extraction
Features: Play/Pause, Frame navigation, Timeline scrubbing, Speed control, Frame export
"""

import sys
import os
from datetime import datetime
import csv
import json
import re

# Set environment variable BEFORE importing cv2 to handle videos with multiple streams (video + audio)
os.environ['OPENCV_FFMPEG_READ_ATTEMPTS'] = '100000'
os.environ['OPENCV_VIDEOIO_PRIORITY_FFMPEG'] = '1'
os.environ['OPENCV_FFMPEG_CAPTURE_OPTIONS'] = 'video_codec_priority;h264'
os.environ['OPENCV_VIDEOIO_DEBUG'] = '0'  # Disable debug warnings

import cv2
from PyQt5.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, 
                             QHBoxLayout, QPushButton, QSlider, QLabel, 
                             QFileDialog, QSpinBox, QComboBox, QMessageBox,
                             QLineEdit, QTextEdit, QScrollArea, QGroupBox, QGridLayout,
                             QShortcut, QInputDialog, QDialog, QListWidget, QListWidgetItem,
                             QDialogButtonBox, QFrame, QDoubleSpinBox, QCheckBox, QSizePolicy,
                             QDesktopWidget)
from PyQt5.QtCore import QTimer, Qt, QUrl
from PyQt5.QtGui import QImage, QPixmap, QKeySequence, QColor
from PyQt5.QtWebEngineWidgets import QWebEngineView


class ValidationRulesDialog(QDialog):
    """Dialog for managing validation rules"""
    
    def __init__(self, parent, template_fieldnames, current_rules=None):
        super().__init__(parent)
        self.template_fieldnames = template_fieldnames
        self.rules = current_rules if current_rules else []
        self.current_rule_index = -1
        
        self.setWindowTitle("Manage Validation Rules")
        self.setGeometry(200, 200, 800, 600)
        
        self.init_ui()
        self.refresh_rules_list()
    
    def init_ui(self):
        """Initialize the UI"""
        layout = QVBoxLayout()
        
        # Title
        title = QLabel("Validation Rules Manager")
        title.setStyleSheet("font-size: 16px; font-weight: bold; padding: 10px;")
        layout.addWidget(title)
        
        # Rules list
        list_label = QLabel("Existing Rules:")
        list_label.setStyleSheet("font-weight: bold;")
        layout.addWidget(list_label)
        
        self.rules_list = QListWidget()
        self.rules_list.itemClicked.connect(self.rule_selected)
        layout.addWidget(self.rules_list)
        
        # Buttons for list management
        list_buttons = QHBoxLayout()
        
        self.add_rule_btn = QPushButton("+ Add New Rule")
        self.add_rule_btn.clicked.connect(self.add_new_rule)
        self.add_rule_btn.setStyleSheet("background-color: #4CAF50; color: white; padding: 5px;")
        list_buttons.addWidget(self.add_rule_btn)
        
        self.edit_rule_btn = QPushButton("Edit Selected")
        self.edit_rule_btn.clicked.connect(self.edit_selected_rule)
        self.edit_rule_btn.setEnabled(False)
        list_buttons.addWidget(self.edit_rule_btn)
        
        self.delete_rule_btn = QPushButton("Delete Selected")
        self.delete_rule_btn.clicked.connect(self.delete_selected_rule)
        self.delete_rule_btn.setEnabled(False)
        self.delete_rule_btn.setStyleSheet("background-color: #F44336; color: white; padding: 5px;")
        list_buttons.addWidget(self.delete_rule_btn)
        
        list_buttons.addStretch()
        layout.addLayout(list_buttons)
        
        # Separator
        line = QFrame()
        line.setFrameShape(QFrame.HLine)
        line.setFrameShadow(QFrame.Sunken)
        layout.addWidget(line)
        
        # Rule editor section
        editor_label = QLabel("Rule Editor:")
        editor_label.setStyleSheet("font-weight: bold; margin-top: 10px;")
        layout.addWidget(editor_label)
        
        # Rule type selector
        type_layout = QHBoxLayout()
        type_layout.addWidget(QLabel("Rule Type:"))
        self.rule_type_combo = QComboBox()
        self.rule_type_combo.addItems([
            "Allowed Values",
            "Numeric Range",
            "Required Field",
            "Conditional (If-Then)",
            "Sum Equals",
            "Conditional Sum",
            "Auto-Fill",
            "Calculated Field"
        ])
        self.rule_type_combo.currentTextChanged.connect(self.rule_type_changed)
        type_layout.addWidget(self.rule_type_combo)
        type_layout.addStretch()
        layout.addLayout(type_layout)
        
        # Rule editor panels (stacked)
        self.editor_container = QWidget()
        self.editor_layout = QVBoxLayout()
        self.editor_container.setLayout(self.editor_layout)
        layout.addWidget(self.editor_container)
        
        self.create_editor_panels()
        self.rule_type_changed(self.rule_type_combo.currentText())
        
        # Save/Cancel buttons for rule editor
        editor_buttons = QHBoxLayout()
        self.save_rule_btn = QPushButton("Save Rule")
        self.save_rule_btn.clicked.connect(self.save_current_rule)
        self.save_rule_btn.setStyleSheet("background-color: #2196F3; color: white; padding: 5px;")
        editor_buttons.addWidget(self.save_rule_btn)
        
        self.cancel_edit_btn = QPushButton("Cancel Edit")
        self.cancel_edit_btn.clicked.connect(self.cancel_edit)
        editor_buttons.addWidget(self.cancel_edit_btn)
        
        editor_buttons.addStretch()
        layout.addLayout(editor_buttons)
        
        # Bottom buttons
        layout.addStretch()
        bottom_buttons = QDialogButtonBox(QDialogButtonBox.Close)
        bottom_buttons.rejected.connect(self.accept)
        layout.addWidget(bottom_buttons)
        
        self.setLayout(layout)
    
    def create_editor_panels(self):
        """Create all rule editor panels"""
        # Clear existing panels
        while self.editor_layout.count():
            item = self.editor_layout.takeAt(0)
            if item.widget():
                item.widget().deleteLater()
        
        # Allowed Values panel
        self.allowed_values_panel = QGroupBox("Allowed Values Rule")
        av_layout = QGridLayout()
        av_layout.addWidget(QLabel("Field:"), 0, 0)
        self.av_field = QComboBox()
        self.av_field.addItems(self.template_fieldnames)
        av_layout.addWidget(self.av_field, 0, 1)
        
        av_layout.addWidget(QLabel("Allowed Values (comma-separated):"), 1, 0)
        self.av_values = QLineEdit()
        self.av_values.setPlaceholderText("e.g., 0, 1 or yes, no")
        av_layout.addWidget(self.av_values, 1, 1)
        
        av_layout.addWidget(QLabel("Error Message:"), 2, 0)
        self.av_error = QLineEdit()
        av_layout.addWidget(self.av_error, 2, 1)
        
        self.allowed_values_panel.setLayout(av_layout)
        self.editor_layout.addWidget(self.allowed_values_panel)
        
        # Numeric Range panel
        self.range_panel = QGroupBox("Numeric Range Rule")
        range_layout = QGridLayout()
        range_layout.addWidget(QLabel("Field:"), 0, 0)
        self.range_field = QComboBox()
        self.range_field.addItems(self.template_fieldnames)
        range_layout.addWidget(self.range_field, 0, 1)
        
        range_layout.addWidget(QLabel("Minimum Value:"), 1, 0)
        self.range_min = QDoubleSpinBox()
        self.range_min.setMinimum(-999999)
        self.range_min.setMaximum(999999)
        self.range_min.setValue(0)
        range_layout.addWidget(self.range_min, 1, 1)
        
        range_layout.addWidget(QLabel("Maximum Value:"), 2, 0)
        self.range_max = QDoubleSpinBox()
        self.range_max.setMinimum(-999999)
        self.range_max.setMaximum(999999)
        self.range_max.setValue(100)
        range_layout.addWidget(self.range_max, 2, 1)
        
        range_layout.addWidget(QLabel("Error Message:"), 3, 0)
        self.range_error = QLineEdit()
        range_layout.addWidget(self.range_error, 3, 1)
        
        self.range_panel.setLayout(range_layout)
        self.editor_layout.addWidget(self.range_panel)
        
        # Required Field panel
        self.required_panel = QGroupBox("Required Field Rule")
        req_layout = QGridLayout()
        req_layout.addWidget(QLabel("Field:"), 0, 0)
        self.req_field = QComboBox()
        self.req_field.addItems(self.template_fieldnames)
        req_layout.addWidget(self.req_field, 0, 1)
        
        req_layout.addWidget(QLabel("Error Message:"), 1, 0)
        self.req_error = QLineEdit()
        req_layout.addWidget(self.req_error, 1, 1)
        
        self.required_panel.setLayout(req_layout)
        self.editor_layout.addWidget(self.required_panel)
        
        # Conditional panel
        self.conditional_panel = QGroupBox("Conditional (If-Then) Rule")
        cond_layout = QGridLayout()
        
        cond_layout.addWidget(QLabel("If Field:"), 0, 0)
        self.cond_if_field = QComboBox()
        self.cond_if_field.addItems(self.template_fieldnames)
        cond_layout.addWidget(self.cond_if_field, 0, 1)
        
        cond_layout.addWidget(QLabel("Equals:"), 1, 0)
        self.cond_if_value = QLineEdit()
        cond_layout.addWidget(self.cond_if_value, 1, 1)
        
        cond_layout.addWidget(QLabel("Then Field:"), 2, 0)
        self.cond_then_field = QComboBox()
        self.cond_then_field.addItems(self.template_fieldnames)
        cond_layout.addWidget(self.cond_then_field, 2, 1)
        
        cond_layout.addWidget(QLabel("Must Be:"), 3, 0)
        self.cond_operator = QComboBox()
        self.cond_operator.addItems([
            "Equal to",
            "Not equal to",
            "Greater than",
            "Less than",
            "Greater than or equal to",
            "Less than or equal to"
        ])
        cond_layout.addWidget(self.cond_operator, 3, 1)
        
        cond_layout.addWidget(QLabel("Value:"), 4, 0)
        self.cond_then_value = QLineEdit()
        cond_layout.addWidget(self.cond_then_value, 4, 1)
        
        cond_layout.addWidget(QLabel("Error Message:"), 5, 0)
        self.cond_error = QLineEdit()
        cond_layout.addWidget(self.cond_error, 5, 1)
        
        self.conditional_panel.setLayout(cond_layout)
        self.editor_layout.addWidget(self.conditional_panel)
        
        # Sum Equals panel
        self.sum_panel = QGroupBox("Sum Equals Rule")
        sum_layout = QGridLayout()
        
        sum_layout.addWidget(QLabel("Fields to Sum (comma-separated):"), 0, 0)
        self.sum_fields = QLineEdit()
        self.sum_fields.setPlaceholderText("e.g., SG_COVER, AL_COVER, HC_COVER")
        sum_layout.addWidget(self.sum_fields, 0, 1)
        
        sum_layout.addWidget(QLabel("Must Equal:"), 1, 0)
        self.sum_value = QDoubleSpinBox()
        self.sum_value.setMinimum(-999999)
        self.sum_value.setMaximum(999999)
        self.sum_value.setValue(100)
        sum_layout.addWidget(self.sum_value, 1, 1)
        
        sum_layout.addWidget(QLabel("Tolerance (+/-):"), 2, 0)
        self.sum_tolerance = QDoubleSpinBox()
        self.sum_tolerance.setMinimum(0)
        self.sum_tolerance.setMaximum(999999)
        self.sum_tolerance.setValue(0)
        self.sum_tolerance.setDecimals(2)
        sum_layout.addWidget(self.sum_tolerance, 2, 1)
        
        sum_layout.addWidget(QLabel("Error Message:"), 3, 0)
        self.sum_error = QLineEdit()
        sum_layout.addWidget(self.sum_error, 3, 1)
        
        self.sum_panel.setLayout(sum_layout)
        self.editor_layout.addWidget(self.sum_panel)
        
        # Conditional Sum panel
        self.conditional_sum_panel = QGroupBox("Conditional Sum Rule")
        cond_sum_layout = QGridLayout()
        
        cond_sum_layout.addWidget(QLabel("If Field:"), 0, 0)
        self.cond_sum_if_field = QComboBox()
        self.cond_sum_if_field.addItems(self.template_fieldnames)
        cond_sum_layout.addWidget(self.cond_sum_if_field, 0, 1)
        
        cond_sum_layout.addWidget(QLabel("Condition:"), 1, 0)
        self.cond_sum_if_condition = QComboBox()
        self.cond_sum_if_condition.addItems(["Equals", "Greater than", "Greater than or equal", "Not equals"])
        cond_sum_layout.addWidget(self.cond_sum_if_condition, 1, 1)
        
        cond_sum_layout.addWidget(QLabel("Value:"), 1, 2)
        self.cond_sum_if_value = QLineEdit()
        cond_sum_layout.addWidget(self.cond_sum_if_value, 1, 3)
        
        cond_sum_layout.addWidget(QLabel("Then Sum of Fields (comma-separated):"), 2, 0)
        self.cond_sum_fields = QLineEdit()
        self.cond_sum_fields.setPlaceholderText("e.g., CR, CS, HO, HD, HS")
        cond_sum_layout.addWidget(self.cond_sum_fields, 2, 1)
        
        cond_sum_layout.addWidget(QLabel("Comparison:"), 3, 0)
        self.cond_sum_comparison = QComboBox()
        self.cond_sum_comparison.addItems(["Equal to", "Greater than", "Greater than or equal"])
        cond_sum_layout.addWidget(self.cond_sum_comparison, 3, 1)
        
        cond_sum_layout.addWidget(QLabel("Target Value:"), 4, 0)
        self.cond_sum_target = QDoubleSpinBox()
        self.cond_sum_target.setMinimum(-999999)
        self.cond_sum_target.setMaximum(999999)
        self.cond_sum_target.setValue(100)
        cond_sum_layout.addWidget(self.cond_sum_target, 4, 1)
        
        cond_sum_layout.addWidget(QLabel("Tolerance (+/-):"), 5, 0)
        self.cond_sum_tolerance = QDoubleSpinBox()
        self.cond_sum_tolerance.setMinimum(0)
        self.cond_sum_tolerance.setMaximum(999999)
        self.cond_sum_tolerance.setValue(0.5)
        self.cond_sum_tolerance.setDecimals(2)
        cond_sum_layout.addWidget(self.cond_sum_tolerance, 5, 1)
        
        tolerance_note = QLabel("(Only applies to 'Equal to' comparison)")
        tolerance_note.setStyleSheet("font-size: 9px; color: #666;")
        cond_sum_layout.addWidget(tolerance_note, 5, 2)
        
        cond_sum_layout.addWidget(QLabel("Treat Blanks As:"), 6, 0)
        self.cond_sum_blank_as = QComboBox()
        self.cond_sum_blank_as.addItems(["0 (zero)", "Skip field"])
        cond_sum_layout.addWidget(self.cond_sum_blank_as, 6, 1)
        
        cond_sum_layout.addWidget(QLabel("Error Message:"), 7, 0)
        self.cond_sum_error = QLineEdit()
        cond_sum_layout.addWidget(self.cond_sum_error, 7, 1)
        
        self.conditional_sum_panel.setLayout(cond_sum_layout)
        self.editor_layout.addWidget(self.conditional_sum_panel)
        
        # Auto-Fill panel
        self.autofill_panel = QGroupBox("Auto-Fill Rule")
        autofill_layout = QGridLayout()
        
        autofill_layout.addWidget(QLabel("When Field:"), 0, 0)
        self.autofill_trigger_field = QComboBox()
        self.autofill_trigger_field.addItems(self.template_fieldnames)
        autofill_layout.addWidget(self.autofill_trigger_field, 0, 1)
        
        autofill_layout.addWidget(QLabel("Equals:"), 1, 0)
        self.autofill_trigger_value = QLineEdit()
        autofill_layout.addWidget(self.autofill_trigger_value, 1, 1)
        
        autofill_layout.addWidget(QLabel("Then Set Fields:"), 2, 0)
        autofill_layout.addWidget(QLabel("(Format: FIELD1=value1, FIELD2=value2)"), 3, 0, 1, 2)
        self.autofill_actions = QTextEdit()
        self.autofill_actions.setMaximumHeight(100)
        self.autofill_actions.setPlaceholderText("Example:\nSG_COVER=0, CR=NA, CS=NA, HO=NA, EPI_COVER=NA")
        autofill_layout.addWidget(self.autofill_actions, 4, 0, 1, 2)
        
        autofill_layout.addWidget(QLabel("Note: This will automatically fill fields when the trigger condition is met"), 5, 0, 1, 2)
        
        self.autofill_panel.setLayout(autofill_layout)
        self.editor_layout.addWidget(self.autofill_panel)
        
        # Calculated Field panel
        self.calculated_panel = QGroupBox("Calculated Field Rule")
        calc_layout = QGridLayout()
        
        calc_layout.addWidget(QLabel("Target Field:"), 0, 0)
        self.calc_target_field = QComboBox()
        self.calc_target_field.addItems(self.template_fieldnames)
        calc_layout.addWidget(self.calc_target_field, 0, 1)
        
        calc_layout.addWidget(QLabel("Formula:"), 1, 0)
        self.calc_formula = QLineEdit()
        self.calc_formula.setPlaceholderText("e.g., 100 - SG_COVER - AL_COVER - HC_COVER")
        calc_layout.addWidget(self.calc_formula, 1, 1)
        
        calc_layout.addWidget(QLabel("Decimal Places:"), 2, 0)
        self.calc_decimals = QSpinBox()
        self.calc_decimals.setMinimum(0)
        self.calc_decimals.setMaximum(10)
        self.calc_decimals.setValue(1)
        calc_layout.addWidget(self.calc_decimals, 2, 1)
        
        calc_layout.addWidget(QLabel("Formula Help:"), 3, 0, 1, 2)
        help_text = QLabel("Use field names and operators: +, -, *, /, ( )\nExample: 100 - SG_COVER - AL_COVER\nFields are replaced with their numeric values.\nBlank fields = 0")
        help_text.setStyleSheet("color: #666; font-size: 10px; padding: 5px; background-color: #f0f0f0; border-radius: 3px;")
        help_text.setWordWrap(True)
        calc_layout.addWidget(help_text, 4, 0, 1, 2)
        
        self.calculated_panel.setLayout(calc_layout)
        self.editor_layout.addWidget(self.calculated_panel)
    
    def rule_type_changed(self, rule_type):
        """Show/hide appropriate editor panel"""
        self.allowed_values_panel.hide()
        self.range_panel.hide()
        self.required_panel.hide()
        self.conditional_panel.hide()
        self.sum_panel.hide()
        self.conditional_sum_panel.hide()
        self.autofill_panel.hide()
        self.calculated_panel.hide()
        
        if rule_type == "Allowed Values":
            self.allowed_values_panel.show()
        elif rule_type == "Numeric Range":
            self.range_panel.show()
        elif rule_type == "Required Field":
            self.required_panel.show()
        elif rule_type == "Conditional (If-Then)":
            self.conditional_panel.show()
        elif rule_type == "Sum Equals":
            self.sum_panel.show()
        elif rule_type == "Conditional Sum":
            self.conditional_sum_panel.show()
        elif rule_type == "Auto-Fill":
            self.autofill_panel.show()
        elif rule_type == "Calculated Field":
            self.calculated_panel.show()
    
    def add_new_rule(self):
        """Prepare to add a new rule"""
        self.current_rule_index = -1
        self.clear_editor_fields()
        self.rules_list.clearSelection()
    
    def edit_selected_rule(self):
        """Load selected rule into editor"""
        if self.current_rule_index < 0 or self.current_rule_index >= len(self.rules):
            return
        
        rule = self.rules[self.current_rule_index]
        rule_type = rule.get('type')
        
        if rule_type == 'allowed_values':
            self.rule_type_combo.setCurrentText("Allowed Values")
            self.av_field.setCurrentText(rule.get('field', ''))
            self.av_values.setText(', '.join(map(str, rule.get('values', []))))
            self.av_error.setText(rule.get('error', ''))
        
        elif rule_type == 'range':
            self.rule_type_combo.setCurrentText("Numeric Range")
            self.range_field.setCurrentText(rule.get('field', ''))
            self.range_min.setValue(float(rule.get('min', 0)))
            self.range_max.setValue(float(rule.get('max', 100)))
            self.range_error.setText(rule.get('error', ''))
        
        elif rule_type == 'required':
            self.rule_type_combo.setCurrentText("Required Field")
            self.req_field.setCurrentText(rule.get('field', ''))
            self.req_error.setText(rule.get('error', ''))
        
        elif rule_type == 'conditional':
            self.rule_type_combo.setCurrentText("Conditional (If-Then)")
            self.cond_if_field.setCurrentText(rule.get('if_field', ''))
            self.cond_if_value.setText(str(rule.get('if_value', '')))
            self.cond_then_field.setCurrentText(rule.get('then_field', ''))
            
            # Map operator
            op_map = {
                'equals': 'Equal to',
                'not_equals': 'Not equal to',
                'greater_than': 'Greater than',
                'less_than': 'Less than',
                'greater_equal': 'Greater than or equal to',
                'less_equal': 'Less than or equal to'
            }
            self.cond_operator.setCurrentText(op_map.get(rule.get('then_condition', 'equals'), 'Equal to'))
            self.cond_then_value.setText(str(rule.get('then_value', '')))
            self.cond_error.setText(rule.get('error', ''))
        
        elif rule_type == 'sum_equals':
            self.rule_type_combo.setCurrentText("Sum Equals")
            self.sum_fields.setText(', '.join(rule.get('fields', [])))
            self.sum_value.setValue(float(rule.get('target', 100)))
            self.sum_tolerance.setValue(float(rule.get('tolerance', 0)))
            self.sum_error.setText(rule.get('error', ''))
        
        elif rule_type == 'conditional_sum':
            self.rule_type_combo.setCurrentText("Conditional Sum")
            self.cond_sum_if_field.setCurrentText(rule.get('if_field', ''))
            
            # Load IF condition operator (default to "Equals" for backward compatibility)
            if_condition = rule.get('if_condition', 'equals')
            if if_condition == 'equals':
                self.cond_sum_if_condition.setCurrentText("Equals")
            elif if_condition == 'greater':
                self.cond_sum_if_condition.setCurrentText("Greater than")
            elif if_condition == 'greater_equal':
                self.cond_sum_if_condition.setCurrentText("Greater than or equal")
            elif if_condition == 'not_equals':
                self.cond_sum_if_condition.setCurrentText("Not equals")
            
            self.cond_sum_if_value.setText(str(rule.get('if_value', '')))
            self.cond_sum_fields.setText(', '.join(rule.get('fields', [])))
            
            # Load SUM comparison operator (default to "Equal to" for backward compatibility)
            comparison = rule.get('comparison', 'equal')
            if comparison == 'equal':
                self.cond_sum_comparison.setCurrentText("Equal to")
            elif comparison == 'greater':
                self.cond_sum_comparison.setCurrentText("Greater than")
            elif comparison == 'greater_equal':
                self.cond_sum_comparison.setCurrentText("Greater than or equal")
            
            self.cond_sum_target.setValue(float(rule.get('target', 100)))
            self.cond_sum_tolerance.setValue(float(rule.get('tolerance', 0.5)))
            blank_as = "0 (zero)" if rule.get('blank_as_zero', True) else "Skip field"
            self.cond_sum_blank_as.setCurrentText(blank_as)
            self.cond_sum_error.setText(rule.get('error', ''))
        
        elif rule_type == 'autofill':
            self.rule_type_combo.setCurrentText("Auto-Fill")
            self.autofill_trigger_field.setCurrentText(rule.get('trigger_field', ''))
            self.autofill_trigger_value.setText(str(rule.get('trigger_value', '')))
            # Convert actions dict to text format
            actions = rule.get('actions', {})
            actions_text = ', '.join([f"{k}={v}" for k, v in actions.items()])
            self.autofill_actions.setPlainText(actions_text)
        
        elif rule_type == 'calculated':
            self.rule_type_combo.setCurrentText("Calculated Field")
            self.calc_target_field.setCurrentText(rule.get('target_field', ''))
            self.calc_formula.setText(rule.get('formula', ''))
            self.calc_decimals.setValue(int(rule.get('decimals', 1)))
    
    def delete_selected_rule(self):
        """Delete the selected rule"""
        if self.current_rule_index < 0 or self.current_rule_index >= len(self.rules):
            return
        
        reply = QMessageBox.question(
            self, "Confirm Delete",
            "Are you sure you want to delete this rule?",
            QMessageBox.Yes | QMessageBox.No
        )
        
        if reply == QMessageBox.Yes:
            del self.rules[self.current_rule_index]
            self.current_rule_index = -1
            self.refresh_rules_list()
            self.clear_editor_fields()
    
    def save_current_rule(self):
        """Save the current rule from editor"""
        rule_type = self.rule_type_combo.currentText()
        
        try:
            if rule_type == "Allowed Values":
                rule = {
                    'type': 'allowed_values',
                    'field': self.av_field.currentText(),
                    'values': [v.strip() for v in self.av_values.text().split(',')],
                    'error': self.av_error.text() or f"{self.av_field.currentText()} must be one of: {self.av_values.text()}"
                }
            
            elif rule_type == "Numeric Range":
                rule = {
                    'type': 'range',
                    'field': self.range_field.currentText(),
                    'min': self.range_min.value(),
                    'max': self.range_max.value(),
                    'error': self.range_error.text() or f"{self.range_field.currentText()} must be between {self.range_min.value()} and {self.range_max.value()}"
                }
            
            elif rule_type == "Required Field":
                rule = {
                    'type': 'required',
                    'field': self.req_field.currentText(),
                    'error': self.req_error.text() or f"{self.req_field.currentText()} is required"
                }
            
            elif rule_type == "Conditional (If-Then)":
                op_map = {
                    'Equal to': 'equals',
                    'Not equal to': 'not_equals',
                    'Greater than': 'greater_than',
                    'Less than': 'less_than',
                    'Greater than or equal to': 'greater_equal',
                    'Less than or equal to': 'less_equal'
                }
                rule = {
                    'type': 'conditional',
                    'if_field': self.cond_if_field.currentText(),
                    'if_value': self.cond_if_value.text(),
                    'then_field': self.cond_then_field.currentText(),
                    'then_condition': op_map[self.cond_operator.currentText()],
                    'then_value': self.cond_then_value.text(),
                    'error': self.cond_error.text() or f"If {self.cond_if_field.currentText()}={self.cond_if_value.text()}, then {self.cond_then_field.currentText()} must be {self.cond_operator.currentText().lower()} {self.cond_then_value.text()}"
                }
            
            elif rule_type == "Sum Equals":
                fields = [f.strip() for f in self.sum_fields.text().split(',')]
                rule = {
                    'type': 'sum_equals',
                    'fields': fields,
                    'target': self.sum_value.value(),
                    'tolerance': self.sum_tolerance.value(),
                    'error': self.sum_error.text() or f"Sum of {', '.join(fields)} must equal {self.sum_value.value()}"
                }
            
            elif rule_type == "Conditional Sum":
                fields = [f.strip() for f in self.cond_sum_fields.text().split(',')]
                blank_as_zero = self.cond_sum_blank_as.currentText() == "0 (zero)"
                
                # Convert IF condition text to internal format
                if_condition_text = self.cond_sum_if_condition.currentText()
                if if_condition_text == "Greater than":
                    if_condition = 'greater'
                    if_condition_desc = ">"
                elif if_condition_text == "Greater than or equal":
                    if_condition = 'greater_equal'
                    if_condition_desc = ">="
                elif if_condition_text == "Not equals":
                    if_condition = 'not_equals'
                    if_condition_desc = "!="
                else:
                    if_condition = 'equals'
                    if_condition_desc = "="
                
                # Convert SUM comparison text to internal format
                comparison_text = self.cond_sum_comparison.currentText()
                if comparison_text == "Greater than":
                    comparison = 'greater'
                    comparison_desc = "be greater than"
                elif comparison_text == "Greater than or equal":
                    comparison = 'greater_equal'
                    comparison_desc = "be greater than or equal to"
                else:
                    comparison = 'equal'
                    comparison_desc = "equal"
                
                rule = {
                    'type': 'conditional_sum',
                    'if_field': self.cond_sum_if_field.currentText(),
                    'if_condition': if_condition,
                    'if_value': self.cond_sum_if_value.text(),
                    'fields': fields,
                    'comparison': comparison,
                    'target': self.cond_sum_target.value(),
                    'tolerance': self.cond_sum_tolerance.value(),
                    'blank_as_zero': blank_as_zero,
                    'error': self.cond_sum_error.text() or f"If {self.cond_sum_if_field.currentText()}{if_condition_desc}{self.cond_sum_if_value.text()}, sum of {', '.join(fields)} must {comparison_desc} {self.cond_sum_target.value()}"
                }
            
            elif rule_type == "Auto-Fill":
                # Parse actions text: "FIELD1=value1, FIELD2=value2"
                actions_text = self.autofill_actions.toPlainText().strip()
                actions = {}
                for action in actions_text.split(','):
                    if '=' in action:
                        field, value = action.split('=', 1)
                        actions[field.strip()] = value.strip()
                
                if not actions:
                    QMessageBox.warning(self, "Invalid Actions", "Please specify at least one field=value pair")
                    return
                
                rule = {
                    'type': 'autofill',
                    'trigger_field': self.autofill_trigger_field.currentText(),
                    'trigger_value': self.autofill_trigger_value.text(),
                    'actions': actions
                }
            
            elif rule_type == "Calculated Field":
                formula = self.calc_formula.text().strip()
                
                if not formula:
                    QMessageBox.warning(self, "Invalid Formula", "Please specify a formula")
                    return
                
                rule = {
                    'type': 'calculated',
                    'target_field': self.calc_target_field.currentText(),
                    'formula': formula,
                    'decimals': self.calc_decimals.value()
                }
            
            # Add or update rule
            if self.current_rule_index >= 0 and self.current_rule_index < len(self.rules):
                self.rules[self.current_rule_index] = rule
            else:
                self.rules.append(rule)
            
            self.refresh_rules_list()
            self.clear_editor_fields()
            self.current_rule_index = -1
            
            QMessageBox.information(self, "Success", "Rule saved successfully!")
        
        except Exception as e:
            QMessageBox.warning(self, "Error", f"Failed to save rule: {str(e)}")
    
    def cancel_edit(self):
        """Cancel editing"""
        self.clear_editor_fields()
        self.current_rule_index = -1
        self.rules_list.clearSelection()
    
    def clear_editor_fields(self):
        """Clear all editor fields"""
        self.av_field.setCurrentIndex(0)
        self.av_values.clear()
        self.av_error.clear()
        
        self.range_field.setCurrentIndex(0)
        self.range_min.setValue(0)
        self.range_max.setValue(100)
        self.range_error.clear()
        
        self.req_field.setCurrentIndex(0)
        self.req_error.clear()
        
        self.cond_if_field.setCurrentIndex(0)
        self.cond_if_value.clear()
        self.cond_then_field.setCurrentIndex(0)
        self.cond_operator.setCurrentIndex(0)
        self.cond_then_value.clear()
        self.cond_error.clear()
        
        self.sum_fields.clear()
        self.sum_value.setValue(100)
        self.sum_tolerance.setValue(0)
        self.sum_error.clear()
        
        self.cond_sum_if_field.setCurrentIndex(0)
        self.cond_sum_if_value.clear()
        self.cond_sum_fields.clear()
        self.cond_sum_target.setValue(100)
        self.cond_sum_tolerance.setValue(0.5)
        self.cond_sum_blank_as.setCurrentIndex(0)
        self.cond_sum_error.clear()
        
        self.autofill_trigger_field.setCurrentIndex(0)
        self.autofill_trigger_value.clear()
        self.autofill_actions.clear()
        
        self.calc_target_field.setCurrentIndex(0)
        self.calc_formula.clear()
        self.calc_decimals.setValue(1)
    
    def rule_selected(self, item):
        """Handle rule selection from list"""
        self.current_rule_index = self.rules_list.row(item)
        self.edit_rule_btn.setEnabled(True)
        self.delete_rule_btn.setEnabled(True)
    
    def refresh_rules_list(self):
        """Refresh the rules list display"""
        self.rules_list.clear()
        self.edit_rule_btn.setEnabled(False)
        self.delete_rule_btn.setEnabled(False)
        
        for i, rule in enumerate(self.rules):
            rule_desc = self.format_rule_description(rule)
            item = QListWidgetItem(f"{i+1}. {rule_desc}")
            self.rules_list.addItem(item)
    
    def format_rule_description(self, rule):
        """Format a rule for display"""
        rule_type = rule.get('type')
        
        if rule_type == 'allowed_values':
            return f"{rule['field']} must be one of: {', '.join(map(str, rule['values']))}"
        
        elif rule_type == 'range':
            return f"{rule['field']} must be between {rule['min']} and {rule['max']}"
        
        elif rule_type == 'required':
            return f"{rule['field']} is required"
        
        elif rule_type == 'conditional':
            op_text = {
                'equals': '=',
                'not_equals': '≠',
                'greater_than': '>',
                'less_than': '<',
                'greater_equal': '≥',
                'less_equal': '≤'
            }.get(rule.get('then_condition'), '=')
            return f"If {rule['if_field']}={rule['if_value']}, then {rule['then_field']} {op_text} {rule['then_value']}"
        
        elif rule_type == 'sum_equals':
            return f"Sum of {', '.join(rule['fields'])} must equal {rule['target']}"
        
        elif rule_type == 'conditional_sum':
            # Format IF condition
            if_condition = rule.get('if_condition', 'equals')
            if if_condition == 'greater':
                if_symbol = ">"
            elif if_condition == 'greater_equal':
                if_symbol = ">="
            elif if_condition == 'not_equals':
                if_symbol = "!="
            else:
                if_symbol = "="
            
            # Format SUM comparison
            comparison = rule.get('comparison', 'equal')
            if comparison == 'greater':
                comp_text = "be greater than"
            elif comparison == 'greater_equal':
                comp_text = "be >= "
            else:
                comp_text = "equal"
            return f"If {rule['if_field']}{if_symbol}{rule['if_value']}, sum of {', '.join(rule['fields'])} must {comp_text} {rule['target']}"
        
        elif rule_type == 'autofill':
            actions_str = ', '.join([f"{k}={v}" for k, v in rule.get('actions', {}).items()])
            return f"When {rule['trigger_field']}={rule['trigger_value']}, auto-set: {actions_str}"
        
        elif rule_type == 'calculated':
            return f"Calculate {rule['target_field']} = {rule['formula']}"
        
        return "Unknown rule"
    
    def get_rules(self):
        """Return the current rules list"""
        return self.rules


class MapDialog(QDialog):
    """Dialog for displaying points on a Leaflet map"""
    def __init__(self, points_data, current_point_id, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Point Locations Map")
        self.setGeometry(100, 100, 1000, 700)
        
        # Store data
        self.points_data = points_data  # List of dicts with point_id, lat, lon
        self.current_point_id = current_point_id
        
        # Setup UI
        layout = QVBoxLayout()
        
        # Create web view
        self.web_view = QWebEngineView()
        
        # Generate and load HTML
        html = self.generate_map_html()
        self.web_view.setHtml(html)
        
        layout.addWidget(self.web_view)
        
        # Close button
        close_btn = QPushButton("Close")
        close_btn.clicked.connect(self.accept)
        layout.addWidget(close_btn)
        
        self.setLayout(layout)
    
    def generate_map_html(self):
        """Generate HTML with Leaflet map"""
        # Calculate center of map (use current point if available, otherwise first point)
        if self.points_data:
            current_point = next((p for p in self.points_data if p['point_id'] == self.current_point_id), None)
            if current_point:
                center_lat = current_point['lat']
                center_lon = current_point['lon']
            else:
                center_lat = self.points_data[0]['lat']
                center_lon = self.points_data[0]['lon']
        else:
            center_lat = -10.0
            center_lon = 142.0
        
        # Build markers JavaScript
        markers_js = []
        for point in self.points_data:
            is_current = point['point_id'] == self.current_point_id
            color = 'red' if is_current else 'blue'
            icon_html = f"'<div style=\"background-color: {color}; width: 25px; height: 25px; border-radius: 50%; border: 3px solid white; box-shadow: 0 0 5px rgba(0,0,0,0.5);\"></div>'"
            
            # Build popup content with available fields
            popup_content = f"<div style='min-width: 200px;'><h3 style='margin: 0 0 10px 0; color: {color};'>{point['point_id']}</h3>"
            popup_content += f"<b>Latitude:</b> {point['lat']:.6f}<br>"
            popup_content += f"<b>Longitude:</b> {point['lon']:.6f}<br>"
            
            # Add optional fields if present
            if 'location' in point and point['location'] != 'N/A':
                popup_content += f"<b>Location:</b> {point['location']}<br>"
            if 'depth' in point and point['depth'] != 'N/A':
                popup_content += f"<b>Depth:</b> {point['depth']}<br>"
            if 'date' in point and point['date'] != 'N/A':
                popup_content += f"<b>Date:</b> {point['date']}<br>"
            if 'substrate' in point and point['substrate'] != 'N/A':
                popup_content += f"<b>Substrate:</b> {point['substrate']}<br>"
            if 'mode' in point and point['mode'] != 'N/A':
                popup_content += f"<b>Mode:</b> {point['mode']}<br>"
            
            popup_content += "</div>"
            
            # Escape single quotes in popup content for JavaScript
            popup_content = popup_content.replace("'", "\\'")
            
            marker_js = f"""
            L.marker([{point['lat']}, {point['lon']}], {{
                icon: L.divIcon({{
                    className: 'custom-div-icon',
                    html: {icon_html},
                    iconSize: [25, 25],
                    iconAnchor: [12, 12]
                }})
            }}).addTo(map).bindPopup('{popup_content}');
            
            // Add permanent label
            L.marker([{point['lat']}, {point['lon']}], {{
                icon: L.divIcon({{
                    className: 'point-label',
                    html: '<div style="color: white; font-weight: bold; font-size: 13px; white-space: nowrap; text-shadow: 2px 2px 3px rgba(0,0,0,0.8), -1px -1px 2px rgba(0,0,0,0.8), 1px -1px 2px rgba(0,0,0,0.8), -1px 1px 2px rgba(0,0,0,0.8);">{point['point_id']}</div>',
                    iconSize: null,
                    iconAnchor: [-18, 0]
                }})
            }}).addTo(map);
            """
            markers_js.append(marker_js)
        
        markers_code = '\n'.join(markers_js)
        
        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Point Locations</title>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
            <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
            <style>
                body {{ margin: 0; padding: 0; }}
                #map {{ height: 100vh; width: 100%; }}
                .point-label {{
                    pointer-events: none; /* Allow clicking through labels to markers */
                }}
                .leaflet-popup-content-wrapper {{
                    border-radius: 8px;
                }}
                .leaflet-popup-content {{
                    margin: 10px 15px;
                    font-family: Arial, sans-serif;
                    font-size: 13px;
                    line-height: 1.6;
                }}
                .legend {{
                    background: white;
                    padding: 10px;
                    border-radius: 5px;
                    box-shadow: 0 2px 5px rgba(0,0,0,0.3);
                    line-height: 24px;
                    font-family: Arial, sans-serif;
                    font-size: 13px;
                }}
                .legend-item {{
                    margin: 5px 0;
                }}
                .legend-icon {{
                    display: inline-block;
                    width: 18px;
                    height: 18px;
                    border-radius: 50%;
                    border: 2px solid white;
                    margin-right: 8px;
                    vertical-align: middle;
                    box-shadow: 0 0 3px rgba(0,0,0,0.5);
                }}
            </style>
        </head>
        <body>
            <div id="map"></div>
            <script>
                // Initialize map
                var map = L.map('map').setView([{center_lat}, {center_lon}], 13);
                
                // Add satellite basemap (Esri World Imagery)
                L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{{z}}/{{y}}/{{x}}', {{
                    attribution: 'Tiles &copy; Esri &mdash; Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community',
                    maxZoom: 18
                }}).addTo(map);
                
                // Add markers
                {markers_code}
                
                // Add legend
                var legend = L.control({{ position: 'bottomright' }});
                legend.onAdd = function (map) {{
                    var div = L.DomUtil.create('div', 'legend');
                    div.innerHTML = '<h4 style="margin: 0 0 8px 0;">Point Locations</h4>';
                    div.innerHTML += '<div class="legend-item"><span class="legend-icon" style="background-color: red;"></span>Current Video Point</div>';
                    div.innerHTML += '<div class="legend-item"><span class="legend-icon" style="background-color: blue;"></span>Other Points</div>';
                    return div;
                }};
                legend.addTo(map);
            </script>
        </body>
        </html>
        """
        return html


class DetachedDataEntryWindow(QMainWindow):
    """Separate window for data entry pane (dual-screen mode)"""
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Data Entry Panel")
        self.setGeometry(200, 100, 500, 900)
        
    def set_data_entry_widget(self, widget):
        """Set the data entry widget as central widget"""
        self.setCentralWidget(widget)
    
    def closeEvent(self, event):
        """Handle window close - reattach to main window"""
        if self.parent():
            self.parent().reattach_data_entry_pane()
        event.accept()


class VideoPlayer(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("MP4 Video Player & Frame Extractor")
        self.setGeometry(100, 100, 1600, 900)
        
        # Video variables
        self.cap = None
        self.video_path = None
        self.is_playing = False
        self.total_frames = 0
        self.fps = 30
        self.current_frame = 0
        self.playback_speed = 1.0
        self.zoom_level = 1.0
        self.cached_frame = None
        self.cached_frame_number = -1
        
        # Auto-loader variables
        self.video_queue = []
        self.current_video_index = 0
        self.drop_counter = 1  # Counter for saved stills
        
        # Get the correct application path (works for both .py and .exe)
        if getattr(sys, 'frozen', False):
            # Running as compiled executable
            application_path = os.path.dirname(sys.executable)
        else:
            # Running as script
            application_path = os.path.dirname(os.path.abspath(__file__))
        
        self.drop_videos_dir = os.path.join(application_path, 'drop_videos')
        self.drop_stills_dir = os.path.join(application_path, 'drop_stills')
        self.data_dir = os.path.join(application_path, 'data')
        self.projects_dir = os.path.join(application_path, 'projects')
        os.makedirs(self.projects_dir, exist_ok=True)
        
        # Project state variables
        self.current_project_file = None
        
        # Data entry variables
        self.data_fields = {}
        self.template_fieldnames = []  # Store fieldnames from template CSV
        self.base_data = {}  # Store preloaded base data from CSV
        self.base_data_csv = []  # Store all rows from loaded base CSV
        self.base_data_csv_path = None  # Store path to loaded base CSV file
        self.all_data_entries = []  # List of all data entries (only created on frame extraction)
        self.current_entry_index = -1  # Current position in data entries (-1 means no entries yet)
        self.unsaved_changes = False  # Track if current entry has unsaved changes
        
        print("Initialized: all_data_entries=[], current_entry_index=-1")
        
        # Validation rules variables
        self.validation_rules = []  # List of validation rules
        self.template_path = None  # Store template path for rules file naming
        
        # Fields that should NOT be copied from previous entry (metadata/unique fields)
        self.non_copyable_fields = [
            'DROP_ID', 'POINT_ID', 'FILENAME', 
            'LATITUDE', 'LONGITUDE', 'GPS_MARK',
            'DATE', 'TIME', 'DATE_TIME', 'YEAR',
            'VIDEO_FILENAME', 'VIDEO_TIMESTAMP', 'GPS_DATETIME'
        ]
        
        # Timer for video playback
        self.timer = QTimer()
        self.timer.timeout.connect(self.play_next_frame)
        
        # Layout mode variables
        self.is_detached_mode = False
        self.detached_window = None
        
        self.init_ui()
        self.setup_shortcuts()
        
        # Show startup dialogs after UI is initialized
        QTimer.singleShot(100, self.show_startup_dialogs_delayed)
    
    def show_startup_dialogs_delayed(self):
        """Show startup dialogs after UI is ready"""
        if not self.show_startup_dialogs():
            # User cancelled, close application
            self.close()
    
    def show_startup_dialogs(self):
        """Show startup dialogs to load template and optional base CSV"""
        # Step 0: Ask if user wants to start new project or load existing
        project_msg = QMessageBox()
        project_msg.setIcon(QMessageBox.Question)
        project_msg.setWindowTitle("Drop Cam Video Analysis - Start")
        project_msg.setText(
            "Welcome to Drop Cam Video Analysis!\n\n"
            "Would you like to:\n\n"
            "• Start a NEW project (setup from scratch)\n"
            "• Load an EXISTING project (resume where you left off)"
        )
        
        new_btn = project_msg.addButton("New Project", QMessageBox.ActionRole)
        load_btn = project_msg.addButton("Load Existing Project", QMessageBox.ActionRole)
        cancel_btn = project_msg.addButton(QMessageBox.Cancel)
        
        project_msg.exec_()
        
        if project_msg.clickedButton() == cancel_btn:
            return False
        
        if project_msg.clickedButton() == load_btn:
            # Load existing project
            if self.load_project():
                return True
            else:
                # Loading failed, ask if they want to start new instead
                retry = QMessageBox.question(
                    self, "Load Failed",
                    "Failed to load project.\n\nWould you like to start a new project instead?",
                    QMessageBox.Yes | QMessageBox.No
                )
                if retry == QMessageBox.No:
                    return False
                # Continue to new project setup below
        
        # Step 1: Load template CSV (required)
        template_msg = QMessageBox()
        template_msg.setIcon(QMessageBox.Information)
        template_msg.setWindowTitle("Load Data Entry Template")
        template_msg.setText("Please select a data entry template CSV file.\n\nThis defines the column names for your data entries.")
        template_msg.setStandardButtons(QMessageBox.Ok | QMessageBox.Cancel)
        
        if template_msg.exec_() == QMessageBox.Cancel:
            return False
        
        template_path, _ = QFileDialog.getOpenFileName(
            self, "Select Data Entry Template CSV", self.data_dir,
            "CSV Files (*.csv);;All Files (*.*)"
        )
        
        if not template_path:
            QMessageBox.warning(self, "No Template", "A template CSV is required to continue.")
            return False
        
        # Store template path for later use
        self.template_path = template_path
        
        # Load template fieldnames
        try:
            with open(template_path, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                self.template_fieldnames = reader.fieldnames
                if not self.template_fieldnames:
                    QMessageBox.critical(self, "Invalid Template", "The template CSV has no column headers.")
                    return False
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Failed to load template CSV:\n{str(e)}")
            return False
        
        # Auto-load validation rules if they exist
        self.load_validation_rules()
        
        # Step 2: Ask if user wants to load base CSV (optional)
        base_msg = QMessageBox()
        base_msg.setIcon(QMessageBox.Question)
        base_msg.setWindowTitle("Load Base CSV (Optional)")
        base_msg.setText("Do you want to load a base CSV to pre-populate fields?\n\n"
                        "This is useful if you have location/metadata information for your videos.")
        base_msg.setStandardButtons(QMessageBox.Yes | QMessageBox.No)
        
        if base_msg.exec_() == QMessageBox.Yes:
            base_path, _ = QFileDialog.getOpenFileName(
                self, "Select Base CSV (Optional)", self.data_dir,
                "CSV Files (*.csv);;All Files (*.*)"
            )
            
            if base_path:
                try:
                    with open(base_path, 'r', encoding='utf-8') as f:
                        reader = csv.DictReader(f)
                        self.base_data_csv = list(reader)
                        self.base_data_csv_path = base_path  # Store the path
                    
                    QMessageBox.information(
                        self, "Base CSV Loaded",
                        f"Loaded {len(self.base_data_csv)} rows from base CSV.\n\n"
                        f"Data will auto-populate when extracting stills."
                    )
                except Exception as e:
                    QMessageBox.warning(self, "Error", f"Failed to load base CSV:\n{str(e)}\n\nContinuing without base data.")
        
        # Now create the data entry pane with the loaded template
        self.create_data_entry_pane()
        
        # Replace placeholder with actual data entry widget
        self.main_layout.removeWidget(self.data_entry_placeholder)
        self.data_entry_placeholder.deleteLater()
        self.main_layout.addWidget(self.data_entry_widget, 1)
        
        # Auto-fill connections are set up during field creation (no need for separate setup)
        
        return True
        
    def init_ui(self):
        """Initialize the user interface"""
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QHBoxLayout()
        
        # Left side: Video player
        video_layout = QVBoxLayout()
        
        # Scroll area for video display (enables zooming without expanding UI)
        self.video_scroll = QScrollArea()
        self.video_scroll.setWidgetResizable(False)  # Allow scrolling when zoomed
        self.video_scroll.setAlignment(Qt.AlignCenter)
        self.video_scroll.setStyleSheet("QScrollArea { background-color: black; }")
        
        # Video display label
        self.video_label = QLabel("Open a video file to start")
        self.video_label.setAlignment(Qt.AlignCenter)
        self.video_label.setStyleSheet("QLabel { background-color: black; color: white; }")
        
        self.video_scroll.setWidget(self.video_label)
        video_layout.addWidget(self.video_scroll, 1)  # Stretch factor 1 to take available space
        
        # Frame info label
        self.info_label = QLabel("Frame: 0 / 0 | Time: 00:00:00")
        self.info_label.setAlignment(Qt.AlignCenter)
        video_layout.addWidget(self.info_label)
        
        # Timeline slider
        self.timeline_slider = QSlider(Qt.Horizontal)
        self.timeline_slider.setMinimum(0)
        self.timeline_slider.setMaximum(0)
        self.timeline_slider.setToolTip("Drag to navigate through video frames")
        self.timeline_slider.setPageStep(100)  # Jump 100 frames when clicking on slider track
        self.timeline_slider.setSingleStep(1)  # Move 1 frame with arrow keys
        self.timeline_slider.valueChanged.connect(self.slider_changed)
        video_layout.addWidget(self.timeline_slider)
        
        # Control buttons layout - Row 1: Main controls
        controls_layout = QHBoxLayout()
        controls_layout.setSpacing(4)  # Reduce spacing between buttons
        
        # Save Project button
        self.save_project_btn = QPushButton("💾")
        self.save_project_btn.setToolTip("Save Project")
        self.save_project_btn.clicked.connect(lambda: self.save_project())
        self.save_project_btn.setStyleSheet("background-color: #9C27B0; color: white; font-weight: bold; padding: 5px;")
        self.save_project_btn.setMaximumWidth(40)
        controls_layout.addWidget(self.save_project_btn)
        
        # Show on Map button
        self.show_map_btn = QPushButton("🗺")
        self.show_map_btn.setToolTip("Show on Map")
        self.show_map_btn.clicked.connect(self.show_map)
        self.show_map_btn.setStyleSheet("background-color: #2196F3; color: white; font-weight: bold; padding: 5px;")
        self.show_map_btn.setMaximumWidth(40)
        controls_layout.addWidget(self.show_map_btn)
        
        # Help/Instructions button
        self.help_btn = QPushButton("❓")
        self.help_btn.setToolTip("Instructions")
        self.help_btn.clicked.connect(self.show_instructions)
        self.help_btn.setStyleSheet("background-color: #2196F3; color: white; font-weight: bold; padding: 5px;")
        self.help_btn.setMaximumWidth(40)
        controls_layout.addWidget(self.help_btn)
        
        # Layout toggle button (dual-screen mode)
        self.layout_toggle_btn = QPushButton("⬌")
        self.layout_toggle_btn.setToolTip("Toggle Dual-Screen Mode (Detach/Attach Data Entry Panel)")
        self.layout_toggle_btn.clicked.connect(self.toggle_layout_mode)
        self.layout_toggle_btn.setStyleSheet("background-color: #FF5722; color: white; font-weight: bold; padding: 5px;")
        self.layout_toggle_btn.setMaximumWidth(40)
        controls_layout.addWidget(self.layout_toggle_btn)
        
        # Open file button
        self.open_btn = QPushButton("Open")
        self.open_btn.setToolTip("Open video file")
        self.open_btn.clicked.connect(self.open_video)
        self.open_btn.setMaximumWidth(60)
        controls_layout.addWidget(self.open_btn)
        
        # Play/Pause button
        self.play_btn = QPushButton("▶")
        self.play_btn.setToolTip("Play/Pause")
        self.play_btn.clicked.connect(self.toggle_play)
        self.play_btn.setEnabled(False)
        self.play_btn.setMaximumWidth(40)
        controls_layout.addWidget(self.play_btn)
        
        # Previous frame button
        self.prev_frame_btn = QPushButton("◀")
        self.prev_frame_btn.setToolTip("Previous Frame")
        self.prev_frame_btn.clicked.connect(self.previous_frame)
        self.prev_frame_btn.setEnabled(False)
        self.prev_frame_btn.setMaximumWidth(40)
        controls_layout.addWidget(self.prev_frame_btn)
        
        # Next frame button
        self.next_frame_btn = QPushButton("▶")
        self.next_frame_btn.setToolTip("Next Frame")
        self.next_frame_btn.clicked.connect(self.next_frame)
        self.next_frame_btn.setEnabled(False)
        self.next_frame_btn.setMaximumWidth(40)
        controls_layout.addWidget(self.next_frame_btn)
        
        # Skip backward button (10 frames)
        self.skip_back_btn = QPushButton("◀◀")
        self.skip_back_btn.setToolTip("Skip -10 frames")
        self.skip_back_btn.clicked.connect(lambda: self.skip_frames(-10))
        self.skip_back_btn.setEnabled(False)
        self.skip_back_btn.setMaximumWidth(45)
        controls_layout.addWidget(self.skip_back_btn)
        
        # Skip forward button (10 frames)
        self.skip_forward_btn = QPushButton("▶▶")
        self.skip_forward_btn.setToolTip("Skip +10 frames")
        self.skip_forward_btn.clicked.connect(lambda: self.skip_frames(10))
        self.skip_forward_btn.setEnabled(False)
        self.skip_forward_btn.setMaximumWidth(45)
        controls_layout.addWidget(self.skip_forward_btn)
        
        # Speed control
        speed_label = QLabel("Speed:")
        controls_layout.addWidget(speed_label)
        self.speed_combo = QComboBox()
        self.speed_combo.addItems(["0.25x", "0.5x", "1x", "2x", "4x", "8x", "12x"])
        self.speed_combo.setCurrentIndex(2)  # 1x default
        self.speed_combo.setToolTip("Playback speed")
        self.speed_combo.currentTextChanged.connect(self.change_speed)
        self.speed_combo.setEnabled(False)
        self.speed_combo.setMaximumWidth(80)
        controls_layout.addWidget(self.speed_combo)
        
        # Zoom control
        zoom_label = QLabel("Zoom:")
        controls_layout.addWidget(zoom_label)
        self.zoom_slider = QSlider(Qt.Horizontal)
        self.zoom_slider.setMinimum(50)  # 50% = 0.5x
        self.zoom_slider.setMaximum(400)  # 400% = 4.0x
        self.zoom_slider.setValue(100)  # 100% = 1.0x
        self.zoom_slider.setToolTip("Zoom video (50% - 400%)")
        self.zoom_slider.setTickPosition(QSlider.TicksBelow)
        self.zoom_slider.setTickInterval(50)
        self.zoom_slider.setMaximumWidth(120)
        self.zoom_slider.valueChanged.connect(self.change_zoom)
        self.zoom_slider.setEnabled(False)
        controls_layout.addWidget(self.zoom_slider)
        
        self.zoom_label = QLabel("100%")
        self.zoom_label.setMinimumWidth(45)
        self.zoom_label.setStyleSheet("font-size: 11px;")
        controls_layout.addWidget(self.zoom_label)
        
        # Extract current frame button
        self.extract_btn = QPushButton("Extract")
        self.extract_btn.setToolTip("Extract Current Frame")
        self.extract_btn.clicked.connect(self.extract_current_frame)
        self.extract_btn.setEnabled(False)
        self.extract_btn.setMaximumWidth(70)
        controls_layout.addWidget(self.extract_btn)
        
        controls_layout.addStretch()  # Push everything to the left
        
        video_layout.addLayout(controls_layout)
        
        # Auto-loader controls
        autoload_layout = QHBoxLayout()
        autoload_layout.setSpacing(4)
        
        # Load videos from drop_videos button
        self.autoload_btn = QPushButton("Load drop_videos/")
        self.autoload_btn.setToolTip("Load all videos from the drop_videos folder")
        self.autoload_btn.clicked.connect(self.load_video_queue)
        self.autoload_btn.setMaximumWidth(130)
        autoload_layout.addWidget(self.autoload_btn)
        
        # Choose video folder button
        self.choose_folder_btn = QPushButton("Choose Folder...")
        self.choose_folder_btn.setToolTip("Choose a custom folder containing videos")
        self.choose_folder_btn.clicked.connect(self.choose_video_folder)
        self.choose_folder_btn.setMaximumWidth(110)
        autoload_layout.addWidget(self.choose_folder_btn)
        
        # Previous video button
        self.prev_video_btn = QPushButton("◀ Prev")
        self.prev_video_btn.setToolTip("Previous Video")
        self.prev_video_btn.clicked.connect(self.previous_video)
        self.prev_video_btn.setEnabled(False)
        self.prev_video_btn.setMaximumWidth(60)
        autoload_layout.addWidget(self.prev_video_btn)
        
        # Next video button
        self.next_video_btn = QPushButton("Next ▶")
        self.next_video_btn.setToolTip("Next Video")
        self.next_video_btn.clicked.connect(self.next_video)
        self.next_video_btn.setEnabled(False)
        self.next_video_btn.setMaximumWidth(60)
        autoload_layout.addWidget(self.next_video_btn)
        
        # Video queue status label
        self.queue_label = QLabel("No videos")
        self.queue_label.setStyleSheet("font-size: 11px;")
        autoload_layout.addWidget(self.queue_label)
        autoload_layout.addStretch()
        
        video_layout.addLayout(autoload_layout)
        
        # Add video layout to main layout
        main_layout.addLayout(video_layout, 2)
        
        # Right side: Data entry pane (placeholder - will be created after template loads)
        self.data_entry_placeholder = QLabel("Data entry form will appear after loading template...")
        self.data_entry_placeholder.setAlignment(Qt.AlignCenter)
        self.data_entry_placeholder.setStyleSheet("padding: 20px; color: gray;")
        main_layout.addWidget(self.data_entry_placeholder, 1)
        
        central_widget.setLayout(main_layout)
        self.main_layout = main_layout  # Store reference for later
        
    def setup_shortcuts(self):
        """Setup keyboard shortcuts"""
        # Space for play/pause
        self.play_shortcut = QShortcut(QKeySequence(Qt.Key_Space), self)
        self.play_shortcut.activated.connect(self.toggle_play)
        
        # Left arrow for previous frame
        self.prev_shortcut = QShortcut(QKeySequence(Qt.Key_Left), self)
        self.prev_shortcut.activated.connect(self.previous_frame)
        
        # Right arrow for next frame
        self.next_shortcut = QShortcut(QKeySequence(Qt.Key_Right), self)
        self.next_shortcut.activated.connect(self.next_frame)
        
        # Shift+Left for skip back 10 frames
        self.skip_back_shortcut = QShortcut(QKeySequence(Qt.SHIFT | Qt.Key_Left), self)
        self.skip_back_shortcut.activated.connect(lambda: self.skip_frames(-10))
        
        # Shift+Right for skip forward 10 frames
        self.skip_forward_shortcut = QShortcut(QKeySequence(Qt.SHIFT | Qt.Key_Right), self)
        self.skip_forward_shortcut.activated.connect(lambda: self.skip_frames(10))
        
        # Ctrl+Left for skip back 100 frames
        self.skip_back_100_shortcut = QShortcut(QKeySequence(Qt.CTRL | Qt.Key_Left), self)
        self.skip_back_100_shortcut.activated.connect(lambda: self.skip_frames(-100))
        
        # Ctrl+Right for skip forward 100 frames
        self.skip_forward_100_shortcut = QShortcut(QKeySequence(Qt.CTRL | Qt.Key_Right), self)
        self.skip_forward_100_shortcut.activated.connect(lambda: self.skip_frames(100))
        
        # S for extract frame
        self.extract_shortcut = QShortcut(QKeySequence(Qt.Key_S), self)
        self.extract_shortcut.activated.connect(self.extract_current_frame)
    
    def create_data_entry_pane(self):
        """Create the data entry pane for field observations based on template"""
        # Create scroll area for data entry
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setMinimumWidth(400)
        
        # Container widget
        container = QWidget()
        layout = QVBoxLayout()
        
        # Title and navigation
        title = QLabel("Data Entry")
        title.setStyleSheet("font-size: 16px; font-weight: bold; padding: 5px;")
        title.setAlignment(Qt.AlignCenter)
        layout.addWidget(title)
        
        # Navigation controls
        nav_layout = QHBoxLayout()
        
        self.prev_entry_btn = QPushButton("◀ Previous Entry")
        self.prev_entry_btn.setToolTip("Navigate to previous saved entry")
        self.prev_entry_btn.clicked.connect(self.previous_entry)
        self.prev_entry_btn.setEnabled(False)
        nav_layout.addWidget(self.prev_entry_btn)
        
        self.entry_position_label = QLabel("No entries loaded")
        self.entry_position_label.setAlignment(Qt.AlignCenter)
        self.entry_position_label.setStyleSheet("font-weight: bold;")
        nav_layout.addWidget(self.entry_position_label)
        
        self.next_entry_btn = QPushButton("Next Entry ▶")
        self.next_entry_btn.setToolTip("Navigate to next saved entry")
        self.next_entry_btn.clicked.connect(self.next_entry)
        self.next_entry_btn.setEnabled(False)
        nav_layout.addWidget(self.next_entry_btn)
        
        layout.addLayout(nav_layout)
        
        # Load all entries button
        load_entries_btn = QPushButton("Load All Entries")
        load_entries_btn.setToolTip("Load all saved entries from the data file for navigation")
        load_entries_btn.clicked.connect(self.load_all_entries)
        load_entries_btn.setStyleSheet("background-color: #FF9800; color: white; padding: 5px;")
        layout.addWidget(load_entries_btn)
        
        # Copy all from previous button
        copy_all_btn = QPushButton("◄ Copy All from Previous Entry")
        copy_all_btn.clicked.connect(self.copy_all_from_previous_entry)
        copy_all_btn.setStyleSheet("background-color: #673AB7; color: white; padding: 5px;")
        copy_all_btn.setToolTip("Copy all field values from the previous entry")
        layout.addWidget(copy_all_btn)
        
        # Create fields dynamically from template
        if self.template_fieldnames:
            # Create a single group with all fields from template
            group_box = QGroupBox("Data Fields")
            group_layout = QGridLayout()
            row = 0
            
            for field_name in self.template_fieldnames:
                label = QLabel(field_name + ":")
                group_layout.addWidget(label, row, 0)
                
                # Use multiline for COMMENTS field, single line for others
                if field_name.upper() == "COMMENTS":
                    field_widget = QTextEdit()
                    field_widget.setMaximumHeight(80)
                    # Connect to combined handler
                    field_widget.textChanged.connect(self.create_field_changed_handler(field_name))
                else:
                    field_widget = QLineEdit()
                    # Connect to combined handler
                    field_widget.textChanged.connect(self.create_field_changed_handler(field_name))
                
                group_layout.addWidget(field_widget, row, 1)
                
                # Add "Copy from Previous" button only for copyable fields (not metadata/unique fields)
                if field_name not in self.non_copyable_fields:
                    copy_btn = QPushButton("◄")
                    copy_btn.setMaximumWidth(30)
                    copy_btn.setToolTip(f"Copy {field_name} from previous entry")
                    copy_btn.setStyleSheet("font-size: 12px; padding: 2px;")
                    copy_btn.clicked.connect(lambda checked, fn=field_name: self.copy_from_previous_entry(fn))
                    group_layout.addWidget(copy_btn, row, 2)
                else:
                    # Add empty space for alignment
                    spacer = QLabel("")
                    spacer.setMaximumWidth(30)
                    group_layout.addWidget(spacer, row, 2)
                
                self.data_fields[field_name] = field_widget
                row += 1
            
            group_box.setLayout(group_layout)
            layout.addWidget(group_box)
        
        # Action buttons
        button_layout = QHBoxLayout()
        
        init_entry_btn = QPushButton("📝 Initialise New Entry")
        init_entry_btn.setToolTip("Create a new data entry with the next DROP_ID (doesn't extract frame)")
        init_entry_btn.clicked.connect(self.initialise_new_entry)
        init_entry_btn.setStyleSheet("background-color: #2196F3; color: white; font-weight: bold; padding: 8px;")
        button_layout.addWidget(init_entry_btn)
        
        save_btn = QPushButton("Save Entry")
        save_btn.setToolTip("Save current entry to the data file")
        save_btn.clicked.connect(self.save_data_entry)
        save_btn.setStyleSheet("background-color: #4CAF50; color: white; font-weight: bold; padding: 8px;")
        button_layout.addWidget(save_btn)
        
        clear_btn = QPushButton("Clear Form")
        clear_btn.setToolTip("Clear all data entry fields")
        clear_btn.clicked.connect(self.clear_data_entry)
        button_layout.addWidget(clear_btn)
        
        layout.addLayout(button_layout)
        
        # Validation rules button
        rules_layout = QHBoxLayout()
        
        manage_rules_btn = QPushButton("⚙ Manage Validation Rules")
        manage_rules_btn.setToolTip("Create and edit validation rules for data entry fields")
        manage_rules_btn.clicked.connect(self.manage_validation_rules)
        manage_rules_btn.setStyleSheet("background-color: #9C27B0; color: white; font-weight: bold; padding: 8px;")
        rules_layout.addWidget(manage_rules_btn)
        
        layout.addLayout(rules_layout)
        
        # Additional action buttons (second row)
        button_layout2 = QHBoxLayout()
        
        delete_btn = QPushButton("Delete Current Entry")
        delete_btn.setToolTip("Delete the currently displayed entry from the data file")
        delete_btn.clicked.connect(self.delete_current_entry)
        delete_btn.setStyleSheet("background-color: #F44336; color: white; font-weight: bold; padding: 8px;")
        button_layout2.addWidget(delete_btn)
        
        reset_drop_btn = QPushButton("Reset Drop Count")
        reset_drop_btn.setToolTip("Manually set the next DROP_ID number")
        reset_drop_btn.clicked.connect(self.reset_drop_count)
        reset_drop_btn.setStyleSheet("background-color: #FF9800; color: white; font-weight: bold; padding: 8px;")
        button_layout2.addWidget(reset_drop_btn)
        
        layout.addLayout(button_layout2)
        layout.addStretch()
        
        container.setLayout(layout)
        scroll.setWidget(container)
        
        self.data_entry_widget = scroll
        
    def open_video(self):
        """Open a video file"""
        file_path, _ = QFileDialog.getOpenFileName(
            self, "Open Video File", "", 
            "Video Files (*.mp4 *.avi *.mov *.mkv);;All Files (*.*)"
        )
        
        if file_path:
            if self.cap:
                self.cap.release()
            
        self.video_path = file_path
        # Use FFMPEG backend explicitly and reduce buffer size for better seeking
        self.cap = cv2.VideoCapture(file_path, cv2.CAP_FFMPEG)
        self.cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)  # Minimum buffer for better frame accuracy
        # Try to open only video stream (ignore audio)
        try:
            self.cap.set(cv2.CAP_PROP_AUDIO_STREAM, -1)
        except:
            pass
        
        if not self.cap.isOpened():
            QMessageBox.critical(self, "Error", "Failed to open video file")
            return
            
            self.total_frames = int(self.cap.get(cv2.CAP_PROP_FRAME_COUNT))
            self.fps = self.cap.get(cv2.CAP_PROP_FPS)
            self.current_frame = 0
            
            self.timeline_slider.setMaximum(self.total_frames - 1)
            self.timeline_slider.setValue(0)
            
            # Enable controls
            self.play_btn.setEnabled(True)
            self.prev_frame_btn.setEnabled(True)
            self.next_frame_btn.setEnabled(True)
            self.skip_back_btn.setEnabled(True)
            self.skip_forward_btn.setEnabled(True)
        self.speed_combo.setEnabled(True)
        self.zoom_slider.setEnabled(True)
        self.extract_btn.setEnabled(True)
        
        self.display_frame()
            
    def toggle_play(self):
        """Toggle play/pause"""
        if not self.cap:
            return
            
        self.is_playing = not self.is_playing
        
        if self.is_playing:
            self.play_btn.setText("⏸")
            interval = int(1000 / (self.fps * self.playback_speed))
            # Ensure minimum interval of 1ms for smooth high-speed playback
            interval = max(1, interval)
            self.timer.start(interval)
        else:
            self.play_btn.setText("▶")
            self.timer.stop()
    
    def change_zoom(self, value):
        """Change video zoom level"""
        self.zoom_level = value / 100.0
        self.zoom_label.setText(f"{value}%")
        
        # Redisplay current frame with new zoom
        if self.cap and self.cached_frame is not None:
            self.display_frame_data(self.cached_frame)
            
    def change_speed(self, speed_text):
        """Change playback speed"""
        speed_map = {"0.25x": 0.25, "0.5x": 0.5, "1x": 1.0, "2x": 2.0, "4x": 4.0, "8x": 8.0, "12x": 12.0}
        self.playback_speed = speed_map.get(speed_text, 1.0)
        
        if self.is_playing:
            interval = int(1000 / (self.fps * self.playback_speed))
            # Ensure minimum interval of 1ms for smooth high-speed playback
            interval = max(1, interval)
            self.timer.start(interval)
            
    def slider_changed(self, value):
        """Handle timeline slider changes"""
        if not self.cap:
            return
        
        # Pause if playing and user is manually scrubbing
        if self.is_playing and abs(value - self.current_frame) > 1:
            self.toggle_play()
            
        self.current_frame = value
        self.cap.set(cv2.CAP_PROP_POS_FRAMES, self.current_frame)
        self.display_frame()
    
    def skip_frames(self, frame_count):
        """Skip forward or backward by specified number of frames"""
        if not self.cap:
            return
            
        was_playing = self.is_playing
        if was_playing:
            self.toggle_play()
            
        new_frame = self.current_frame + frame_count
        new_frame = max(0, min(new_frame, self.total_frames - 1))  # Clamp to valid range
        
        self.current_frame = new_frame
        self.cap.set(cv2.CAP_PROP_POS_FRAMES, self.current_frame)
        
        # Block slider signals to prevent feedback loop
        self.timeline_slider.blockSignals(True)
        self.timeline_slider.setValue(self.current_frame)
        self.timeline_slider.blockSignals(False)
        
        self.display_frame()
        
    def previous_frame(self):
        """Go to previous frame"""
        if not self.cap or self.current_frame <= 0:
            return
            
        was_playing = self.is_playing
        if was_playing:
            self.toggle_play()
            
        self.current_frame -= 1
        self.cap.set(cv2.CAP_PROP_POS_FRAMES, self.current_frame)
        
        # Block slider signals to prevent feedback loop
        self.timeline_slider.blockSignals(True)
        self.timeline_slider.setValue(self.current_frame)
        self.timeline_slider.blockSignals(False)
        
        # Read and display immediately
        ret, frame = self.cap.read()
        if ret:
            self.display_frame_data(frame)
        else:
            self.display_frame()
        
    def next_frame(self):
        """Go to next frame (manual navigation)"""
        if not self.cap:
            return
            
        was_playing = self.is_playing
        if was_playing:
            self.toggle_play()
            
        if self.current_frame >= self.total_frames - 1:
            return
        
        # Read next frame directly (more efficient than seeking)
        ret, frame = self.cap.read()
        if ret:
            self.current_frame += 1
            
            # Block slider signals to prevent feedback loop
            self.timeline_slider.blockSignals(True)
            self.timeline_slider.setValue(self.current_frame)
            self.timeline_slider.blockSignals(False)
            
            self.display_frame_data(frame)
        else:
            # Fallback to seek if read fails
            self.current_frame += 1
            self.cap.set(cv2.CAP_PROP_POS_FRAMES, self.current_frame)
            self.timeline_slider.blockSignals(True)
            self.timeline_slider.setValue(self.current_frame)
            self.timeline_slider.blockSignals(False)
            self.display_frame()
    
    def play_next_frame(self):
        """Play next frame during playback (optimized for smooth playback)"""
        if not self.cap or not self.is_playing:
            return
            
        if self.current_frame >= self.total_frames - 1:
            self.toggle_play()
            return
        
        ret, frame = self.cap.read()
        if ret and frame is not None:
            self.current_frame += 1
            self.timeline_slider.blockSignals(True)  # Prevent slider feedback during playback
            self.timeline_slider.setValue(self.current_frame)
            self.timeline_slider.blockSignals(False)
            self.display_frame_data(frame)
        else:
            # Try to recover by seeking to next frame
            if self.current_frame < self.total_frames - 1:
                self.current_frame += 1
                self.cap.set(cv2.CAP_PROP_POS_FRAMES, self.current_frame)
                ret, frame = self.cap.read()
                if ret and frame is not None:
                    self.timeline_slider.blockSignals(True)
                    self.timeline_slider.setValue(self.current_frame)
                    self.timeline_slider.blockSignals(False)
                    self.display_frame_data(frame)
                else:
                    self.toggle_play()
            else:
                self.toggle_play()
                
    def display_frame(self):
        """Display current frame"""
        if not self.cap:
            return
            
        ret, frame = self.cap.read()
        if ret:
            self.display_frame_data(frame)
            
    def display_frame_data(self, frame):
        """Display frame data on label"""
        # Convert BGR to RGB
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        h, w, ch = rgb_frame.shape
        bytes_per_line = ch * w
        
        # Create QImage
        q_img = QImage(rgb_frame.data, w, h, bytes_per_line, QImage.Format_RGB888)
        pixmap = QPixmap.fromImage(q_img)
        
        # Get scroll area viewport size
        viewport_size = self.video_scroll.viewport().size()
        
        # Calculate base scaled size to fit viewport
        base_scaled = pixmap.scaled(
            viewport_size,
            Qt.KeepAspectRatio,
            Qt.SmoothTransformation
        )
        
        # Apply zoom to the base scaled size
        target_width = int(base_scaled.width() * self.zoom_level)
        target_height = int(base_scaled.height() * self.zoom_level)
        
        # Create final scaled pixmap with zoom
        transformation = Qt.SmoothTransformation if self.zoom_level > 1.0 else Qt.FastTransformation
        scaled_pixmap = pixmap.scaled(
            target_width,
            target_height,
            Qt.KeepAspectRatio,
            transformation
        )
        
        # Resize label to match pixmap (this enables scrolling when zoomed)
        self.video_label.resize(scaled_pixmap.size())
        self.video_label.setPixmap(scaled_pixmap)
        
        # Update info label
        time_seconds = self.current_frame / self.fps if self.fps > 0 else 0
        hours = int(time_seconds // 3600)
        minutes = int((time_seconds % 3600) // 60)
        seconds = int(time_seconds % 60)
        time_str = f"{hours:02d}:{minutes:02d}:{seconds:02d}"
        
        self.info_label.setText(
            f"Frame: {self.current_frame} / {self.total_frames - 1} | "
            f"Time: {time_str} | FPS: {self.fps:.2f}"
        )
        
    def extract_current_frame(self):
        """Extract and save current frame"""
        if not self.cap:
            return
            
        self.cap.set(cv2.CAP_PROP_POS_FRAMES, self.current_frame)
        ret, frame = self.cap.read()
        
        if ret:
            # Check if we're in auto-loader mode
            if self.video_queue and self.video_path in self.video_queue:
                # Auto-load base data from CSV on first extraction if not already loaded
                if not self.base_data:
                    self.auto_load_base_data_from_csv()
                
                # ALWAYS calculate the next drop number using simple logic
                # (Compare current POINT_ID with last entry's POINT_ID)
                self.drop_counter = self.get_next_drop_number_for_point()
                
                # VALIDATE DATA BEFORE EXTRACTING FRAME
                # Prepare data row for validation
                data_row = {}
                for field_name, widget in self.data_fields.items():
                    if isinstance(widget, QTextEdit):
                        data_row[field_name] = widget.toPlainText().strip()
                    else:
                        data_row[field_name] = widget.text().strip()
                
                # Check if validation should be skipped (mostly empty entry)
                skip_validation = self.is_mostly_empty_entry(data_row)
                
                if self.validation_rules and not skip_validation:
                    is_valid, errors = self.validate_data_entry(data_row)
                    
                    if not is_valid:
                        self.highlight_invalid_fields(errors)
                        
                        # BLOCK extraction and show error
                        error_msg = "❌ Validation Failed - Cannot Extract Frame\n\n" + "\n".join([f"• {error}" for error in errors])
                        error_msg += "\n\nPlease fix the highlighted fields before pressing 'S' to extract."
                        
                        QMessageBox.critical(self, "Validation Failed", error_msg)
                        return  # Block extraction completely
                
                # Clear any previous highlights
                self.highlight_invalid_fields([])
                
                # Save to drop_stills with auto-naming using video filename format
                os.makedirs(self.drop_stills_dir, exist_ok=True)
                
                # Use video filename as base
                video_name = os.path.splitext(os.path.basename(self.video_path))[0]
                still_filename = f"{video_name}_drop{self.drop_counter}.jpg"
                
                output_path = os.path.join(self.drop_stills_dir, still_filename)
                cv2.imwrite(output_path, frame, [cv2.IMWRITE_JPEG_QUALITY, 95])
                
                # Auto-save data entry with drop information
                drop_id = f"drop{self.drop_counter}"
                self.auto_save_data_entry(drop_id, still_filename)
                
                self.drop_counter += 1
                
                # Update DROP_ID and FILENAME fields in the form to show the NEXT drop information
                next_drop_id = f"drop{self.drop_counter}"
                next_filename = f"{video_name}_drop{self.drop_counter}.jpg"
                
                if 'DROP_ID' in self.data_fields:
                    widget = self.data_fields['DROP_ID']
                    widget.blockSignals(True)
                    if isinstance(widget, QTextEdit):
                        widget.setPlainText(next_drop_id)
                    else:
                        widget.setText(next_drop_id)
                    widget.blockSignals(False)
                    print(f"  Updated DROP_ID field to: {next_drop_id}")
                
                if 'FILENAME' in self.data_fields:
                    widget = self.data_fields['FILENAME']
                    widget.blockSignals(True)
                    if isinstance(widget, QTextEdit):
                        widget.setPlainText(next_filename)
                    else:
                        widget.setText(next_filename)
                    widget.blockSignals(False)
                    print(f"  Updated FILENAME field to: {next_filename}")
                
                # Update queue label to show new drop count
                self.queue_label.setText(
                    f"{self.current_video_index + 1}/{len(self.video_queue)}: Drop {self.drop_counter}"
                )
                
                # Show success message
                msg = f"Frame saved to:\n{output_path}\n\nData entry auto-saved with DROP_ID: {drop_id}\n\n"
                msg += "Form is now ready for your next observation."
                QMessageBox.information(self, "Success", msg)
            else:
                # Original behavior for manually opened videos
                video_name = os.path.splitext(os.path.basename(self.video_path))[0]
                output_dir = os.path.join(os.path.dirname(self.video_path), f"{video_name}_frames")
                os.makedirs(output_dir, exist_ok=True)
                
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                output_path = os.path.join(
                    output_dir, 
                    f"frame_{self.current_frame:06d}_{timestamp}.jpg"
                )
                cv2.imwrite(output_path, frame, [cv2.IMWRITE_JPEG_QUALITY, 95])
                QMessageBox.information(self, "Success", f"Frame saved to:\n{output_path}")
        else:
            QMessageBox.warning(self, "Error", "Failed to extract frame")
            
    def choose_video_folder(self):
        """Choose a custom video folder and load videos from it"""
        folder_path = QFileDialog.getExistingDirectory(
            self, "Select Video Folder",
            self.drop_videos_dir,
            QFileDialog.ShowDirsOnly | QFileDialog.DontResolveSymlinks
        )
        
        if folder_path:
            self.drop_videos_dir = folder_path
            self.load_video_queue()
    
    def load_video_queue(self):
        """Load all videos from drop_videos directory"""
        if not os.path.exists(self.drop_videos_dir):
            os.makedirs(self.drop_videos_dir)
            QMessageBox.information(
                self, "Directory Created",
                f"Created drop_videos directory:\n{self.drop_videos_dir}\n\nPlease add video files to this directory."
            )
            return
        
        # Find all video files
        video_extensions = ('.mp4', '.avi', '.mov', '.mkv', '.flv', '.wmv', '.m4v')
        self.video_queue = [
            os.path.join(self.drop_videos_dir, f)
            for f in os.listdir(self.drop_videos_dir)
            if f.lower().endswith(video_extensions)
        ]
        
        if not self.video_queue:
            QMessageBox.warning(
                self, "No Videos Found",
                f"No video files found in:\n{self.drop_videos_dir}"
            )
            return
        
        # Sort videos alphabetically
        self.video_queue.sort()
        self.current_video_index = 0
        
        # Create drop_stills directory
        os.makedirs(self.drop_stills_dir, exist_ok=True)
        
        # Load first video
        self.load_video_from_queue(0)
        
        # Enable navigation buttons
        self.prev_video_btn.setEnabled(True)
        self.next_video_btn.setEnabled(True)
        
        QMessageBox.information(
            self, "Videos Loaded",
            f"Loaded {len(self.video_queue)} video(s) from:\n{self.drop_videos_dir}\n\n"
            f"Stills will be saved to drop_stills/\n\n"
            f"Use 'S' key or Extract Frame button to save stills."
        )
    
    def load_video_from_queue(self, index):
        """Load a specific video from the queue"""
        if not self.video_queue or index < 0 or index >= len(self.video_queue):
            return
        
        self.current_video_index = index
        video_path = self.video_queue[index]
        
        # Set video path first
        self.video_path = video_path
        video_name = os.path.splitext(os.path.basename(video_path))[0]
        
        # Load base data FIRST - this sets the correct POINT_ID
        # Do NOT call populate_fields_from_base_data() yet
        if self.base_data_csv:
            # Find matching base data without populating fields yet
            for row in self.base_data_csv:
                video_fn = row.get('VIDEO_FILENAME', '')
                if video_fn:
                    csv_video_name = os.path.splitext(video_fn)[0]
                    if csv_video_name == video_name or video_fn == os.path.basename(video_path):
                        self.base_data = row
                        print(f"  Loaded base data for POINT_ID: {row.get('POINT_ID', 'N/A')}")
                        break
        
        # NOW reset drop counter with the correct POINT_ID from new base_data
        self.drop_counter = self.get_next_drop_number_for_point()
        
        # NOW populate fields (this will call update_drop_fields_for_next() with correct counter)
        if self.base_data:
            self.populate_fields_from_base_data()
        
        # Load video
        if self.cap:
            self.cap.release()
        
        self.video_path = video_path
        self.cap = cv2.VideoCapture(video_path, cv2.CAP_FFMPEG)
        self.cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
        # Try to open only video stream (ignore audio)
        try:
            self.cap.set(cv2.CAP_PROP_AUDIO_STREAM, -1)
        except:
            pass
        
        if not self.cap.isOpened():
            QMessageBox.critical(self, "Error", f"Failed to open video:\n{video_path}")
            return
        
        self.total_frames = int(self.cap.get(cv2.CAP_PROP_FRAME_COUNT))
        self.fps = self.cap.get(cv2.CAP_PROP_FPS)
        self.current_frame = 0
        
        self.timeline_slider.setMaximum(self.total_frames - 1)
        self.timeline_slider.setValue(0)
        
        # Enable controls
        self.play_btn.setEnabled(True)
        self.prev_frame_btn.setEnabled(True)
        self.next_frame_btn.setEnabled(True)
        self.skip_back_btn.setEnabled(True)
        self.skip_forward_btn.setEnabled(True)
        self.speed_combo.setEnabled(True)
        self.zoom_slider.setEnabled(True)
        self.extract_btn.setEnabled(True)
        
        # Update queue label
        self.queue_label.setText(
            f"{self.current_video_index + 1}/{len(self.video_queue)}: "
            f"{os.path.basename(video_path)[:30]} (Drop {self.drop_counter})"
        )
        
        self.display_frame()
    
    def previous_video(self):
        """Load previous video from queue"""
        if not self.video_queue:
            return
        
        # Confirm before moving to previous video
        reply = QMessageBox.question(
            self, "Move to Previous Video?",
            "⚠️ Have you extracted and saved ALL drops for this video?\n\n"
            "IMPORTANT: Make sure the last drop is saved before continuing.\n\n"
            "Moving to the previous video will:\n"
            "• Reset drop counter\n"
            "• Load base data for that video\n"
            "• Clear observation fields\n\n"
            "Continue to previous video?",
            QMessageBox.Yes | QMessageBox.No,
            QMessageBox.No
        )
        
        if reply == QMessageBox.No:
            return
        
        if self.is_playing:
            self.toggle_play()
        
        new_index = (self.current_video_index - 1) % len(self.video_queue)
        self.load_video_from_queue(new_index)
    
    def next_video(self):
        """Load next video from queue"""
        if not self.video_queue:
            return
        
        # Confirm before moving to next video
        reply = QMessageBox.question(
            self, "Move to Next Video?",
            "⚠️ Have you extracted and saved ALL drops for this video?\n\n"
            "IMPORTANT: Make sure the last drop is saved before continuing.\n\n"
            "Moving to the next video will:\n"
            "• Reset drop counter to drop1\n"
            "• Load base data for the new video\n"
            "• Clear observation fields\n\n"
            "Continue to next video?",
            QMessageBox.Yes | QMessageBox.No,
            QMessageBox.No
        )
        
        if reply == QMessageBox.No:
            return
        
        if self.is_playing:
            self.toggle_play()
        
        new_index = (self.current_video_index + 1) % len(self.video_queue)
        self.load_video_from_queue(new_index)
    
    def save_data_entry(self):
        """Save current data entry to CSV file"""
        # Collect data from all fields
        data_row = {}
        for field_name, widget in self.data_fields.items():
            if isinstance(widget, QTextEdit):
                data_row[field_name] = widget.toPlainText().strip()
            else:
                data_row[field_name] = widget.text().strip()
        
        # Auto-fill FILENAME if empty and video is loaded
        if not data_row.get('FILENAME') and self.video_path:
            data_row['FILENAME'] = os.path.basename(self.video_path)
        
        # Auto-fill DATE_TIME if DATE and TIME are provided
        if data_row.get('DATE') and data_row.get('TIME'):
            data_row['DATE_TIME'] = f"{data_row['DATE']} {data_row['TIME']}"
        else:
            data_row['DATE_TIME'] = ''
        
        # Validate data entry if rules exist
        if self.validation_rules:
            is_valid, errors = self.validate_data_entry(data_row)
            
            if not is_valid:
                # Highlight invalid fields
                self.highlight_invalid_fields(errors)
                
                # Show validation errors and BLOCK saving
                error_msg = "❌ Validation Failed - Cannot Save\n\n" + "\n".join([f"• {error}" for error in errors])
                error_msg += "\n\nPlease fix the highlighted fields before saving."
                
                QMessageBox.critical(
                    self, "Validation Failed",
                    error_msg
                )
                return  # Block saving completely
            else:
                # Clear any previous highlights
                self.highlight_invalid_fields([])
        
        # Ensure data directory exists
        os.makedirs(self.data_dir, exist_ok=True)
        
        # Determine output file
        output_file = os.path.join(self.data_dir, "data_entries.csv")
        
        # Check if file exists to determine if we need to write headers
        file_exists = os.path.exists(output_file)
        
        # Use fieldnames from template
        fieldnames = self.template_fieldnames if self.template_fieldnames else list(data_row.keys())
        
        try:
            with open(output_file, 'a', newline='', encoding='utf-8') as f:
                writer = csv.DictWriter(f, fieldnames=fieldnames)
                
                # Write header if file is new
                if not file_exists:
                    writer.writeheader()
                
                # Write data row
                writer.writerow(data_row)
            
            # Add to in-memory list if entries are loaded
            if self.all_data_entries is not None:
                self.all_data_entries.append(data_row)
                self.current_entry_index = len(self.all_data_entries) - 1
                self.unsaved_changes = False
                self.update_navigation_buttons()
            
            QMessageBox.information(
                self, "Success", 
                f"Data entry saved to:\n{output_file}"
            )
            
            # Optionally clear form after saving
            reply = QMessageBox.question(
                self, "Clear Form?",
                "Do you want to clear the form for the next entry?",
                QMessageBox.Yes | QMessageBox.No
            )
            if reply == QMessageBox.Yes:
                self.clear_data_entry()
                
        except Exception as e:
            QMessageBox.critical(
                self, "Error", 
                f"Failed to save data entry:\n{str(e)}"
            )
    
    def clear_data_entry(self):
        """Clear all data entry fields"""
        # Clear validation highlights
        self.highlight_invalid_fields([])
        
        for widget in self.data_fields.values():
            if isinstance(widget, QTextEdit):
                widget.clear()
            else:
                widget.clear()
    
    def initialise_new_entry(self):
        """Save current entry (without extracting frame) and prepare for next entry"""
        # Check if we're in auto-loader mode
        if not self.video_queue or not self.video_path or self.video_path not in self.video_queue:
            QMessageBox.warning(
                self, "Not in Video Queue Mode",
                "This feature only works when using 'Load Videos from drop_videos/'.\n\n"
                "For manual video mode, use 'Save Entry' button instead."
            )
            return
        
        # Auto-load base data from CSV on first use if not already loaded
        if not self.base_data:
            self.auto_load_base_data_from_csv()
        
        # ALWAYS calculate the next drop number using the simple logic
        # (Compare current POINT_ID with last entry's POINT_ID)
        self.drop_counter = self.get_next_drop_number_for_point()
        
        # Save current data entry without extracting frame
        drop_id = f"drop{self.drop_counter}"
        
        # Use video filename as base for still filename (even though no still is extracted)
        video_name = os.path.splitext(os.path.basename(self.video_path))[0]
        still_filename = f"{video_name}_drop{self.drop_counter}.jpg"  # Placeholder - no actual file created
        
        # Auto-save data entry
        self.auto_save_data_entry(drop_id, still_filename)
        
        self.drop_counter += 1
        
        # Update DROP_ID and FILENAME fields in the form to show the NEXT drop information
        next_drop_id = f"drop{self.drop_counter}"
        next_filename = f"{video_name}_drop{self.drop_counter}.jpg"
        
        if 'DROP_ID' in self.data_fields:
            widget = self.data_fields['DROP_ID']
            widget.blockSignals(True)
            if isinstance(widget, QTextEdit):
                widget.setPlainText(next_drop_id)
            else:
                widget.setText(next_drop_id)
            widget.blockSignals(False)
            print(f"  Updated DROP_ID field to: {next_drop_id}")
        
        if 'FILENAME' in self.data_fields:
            widget = self.data_fields['FILENAME']
            widget.blockSignals(True)
            if isinstance(widget, QTextEdit):
                widget.setPlainText(next_filename)
            else:
                widget.setText(next_filename)
            widget.blockSignals(False)
            print(f"  Updated FILENAME field to: {next_filename}")
        
        # Update queue label to show new drop count
        self.queue_label.setText(
            f"{self.current_video_index + 1}/{len(self.video_queue)}: Drop {self.drop_counter}"
        )
        
        # Show success message
        msg = f"Entry initialized with DROP_ID: {drop_id}\n\n"
        msg += "Data saved (no frame extracted).\n\n"
        msg += "Form is now ready for your next observation."
        QMessageBox.information(self, "Success", msg)
    
    def load_base_data(self):
        """Load base data from a CSV file"""
        file_path, _ = QFileDialog.getOpenFileName(
            self, "Load Base CSV", self.data_dir,
            "CSV Files (*.csv);;All Files (*.*)"
        )
        
        if not file_path:
            return
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                rows = list(reader)
                
                if not rows:
                    QMessageBox.warning(self, "No Data", "The CSV file contains no data rows.")
                    return
                
                # Store all rows for matching later
                self.base_data_csv = rows
                self.base_data_csv_path = file_path  # Store the path
                
                QMessageBox.information(
                    self, "Success",
                    f"Loaded {len(rows)} rows from:\n{file_path}\n\n"
                    f"When you extract stills, the form will auto-populate\n"
                    f"with data matching the video filename."
                )
        except Exception as e:
            QMessageBox.critical(
                self, "Error",
                f"Failed to load base CSV:\n{str(e)}"
            )
    
    def populate_fields_from_base_data(self):
        """Populate form fields with base data and clear observation fields"""
        print("populate_fields_from_base_data called")
        
        if not self.base_data:
            print("  No base data to populate")
            return
        
        print(f"  Populating from base data (will clear observation fields)")
        
        # Block signals to avoid marking as changed during population
        for widget in self.data_fields.values():
            widget.blockSignals(True)
        
        # Clear all fields first
        for widget in self.data_fields.values():
            if isinstance(widget, QTextEdit):
                widget.clear()
            else:
                widget.clear()
        
        # Then populate with base data
        for field_name, widget in self.data_fields.items():
            value = self.base_data.get(field_name, '')
            if value:
                if isinstance(widget, QTextEdit):
                    widget.setPlainText(value)
                else:
                    widget.setText(value)
        
        # Unblock signals
        for widget in self.data_fields.values():
            widget.blockSignals(False)
        
        # Set DROP_ID and FILENAME for next extraction
        self.update_drop_fields_for_next()
    
    def auto_load_base_data_from_csv(self):
        """Automatically load base data from preloaded CSV matching current video filename"""
        if not self.video_path or not self.base_data_csv:
            return
        
        # Get video filename without extension
        video_filename = os.path.basename(self.video_path)
        video_name_no_ext = os.path.splitext(video_filename)[0]
        
        # Search through preloaded CSV rows
        for row in self.base_data_csv:
            # Check if VIDEO_FILENAME matches (with or without extension)
            video_fn = row.get('VIDEO_FILENAME', '')
            if video_fn:
                # Remove extension for comparison
                csv_video_name = os.path.splitext(video_fn)[0]
                if csv_video_name == video_name_no_ext or video_fn == video_filename:
                    # Found matching row - use it as base data
                    self.base_data = row
                    self.populate_fields_from_base_data()
                    return
    
    def get_next_drop_number_for_point(self):
        """
        Get the next drop number using simple logic:
        - If no previous entries OR POINT_ID changed: drop1
        - If POINT_ID same as previous entry: increment drop number
        """
        # Get current POINT_ID from base_data
        current_point_id = self.base_data.get('POINT_ID', '') if self.base_data else ''
        
        print(f"  get_next_drop_number_for_point called")
        print(f"    Current POINT_ID: '{current_point_id}'")
        print(f"    Total entries: {len(self.all_data_entries)}")
        
        # If no entries exist, start at drop1
        if not self.all_data_entries or len(self.all_data_entries) == 0:
            print(f"    No previous entries → drop1")
            return 1
        
        # Get the last entry
        last_entry = self.all_data_entries[-1]
        last_point_id = last_entry.get('POINT_ID', '')
        last_drop_id = last_entry.get('DROP_ID', '')
        
        print(f"    Last entry: POINT_ID='{last_point_id}', DROP_ID='{last_drop_id}'")
        
        # Extract drop number from last entry
        last_drop_num = 1
        if last_drop_id and last_drop_id.startswith('drop'):
            try:
                last_drop_num = int(last_drop_id.replace('drop', ''))
            except:
                last_drop_num = 1
        
        # Simple logic: Same POINT_ID = increment, Different POINT_ID = reset to 1
        if current_point_id == last_point_id:
            next_drop = last_drop_num + 1
            print(f"    Same POINT_ID → increment to drop{next_drop}")
            return next_drop
        else:
            print(f"    Different POINT_ID → reset to drop1")
            return 1
    
    def update_drop_fields_for_next(self):
        """Update DROP_ID and FILENAME fields for the next drop"""
        # Block signals to avoid marking as changed
        for widget in self.data_fields.values():
            widget.blockSignals(True)
        
        # Update DROP_ID to show the next drop number
        next_drop_id = f"drop{self.drop_counter}"
        if 'DROP_ID' in self.data_fields:
            self.data_fields['DROP_ID'].setText(next_drop_id)
        
        # Clear FILENAME since it will be set on next extraction
        if 'FILENAME' in self.data_fields:
            self.data_fields['FILENAME'].setText("[Will be set on next extraction]")
        
        # Auto-fill YEAR, DATE, TIME from base data if available
        if self.base_data:
            # Try to parse VIDEO_TIMESTAMP field (format: DD/MM/YYYY HH:MM or similar)
            video_timestamp = self.base_data.get('VIDEO_TIMESTAMP', '')
            if video_timestamp:
                try:
                    # Parse formats like "27/11/2025 9:22" or "27/11/2025 9:22:00"
                    parts = video_timestamp.strip().split()
                    if len(parts) >= 2:
                        date_part = parts[0]  # e.g., "27/11/2025"
                        time_part = parts[1]  # e.g., "9:22"
                        
                        # Extract year from date
                        date_components = date_part.split('/')
                        if len(date_components) == 3:
                            day, month, year = date_components
                            if 'YEAR' in self.data_fields:
                                self.data_fields['YEAR'].setText(year)
                            if 'DATE' in self.data_fields:
                                self.data_fields['DATE'].setText(date_part)
                        
                        # Set time
                        if 'TIME' in self.data_fields:
                            self.data_fields['TIME'].setText(time_part)
                except Exception as e:
                    pass  # If parsing fails, just skip
            
            # Fallback to direct YEAR, DATE, TIME fields if VIDEO_TIMESTAMP not available
            if not video_timestamp:
                if self.base_data.get('YEAR') and 'YEAR' in self.data_fields:
                    self.data_fields['YEAR'].setText(self.base_data['YEAR'])
                if self.base_data.get('DATE') and 'DATE' in self.data_fields:
                    self.data_fields['DATE'].setText(self.base_data['DATE'])
                if self.base_data.get('TIME') and 'TIME' in self.data_fields:
                    self.data_fields['TIME'].setText(self.base_data['TIME'])
            
            # Set DATE_TIME if it exists in base_data
            if self.base_data.get('DATE_TIME') and 'DATE_TIME' in self.data_fields:
                self.data_fields['DATE_TIME'].setText(self.base_data['DATE_TIME'])
            # Or construct from VIDEO_TIMESTAMP if DATE_TIME field exists
            elif video_timestamp and 'DATE_TIME' in self.data_fields:
                self.data_fields['DATE_TIME'].setText(video_timestamp)
        
        # Unblock signals
        for widget in self.data_fields.values():
            widget.blockSignals(False)
    
    def create_field_changed_handler(self, field_name):
        """Create a handler function for field changes that properly captures the field name"""
        def handler():
            self.mark_entry_changed()
            self.check_autofill_rules(field_name)
            self.check_calculated_rules(field_name)
        return handler
    
    def mark_entry_changed(self):
        """Mark that the current entry has been modified"""
        self.unsaved_changes = True
    
    def load_all_entries(self):
        """Load all data entries from CSV file"""
        output_file = os.path.join(self.data_dir, "data_entries.csv")
        
        if not os.path.exists(output_file):
            QMessageBox.information(
                self, "No Entries",
                "No data entries file found. Extract some stills first or save an entry."
            )
            return
        
        try:
            with open(output_file, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                self.all_data_entries = list(reader)
            
            if not self.all_data_entries:
                QMessageBox.information(
                    self, "No Entries",
                    "The data entries file is empty."
                )
                return
            
            # Automatically open the NEXT video after the last completed entry FIRST
            last_entry_index = len(self.all_data_entries) - 1
            last_entry = self.all_data_entries[last_entry_index]
            video_filename = None
            
            # Try to get video filename from various fields
            if 'VIDEO_FILENAME' in last_entry:
                video_filename = last_entry['VIDEO_FILENAME']
            elif 'FILENAME' in last_entry:
                # Extract video name from still filename (e.g., "video_drop3.jpg" -> "video.mp4")
                filename = last_entry['FILENAME']
                if '_drop' in filename:
                    video_name = filename.split('_drop')[0]
                    video_filename = video_name + '.mp4'  # Assume mp4, could also check for other extensions
            
            # Try to find and open the NEXT video in the queue
            video_loaded = False
            if video_filename and self.video_queue:
                # Search for the video in the queue
                for idx, video_path in enumerate(self.video_queue):
                    if os.path.basename(video_path) == video_filename or os.path.splitext(os.path.basename(video_path))[0] == os.path.splitext(video_filename)[0]:
                        # Found the last video - load the NEXT one
                        next_idx = (idx + 1) % len(self.video_queue)
                        if next_idx != idx:  # Make sure there's a next video
                            # Load the next video - this will populate fields with correct DROP_ID
                            self.load_video_from_queue(next_idx)
                            next_video_name = os.path.basename(self.video_queue[next_idx])
                            print(f"  Auto-loaded NEXT video: {next_video_name}")
                            video_loaded = True
                        break
            
            # Set current_entry_index to point to a new entry (beyond saved entries)
            # This allows "copy from previous" to work correctly
            self.current_entry_index = len(self.all_data_entries)
            
            # Enable navigation buttons
            self.update_navigation_buttons()
            
            # Show appropriate message
            if video_loaded:
                QMessageBox.information(
                    self, "Success - Ready to Resume",
                    f"Loaded {len(self.all_data_entries)} data entries.\n\n"
                    f"✓ Showing last entry (#{last_entry_index + 1})\n"
                    f"✓ Next video automatically loaded and ready\n\n"
                    f"⚠️ IMPORTANT: Always complete ALL drops for a video\n"
                    f"before moving to the next video or quitting the app!\n\n"
                    f"Use navigation arrows to review previous entries.\n"
                    f"Changes are auto-saved when navigating."
                )
            else:
                QMessageBox.information(
                    self, "Success",
                    f"Loaded {len(self.all_data_entries)} data entries.\n\n"
                    f"Showing last entry (#{last_entry_index + 1}).\n\n"
                    f"⚠️ IMPORTANT: Always complete ALL drops for a video\n"
                    f"before moving to the next video or quitting the app!\n\n"
                    f"Use navigation arrows to browse through entries.\n"
                    f"Changes are auto-saved when navigating."
                )
        except Exception as e:
            QMessageBox.critical(
                self, "Error",
                f"Failed to load data entries:\n{str(e)}"
            )
    
    def load_entry_at_index(self, index):
        """Load a specific entry by index"""
        if index < 0 or index >= len(self.all_data_entries):
            return
        
        entry = self.all_data_entries[index]
        
        # Clear validation highlights
        self.highlight_invalid_fields([])
        
        # Block signals to prevent marking as changed while loading
        for widget in self.data_fields.values():
            widget.blockSignals(True)
        
        # Load data into fields
        for field_name, widget in self.data_fields.items():
            value = entry.get(field_name, '')
            if isinstance(widget, QTextEdit):
                widget.setPlainText(value)
            else:
                widget.setText(value)
        
        # Unblock signals
        for widget in self.data_fields.values():
            widget.blockSignals(False)
        
        # Update drop_counter based on the loaded entry's DROP_ID
        # This ensures the next extraction uses the correct drop number
        drop_id = entry.get('DROP_ID', '')
        if drop_id:
            # Extract number from DROP_ID (e.g., "drop3" -> 3)
            import re
            match = re.search(r'drop(\d+)', drop_id, re.IGNORECASE)
            if match:
                current_drop_num = int(match.group(1))
                # Set counter to next drop number
                self.drop_counter = current_drop_num + 1
                print(f"  Loaded entry with DROP_ID={drop_id}, set drop_counter={self.drop_counter} for next extraction")
        
        self.unsaved_changes = False
        self.update_navigation_buttons()
    
    def update_navigation_buttons(self):
        """Update navigation button states and position label"""
        print(f"Update navigation: entries={len(self.all_data_entries)}, index={self.current_entry_index}")
        
        if not self.all_data_entries or self.current_entry_index < 0:
            self.prev_entry_btn.setEnabled(False)
            self.next_entry_btn.setEnabled(False)
            self.entry_position_label.setText("No entries - extract a frame to start")
            return
        
        # Check if we're working on a new entry (beyond the saved entries)
        if self.current_entry_index >= len(self.all_data_entries):
            # Working on a new entry
            self.prev_entry_btn.setEnabled(True)  # Can go back to last saved entry
            self.next_entry_btn.setEnabled(False)  # No next entry yet
            status = f"New entry (will be #{len(self.all_data_entries) + 1})"
            if self.unsaved_changes:
                status += " *"
            self.entry_position_label.setText(status)
        else:
            # Viewing/editing an existing entry
            self.prev_entry_btn.setEnabled(self.current_entry_index > 0)
            self.next_entry_btn.setEnabled(self.current_entry_index < len(self.all_data_entries) - 1)
            
            status = f"Entry {self.current_entry_index + 1} of {len(self.all_data_entries)}"
            if self.unsaved_changes:
                status += " *"
            self.entry_position_label.setText(status)
    
    def save_current_entry_changes(self):
        """Save changes to the current entry in memory and CSV"""
        if self.current_entry_index < 0 or self.current_entry_index >= len(self.all_data_entries):
            return
        
        # Collect current data
        data_row = {}
        for field_name, widget in self.data_fields.items():
            if isinstance(widget, QTextEdit):
                data_row[field_name] = widget.toPlainText().strip()
            else:
                data_row[field_name] = widget.text().strip()
        
        # Update DATE_TIME if needed
        if data_row.get('DATE') and data_row.get('TIME'):
            data_row['DATE_TIME'] = f"{data_row['DATE']} {data_row['TIME']}"
        
        # Validate if rules exist
        if self.validation_rules:
            is_valid, errors = self.validate_data_entry(data_row)
            
            if not is_valid:
                self.highlight_invalid_fields(errors)
                
                # BLOCK saving and show error
                error_msg = "❌ Validation Failed - Cannot Save Changes\n\n" + "\n".join([f"• {error}" for error in errors])
                error_msg += "\n\nPlease fix the highlighted fields before saving."
                
                QMessageBox.critical(
                    self, "Validation Failed",
                    error_msg
                )
                return  # Block saving completely
            else:
                self.highlight_invalid_fields([])
        
        # Update the entry in memory
        self.all_data_entries[self.current_entry_index] = data_row
        
        # Write all entries back to CSV
        output_file = os.path.join(self.data_dir, "data_entries.csv")
        
        # Use fieldnames from template
        fieldnames = self.template_fieldnames if self.template_fieldnames else []
        
        try:
            with open(output_file, 'w', newline='', encoding='utf-8') as f:
                writer = csv.DictWriter(f, fieldnames=fieldnames)
                writer.writeheader()
                writer.writerows(self.all_data_entries)
            
            self.unsaved_changes = False
            self.update_navigation_buttons()
        except Exception as e:
            QMessageBox.critical(
                self, "Error",
                f"Failed to save changes:\n{str(e)}"
            )
    
    def previous_entry(self):
        """Navigate to previous entry"""
        if self.current_entry_index <= 0:
            return
        
        # Auto-save current changes before navigating
        if self.unsaved_changes:
            self.save_current_entry_changes()
        
        self.current_entry_index -= 1
        self.load_entry_at_index(self.current_entry_index)
    
    def next_entry(self):
        """Navigate to next entry"""
        if self.current_entry_index >= len(self.all_data_entries) - 1:
            return
        
        # Auto-save current changes before navigating
        if self.unsaved_changes:
            self.save_current_entry_changes()
        
        self.current_entry_index += 1
        self.load_entry_at_index(self.current_entry_index)
    
    def copy_from_previous_entry(self, field_name):
        """Copy value from previous entry for a specific field"""
        print(f"Copy from previous called for field: {field_name}")
        print(f"  Current entry index: {self.current_entry_index}")
        print(f"  Total entries: {len(self.all_data_entries)}")
        
        # Check if there are any saved entries to copy from
        if not self.all_data_entries or len(self.all_data_entries) == 0:
            print(f"  ❌ Cannot copy - no saved entries")
            QMessageBox.information(
                self, "No Previous Entry",
                "There are no saved entries to copy from.\n\n"
                "Extract at least one frame first (Press 'S')."
            )
            return
        
        # Determine which entry to copy from
        # If current_entry_index points to a valid entry, copy from the one before it
        # If current_entry_index is beyond the array (new entry), copy from the last saved entry
        if self.current_entry_index > 0 and self.current_entry_index < len(self.all_data_entries):
            # Editing an existing entry - copy from previous
            source_index = self.current_entry_index - 1
        elif self.current_entry_index >= len(self.all_data_entries):
            # Working on a new entry - copy from last saved entry
            source_index = len(self.all_data_entries) - 1
        else:
            # current_entry_index <= 0 and at entry 0 - no previous
            print(f"  ❌ Cannot copy - at first entry with no previous")
            QMessageBox.information(
                self, "No Previous Entry",
                "You are at the first entry. There is no previous entry to copy from."
            )
            return
        
        print(f"  ✓ Copying from saved entry index {source_index} (Entry #{source_index + 1})")
        
        # Get the entry to copy from
        previous_entry = self.all_data_entries[source_index]
        previous_value = previous_entry.get(field_name, '')
        
        print(f"  Previous entry data for {field_name}: '{previous_value}'")
        
        # Set the value in the current field
        if field_name in self.data_fields:
            widget = self.data_fields[field_name]
            
            # Get current value before copying
            if isinstance(widget, QTextEdit):
                current_val = widget.toPlainText()
            else:
                current_val = widget.text()
            print(f"  Current value in field: '{current_val}'")
            
            # Block signals temporarily to avoid marking as changed
            widget.blockSignals(True)
            
            if isinstance(widget, QTextEdit):
                widget.setPlainText(previous_value)
            else:
                widget.setText(previous_value)
            
            # Verify it was set
            if isinstance(widget, QTextEdit):
                new_val = widget.toPlainText()
            else:
                new_val = widget.text()
            print(f"  After setting: '{new_val}'")
            
            # Unblock signals
            widget.blockSignals(False)
            
            # Mark as changed
            self.mark_entry_changed()
            
            print(f"  ✓ Copy completed successfully")
            
            # Show brief confirmation in console
            if previous_value:
                print(f"  → Copied '{previous_value}' to {field_name}")
            else:
                print(f"  ⚠ Warning: Previous entry had no value for {field_name}")
    
    def copy_all_from_previous_entry(self):
        """Copy all field values from the previous entry"""
        print(f"Copy all from previous called")
        print(f"  Current entry index: {self.current_entry_index}")
        print(f"  Total entries: {len(self.all_data_entries)}")
        
        # Check if there are any saved entries to copy from
        if not self.all_data_entries or len(self.all_data_entries) == 0:
            print(f"  ❌ Cannot copy - no saved entries")
            QMessageBox.information(
                self, "No Previous Entry",
                "There are no saved entries to copy from.\n\n"
                "Extract at least one frame first (Press 'S')."
            )
            return
        
        # Determine which entry to copy from (same logic as single field copy)
        if self.current_entry_index > 0 and self.current_entry_index < len(self.all_data_entries):
            # Editing an existing entry - copy from previous
            source_index = self.current_entry_index - 1
        elif self.current_entry_index >= len(self.all_data_entries):
            # Working on a new entry - copy from last saved entry
            source_index = len(self.all_data_entries) - 1
        else:
            # current_entry_index <= 0 and at entry 0 - no previous
            print(f"  ❌ Cannot copy - at first entry with no previous")
            QMessageBox.information(
                self, "No Previous Entry",
                "You are at the first entry. There is no previous entry to copy from."
            )
            return
        
        print(f"  ✓ Can copy from saved entry index {source_index} (Entry #{source_index + 1})")
        
        # Confirm action
        reply = QMessageBox.question(
            self, "Copy All Fields",
            "Copy all field values from the previous entry?\n\n"
            "This will overwrite the current form data.",
            QMessageBox.Yes | QMessageBox.No,
            QMessageBox.No
        )
        
        if reply == QMessageBox.No:
            return
        
        # Get the entry to copy from
        previous_entry = self.all_data_entries[source_index]
        
        # Block signals for all widgets
        for widget in self.data_fields.values():
            widget.blockSignals(True)
        
        # Copy all field values (except non-copyable metadata fields)
        fields_copied = 0
        skipped_fields = []
        
        for field_name, widget in self.data_fields.items():
            # Skip non-copyable fields (metadata/unique identifiers)
            if field_name in self.non_copyable_fields:
                skipped_fields.append(field_name)
                continue
            
            previous_value = previous_entry.get(field_name, '')
            
            if isinstance(widget, QTextEdit):
                widget.setPlainText(previous_value)
            else:
                widget.setText(previous_value)
            
            if previous_value:
                fields_copied += 1
        
        # Unblock signals
        for widget in self.data_fields.values():
            widget.blockSignals(False)
        
        # Mark as changed
        self.mark_entry_changed()
        
        # Show confirmation
        msg = f"Successfully copied {fields_copied} observation field values from the previous entry.\n\n"
        
        if skipped_fields:
            # Show only first few skipped fields if there are many
            skipped_display = ', '.join(skipped_fields[:5])
            if len(skipped_fields) > 5:
                skipped_display += f" and {len(skipped_fields) - 5} more"
            msg += f"Preserved unique fields: {skipped_display}\n\n"
        
        msg += "Review and modify as needed, then save or navigate to auto-save."
        
        QMessageBox.information(self, "Observation Fields Copied", msg)
    
    def auto_save_data_entry(self, drop_id, still_filename):
        """Automatically save data entry when extracting a still"""
        # Collect data from all fields
        data_row = {}
        for field_name, widget in self.data_fields.items():
            if isinstance(widget, QTextEdit):
                data_row[field_name] = widget.toPlainText().strip()
            else:
                data_row[field_name] = widget.text().strip()
        
        # Override with drop-specific information
        data_row['DROP_ID'] = drop_id
        data_row['FILENAME'] = still_filename
        
        # Auto-fill DATE_TIME if DATE and TIME are provided
        if data_row.get('DATE') and data_row.get('TIME'):
            data_row['DATE_TIME'] = f"{data_row['DATE']} {data_row['TIME']}"
        else:
            data_row['DATE_TIME'] = ''
        
        # Validate if rules exist and BLOCK if validation fails
        # Skip validation if this is the first extraction and fields are mostly empty
        skip_validation = self.is_mostly_empty_entry(data_row)
        
        if self.validation_rules and not skip_validation:
            is_valid, errors = self.validate_data_entry(data_row)
            
            if not is_valid:
                self.highlight_invalid_fields(errors)
                
                # BLOCK saving and show error
                error_msg = "❌ Validation Failed - Cannot Extract Frame\n\n" + "\n".join([f"• {error}" for error in errors])
                error_msg += "\n\nPlease fix the highlighted fields before extracting."
                
                QMessageBox.critical(self, "Validation Failed", error_msg)
                return  # Block extraction/saving completely
        
        # Clear any previous highlights
        self.highlight_invalid_fields([])
        
        # Ensure data directory exists
        os.makedirs(self.data_dir, exist_ok=True)
        
        # Determine output file
        output_file = os.path.join(self.data_dir, "data_entries.csv")
        
        # Check if file exists to determine if we need to write headers
        file_exists = os.path.exists(output_file)
        
        # Use fieldnames from template
        fieldnames = self.template_fieldnames if self.template_fieldnames else list(data_row.keys())
        
        try:
            with open(output_file, 'a', newline='', encoding='utf-8') as f:
                writer = csv.DictWriter(f, fieldnames=fieldnames)
                
                # Write header if file is new
                if not file_exists:
                    writer.writeheader()
                
                # Write data row
                writer.writerow(data_row)
            
            # Add to in-memory list
            self.all_data_entries.append(data_row)
            
            print(f"✓ Auto-save: Added entry #{len(self.all_data_entries)}, total entries={len(self.all_data_entries)}")
            
            # Prepare form for NEXT entry by repopulating base data and clearing observation fields
            self.populate_fields_from_base_data()
            
            # Set current_entry_index to indicate we're working on a NEW entry (next entry after the last saved)
            self.current_entry_index = len(self.all_data_entries)
            
            print(f"  Now ready for entry #{self.current_entry_index + 1}")
            print(f"  Can copy from previous: {len(self.all_data_entries) > 0}")
            
            # Update navigation display
            self.update_navigation_buttons()
        except Exception as e:
            QMessageBox.critical(
                self, "Error",
                f"Failed to auto-save data entry:\n{str(e)}"
            )
    
    def delete_current_entry(self):
        """Delete the currently displayed entry"""
        if self.current_entry_index < 0 or self.current_entry_index >= len(self.all_data_entries):
            QMessageBox.warning(
                self, "No Entry",
                "No entry is currently loaded. Load entries first using 'Load All Entries' button."
            )
            return
        
        # Get the entry to delete
        entry = self.all_data_entries[self.current_entry_index]
        drop_id = entry.get('DROP_ID', '')
        filename = entry.get('FILENAME', '')
        
        # Confirm deletion
        reply = QMessageBox.question(
            self, "Confirm Delete",
            f"Are you sure you want to delete this entry?\n\nDROP_ID: {drop_id}\nFILENAME: {filename}\n\nThis will remove it from the CSV file.",
            QMessageBox.Yes | QMessageBox.No
        )
        
        if reply == QMessageBox.No:
            return
        
        # Remove from in-memory list
        del self.all_data_entries[self.current_entry_index]
        
        # Write updated list back to CSV
        output_file = os.path.join(self.data_dir, "data_entries.csv")
        fieldnames = self.template_fieldnames if self.template_fieldnames else []
        
        try:
            with open(output_file, 'w', newline='', encoding='utf-8') as f:
                writer = csv.DictWriter(f, fieldnames=fieldnames)
                writer.writeheader()
                writer.writerows(self.all_data_entries)
            
            QMessageBox.information(
                self, "Success",
                f"Entry deleted successfully.\n\nRemaining entries: {len(self.all_data_entries)}"
            )
            
            # Navigate to the next entry or previous if at end
            if len(self.all_data_entries) == 0:
                self.clear_data_entry()
                self.current_entry_index = -1
                self.update_navigation_buttons()
            else:
                # Stay at same index (which now shows the next entry) or go to last if we deleted the last entry
                if self.current_entry_index >= len(self.all_data_entries):
                    self.current_entry_index = len(self.all_data_entries) - 1
                self.load_entry_at_index(self.current_entry_index)
        except Exception as e:
            QMessageBox.critical(
                self, "Error",
                f"Failed to delete entry:\n{str(e)}"
            )
    
    def reset_drop_count(self):
        """Reset the drop counter for the current video"""
        if not self.video_path:
            QMessageBox.warning(
                self, "No Video",
                "No video is currently loaded. Load a video first."
            )
            return
        
        # Ask for new drop number
        current_count = self.drop_counter
        video_name = os.path.basename(self.video_path)
        
        new_count, ok = QInputDialog.getInt(
            self, "Reset Drop Count",
            f"Current video: {video_name}\n\nCurrent drop count: {current_count}\n\nEnter new drop count:",
            value=1, minValue=1, maxValue=9999
        )
        
        if ok:
            self.drop_counter = new_count
            
            # Update the queue label if using video queue
            if self.video_queue and self.video_path in self.video_queue:
                self.queue_label.setText(
                    f"{self.current_video_index + 1}/{len(self.video_queue)}: Drop {self.drop_counter}"
                )
            
            # Update DROP_ID field if data is loaded
            if self.data_fields and 'DROP_ID' in self.data_fields:
                self.data_fields['DROP_ID'].blockSignals(True)
                self.data_fields['DROP_ID'].setText(f"drop{self.drop_counter}")
                self.data_fields['DROP_ID'].blockSignals(False)
            
            QMessageBox.information(
                self, "Success",
                f"Drop count reset to {new_count} for current video.\n\nNext extracted frame will be: drop{new_count}"
            )
    
    def manage_validation_rules(self):
        """Open the validation rules management dialog"""
        dialog = ValidationRulesDialog(self, self.template_fieldnames, self.validation_rules)
        if dialog.exec_() == QDialog.Accepted:
            self.validation_rules = dialog.get_rules()
            self.save_validation_rules()
            
            # Show summary
            QMessageBox.information(
                self, "Rules Updated",
                f"Validation rules updated successfully!\n\nTotal rules: {len(self.validation_rules)}\n\n"
                f"Rules will be checked when saving entries."
            )
    
    def show_map(self):
        """Show all points on a Leaflet map with current point highlighted"""
        if not self.base_data_csv or len(self.base_data_csv) < 1:
            QMessageBox.warning(
                self, "No Data",
                "No base data loaded. Please load a base CSV file first."
            )
            return
        
        # Extract unique points with their coordinates
        points_data = []
        seen_points = set()
        
        # base_data_csv contains dictionaries (from csv.DictReader)
        # Check if required fields exist
        first_row = self.base_data_csv[0]
        if 'POINT_ID' not in first_row or 'LATITUDE' not in first_row or 'LONGITUDE' not in first_row:
            QMessageBox.warning(
                self, "Missing Fields",
                "Required fields not found in base CSV.\n\nMake sure your CSV has POINT_ID, LATITUDE, and LONGITUDE columns."
            )
            return
        
        # Collect unique points
        for row in self.base_data_csv:
            point_id = row.get('POINT_ID', '')
            lat_str = row.get('LATITUDE', '')
            lon_str = row.get('LONGITUDE', '')
            
            # Skip if already seen or if coordinates are empty
            if point_id in seen_points or not lat_str or not lon_str:
                continue
            
            try:
                lat = float(lat_str)
                lon = float(lon_str)
                
                point_info = {
                    'point_id': point_id,
                    'lat': lat,
                    'lon': lon
                }
                
                # Add optional fields if available
                for field in ['LOCATION', 'DEPTH', 'DATE', 'SUBSTRATE', 'MODE']:
                    value = row.get(field, '')
                    point_info[field.lower()] = value if value else 'N/A'
                
                points_data.append(point_info)
                seen_points.add(point_id)
            except (ValueError, TypeError):
                continue
        
        if not points_data:
            QMessageBox.warning(
                self, "No Valid Points",
                "No valid points with coordinates found in base CSV."
            )
            return
        
        # Get current point ID
        current_point_id = self.base_data.get('POINT_ID', '') if self.base_data else ''
        
        # Show map dialog
        dialog = MapDialog(points_data, current_point_id, self)
        dialog.exec_()
    
    def load_validation_rules(self):
        """Load validation rules from JSON file"""
        if not self.template_path:
            print("No template path - skipping rule load")
            return
        
        # Generate rules filename based on template
        template_dir = os.path.dirname(self.template_path)
        template_name = os.path.splitext(os.path.basename(self.template_path))[0]
        rules_path = os.path.join(template_dir, f"{template_name}_rules.json")
        
        print(f"Looking for rules file: {rules_path}")
        
        if os.path.exists(rules_path):
            try:
                with open(rules_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    self.validation_rules = data.get('rules', [])
                
                if self.validation_rules:
                    print(f"✓ Loaded {len(self.validation_rules)} validation rules")
                    # Show rule types for debugging
                    for i, rule in enumerate(self.validation_rules):
                        print(f"  Rule {i+1}: {rule.get('type')} - {self.format_rule_summary(rule)}")
            except Exception as e:
                print(f"❌ Failed to load validation rules: {str(e)}")
        else:
            print(f"No rules file found at: {rules_path}")
    
    def save_validation_rules(self):
        """Save validation rules to JSON file"""
        if not self.template_path:
            return
        
        # Generate rules filename based on template
        template_dir = os.path.dirname(self.template_path)
        template_name = os.path.splitext(os.path.basename(self.template_path))[0]
        rules_path = os.path.join(template_dir, f"{template_name}_rules.json")
        
        try:
            with open(rules_path, 'w', encoding='utf-8') as f:
                json.dump({'rules': self.validation_rules}, f, indent=2)
            
            print(f"Saved {len(self.validation_rules)} validation rules to {rules_path}")
        except Exception as e:
            QMessageBox.warning(
                self, "Save Error",
                f"Failed to save validation rules:\n{str(e)}"
            )
    
    def format_rule_summary(self, rule):
        """Format a brief rule summary for debugging"""
        rule_type = rule.get('type')
        if rule_type == 'autofill':
            return f"When {rule.get('trigger_field')}={rule.get('trigger_value')}, fill {len(rule.get('actions', {}))} fields"
        elif rule_type == 'conditional_sum':
            # Format IF condition symbol
            if_condition = rule.get('if_condition', 'equals')
            if if_condition == 'greater':
                if_symbol = ">"
            elif if_condition == 'greater_equal':
                if_symbol = ">="
            elif if_condition == 'not_equals':
                if_symbol = "!="
            else:
                if_symbol = "="
            
            # Format SUM comparison symbol
            comparison = rule.get('comparison', 'equal')
            if comparison == 'greater':
                comp_symbol = ">"
            elif comparison == 'greater_equal':
                comp_symbol = ">="
            else:
                comp_symbol = "="
            return f"If {rule.get('if_field')}{if_symbol}{rule.get('if_value')}, sum{comp_symbol}{rule.get('target')}"
        elif rule_type == 'conditional':
            return f"If {rule.get('if_field')}={rule.get('if_value')}"
        elif rule_type == 'calculated':
            return f"Calc: {rule.get('target_field')}={rule.get('formula')}"
        else:
            return rule_type
    
    def is_mostly_empty_entry(self, data_row):
        """Check if entry is mostly empty (only metadata filled, no observations)"""
        # Count non-empty observation fields (excluding metadata fields)
        non_empty_observation_fields = 0
        total_observation_fields = 0
        
        for field_name, value in data_row.items():
            # Skip metadata fields
            if field_name in self.non_copyable_fields:
                continue
            
            total_observation_fields += 1
            if value and value.strip():
                non_empty_observation_fields += 1
        
        # If less than 20% of observation fields are filled, consider it mostly empty
        if total_observation_fields == 0:
            return True
        
        fill_percentage = non_empty_observation_fields / total_observation_fields
        return fill_percentage < 0.2
    
    def validate_data_entry(self, data_row):
        """Validate a data entry against all rules. Returns (is_valid, errors_list)"""
        if not self.validation_rules:
            return True, []
        
        errors = []
        
        for rule in self.validation_rules:
            rule_type = rule.get('type')
            
            try:
                if rule_type == 'allowed_values':
                    field = rule.get('field')
                    value = data_row.get(field, '').strip()
                    allowed = [str(v).strip() for v in rule.get('values', [])]
                    
                    if value and value not in allowed:
                        errors.append(rule.get('error', f"{field} has invalid value"))
                
                elif rule_type == 'range':
                    field = rule.get('field')
                    value_str = data_row.get(field, '').strip()
                    
                    if value_str:
                        try:
                            value = float(value_str)
                            min_val = float(rule.get('min', 0))
                            max_val = float(rule.get('max', 100))
                            
                            if value < min_val or value > max_val:
                                errors.append(rule.get('error', f"{field} out of range"))
                        except ValueError:
                            errors.append(f"{field} must be a number")
                
                elif rule_type == 'required':
                    field = rule.get('field')
                    value = data_row.get(field, '').strip()
                    
                    if not value:
                        errors.append(rule.get('error', f"{field} is required"))
                
                elif rule_type == 'conditional':
                    if_field = rule.get('if_field')
                    if_value = str(rule.get('if_value', '')).strip()
                    then_field = rule.get('then_field')
                    then_condition = rule.get('then_condition', 'equals')
                    then_value = str(rule.get('then_value', '')).strip()
                    
                    current_if_value = data_row.get(if_field, '').strip()
                    
                    # Check if condition applies
                    if current_if_value == if_value:
                        current_then_value = data_row.get(then_field, '').strip()
                        
                        # Evaluate the condition
                        condition_met = False
                        
                        try:
                            # Try numeric comparison first
                            curr_num = float(current_then_value) if current_then_value else 0
                            then_num = float(then_value) if then_value else 0
                            
                            if then_condition == 'equals':
                                condition_met = curr_num == then_num
                            elif then_condition == 'not_equals':
                                condition_met = curr_num != then_num
                            elif then_condition == 'greater_than':
                                condition_met = curr_num > then_num
                            elif then_condition == 'less_than':
                                condition_met = curr_num < then_num
                            elif then_condition == 'greater_equal':
                                condition_met = curr_num >= then_num
                            elif then_condition == 'less_equal':
                                condition_met = curr_num <= then_num
                        except ValueError:
                            # Fall back to string comparison
                            if then_condition == 'equals':
                                condition_met = current_then_value == then_value
                            elif then_condition == 'not_equals':
                                condition_met = current_then_value != then_value
                        
                        if not condition_met:
                            errors.append(rule.get('error', f"Conditional rule failed"))
                
                elif rule_type == 'sum_equals':
                    fields = rule.get('fields', [])
                    target = float(rule.get('target', 0))
                    tolerance = float(rule.get('tolerance', 0))
                    
                    total = 0
                    missing_fields = []
                    
                    for field in fields:
                        value_str = data_row.get(field, '').strip()
                        if value_str:
                            try:
                                total += float(value_str)
                            except ValueError:
                                errors.append(f"{field} must be a number for sum calculation")
                        else:
                            missing_fields.append(field)
                    
                    # Only validate if all fields have values
                    if not missing_fields:
                        if abs(total - target) > tolerance:
                            errors.append(rule.get('error', f"Sum validation failed"))
                
                elif rule_type == 'conditional_sum':
                    if_field = rule.get('if_field')
                    if_value = str(rule.get('if_value', '')).strip()
                    if_condition = rule.get('if_condition', 'equals')  # Default to 'equals' for backward compatibility
                    current_if_value = data_row.get(if_field, '').strip()
                    
                    # Check if condition applies based on if_condition operator
                    condition_met = False
                    try:
                        # Try numeric comparison first
                        curr_num = float(current_if_value) if current_if_value else 0
                        if_num = float(if_value) if if_value else 0
                        
                        if if_condition == 'equals':
                            condition_met = curr_num == if_num
                        elif if_condition == 'greater':
                            condition_met = curr_num > if_num
                        elif if_condition == 'greater_equal':
                            condition_met = curr_num >= if_num
                        elif if_condition == 'not_equals':
                            condition_met = curr_num != if_num
                    except ValueError:
                        # Fall back to string comparison
                        if if_condition == 'equals':
                            condition_met = current_if_value == if_value
                        elif if_condition == 'not_equals':
                            condition_met = current_if_value != if_value
                        # For greater/greater_equal, cannot compare strings meaningfully
                        else:
                            condition_met = False
                    
                    if condition_met:
                        fields = rule.get('fields', [])
                        target = float(rule.get('target', 0))
                        tolerance = float(rule.get('tolerance', 0))
                        blank_as_zero = rule.get('blank_as_zero', True)
                        comparison = rule.get('comparison', 'equal')  # Default to 'equal' for backward compatibility
                        
                        total = 0
                        has_error = False
                        
                        for field in fields:
                            value_str = data_row.get(field, '').strip()
                            
                            if value_str:
                                try:
                                    total += float(value_str)
                                except ValueError:
                                    errors.append(f"{field} must be a number for sum calculation")
                                    has_error = True
                            elif blank_as_zero:
                                # Treat blank as 0
                                total += 0
                            # else: skip this field in calculation
                        
                        if not has_error:
                            # Check based on comparison operator
                            is_valid = False
                            if comparison == 'equal':
                                is_valid = abs(total - target) <= tolerance
                            elif comparison == 'greater':
                                is_valid = total > target
                            elif comparison == 'greater_equal':
                                is_valid = total >= target
                            
                            if not is_valid:
                                errors.append(rule.get('error', f"Conditional sum validation failed"))
            
            except Exception as e:
                print(f"Error validating rule: {str(e)}")
                continue
        
        return len(errors) == 0, errors
    
    def highlight_invalid_fields(self, errors):
        """Highlight fields mentioned in errors"""
        # Reset all fields to normal
        for field_name, widget in self.data_fields.items():
            if isinstance(widget, QTextEdit):
                widget.setStyleSheet("")
            else:
                widget.setStyleSheet("")
        
        # Highlight fields with errors
        for error in errors:
            for field_name, widget in self.data_fields.items():
                if field_name in error:
                    if isinstance(widget, QTextEdit):
                        widget.setStyleSheet("border: 2px solid red;")
                    else:
                        widget.setStyleSheet("border: 2px solid red;")
    
    def check_autofill_rules(self, changed_field):
        """Check if any auto-fill rules should be triggered"""
        if not self.validation_rules:
            return
        
        # Get current value of the changed field
        widget = self.data_fields.get(changed_field)
        if not widget:
            return
        
        if isinstance(widget, QTextEdit):
            current_value = widget.toPlainText().strip()
        else:
            current_value = widget.text().strip()
        
        # Debug output (can be removed later)
        print(f"Auto-fill check: {changed_field} = '{current_value}'")
        
        # Check all auto-fill rules
        for rule in self.validation_rules:
            if rule.get('type') == 'autofill':
                trigger_field = rule.get('trigger_field')
                trigger_value = str(rule.get('trigger_value', '')).strip()
                
                print(f"  Rule: If {trigger_field}='{trigger_value}' (current field: {changed_field})")
                
                # Check if this rule applies to the changed field
                if trigger_field == changed_field and current_value == trigger_value:
                    print(f"  ✓ Auto-fill triggered!")
                    # Apply the auto-fill actions
                    actions = rule.get('actions', {})
                    
                    # Block signals temporarily to avoid triggering other rules
                    for field_name, w in self.data_fields.items():
                        w.blockSignals(True)
                    
                    # Apply each action
                    fields_filled = 0
                    for field_name, value in actions.items():
                        if field_name in self.data_fields:
                            target_widget = self.data_fields[field_name]
                            if isinstance(target_widget, QTextEdit):
                                target_widget.setPlainText(str(value))
                            else:
                                target_widget.setText(str(value))
                            fields_filled += 1
                            print(f"    Set {field_name} = {value}")
                    
                    print(f"  Auto-filled {fields_filled} fields")
                    
                    # Unblock signals
                    for field_name, w in self.data_fields.items():
                        w.blockSignals(False)
                    
                    # Mark as changed
                    self.mark_entry_changed()
                    
                    # Break after first matching rule
                    break
    
    def check_calculated_rules(self, changed_field):
        """Check if any calculated field rules should be triggered"""
        if not self.validation_rules:
            return
        
        # Check all calculated rules
        for rule in self.validation_rules:
            if rule.get('type') == 'calculated':
                formula = rule.get('formula', '')
                target_field = rule.get('target_field')
                decimals = int(rule.get('decimals', 1))
                
                # Find all field names referenced in the formula
                # Field names are uppercase letters and underscores
                referenced_fields = re.findall(r'\b[A-Z][A-Z0-9_]*\b', formula)
                
                # Check if the changed field is referenced in this formula
                if changed_field in referenced_fields or changed_field == target_field:
                    print(f"Calculated field check: {target_field} = {formula}")
                    
                    # Get current values for all fields
                    formula_to_eval = formula
                    all_fields_available = True
                    
                    for field_name in referenced_fields:
                        if field_name in self.data_fields:
                            widget = self.data_fields[field_name]
                            if isinstance(widget, QTextEdit):
                                value_str = widget.toPlainText().strip()
                            else:
                                value_str = widget.text().strip()
                            
                            # Try to convert to number (blank = 0)
                            try:
                                value = float(value_str) if value_str and value_str != 'NA' else 0
                            except ValueError:
                                # Non-numeric value, skip this calculation
                                print(f"  ⚠ Field {field_name} has non-numeric value: '{value_str}'")
                                all_fields_available = False
                                break
                            
                            # Replace field name with its value in the formula
                            formula_to_eval = re.sub(r'\b' + field_name + r'\b', str(value), formula_to_eval)
                        else:
                            all_fields_available = False
                            break
                    
                    if all_fields_available:
                        try:
                            # Evaluate the formula (safe eval with limited scope)
                            result = eval(formula_to_eval, {"__builtins__": {}}, {})
                            result_formatted = f"{result:.{decimals}f}"
                            
                            print(f"  ✓ Calculated: {formula_to_eval} = {result_formatted}")
                            
                            # Update the target field
                            if target_field in self.data_fields:
                                target_widget = self.data_fields[target_field]
                                
                                # Block signals temporarily to avoid triggering other rules
                                target_widget.blockSignals(True)
                                
                                if isinstance(target_widget, QTextEdit):
                                    target_widget.setPlainText(result_formatted)
                                else:
                                    target_widget.setText(result_formatted)
                                
                                target_widget.blockSignals(False)
                                
                                print(f"  Set {target_field} = {result_formatted}")
                        
                        except Exception as e:
                            print(f"  ❌ Error evaluating formula: {str(e)}")
    
    def show_instructions(self):
        """Show instructions popup dialog"""
        # Create a proper dialog with scroll area
        dialog = QDialog(self)
        dialog.setWindowTitle("📖 Instructions - Drop Cam Video Analysis")
        dialog.setMinimumSize(700, 600)
        
        # Create layout
        layout = QVBoxLayout(dialog)
        
        # Create scroll area
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setHorizontalScrollBarPolicy(Qt.ScrollBarAsNeeded)
        scroll.setVerticalScrollBarPolicy(Qt.ScrollBarAsNeeded)
        
        # Create content widget
        content_widget = QWidget()
        content_layout = QVBoxLayout(content_widget)
        
        # Create label with HTML content
        instructions = """
<div style="padding: 20px; max-width: 100%;">

<h2 style="color: #2196F3;">📖 Quick Start Guide</h2>

<h3 style="color: #F44336;">⚠️ CRITICAL: Correct Workflow Order</h3>
<p><b>Press 'S' to "Save and Snapshot"</b> - it saves current form data + captures image</p>
<p><b style="color: #4CAF50;">✓ Correct:</b> Find frame → Fill data → Press 'S' (saves + extracts)</p>
<p><b style="color: #F44336;">✗ Wrong:</b> Press 'S' first → Fill data (will save empty data!)</p>

<hr>

<h3 style="color: #2196F3;">🎯 Step-by-Step Workflow</h3>
<ol>
  <li><b>Load Videos:</b> Click "Load Videos from drop_videos/"</li>
  <li><b>Find Frame:</b> Use Play/Pause and arrow keys to navigate</li>
  <li><b>Fill Data FIRST:</b> Enter observations (or copy from previous)</li>
  <li><b>Press 'S':</b> Saves data + extracts still image</li>
  <li><b>Repeat:</b> Find next frame → Fill data → Press 'S'</li>
  <li><b>Last Drop:</b> Click "Save Entry" manually or "Next Video"</li>
</ol>

<hr>

<h3 style="color: #2196F3;">⌨️ Keyboard Shortcuts</h3>
<table border="1" cellpadding="8" cellspacing="0" style="border-collapse: collapse; width: 100%;">
  <tr style="background-color: #E3F2FD;"><td><b>Spacebar</b></td><td>Play/Pause</td></tr>
  <tr><td><b>→ / ←</b></td><td>Next/Previous frame</td></tr>
  <tr style="background-color: #E3F2FD;"><td><b>Shift+→ / Shift+←</b></td><td>Skip ±10 frames</td></tr>
  <tr><td><b>Ctrl+→ / Ctrl+←</b></td><td>Skip ±100 frames</td></tr>
  <tr style="background-color: #E3F2FD;"><td><b>S</b></td><td>Extract frame (saves data + image)</td></tr>
</table>

<hr>

<h3 style="color: #FF9800;">⚡ Time-Saving Features</h3>

<h4>1. Copy from Previous Entry</h4>
<ul>
  <li><b>◄ Copy All from Previous Entry</b> (purple button) - Copies ALL observation fields</li>
  <li><b>◄ buttons</b> next to each field - Copy individual fields</li>
  <li><b>What's copied:</b> SUBSTRATE, species, coverage, COMMENTS</li>
  <li><b>What's preserved:</b> DROP_ID, POINT_ID, FILENAME, coordinates, dates</li>
  <li><b>Time saved:</b> 67% faster for similar drops!</li>
</ul>

<h4>2. Auto-Fill Rules</h4>
<ul>
  <li>Set up in "⚙ Manage Validation Rules"</li>
  <li><b>Example:</b> When SG_PRESENT=0 → Auto-fills all species with "NA"</li>
  <li>Saves typing "NA" in 10+ fields!</li>
</ul>

<h4>3. Validation Rules (QAQC)</h4>
<ul>
  <li>Automatically checks data quality before saving</li>
  <li>Highlights invalid fields in red</li>
  <li>Prevents common errors (wrong values, sum errors, missing data)</li>
  <li><b>⚠️ STRICT MODE:</b> You CANNOT save if validation fails!</li>
  <li>Click "⚙ Manage Validation Rules" to set up</li>
</ul>

<hr>

<h3 style="color: #4CAF50;">💡 Pro Tips</h3>
<ul>
  <li><b>First drop:</b> Fill all fields manually (~2 minutes)</li>
  <li><b>Similar drops:</b> Click "Copy All" → Adjust differences (~30 seconds)</li>
  <li><b>No seagrass:</b> Type SG_PRESENT=0 → Auto-fill handles the rest!</li>
  <li><b>Review data:</b> Click "Load All Entries" to browse and edit</li>
  <li><b>Backup regularly:</b> Copy data_entries.csv to safe location</li>
</ul>

<hr>

<h3 style="color: #F44336;">🆘 Common Issues</h3>
<ul>
  <li><b>Empty drop1 data:</b> You extracted before filling data - delete row 2 in CSV</li>
  <li><b>Copy not working:</b> Need at least 2 drops extracted first</li>
  <li><b>Auto-fill not working:</b> Set up auto-fill rule in Validation Rules first</li>
  <li><b>Validation blocking save:</b> Fix all highlighted fields - strict mode ON!</li>
</ul>

<hr>

<p><b>For detailed documentation, see:</b> README.md and TUTORIAL.md</p>

</div>
"""
        
        label = QLabel(instructions)
        label.setTextFormat(Qt.RichText)
        label.setWordWrap(True)
        label.setAlignment(Qt.AlignTop | Qt.AlignLeft)
        label.setStyleSheet("padding: 10px;")
        
        content_layout.addWidget(label)
        content_layout.addStretch()
        
        # Set content widget to scroll area
        scroll.setWidget(content_widget)
        
        # Add scroll area to main layout
        layout.addWidget(scroll)
        
        # Add OK button
        button_layout = QHBoxLayout()
        ok_button = QPushButton("Got it!")
        ok_button.setStyleSheet("background-color: #4CAF50; color: white; font-weight: bold; padding: 10px 30px;")
        ok_button.clicked.connect(dialog.accept)
        button_layout.addStretch()
        button_layout.addWidget(ok_button)
        button_layout.addStretch()
        
        layout.addLayout(button_layout)
        
        # Show dialog
        dialog.exec_()
    
    def save_project(self, project_path=None):
        """Save current project state to a file"""
        if not project_path:
            project_path, _ = QFileDialog.getSaveFileName(
                self, "Save Project",
                self.projects_dir,
                "Project Files (*.json);;All Files (*.*)"
            )
            
            if not project_path:
                return False
        
        try:
            # Collect project state
            project_data = {
                'template_path': self.template_path,
                'base_data_csv_path': self.base_data_csv_path,  # Store path to base CSV file
                'video_queue': self.video_queue,
                'current_video_index': self.current_video_index,
                'current_video_path': self.video_path,
                'current_frame': self.current_frame if self.cap else 0,
                'drop_counter': self.drop_counter,
                'current_entry_index': self.current_entry_index,
                'base_data': self.base_data,
                'base_data_csv': self.base_data_csv,  # Save the full CSV data for map
                'saved_at': datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            }
            
            # Save to JSON
            with open(project_path, 'w', encoding='utf-8') as f:
                json.dump(project_data, f, indent=2)
            
            self.current_project_file = project_path
            print(f"Project saved to: {project_path}")
            return True
            
        except Exception as e:
            QMessageBox.critical(
                self, "Error",
                f"Failed to save project:\n{str(e)}"
            )
            return False
    
    def load_project(self):
        """Load project state from a file"""
        project_path, _ = QFileDialog.getOpenFileName(
            self, "Load Project",
            self.projects_dir,
            "Project Files (*.json);;All Files (*.*)"
        )
        
        if not project_path:
            return False
        
        try:
            # Load project data
            with open(project_path, 'r', encoding='utf-8') as f:
                project_data = json.load(f)
            
            # Restore template
            self.template_path = project_data.get('template_path')
            if not self.template_path or not os.path.exists(self.template_path):
                QMessageBox.critical(self, "Error", "Template file not found. Project cannot be loaded.")
                return False
            
            # Load template fieldnames
            with open(self.template_path, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                self.template_fieldnames = reader.fieldnames
            
            # Load validation rules
            self.load_validation_rules()
            
            # Restore state
            self.video_queue = project_data.get('video_queue', [])
            self.current_video_index = project_data.get('current_video_index', 0)
            self.drop_counter = project_data.get('drop_counter', 1)
            self.current_entry_index = project_data.get('current_entry_index', -1)
            self.base_data = project_data.get('base_data', {})
            self.base_data_csv = project_data.get('base_data_csv', [])  # Restore base CSV for map
            self.base_data_csv_path = project_data.get('base_data_csv_path')  # Restore base CSV path
            
            # Create data entry pane with loaded template
            self.create_data_entry_pane()
            
            # Replace placeholder with actual data entry widget
            self.main_layout.removeWidget(self.data_entry_placeholder)
            self.data_entry_placeholder.deleteLater()
            self.main_layout.addWidget(self.data_entry_widget, 1)
            
            # Load all data entries from CSV
            output_file = os.path.join(self.data_dir, "data_entries.csv")
            if os.path.exists(output_file):
                with open(output_file, 'r', encoding='utf-8') as f:
                    reader = csv.DictReader(f)
                    self.all_data_entries = list(reader)
            
            # Restore video if it exists
            current_video_path = project_data.get('current_video_path')
            if current_video_path and os.path.exists(current_video_path):
                # Load the video
                if self.cap:
                    self.cap.release()
                
                self.video_path = current_video_path
                self.cap = cv2.VideoCapture(current_video_path, cv2.CAP_FFMPEG)
                self.cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
                
                if self.cap.isOpened():
                    self.total_frames = int(self.cap.get(cv2.CAP_PROP_FRAME_COUNT))
                    self.fps = self.cap.get(cv2.CAP_PROP_FPS)
                    self.current_frame = project_data.get('current_frame', 0)
                    
                    self.timeline_slider.setMaximum(self.total_frames - 1)
                    self.timeline_slider.setValue(self.current_frame)
                    
                    # Enable controls
                    self.play_btn.setEnabled(True)
                    self.prev_frame_btn.setEnabled(True)
                    self.next_frame_btn.setEnabled(True)
                    self.skip_back_btn.setEnabled(True)
                    self.skip_forward_btn.setEnabled(True)
                    self.speed_combo.setEnabled(True)
                    self.zoom_slider.setEnabled(True)
                    self.extract_btn.setEnabled(True)
                    
                    # Update queue label if in queue mode
                    if self.video_queue:
                        self.queue_label.setText(
                            f"{self.current_video_index + 1}/{len(self.video_queue)}: Drop {self.drop_counter}"
                        )
                        # Enable video navigation buttons
                        self.prev_video_btn.setEnabled(True)
                        self.next_video_btn.setEnabled(True)
                    
                    self.display_frame()
            
            # Populate fields with base data
            if self.base_data:
                self.populate_fields_from_base_data()
            
            # Update navigation
            self.update_navigation_buttons()
            
            self.current_project_file = project_path
            
            QMessageBox.information(
                self, "Project Loaded",
                f"Project loaded successfully!\n\n"
                f"Entries: {len(self.all_data_entries)}\n"
                f"Video: {os.path.basename(current_video_path) if current_video_path else 'None'}\n"
                f"Next drop: {self.drop_counter}\n\n"
                f"Ready to resume work!"
            )
            
            return True
            
        except Exception as e:
            QMessageBox.critical(
                self, "Error",
                f"Failed to load project:\n{str(e)}"
            )
            return False
    
    def toggle_layout_mode(self):
        """Toggle between single-window and dual-screen layout"""
        if self.is_detached_mode:
            self.reattach_data_entry_pane()
        else:
            self.detach_data_entry_pane()
    
    def detach_data_entry_pane(self):
        """Detach data entry pane into separate window (dual-screen mode)"""
        if self.is_detached_mode or not self.data_entry_widget:
            return
        
        # Remove data entry widget from main layout
        self.main_layout.removeWidget(self.data_entry_widget)
        
        # Create detached window
        self.detached_window = DetachedDataEntryWindow(self)
        self.detached_window.set_data_entry_widget(self.data_entry_widget)
        
        # Position on second screen if available
        desktop = QApplication.desktop()
        if desktop.screenCount() > 1:
            # Move to second screen
            screen_rect = desktop.screenGeometry(1)
            self.detached_window.move(screen_rect.left() + 100, screen_rect.top() + 100)
        else:
            # Position to the right of main window
            main_geom = self.geometry()
            self.detached_window.move(main_geom.right() + 20, main_geom.top())
        
        self.detached_window.show()
        self.is_detached_mode = True
        
        # Update button tooltip
        self.layout_toggle_btn.setToolTip("Attach Data Entry Panel (Single Window Mode)")
        self.layout_toggle_btn.setStyleSheet("background-color: #4CAF50; color: white; font-weight: bold; padding: 5px;")
        
        print("Data entry panel detached to separate window")
    
    def reattach_data_entry_pane(self):
        """Reattach data entry pane to main window (single-window mode)"""
        if not self.is_detached_mode or not self.data_entry_widget:
            return
        
        # Remove from detached window
        if self.detached_window:
            self.detached_window.takeCentralWidget()
            self.detached_window.close()
            self.detached_window = None
        
        # Add back to main layout
        self.main_layout.addWidget(self.data_entry_widget, 1)
        
        self.is_detached_mode = False
        
        # Update button tooltip
        self.layout_toggle_btn.setToolTip("Toggle Dual-Screen Mode (Detach Data Entry Panel)")
        self.layout_toggle_btn.setStyleSheet("background-color: #FF5722; color: white; font-weight: bold; padding: 5px;")
        
        print("Data entry panel reattached to main window")
    
    def closeEvent(self, event):
        """Clean up when closing"""
        # Auto-save project before closing
        if self.current_project_file:
            self.save_project(self.current_project_file)
            print(f"Auto-saved project on close: {self.current_project_file}")
        elif self.template_path:
            # Offer to save project
            reply = QMessageBox.question(
                self, "Save Project?",
                "Would you like to save your project before closing?\n\n"
                "This will let you resume exactly where you left off next time.",
                QMessageBox.Yes | QMessageBox.No,
                QMessageBox.Yes
            )
            
            if reply == QMessageBox.Yes:
                self.save_project()
        
        # Close detached window if exists
        if self.detached_window:
            self.detached_window.close()
        
        if self.cap:
            self.cap.release()
        event.accept()


def main():
    app = QApplication(sys.argv)
    
    # Set global tooltip style to ensure visibility
    app.setStyleSheet("""
        QToolTip {
            background-color: #2b2b2b;
            color: #ffffff;
            border: 1px solid #555555;
            padding: 5px;
            border-radius: 3px;
            font-size: 11px;
        }
    """)
    
    player = VideoPlayer()
    player.show()
    sys.exit(app.exec_())


if __name__ == "__main__":
    main()
