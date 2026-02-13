# DJI Video Renamer

A tool to automatically match and rename DJI camera videos based on timestamps from a CSV file, with support for timezone conversions, manual editing, and revert functionality.

## 🚀 Quick Start

**New users - just run this:**
```r
source("START_HERE.R")
```

This interactive script will guide you through installation and launch the app!

---

## 📋 What This Tool Does

- ✅ Matches DJI video files to CSV timestamps (finds closest match)
- ✅ Renames videos with standardized format: `Location_YYYYMMDD_HHMMSS_ID###.MP4`
- ✅ Handles timezone conversion (e.g., UTC in CSV → IST for camera)
- ✅ Supports multiple videos at same location (sequential recordings)
- ✅ Interactive web interface (Shiny app)
- ✅ Preview mode (see matches before renaming)
- ✅ File browser for easy path selection
- ✅ Export matching results as CSV log
- ✅ **Auto-generates output CSV with all survey data + matched video info**
- ✅ **Manual editing of matches** - Double-click to change any match
- ✅ **Video duration warnings** - Flags videos shorter than 30 seconds
- ✅ **Unmatched mapping point tracking** - See which CSV entries have no video
- ✅ **Revert renaming** - Restore original DJI filenames anytime
- ✅ **Dynamic column selection** - Auto-populated dropdowns for CSV columns
- ✅ **Auto-detect date/time format** - Automatically detects format from your data
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

| Package | Purpose | Required |
|---------|---------|----------|
| `shiny` | Web application framework | ✅ Yes |
| `DT` | Interactive data tables | ✅ Yes |
| `lubridate` | Date/time handling | ✅ Yes |
| `shinyFiles` | File browser dialog | ✅ Yes |
| `fs` | Cross-platform file operations | ✅ Yes |
| `av` | Video duration checking | ⚠️ Optional |

**Note**: The `av` package is optional. If installed, the app will check video durations and warn you about videos shorter than 30 seconds. Install with: `install.packages("av")`

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
   - Select the date/time column from the dropdown (auto-populated from your CSV)
   - Select the mapping point ID column from the dropdown (e.g., "OBJECTID")
   - Date/time format is auto-detected, or select from the dropdown if needed
   - Select CSV timezone (e.g., "UTC")
   - Select camera timezone (e.g., "Australia/Brisbane")

4. **Set Matching Parameters**
   - Set maximum time difference in seconds (default: 180 = 3 minutes)

5. **Preview Matches**
   - Click "Preview Matches" to see what will be renamed
   - Review results in the Results tab
   - Check for any warnings or errors
   - Review unmatched mapping point IDs (CSV entries without matching videos)
   - Check for video duration warnings (videos < 30 seconds)

6. **Manual Editing (Optional)**
   - Go to "Edit Matches" tab
   - Click "Load Current Matches"
   - Double-click any mapping point ID (yellow column) to edit
   - Enter a different ID or leave blank to unmatch
   - New filename updates automatically
   - Use "Rename Videos (Edited Matches)" when ready

7. **Rename Videos**
   - For automatic matches: Click "Rename Videos (Auto-Match)"
   - For edited matches: Click "Rename Videos (Edited Matches)"
   - Confirm the action
   - Videos will be renamed according to the matches
   - **An output CSV will be automatically saved with all your data + video matches**
   - Original DJI filenames are stored in the CSV for revert capability

8. **Revert Renaming (Optional)**
   - Go to "Revert Renaming" tab
   - Select the output CSV file from a previous renaming
   - Click "Load Renamed Videos"
   - Review what will be reverted
   - Click "Revert to Original Filenames" to restore DJI names

9. **Download Log**
   - Click "Download Log" to save the matching results as CSV

### App Tabs Explained

| Tab | Purpose |
|-----|---------|
| **Instructions** | Detailed usage guide, time format examples, timezone info |
| **Results** | Summary statistics, detailed results table, unmatched mapping point IDs |
| **Edit Matches** | Manually edit video-to-mapping point matches, double-click to change |
| **Revert Renaming** | Restore original DJI filenames from a previous renaming |
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
- **Filename**: `video_matching_output_YYYYMMDD_HHMMSS.csv` (or `_edited_` for manual edits)
- **Contains**: 
  - ✅ **All original columns from your imported CSV** (OBJECTID, Date.Time, Latitude, Longitude, etc.)
  - ✅ `original_filename` - the original DJI video filename (for revert functionality)
  - ✅ `matched_video_filename` - the new renamed video filename
  - ✅ `video_datetime` - the datetime extracted from the video file
  - ✅ `time_difference_sec` - time difference between CSV and video timestamps
- **Purpose**: Complete dataset linking your survey data with matched videos
- **Note**: Only includes successfully matched/renamed videos
- **Revert**: Use this CSV file in the "Revert Renaming" tab to restore original names

**Example Output CSV:**

| OBJECTID | Date.Time | Latitude | Longitude | original_filename | matched_video_filename | video_datetime | time_difference_sec |
|----------|-----------|----------|-----------|-------------------|------------------------|----------------|---------------------|
| 1 | 11/18/2025 06:51:51 | -17.234 | 139.567 | DJI_20251118122107_0024_D.MP4 | Burketown_20251118_122107_ID001.MP4 | 2025-11-18 12:21:07 | 45.2 |
| 2 | 11/18/2025 07:15:32 | -17.235 | 139.568 | DJI_20251118124532_0025_D.MP4 | Burketown_20251118_124532_ID002.MP4 | 2025-11-18 12:45:32 | 12.8 |

