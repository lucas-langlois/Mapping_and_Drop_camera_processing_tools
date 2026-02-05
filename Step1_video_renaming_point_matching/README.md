# DJI Video Renamer

A tool to automatically match and rename DJI camera videos based on timestamps from a CSV file, with support for timezone conversions.

## 🚀 Quick Start

**New users - just run this:**
```r
source("START_HERE.R")
```

This interactive script will guide you through installation and launch the app!

---

## 📋 What This Tool Does

- ✅ Matches DJI video files to CSV timestamps (finds closest match)
- ✅ Renames videos with standardized format: `Location_YYYYMMDD_ID###_HHMMSS.MP4`
- ✅ Handles timezone conversion (e.g., UTC in CSV → IST for camera)
- ✅ Supports multiple videos at same location (sequential recordings)
- ✅ Interactive web interface (Shiny app)
- ✅ Preview mode (see matches before renaming)
- ✅ File browser for easy path selection
- ✅ Export matching results as CSV log
- ✅ **Auto-generates output CSV with all survey data + matched video info**
- ✅ Batch processing for multiple videos

---

## 📁 Project Files

### 🎯 Main Files (Use These!)

| File | Purpose |
|------|---------|
| **`START_HERE.R`** | 👈 **START HERE!** Interactive setup & launch |
| `video_renamer_app.R` | Main Shiny web application |
| `launch_app.R` | App launcher (checks packages & runs app) |
| `match_and_rename_videos_fun.R` | Core matching & renaming function |
| `install_packages.R` | Automatic package installer |

### 📂 Folders

| Folder | Purpose |
|--------|---------|
| `Videos/` | DJI video files |

---

## 🎓 Setup & Installation

### First Time Setup (Recommended)

1. Open R or RStudio
2. Set working directory to this folder
3. Run: `source("START_HERE.R")`
4. Follow the prompts to install packages and launch

The interactive script will:
- ✓ Check if packages are installed
- ✓ Offer to install missing packages
- ✓ Launch the app when ready

### Alternative Setup Methods

**Option 1: Semi-Automatic**
```r
# Install packages first
source("install_packages.R")

# Then launch
source("launch_app.R")
```

**Option 2: Manual Installation**
```r
# Install packages manually
install.packages(c("shiny", "DT", "lubridate", "shinyFiles", "fs"))

# Launch the app
source("launch_app.R")
```

**Option 3: Direct Launch (Advanced)**
```r
library(shiny)
runApp("video_renamer_app.R")
```

### Required R Packages

All of these will be installed automatically if you use the setup scripts:

| Package | Purpose |
|---------|---------|
| `shiny` | Web application framework |
| `DT` | Interactive data tables |
| `lubridate` | Date/time handling |
| `shinyFiles` | File browser dialog |
| `fs` | Cross-platform file operations |

---

## 🎯 How to Use

### Regular Use (After Installation)

Just run:
```r
source("launch_app.R")
```

### In the App

1. **Set Paths**
   - Enter the directory containing your DJI video files (or click "Browse..." to select)
   - Enter the path to your CSV file with timestamps (or click "Browse..." to select)

2. **Configure Naming**
   - Set the location name (e.g., "Chilika")
   - Choose ID prefix (e.g., "ID")
   - Set number of digits for zero-padding (e.g., 3 for ID001)

3. **Configure CSV Settings**
   - Enter the column name for date/time (e.g., "Date.Time")
   - Enter the column name for Object ID (e.g., "OBJECTID")
   - Set the time format matching your CSV
   - Select CSV timezone (e.g., "UTC")
   - Select camera timezone (e.g., "Australia/Brisbane")

4. **Set Matching Parameters**
   - Set maximum time difference in seconds (default: 180 = 3 minutes)

5. **Preview Matches**
   - Click "Preview Matches" to see what will be renamed
   - Review results in the Results tab
   - Check for any warnings or errors

6. **Rename Videos**
   - If everything looks good, click "Rename Videos"
   - Confirm the action
   - Videos will be renamed according to the matches
   - **An output CSV will be automatically saved with all your data + video matches**

7. **Download Log**
   - Click "Download Log" to save the matching results as CSV

### App Tabs Explained

| Tab | Purpose |
|-----|---------|
| **Instructions** | Detailed usage guide, time format examples, timezone info |
| **Results** | Summary statistics, detailed matching results table |
| **CSV Preview** | Load and preview your CSV data (first 100 rows) |
| **Video Files** | Scan and list DJI videos in directory |

---

## 📤 Output Files

When you rename videos (not in preview mode), the app generates **two** files:

### 1. Matching Log (Manual Download)
- **Downloaded via**: "Download Log" button
- **Contains**: Video matching details (original filename, video timestamp, matched OBJECTID, new filename, status, etc.)
- **Purpose**: Track the renaming operation itself

### 2. **Output CSV with Full Survey Data** (Automatic)
- **Location**: Automatically saved in your video directory
- **Filename**: `video_matching_output_YYYYMMDD_HHMMSS.csv`
- **Contains**: 
  - ✅ **All original columns from your imported CSV** (OBJECTID, Date.Time, Latitude, Longitude, etc.)
  - ✅ `matched_video_filename` - the new renamed video filename
  - ✅ `video_datetime` - the datetime extracted from the video file
  - ✅ `time_difference_sec` - time difference between CSV and video timestamps
- **Purpose**: Complete dataset linking your survey data with matched videos
- **Note**: Only includes successfully matched/renamed videos

**Example Output CSV:**

