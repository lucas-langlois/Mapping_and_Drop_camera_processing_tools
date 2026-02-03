"""
MP4 Video Player with Frame Extraction
Features: Play/Pause, Frame navigation, Timeline scrubbing, Speed control, Frame export
"""

import sys
import os
from datetime import datetime
import csv

# Set environment variable BEFORE importing cv2 to handle videos with multiple streams (video + audio)
os.environ['OPENCV_FFMPEG_READ_ATTEMPTS'] = '100000'
os.environ['OPENCV_VIDEOIO_PRIORITY_FFMPEG'] = '1'
os.environ['OPENCV_FFMPEG_CAPTURE_OPTIONS'] = 'video_codec_priority;h264'
os.environ['OPENCV_VIDEOIO_DEBUG'] = '0'  # Disable debug warnings

import cv2
from PyQt5.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, 
                             QHBoxLayout, QPushButton, QSlider, QLabel, 
                             QFileDialog, QSpinBox, QComboBox, QMessageBox,
                             QLineEdit, QTextEdit, QScrollArea, QGroupBox, QGridLayout)
from PyQt5.QtCore import QTimer, Qt
from PyQt5.QtGui import QImage, QPixmap, QKeySequence
from PyQt5.QtWidgets import QShortcut


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
        
        # Data entry variables
        self.data_fields = {}
        self.template_fieldnames = []  # Store fieldnames from template CSV
        self.base_data = {}  # Store preloaded base data from CSV
        self.base_data_csv = []  # Store all rows from loaded base CSV
        self.all_data_entries = []  # List of all data entries
        self.current_entry_index = -1  # Current position in data entries
        self.unsaved_changes = False  # Track if current entry has unsaved changes
        
        # Timer for video playback
        self.timer = QTimer()
        self.timer.timeout.connect(self.play_next_frame)
        
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
        
        return True
        
    def init_ui(self):
        """Initialize the user interface"""
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QHBoxLayout()
        
        # Left side: Video player
        video_layout = QVBoxLayout()
        
        # Video display label
        self.video_label = QLabel("Open a video file to start")
        self.video_label.setAlignment(Qt.AlignCenter)
        self.video_label.setStyleSheet("QLabel { background-color: black; color: white; }")
        self.video_label.setMinimumSize(800, 600)
        video_layout.addWidget(self.video_label)
        
        # Frame info label
        self.info_label = QLabel("Frame: 0 / 0 | Time: 00:00:00")
        self.info_label.setAlignment(Qt.AlignCenter)
        video_layout.addWidget(self.info_label)
        
        # Timeline slider
        self.timeline_slider = QSlider(Qt.Horizontal)
        self.timeline_slider.setMinimum(0)
        self.timeline_slider.setMaximum(0)
        self.timeline_slider.setPageStep(100)  # Jump 100 frames when clicking on slider track
        self.timeline_slider.setSingleStep(1)  # Move 1 frame with arrow keys
        self.timeline_slider.valueChanged.connect(self.slider_changed)
        video_layout.addWidget(self.timeline_slider)
        
        # Control buttons layout
        controls_layout = QHBoxLayout()
        
        # Open file button
        self.open_btn = QPushButton("Open Video")
        self.open_btn.clicked.connect(self.open_video)
        controls_layout.addWidget(self.open_btn)
        
        # Play/Pause button
        self.play_btn = QPushButton("Play")
        self.play_btn.clicked.connect(self.toggle_play)
        self.play_btn.setEnabled(False)
        controls_layout.addWidget(self.play_btn)
        
        # Previous frame button
        self.prev_frame_btn = QPushButton("◀ Frame")
        self.prev_frame_btn.clicked.connect(self.previous_frame)
        self.prev_frame_btn.setEnabled(False)
        controls_layout.addWidget(self.prev_frame_btn)
        
        # Next frame button
        self.next_frame_btn = QPushButton("Frame ▶")
        self.next_frame_btn.clicked.connect(self.next_frame)
        self.next_frame_btn.setEnabled(False)
        controls_layout.addWidget(self.next_frame_btn)
        
        # Skip backward button (10 frames)
        self.skip_back_btn = QPushButton("◀◀ -10")
        self.skip_back_btn.clicked.connect(lambda: self.skip_frames(-10))
        self.skip_back_btn.setEnabled(False)
        controls_layout.addWidget(self.skip_back_btn)
        
        # Skip forward button (10 frames)
        self.skip_forward_btn = QPushButton("+10 ▶▶")
        self.skip_forward_btn.clicked.connect(lambda: self.skip_frames(10))
        self.skip_forward_btn.setEnabled(False)
        controls_layout.addWidget(self.skip_forward_btn)
        
        # Speed control
        speed_label = QLabel("Speed:")
        controls_layout.addWidget(speed_label)
        self.speed_combo = QComboBox()
        self.speed_combo.addItems(["0.25x", "0.5x", "1x", "2x", "4x", "8x", "12x"])
        self.speed_combo.setCurrentIndex(2)  # 1x default
        self.speed_combo.currentTextChanged.connect(self.change_speed)
        self.speed_combo.setEnabled(False)
        controls_layout.addWidget(self.speed_combo)
        
        # Extract current frame button
        self.extract_btn = QPushButton("Extract Frame")
        self.extract_btn.clicked.connect(self.extract_current_frame)
        self.extract_btn.setEnabled(False)
        controls_layout.addWidget(self.extract_btn)
        
        # Batch extract button
        self.batch_extract_btn = QPushButton("Batch Extract")
        self.batch_extract_btn.clicked.connect(self.batch_extract)
        self.batch_extract_btn.setEnabled(False)
        controls_layout.addWidget(self.batch_extract_btn)
        
        video_layout.addLayout(controls_layout)
        
        # Auto-loader controls
        autoload_layout = QHBoxLayout()
        
        # Load videos from drop_videos button
        self.autoload_btn = QPushButton("Load Videos from drop_videos/")
        self.autoload_btn.clicked.connect(self.load_video_queue)
        autoload_layout.addWidget(self.autoload_btn)
        
        # Choose video folder button
        self.choose_folder_btn = QPushButton("Choose Video Folder...")
        self.choose_folder_btn.clicked.connect(self.choose_video_folder)
        autoload_layout.addWidget(self.choose_folder_btn)
        
        # Previous video button
        self.prev_video_btn = QPushButton("◀ Previous Video")
        self.prev_video_btn.clicked.connect(self.previous_video)
        self.prev_video_btn.setEnabled(False)
        autoload_layout.addWidget(self.prev_video_btn)
        
        # Next video button
        self.next_video_btn = QPushButton("Next Video ▶")
        self.next_video_btn.clicked.connect(self.next_video)
        self.next_video_btn.setEnabled(False)
        autoload_layout.addWidget(self.next_video_btn)
        
        # Video queue status label
        self.queue_label = QLabel("No videos loaded")
        autoload_layout.addWidget(self.queue_label)
        autoload_layout.addStretch()
        
        video_layout.addLayout(autoload_layout)
        
        # Batch extraction controls
        batch_layout = QHBoxLayout()
        batch_layout.addWidget(QLabel("Extract every"))
        self.frame_interval = QSpinBox()
        self.frame_interval.setMinimum(1)
        self.frame_interval.setMaximum(1000)
        self.frame_interval.setValue(30)
        batch_layout.addWidget(self.frame_interval)
        batch_layout.addWidget(QLabel("frames"))
        batch_layout.addStretch()
        video_layout.addLayout(batch_layout)
        
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
        self.prev_entry_btn.clicked.connect(self.previous_entry)
        self.prev_entry_btn.setEnabled(False)
        nav_layout.addWidget(self.prev_entry_btn)
        
        self.entry_position_label = QLabel("No entries loaded")
        self.entry_position_label.setAlignment(Qt.AlignCenter)
        self.entry_position_label.setStyleSheet("font-weight: bold;")
        nav_layout.addWidget(self.entry_position_label)
        
        self.next_entry_btn = QPushButton("Next Entry ▶")
        self.next_entry_btn.clicked.connect(self.next_entry)
        self.next_entry_btn.setEnabled(False)
        nav_layout.addWidget(self.next_entry_btn)
        
        layout.addLayout(nav_layout)
        
        # Load all entries button
        load_entries_btn = QPushButton("Load All Entries")
        load_entries_btn.clicked.connect(self.load_all_entries)
        load_entries_btn.setStyleSheet("background-color: #FF9800; color: white; padding: 5px;")
        layout.addWidget(load_entries_btn)
        
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
                    field_widget.textChanged.connect(self.mark_entry_changed)
                else:
                    field_widget = QLineEdit()
                    field_widget.textChanged.connect(self.mark_entry_changed)
                
                group_layout.addWidget(field_widget, row, 1)
                self.data_fields[field_name] = field_widget
                row += 1
            
            group_box.setLayout(group_layout)
            layout.addWidget(group_box)
        
        # Action buttons
        button_layout = QHBoxLayout()
        
        load_base_btn = QPushButton("Load Base CSV")
        load_base_btn.clicked.connect(self.load_base_data)
        load_base_btn.setStyleSheet("background-color: #2196F3; color: white; font-weight: bold; padding: 8px;")
        button_layout.addWidget(load_base_btn)
        
        save_btn = QPushButton("Save Entry")
        save_btn.clicked.connect(self.save_data_entry)
        save_btn.setStyleSheet("background-color: #4CAF50; color: white; font-weight: bold; padding: 8px;")
        button_layout.addWidget(save_btn)
        
        clear_btn = QPushButton("Clear Form")
        clear_btn.clicked.connect(self.clear_data_entry)
        button_layout.addWidget(clear_btn)
        
        layout.addLayout(button_layout)
        
        # Additional action buttons (second row)
        button_layout2 = QHBoxLayout()
        
        delete_btn = QPushButton("Delete Current Entry")
        delete_btn.clicked.connect(self.delete_current_entry)
        delete_btn.setStyleSheet("background-color: #F44336; color: white; font-weight: bold; padding: 8px;")
        button_layout2.addWidget(delete_btn)
        
        reset_drop_btn = QPushButton("Reset Drop Count")
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
            self.extract_btn.setEnabled(True)
            self.batch_extract_btn.setEnabled(True)
            
            self.display_frame()
            
    def toggle_play(self):
        """Toggle play/pause"""
        if not self.cap:
            return
            
        self.is_playing = not self.is_playing
        
        if self.is_playing:
            self.play_btn.setText("Pause")
            interval = int(1000 / (self.fps * self.playback_speed))
            # Ensure minimum interval of 1ms for smooth high-speed playback
            interval = max(1, interval)
            self.timer.start(interval)
        else:
            self.play_btn.setText("Play")
            self.timer.stop()
            
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
        
        # Create QImage and scale to fit label
        q_img = QImage(rgb_frame.data, w, h, bytes_per_line, QImage.Format_RGB888)
        pixmap = QPixmap.fromImage(q_img)
        
        # Scale pixmap to fit label while maintaining aspect ratio
        # Use FastTransformation for better performance during navigation
        scaled_pixmap = pixmap.scaled(
            self.video_label.size(), 
            Qt.KeepAspectRatio, 
            Qt.FastTransformation
        )
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
                first_extraction = False
                if not self.base_data:
                    self.auto_load_base_data_from_csv()
                    # Update drop counter based on POINT_ID
                    self.drop_counter = self.get_next_drop_number_for_point()
                    first_extraction = True
                
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
                
                # Update queue label to show new drop count
                self.queue_label.setText(
                    f"Video {self.current_video_index + 1}/{len(self.video_queue)}: "
                    f"{os.path.basename(self.video_path)} (Next drop: {self.drop_counter})"
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
            
    def batch_extract(self):
        """Extract frames at specified intervals"""
        if not self.cap:
            return
            
        interval = self.frame_interval.value()
        
        # Confirm action
        reply = QMessageBox.question(
            self, "Batch Extract",
            f"Extract every {interval} frame(s)?\n"
            f"This will create approximately {self.total_frames // interval} images.",
            QMessageBox.Yes | QMessageBox.No
        )
        
        if reply == QMessageBox.No:
            return
            
        # Create output directory
        video_name = os.path.splitext(os.path.basename(self.video_path))[0]
        output_dir = os.path.join(os.path.dirname(self.video_path), f"{video_name}_batch_frames")
        os.makedirs(output_dir, exist_ok=True)
        
        # Extract frames
        saved_count = 0
        self.cap.set(cv2.CAP_PROP_POS_FRAMES, 0)
        
        for frame_num in range(0, self.total_frames, interval):
            self.cap.set(cv2.CAP_PROP_POS_FRAMES, frame_num)
            ret, frame = self.cap.read()
            
            if ret:
                output_path = os.path.join(output_dir, f"frame_{frame_num:06d}.jpg")
                cv2.imwrite(output_path, frame, [cv2.IMWRITE_JPEG_QUALITY, 95])
                saved_count += 1
                
        # Reset to original frame
        self.cap.set(cv2.CAP_PROP_POS_FRAMES, self.current_frame)
        
        QMessageBox.information(
            self, "Success", 
            f"Extracted {saved_count} frames to:\n{output_dir}"
        )
        
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
        
        # Auto-load base data from CSV when loading a new video
        self.video_path = video_path
        if self.base_data_csv:
            self.auto_load_base_data_from_csv()
        
        # Reset drop counter - check existing drops for this POINT_ID
        self.drop_counter = self.get_next_drop_number_for_point()
        
        video_name = os.path.splitext(os.path.basename(video_path))[0]
        
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
        self.extract_btn.setEnabled(True)
        self.batch_extract_btn.setEnabled(True)
        
        # Update queue label
        self.queue_label.setText(
            f"Video {self.current_video_index + 1}/{len(self.video_queue)}: "
            f"{os.path.basename(video_path)} (Next drop: {self.drop_counter})"
        )
        
        self.display_frame()
    
    def previous_video(self):
        """Load previous video from queue"""
        if not self.video_queue:
            return
        
        if self.is_playing:
            self.toggle_play()
        
        new_index = (self.current_video_index - 1) % len(self.video_queue)
        self.load_video_from_queue(new_index)
    
    def next_video(self):
        """Load next video from queue"""
        if not self.video_queue:
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
        for widget in self.data_fields.values():
            if isinstance(widget, QTextEdit):
                widget.clear()
            else:
                widget.clear()
    
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
        if not self.base_data:
            return
        
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
        """Get the next drop number for the current POINT_ID"""
        # Get POINT_ID from base_data
        point_id = self.base_data.get('POINT_ID', '') if self.base_data else ''
        
        if not point_id and self.video_path:
            # Try to extract POINT_ID from video filename (e.g., "ID001" from filename)
            video_name = os.path.basename(self.video_path)
            import re
            match = re.search(r'ID(\d+)', video_name, re.IGNORECASE)
            if match:
                point_id = match.group(1)  # Extract just the number part
        
        if not point_id:
            # Fallback to video-based naming if no POINT_ID
            video_name = os.path.splitext(os.path.basename(self.video_path))[0] if self.video_path else ''
            existing_drops = [
                f for f in os.listdir(self.drop_stills_dir)
                if f.startswith(video_name + "_drop") and f.endswith('.jpg')
            ] if os.path.exists(self.drop_stills_dir) else []
            
            if existing_drops:
                drop_numbers = []
                for f in existing_drops:
                    try:
                        num = int(f.replace(video_name + "_drop", "").replace(".jpg", ""))
                        drop_numbers.append(num)
                    except:
                        pass
                return max(drop_numbers) + 1 if drop_numbers else 1
            return 1
        
        # Check data_entries.csv for existing entries with same POINT_ID
        output_file = os.path.join(self.data_dir, "data_entries.csv")
        if not os.path.exists(output_file):
            return 1
        
        try:
            with open(output_file, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                max_drop = 0
                for row in reader:
                    if row.get('POINT_ID') == point_id:
                        drop_id = row.get('DROP_ID', '')
                        # Extract number from drop ID (e.g., "drop3" -> 3)
                        if drop_id.startswith('drop'):
                            try:
                                num = int(drop_id.replace('drop', ''))
                                max_drop = max(max_drop, num)
                            except:
                                pass
                return max_drop + 1
        except:
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
            
            # Load the first entry
            self.current_entry_index = 0
            self.load_entry_at_index(0)
            
            # Enable navigation buttons
            self.update_navigation_buttons()
            
            QMessageBox.information(
                self, "Success",
                f"Loaded {len(self.all_data_entries)} data entries.\n\n"
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
        
        self.unsaved_changes = False
        self.update_navigation_buttons()
    
    def update_navigation_buttons(self):
        """Update navigation button states and position label"""
        if not self.all_data_entries:
            self.prev_entry_btn.setEnabled(False)
            self.next_entry_btn.setEnabled(False)
            self.entry_position_label.setText("No entries loaded")
            return
        
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
        
        # Update the entry in memory
        for field_name, widget in self.data_fields.items():
            if isinstance(widget, QTextEdit):
                self.all_data_entries[self.current_entry_index][field_name] = widget.toPlainText().strip()
            else:
                self.all_data_entries[self.current_entry_index][field_name] = widget.text().strip()
        
        # Update DATE_TIME if needed
        entry = self.all_data_entries[self.current_entry_index]
        if entry.get('DATE') and entry.get('TIME'):
            entry['DATE_TIME'] = f"{entry['DATE']} {entry['TIME']}"
        
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
            self.current_entry_index = len(self.all_data_entries) - 1
            
            # Update navigation display
            self.update_navigation_buttons()
            
            # Prepare form for NEXT entry by repopulating base data and clearing observation fields
            self.populate_fields_from_base_data()
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
        from PyQt5.QtWidgets import QInputDialog
        
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
                    f"Video {self.current_video_index + 1}/{len(self.video_queue)}: "
                    f"{os.path.basename(self.video_path)} (Next drop: {self.drop_counter})"
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
    
    def closeEvent(self, event):
        """Clean up when closing"""
        if self.cap:
            self.cap.release()
        event.accept()


def main():
    app = QApplication(sys.argv)
    player = VideoPlayer()
    player.show()
    sys.exit(app.exec_())


if __name__ == "__main__":
    main()
