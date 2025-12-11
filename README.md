# Mapping and Drop Camera Processing Tools

A comprehensive toolkit for processing underwater drop camera videos, from initial file organization to data extraction and analysis. This repository contains two main processing steps designed to streamline marine/environmental video workflows.

## 🎯 Overview

This toolkit provides end-to-end processing for drop camera footage:

1. **Step 1**: Match GPS waypoints to video timestamps and rename files systematically
2. **Step 2**: Extract still frames from videos and perform structured data entry for benthic/habitat analysis

---

## 📦 Repository Structure

```
Mapping_and_Drop_camera_processing_tools/
│
├── Step1_video_renaming_point_matching/
│   ├── START_HERE.R                    # 👈 Quick start for video renaming
│   ├── video_renamer_app.R             # Interactive Shiny app
│   ├── README.md                       # Detailed Step 1 documentation
│   └── Videos/                         # Place your DJI videos here
│
└── Step2_video_processing_still_extract_data_entry/
    ├── TUTORIAL.md                     # Detailed Step 2 tutorial
    ├── drop_videos/                    # Renamed videos go here
    ├── drop_stills/                    # Extracted frames saved here
    ├── data/                           # Data entry templates & output
    └── Source_code/                    # Video player application code
```

---

## 🚀 Quick Start Guide

### Step 1: Video Renaming & Point Matching

**Purpose**: Match DJI camera videos to GPS waypoints and rename with standardized format.

**Requirements**:
- R (version 4.0+)
- DJI camera video files
- CSV file with GPS waypoint timestamps

**Quick Start**:
```r
# Navigate to Step1 folder
setwd("Step1_video_renaming_point_matching")

# Run the interactive setup
source("START_HERE.R")
```

The tool will:
- ✅ Install required R packages automatically
- ✅ Launch an interactive web interface
- ✅ Match videos to GPS points by timestamp
- ✅ Rename files: `Location_YYYYMMDD_ID###_HHMMSS.MP4`
- ✅ Handle timezone conversions
- ✅ Generate a matching log CSV

📖 **[Full Step 1 Documentation](Step1_video_renaming_point_matching/README.md)**

---

### Step 2: Video Processing & Data Entry

**Purpose**: Extract still frames from videos and perform structured habitat/benthic data entry.

**Requirements**:
- Python 3.8+
- Renamed video files from Step 1
- Data entry template CSV

**Quick Start (Run from Source)**:
```bash
# Navigate to Step2 folder
cd Step2_video_processing_still_extract_data_entry/Source_code

# Install dependencies
pip install -r requirements.txt

# Launch the video player
python video_player.py
```

**Alternative: Build Standalone Executable**:
```bash
# Install PyInstaller
pip install pyinstaller

# Build the .exe (output in dist/ folder)
python build_exe.py
```
> **Note**: The executable is not included in this repository due to its large size (~500MB-3GB). Build it locally using the instructions above.

# Install dependencies
pip install -r requirements.txt

# Launch the video player
python video_player.py
```

The tool provides:
- 🎬 Video playback with frame-by-frame control
- 📸 One-click still frame extraction
- 📝 Customizable data entry forms
- 💾 CSV export of all annotations
- 🔄 Edit and review previous entries
- 📊 Progress tracking across multiple videos

📖 **[Full Step 2 Tutorial](Step2_video_processing_still_extract_data_entry/TUTORIAL.md)**

---

## 🔧 Typical Workflow

```
1. Collect field data
   ├── GPS waypoints with timestamps (CSV)
   └── DJI camera video files
            ↓
2. Run Step 1: Video Renaming
   ├── Match videos to GPS points
   ├── Rename with standardized format
   └── Export to drop_videos folder
            ↓
3. Run Step 2: Video Analysis
   ├── Load renamed videos
   ├── Extract still frames at key moments
   ├── Enter habitat/benthic data
   └── Export complete dataset (CSV)
            ↓
4. Analysis Ready!
   └── Clean dataset with matched stills
```

---

## 💡 Key Features

### Step 1 Features
- Automatic timestamp matching with tolerance settings
- Timezone conversion (UTC ↔ local time)
- Preview mode before committing changes
- Batch processing for multiple videos
- Sequential video numbering for same location
- File browser integration for easy path selection

### Step 2 Features
- Custom data entry templates (define your own fields)
- Automatic POINT_ID extraction from filenames
- Pre-populated forms from base CSV
- Quality validation and auto-calculations
- Frame-by-frame video navigation
- Keyboard shortcuts for efficient data entry
- Auto-save and export functionality

---

## 📋 Prerequisites

### For Step 1 (R Tools)
- **R** (4.0 or higher): [Download R](https://cran.r-project.org/)
- **RStudio** (optional but recommended): [Download RStudio](https://posit.co/download/rstudio-desktop/)

Required R packages (auto-installed by START_HERE.R):
- `shiny`, `shinythemes`, `shinyFiles`
- `lubridate`, `dplyr`, `readr`

### For Step 2 (Python Tools)
- **Python** 3.8+: [Download Python](https://www.python.org/downloads/)

Required Python packages:
```bash
pip install -r Step2_video_processing_still_extract_data_entry/Source_code/requirements.txt
```

Main dependencies: `opencv-python`, `pandas`, `pillow`, `PyQt5`, `numpy`

**Optional** - To build standalone executable:
```bash
pip install pyinstaller
```

---

## 📝 Documentation

- **[Step 1 README](Step1_video_renaming_point_matching/README.md)** - Complete guide for video renaming
- **[Step 2 TUTORIAL](Step2_video_processing_still_extract_data_entry/TUTORIAL.md)** - Detailed walkthrough for video analysis
- **[Video Player README](Step2_video_processing_still_extract_data_entry/Source_code/README.md)** - Technical details for the player app

---

## 🤝 Contributing

Contributions are welcome! If you encounter issues or have suggestions:

1. Check existing documentation first
2. Open an issue describing the problem/feature
3. Submit pull requests with clear descriptions

---

## 📄 License

This project is part of the NESP Marine Biodiversity Hub research program.

---

## 👥 Support

For questions or issues:
- Review the detailed documentation in each step folder
- Check the tutorial files for troubleshooting tips
- Open a GitHub issue for bug reports or feature requests

---

## 🔄 Version History

- **v1.0.0** - Initial release with complete two-step workflow
  - Video renaming and GPS matching (R Shiny)
  - Video analysis and data entry tool (Python)

---

## ⚡ Tips for Success

1. **Always run Step 1 before Step 2** - Proper file naming is crucial
2. **Use the data entry template** - Define your fields before starting
3. **Keep a backup** - Original videos should be preserved separately
4. **Test with one video first** - Verify your workflow before batch processing
5. **Document your field codes** - Maintain a reference for substrate types, etc.

---

**Ready to get started?** Head to [Step 1](Step1_video_renaming_point_matching/) to begin processing your drop camera videos! 🎥📊
