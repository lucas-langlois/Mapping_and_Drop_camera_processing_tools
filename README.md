# Mapping and Drop Camera Processing Tools

A comprehensive toolkit for processing underwater drop camera videos, from initial file organization to data extraction and analysis. This repository contains two main processing steps designed to streamline marine/environmental video workflows.

## 🎯 Overview

This toolkit provides end-to-end processing for drop camera footage:

0. **Step 0**: Match grab-sample photos to survey CSV rows and rename with standardised filenames
1. **Step 1**: Match GPS waypoints to video timestamps and rename files systematically
2. **Step 2**: Extract still frames from videos and perform structured data entry for benthic/habitat analysis

---

## 📦 Repository Structure

```
Mapping_and_Drop_camera_processing_tools/
│
├── Step0_grab_photo_mathing/
│   ├── START_HERE.R                    # 👈 Quick start for grab photo matching
│   ├── link_photos_to_csv_app.R        # Interactive Shiny app
│   ├── install_packages.R              # R package installer
│   ├── launch_app.R                    # App launcher
│   ├── README.md                       # Detailed Step 0 documentation
│   └── Grab_photos/                    # Place your grab photos here
│
├── Step1_video_renaming_point_matching/
│   ├── START_HERE.R                    # 👈 Quick start for video renaming
│   ├── video_renamer_app.R             # Interactive Shiny app
│   ├── match_and_rename_videos_fun.R   # Core matching logic
│   ├── install_packages.R              # R package installer
│   ├── launch_app.R                    # App launcher
│   ├── README.md                       # Detailed Step 1 documentation
│   └── Videos/                         # Place your DJI videos here
│
└── Step2_video_processing_still_extract_data_entry/
    ├── video_player.py                 # 👈 Main application source
    ├── build_exe.py                    # Build script (produces dist/drop_cam_analysis_app.exe)
    ├── requirements.txt                # Python dependencies
    ├── README.md                       # Detailed Step 2 documentation
    ├── TUTORIAL.md                     # Step-by-step tutorial
    ├── dist/
    │   └── drop_cam_analysis_app.exe   # ✅ Pre-built Windows executable (Git LFS)
    ├── drop_videos/                    # Place renamed videos here
    ├── drop_stills/                    # Extracted still frames saved here
    ├── grab_photos/                    # Grab photos for no-video points
    ├── projects/                       # Saved project files
    └── data/
        └── data_entry_templates/       # CSV & JSON data entry templates
```

---

## 🚀 Quick Start Guide

### Step 0: Grab Photo Matching

**Purpose**: Link grab-sample photos to survey CSV rows, rename photos with standardised filenames, and optionally correct bad GPS coordinates embedded in the photo files.

**Requirements**:
- R (version 4.0+)
- JPEG grab photos
- CSV file with survey GPS points and timestamps

**Quick Start**:
```r
# Navigate to Step0 folder
setwd("Step0_grab_photo_mathing")

# Run the interactive setup
source("START_HERE.R")
```

The tool will:
- ✅ Install required R packages automatically
- ✅ Read GPS + timestamp EXIF data directly from JPEGs (no ExifTool needed)
- ✅ Match photos to CSV rows by GPS distance + timestamp
- ✅ Fall back to time-only matching for cameras with bad GPS (e.g. reports 0,0)
- ✅ Display an interactive map to visually verify all matches
- ✅ Rename photos: `{Location}_{POINT_ID}_{Date}_GRAB_{N}.jpg`
- ✅ Optionally overwrite bad GPS in renamed photos with correct CSV coordinates
- ✅ Export matched CSV with `GRAB_FILENAME`, `GRAB_DISTANCE_M`, `GRAB_MATCH_METHOD`, `GRAB_TIME_DIFF_S` columns

📖 **[Full Step 0 Documentation](Step0_grab_photo_mathing/README.md)**

---

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

**Option 1: Use the Pre-Built Executable (Recommended)**:

The standalone Windows app is included in the repository via Git LFS:
```
Step2_video_processing_still_extract_data_entry/dist/drop_cam_analysis_app.exe
```
Just download and double-click — no Python required.

**Option 2: Run from Source**:
```bash
# Navigate to Step2 folder
cd Step2_video_processing_still_extract_data_entry

# Install dependencies
pip install -r requirements.txt

# Launch the video player
python video_player.py
```

**Option 3: Rebuild the Executable**:
```bash
# Navigate to Step2 folder
cd Step2_video_processing_still_extract_data_entry

# Build the .exe (output in dist/drop_cam_analysis_app.exe)
python build_exe.py
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
   ├── DJI camera video files
   └── Grab sample photos (JPEG)
            ↓
2. Run Step 0: Grab Photo Matching  [R]
   ├── Match grab photos to CSV survey points
   ├── Rename photos with standardised format
   └── Export updated CSV with GRAB_FILENAME column
            ↓
3. Run Step 1: Video Renaming  [R]
   ├── Match videos to GPS points
   ├── Rename with standardized format
   └── Export to drop_videos folder
            ↓
4. Run Step 2: Video Analysis  [Python]
   ├── Load renamed videos (and grab photos)
   ├── Extract still frames at key moments
   ├── Enter habitat/benthic data
   └── Export complete dataset (CSV)
            ↓
5. Analysis Ready!
   └── Clean dataset with matched stills & grab photos
```

---

## 💡 Key Features

### Step 0 Features
- EXIF GPS + timestamp matching (pure R, no ExifTool)
- Time-only fallback for cameras with unreliable GPS
- Filename POINT_ID fallback as last resort
- Interactive map to verify all photo matches
- Diagnostic table for unmatched photos
- GPS coordinate correction written into renamed photos
- Semicolon-separated multi-photo support per point

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
- Grab-only mode for points with photos but no video
- Inline grab photo viewer with multi-photo navigation
- Keyboard shortcuts for efficient data entry
- Auto-save and export functionality

---

## 📋 Prerequisites

### For Step 0 (R Tools)
- **R** (4.0 or higher): [Download R](https://cran.r-project.org/)
- **RStudio** (optional but recommended): [Download RStudio](https://posit.co/download/rstudio-desktop/)

Required R packages (auto-installed by START_HERE.R):
- `shiny`, `shinydashboard`, `DT`, `shinyFiles`
- `leaflet`, `shinyjs`, `lubridate`, `dplyr`, `fs`

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

- **[Step 0 README](Step0_grab_photo_mathing/README.md)** - Complete guide for grab photo matching
- **[Step 1 README](Step1_video_renaming_point_matching/README.md)** - Complete guide for video renaming
- **[Step 2 README](Step2_video_processing_still_extract_data_entry/README.md)** - Complete guide for video analysis and data entry
- **[Step 2 TUTORIAL](Step2_video_processing_still_extract_data_entry/TUTORIAL.md)** - Detailed walkthrough for video analysis

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