This output CSV is ideal for importing into GIS software, databases, or further analysis!

---

## 📊 Examples

### Input/Output Example

**Input:**
- Video: `DJI_20251118122107_0024_D.MP4`
- CSV: Object ID = 1, Timestamp = 11/18/2025 06:51:51 (UTC)
- Location: "Burketown"

**Output:**
- Renamed: `Burketown_20251118_122107_ID001.MP4`
- Format: `Location_YYYYMMDD_HHMMSS_ID###.MP4`

Multiple videos at the same location are differentiated by their time component (HHMMSS).

### Manual Editing Example

**Changing a match:**
1. Go to "Edit Matches" tab
2. Double-click the matched_objectid cell
3. Change from "5" to "7" (for example)
4. New filename automatically updates to use ID007
5. Click "Rename Videos (Edited Matches)"

**Excluding bad/unusable videos:**
1. Go to "Edit Matches" tab
2. Double-click the matched_objectid cell for a bad video
3. Type `BAD`, `SKIP`, `EXCLUDE`, or `UNUSABLE` (or leave blank)
4. Status changes to "Excluded - Bad/unusable video"
5. This video will be skipped during renaming

### Revert Example

To restore original DJI names:
1. Locate the output CSV: `video_matching_output_20260213_143025.csv`
2. Go to "Revert Renaming" tab
3. Browse and select the CSV file
4. Click "Load Renamed Videos"
5. Review the files to be reverted
6. Click "Revert to Original Filenames"
7. Videos restored: `Burketown_20251118_122107_ID001.MP4` → `DJI_20251118122107_0024_D.MP4`

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

## ✨ New Features

### 🎯 Manual Match Editing
- **Double-click to edit** any matched mapping point ID
- **Auto-updates** new filename as you edit
- **Validation** - only accepts mapping point IDs from your CSV
- **Color-coded** - Yellow = editable, Blue = auto-updates
- **Flexible** - Unmatch videos by leaving mapping point ID blank
- **Exclude bad videos** - Type `SKIP`, `BAD`, `EXCLUDE`, or `UNUSABLE` to mark videos you don't want to rename (e.g., corrupted/unusable footage)
- **CSV reference table** - See all CSV points with converted camera times for easy comparison

### ⏱️ Video Duration Warnings
- **Automatic checking** of video duration (requires `av` package)
- **Flags videos < 30 seconds** for review
- **Yellow highlighting** in results table
- **Summary count** of short videos

### 🎯 Dynamic Column Selection & Auto-Detection
- **Auto-populated dropdowns** - CSV columns appear automatically in dropdowns
- **Smart pre-selection** - Likely columns are pre-selected based on common names
- **Date/time format auto-detection** - Automatically detects from 15 common formats
- **No typing errors** - Select instead of typing column names
- **CSV reference table** - View all CSV data with timezone-converted times while editing matches

### 📋 Unmatched Mapping Point Tracking
- **Identifies CSV entries** without matching videos
- **Separate table** showing unmatched mapping point IDs with timestamps
- **Downloadable** for investigation
- **Summary count** in results

### ↩️ Revert Renaming
- **Restore original DJI filenames** anytime
- **Uses output CSV** to track original names
- **Safe operation** - warns if original filename already exists
- **Status tracking** - shows what was reverted successfully

---

## 🛠️ Technical Details

### Video Format Requirements
Expected DJI format: `DJI_YYYYMMDDHHMMSS_####_D.MP4`

### CSV Requirements
- Must have a date/time column (any format supported - auto-detected)
- Must have a mapping point ID column (integer or text)
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

### Manual Editing Issues

**"Mapping point ID not found in CSV"**
- Verify you're entering an ID that exists in your CSV
- Check for typos or extra spaces
- IDs are case-sensitive if they contain letters
- Use the CSV reference table to see all available IDs

**"Can't edit matched mapping point ID column"**
- Make sure you've clicked "Load Current Matches" first
- Double-click the cell (not single-click)
- Only the matched_mappingid column (yellow) is editable

**"Dropdowns not populating"**
- Wait a moment after loading the CSV file
- Check that the CSV file path is correct and file exists
- Verify CSV is properly formatted with headers
- If dropdowns still don't appear, check the R console for errors

### Revert Issues

**"Original filename already exists"**
- Another file with the original DJI name is in the directory
- Check for duplicate videos
- Manually rename/move the conflicting file first

**"CSV must contain 'original_filename' column"**
- The CSV you selected wasn't created by this app's renaming process
- Use only the output CSV files generated after renaming
- File must be named like: `video_matching_output_*.csv`

### Duration Warning Issues

**"Duration warnings not showing"**
- Install the `av` package: `install.packages("av")`
- Restart the app after installation
- If still not working, duration checking will be skipped (app still works)

---

## ⚠️ Important Notes

- Always use **Preview mode first** to verify matches
- **Review unmatched mapping point IDs** - these CSV entries have no matching videos
- **Check duration warnings** - videos <30 sec might be incomplete recordings
- The app runs **locally** on your computer (not online)
- Your files stay on **your computer** (nothing uploaded)
- **Timezone settings** must match your data for accurate matching
- **Backup your videos** before first use (safety first!)
- **Output CSV files contain original filenames** - keep these for revert capability
- Test with a few videos first before processing large batches
- Check your **video directory** for the output CSV after renaming
- **Manual editing** allows you to correct any automatic matching errors
- **Dynamic dropdowns** eliminate typing errors for column names
- **Auto-detection** helps identify the correct date/time format automatically

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