| OBJECTID | Date.Time | Latitude | Longitude | Other_Data | matched_video_filename | video_datetime | time_difference_sec |
|----------|-----------|----------|-----------|------------|------------------------|----------------|---------------------|
| 1 | 11/18/2025 06:51:51 | -17.234 | 139.567 | ... | Burketown_20251118_ID001_122107.MP4 | 2025-11-18 12:21:07 | 45.2 |
| 2 | 11/18/2025 07:15:32 | -17.235 | 139.568 | ... | Burketown_20251118_ID002_124532.MP4 | 2025-11-18 12:45:32 | 12.8 |

This output CSV is ideal for importing into GIS software, databases, or further analysis!

---

## 📊 Examples

### Input/Output Example

**Input:**
- Video: `DJI_20251118122107_0024_D.MP4`
- CSV: Object ID = 1, Timestamp = 11/18/2025 06:51:51 (UTC)
- Location: "Burketown"

**Output:**
- Renamed: `Burketown_20251118_ID001_122107.MP4`

Multiple videos at the same location are differentiated by their time component (HHMMSS).

### Time Format Guide

Common time formats:
- `%m/%d/%Y %H:%M:%S` → 11/18/2025 14:30:45
- `%Y-%m-%d %H:%M:%S` → 2025-11-18 14:30:45
- `%d/%m/%Y %H:%M:%S` → 18/11/2025 14:30:45

---

## 🌍 Timezone Support

The tool automatically converts between timezones:
- **CSV timezone**: The timezone your data is recorded in (commonly UTC)
- **Camera timezone**: The timezone your DJI camera uses (local time)

### Common Timezones

| Region | Timezone Code | Description |
|--------|---------------|-------------|
| 🌐 Universal | `UTC` | Coordinated Universal Time |
| 🇮🇳 India | `Asia/Kolkata` | IST (UTC+5:30) |
| 🇦🇺 Australia | `Australia/Sydney` | Sydney/Melbourne (UTC+10/+11 with DST) |
| 🇦🇺 Australia | `Australia/Brisbane` | Brisbane (UTC+10, no DST) |
| 🇦🇺 Australia | `Australia/Perth` | Perth (UTC+8) |
| 🇦🇺 Australia | `Australia/Adelaide` | Adelaide (UTC+9:30/+10:30 with DST) |
| 🇦🇺 Australia | `Australia/Darwin` | Darwin (UTC+9:30, no DST) |
| 🇦🇺 Australia | `Australia/Hobart` | Hobart (UTC+10/+11 with DST) |
| 🇺🇸 USA | `America/New_York` | Eastern Time (UTC-5/-4) |
| 🇬🇧 UK | `Europe/London` | British Time (UTC+0/+1) |

---

## 🛠️ Technical Details

### Video Format Requirements
Expected DJI format: `DJI_YYYYMMDDHHMMSS_####_D.MP4`

### CSV Requirements
- Must have a date/time column (any format supported)
- Must have an Object ID column (integer)
- Can be in any timezone (will be converted)

### System Requirements
- **R Version**: 3.5.0 or higher (4.0.0+ recommended)
- **Operating System**: Windows, macOS, or Linux
- **Internet**: Required for initial package installation only
- **RAM**: 2GB minimum (4GB+ recommended for large video collections)

---

## 🛡️ Safety Features

- **Dry Run by Default**: Preview mode shows matches without renaming
- **Confirmation Dialog**: Warns before actual renaming
- **Status Tracking**: Clear status indicators for each video
- **Log Export**: Save detailed results for record-keeping
- **No Overwriting**: Won't rename if target filename already exists
- **Local Processing**: App runs locally on your computer, files never uploaded

---

## 🔧 Troubleshooting

### Package Installation Issues

**"Package installation failed"**
```r
# Try installing packages manually one by one:
install.packages("shiny")
install.packages("DT")
install.packages("lubridate")
install.packages("shinyFiles")
install.packages("fs")
```

**"Cannot find function"**
```r
# Make sure all packages loaded successfully:
library(shiny)
library(DT)
library(lubridate)
library(shinyFiles)
library(fs)
```

### App Launch Issues

**"File not found"**
```r
# Check current directory
getwd()

# Set to project directory if needed
setwd("path/to/project")
```

**"App won't open in browser"**
```r
# Try launching with explicit browser:
shiny::runApp("video_renamer_app.R", launch.browser = TRUE)
```

### Video Matching Issues

**"No match within time threshold"**
- Check if video and CSV dates align
- Verify timezone settings are correct
- Increase max_time_diff if videos were recorded slightly outside the window

**"Failed to parse timestamp"**
- Verify time_format matches your CSV format exactly
- Check for missing or malformed dates in CSV

**"CSV file does not exist"**
- Check the file path is correct
- Use forward slashes (/) or double backslashes (\\\\) in Windows paths

**"No DJI video files found"**
- Ensure videos follow DJI naming: `DJI_YYYYMMDDHHMMSS_####_D.MP4`
- Check the video directory path is correct

---

## ⚠️ Important Notes

- Always use **Preview mode first** to verify matches
- The app runs **locally** on your computer (not online)
- Your files stay on **your computer** (nothing uploaded)
- **Timezone settings** must match your data for accurate matching
- **Backup your videos** before first use (safety first!)
- Test with a few videos first before processing large batches
- Check your **video directory** for the output CSV after renaming

---

## 📞 Getting Help

1. Check the **Instructions tab** in the app
2. Review the **Troubleshooting** section above
3. Verify your timezone settings match your data
4. Verify your time format matches your CSV
5. Check that column names are spelled correctly (case-sensitive)

---

## 🗂️ Archive

Old command-line scripts are in the `archive/` folder. The Shiny app is now the recommended way to use this tool.

---

**Made for marine researchers working with DJI drone footage** 🌊📹

