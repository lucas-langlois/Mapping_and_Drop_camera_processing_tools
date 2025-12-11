# Drop Cam Video Analysis - Detailed Tutorial

This tutorial will guide you through the complete workflow of using the Drop Cam Video Analysis tool for marine/environmental video annotation.

## Table of Contents
1. [Preparing Your Files](#preparing-your-files)
2. [First Launch Setup](#first-launch-setup)
3. [Loading Videos](#loading-videos)
4. [Extracting Stills and Entering Data](#extracting-stills-and-entering-data)
5. [Navigating and Editing Entries](#navigating-and-editing-entries)
6. [Tips and Best Practices](#tips-and-best-practices)

---

## Preparing Your Files

### Step 1: Organize Your Videos

1. Create the `drop_videos` folder if it doesn't exist (the app will create it automatically on first run)
2. Copy all your drop camera videos into this folder
3. Ensure videos are named consistently (e.g., `Wuthathi_Subtidal_20251127_ID001_092219.MP4`)
   - Include an ID code like `ID001`, `ID002`, etc. if you want automatic POINT_ID extraction
   - This helps the system match videos to your metadata

**Example:**
```
drop_videos/
├── Wuthathi_Subtidal_20251127_ID001_092219.MP4
├── Wuthathi_Subtidal_20251127_ID001_092230.MP4  (second video for same point)
├── Wuthathi_Subtidal_20251127_ID002_092504.MP4
└── Wuthathi_Subtidal_20251127_ID003_093033.MP4
```

### Step 2: Create Your Data Entry Template

The template CSV defines what fields appear in your data entry form.

1. Open Excel or a text editor
2. Create a CSV with your desired column headers in the first row
3. Save as `data_entry_template.csv` in the `data/` folder

**Example Template:**
```csv
POINT_ID,DROP_ID,YEAR,DATE,TIME,DATE_TIME,GPS_MARK,LATITUDE,LONGITUDE,LOCATION,FILENAME,MODE,BOAT_PER,CAMERA,SUBSTRATE,DEPTH,SG_PRESENT,SG_COVER,CR,CS,HO,HD,HS,HU,SI,EA,TH,ZC,EPI_COVER,AL_COVER,AL_CAL,AL_ENC,AL_FIL,AL_MAC,AL_TUR,HC_COVER,HC_BRA,HC_DIG,HC_ENC,HC_COL,HC_FOL,HC_MAS,HC_SOL,HC_TAB,SC_COVER,SPONGE,WHIP,OTHER_COVER,OPEN,TOT_COVER,TOT_COVER_CAT_CHECK,COMMENTS
```

**Pro Tip:** Include only the fields you actually need. The form will display every column you define.

### Step 3: Create Base CSV (Optional but Recommended)

The base CSV contains location and metadata for each video. This saves you from re-entering the same information.

1. Create a CSV with one row per video
2. Include these key columns:
   - `POINT_ID` - Identifier for the sampling point
   - `VIDEO_FILENAME` - Exact filename of the video (e.g., `Wuthathi_Subtidal_20251127_ID001_092219.MP4`)
   - `VIDEO_TIMESTAMP` - Date and time in format: `DD/MM/YYYY HH:MM`
   - `LATITUDE` - GPS latitude
   - `LONGITUDE` - GPS longitude
   - `DEPTH` - Depth measurement
   - Any other fields that are the same for all observations from that video

**Example Base CSV:**
```csv
POINT_ID,GPS_DATETIME,VIDEO_TIMESTAMP,VIDEO_FILENAME,LATITUDE,LONGITUDE,DEPTH,LOCATION,MODE,CAMERA
1,27/11/2025 9:19,27/11/2025 9:22,Wuthathi_Subtidal_20251127_ID001_092219.MP4,143.134413,-11.90676302,15m,Wuthathi Subtidal,drop-cam,GoPro Hero 10
1,27/11/2025 9:22,27/11/2025 9:23,Wuthathi_Subtidal_20251127_ID001_092230.MP4,143.134413,-11.90676302,15m,Wuthathi Subtidal,drop-cam,GoPro Hero 10
2,27/11/2025 9:25,27/11/2025 9:25,Wuthathi_Subtidal_20251127_ID002_092504.MP4,143.132552,-11.90740599,18m,Wuthathi Subtidal,drop-cam,GoPro Hero 10
```

3. Save as `base_data.csv` (or any name you prefer) in the `data/` folder

---

## First Launch Setup

### Step 1: Launch the Application

Open PowerShell in the project directory and run:
```powershell
python video_player.py
```

### Step 2: Load Data Entry Template

1. A dialog appears: **"Load Data Entry Template"**
2. Click **OK**
3. Navigate to your `data/` folder
4. Select your template CSV (e.g., `data_entry_template.csv`)
5. Click **Open**

The application will read the column headers and create form fields for each one.

### Step 3: Load Base CSV (Optional)

1. A second dialog appears: **"Load Base CSV (Optional)"**
2. If you have a base CSV with location data:
   - Click **Yes**
   - Navigate to your `data/` folder
   - Select your base CSV (e.g., `base_data.csv`)
   - Click **Open**
   - You'll see a confirmation: "Loaded X rows from base CSV"
3. If you don't have base data (you'll enter everything manually):
   - Click **No**

The application window now opens with the video player on the left and data entry form on the right.

---

## Loading Videos

### Step 1: Load Video Queue

1. Click the **"Load Videos from drop_videos/"** button
2. The application scans the `drop_videos/` folder
3. Confirmation message shows: "Loaded X video(s) from drop_videos/"
4. The status bar shows: "Video 1/X: [filename] (Next drop: 1)"

### Step 2: Navigate Videos

- **Next Video ▶** button: Load the next video in the queue
- **◀ Previous Video** button: Go back to the previous video
- Videos loop: after the last video, it returns to the first

### What Happens When a Video Loads

1. Video appears in the player window
2. Timeline slider shows video length
3. Frame counter shows: "Frame: 0 / [total frames]"
4. If you have base CSV loaded:
   - System automatically searches for matching VIDEO_FILENAME
   - If found, data entry form pre-fills with location data
   - Drop counter shows the next sequential number for this POINT_ID

---

## Extracting Stills and Entering Data

This is the core workflow for data collection.

### Step 1: Find Your Observation Point

1. **Play the video** - Press **Spacebar** or click **Play**
2. **Adjust speed** - Use the Speed dropdown (0.25x for slow motion, up to 12x for fast)
3. **Pause** - Press **Spacebar** again when you see something interesting
4. **Fine-tune** - Use arrow keys to move frame-by-frame:
   - **→** (Right Arrow): Next frame
   - **←** (Left Arrow): Previous frame
   - **Shift+→**: Skip forward 10 frames
   - **Shift+←**: Skip back 10 frames
   - **Ctrl+→**: Skip forward 100 frames
   - **Ctrl+←**: Skip back 100 frames

### Step 2: Extract the Still

1. When you're on the perfect frame, press **'S'** (or click **"Extract Frame"**)
2. The following happens automatically:
   - Still image is saved to `drop_stills/` folder
     - Named: `[video_name]_drop1.jpg`, `[video_name]_drop2.jpg`, etc.
   - Data entry form populates with:
     - **POINT_ID**: From base CSV or video filename
     - **DROP_ID**: Sequential (drop1, drop2, drop3...)
     - **LATITUDE, LONGITUDE, DEPTH**: From base CSV
     - **YEAR, DATE, TIME**: Parsed from VIDEO_TIMESTAMP
     - **FILENAME**: The still image filename
   - A data entry row is created in `data/data_entries.csv`
   - Entry navigation shows: "Entry 1 of 1"

3. A confirmation message shows: "Frame saved to: [path]. Data entry auto-saved with DROP_ID: drop1"

### Step 3: Fill in Observation Data

Now the form is ready for your observations. The location data is already filled in, so you only need to enter:

1. **SUBSTRATE**: Type of substrate (e.g., "Sand", "Coral rubble", "Silt")
2. **Coverage fields**: Enter percentages or presence/absence
   - SG_COVER (Seagrass cover)
   - AL_COVER (Algae cover)
   - HC_COVER (Hard coral cover)
   - SC_COVER (Soft coral cover)
   - EPI_COVER (Epiphyte cover)
   - etc.
3. **Species codes**: If you see specific species, enter codes in appropriate fields
4. **COMMENTS**: Any additional notes

**Important:** You don't need to click "Save Entry" - the data is already saved!

### Step 4: Extract Next Still

1. Continue playing the video or navigate to the next observation point
2. Press **'S'** to extract another still
3. The system:
   - Saves the new still as `_drop2.jpg`
   - Creates a new data entry with DROP_ID: drop2
   - **Clears observation fields** (substrate, cover percentages, comments)
   - **Keeps location data** (POINT_ID, LAT, LONG, DEPTH, DATE, TIME)
   - Navigation shows: "Entry 2 of 2"

4. Fill in the observation data for this new drop
5. Repeat for all observations in the video

### Step 5: Move to Next Video

1. Click **Next Video ▶** when finished with current video
2. The next video loads
3. **Drop counter continues** if the new video has the same POINT_ID
   - Example: If Video 1 (POINT_ID=1) had drop1 and drop2, Video 2 (POINT_ID=1) starts at drop3
4. **Drop counter resets to 1** if the new video has a different POINT_ID

---

## Navigating and Editing Entries

After collecting data, you may want to review or edit previous entries.

### Step 1: Load All Entries

1. Click the **"Load All Entries"** button (orange button in data entry pane)
2. The system loads all rows from `data/data_entries.csv`
3. You see: "Entry 1 of X" where X is total entries
4. The form displays the first entry's data

### Step 2: Navigate Through Entries

Use the navigation buttons at the top of the data entry pane:

- **◀ Previous Entry**: Go to previous entry
- **Next Entry ▶**: Go to next entry
- **Entry X of Y**: Shows current position

As you navigate:
- The form loads each entry's data
- If you made changes, they auto-save when you move to another entry
- An asterisk (*) appears if you have unsaved changes: "Entry 2 of 10 *"

### Step 3: Edit Data

1. Click into any field
2. Change the value
3. The navigation label shows: "Entry 2 of 10 *" (asterisk indicates unsaved changes)
4. Navigate to another entry - changes are **automatically saved**
5. Return to the edited entry to verify changes

### Step 4: Manual Save (Optional)

While navigation auto-saves, you can also manually save:

1. Click **"Save Entry"** button
2. Confirmation: "Data entry saved to: data/data_entries.csv"
3. Option to clear form for new manual entry (usually click "No")

---

## Tips and Best Practices

### Workflow Efficiency

**Single Pass Method:**
1. Watch video at normal speed first to identify observation points
2. Make mental notes of approximate times
3. Second pass: navigate to those times, extract stills, enter data

**Continuous Entry Method:**
1. Play video at 0.5x or 1x speed
2. Press 'S' whenever you see something worth recording
3. Quickly enter observations
4. Continue playing

**Batch Review Method:**
1. Extract all stills first (press 'S' frequently)
2. Later, use entry navigation to review each still
3. Add detailed observations at your own pace

### Data Quality Tips

1. **Be consistent with codes/categories**
   - Decide on substrate codes beforehand (e.g., "Sand" vs "sand" vs "S")
   - Keep a reference sheet nearby

2. **Use COMMENTS field liberally**
   - Note unusual features
   - Record uncertainties
   - Flag entries that need review

3. **Check your data periodically**
   - Click "Load All Entries" and browse through
   - Look for blank fields or typos
   - Verify coverage percentages add up correctly

4. **Backup your data**
   - `data/data_entries.csv` is your master file
   - Copy it regularly to another location
   - Consider version control (name it with date: `data_entries_2025-12-09.csv`)

### Keyboard Shortcuts Cheat Sheet

Print this and keep it nearby:

| Action | Shortcut |
|--------|----------|
| Play/Pause | **Spacebar** |
| Next frame | **→** |
| Previous frame | **←** |
| Skip +10 frames | **Shift+→** |
| Skip -10 frames | **Shift+←** |
| Skip +100 frames | **Ctrl+→** |
| Skip -100 frames | **Ctrl+←** |
| Extract still | **S** |

### Handling Multiple Videos Per Point

If you have multiple videos for the same sampling point:

1. Base CSV should have multiple rows with same POINT_ID but different VIDEO_FILENAME
2. Drop numbering continues automatically:
   - Video 1 (POINT_ID=3): drop1, drop2, drop3
   - Video 2 (POINT_ID=3): drop4, drop5, drop6 (continues from Video 1)
3. Still images are named by video: 
   - `Video1_ID003_drop1.jpg`, `Video1_ID003_drop2.jpg`
   - `Video2_ID003_drop4.jpg`, `Video2_ID003_drop5.jpg`

### Troubleshooting Common Issues

**Form fields not pre-populating:**
- Check VIDEO_FILENAME in base CSV matches exactly (including extension)
- Verify VIDEO_TIMESTAMP format: `DD/MM/YYYY HH:MM`
- Try clicking "Load Base CSV" button to reload

**Drop numbers not sequential:**
- Check POINT_ID is consistent in base CSV
- Review existing entries in `data/data_entries.csv`
- Delete test entries if needed and restart

**Can't see all form fields:**
- The data entry pane is scrollable - scroll down
- Maximize the window for more space
- Consider using fewer fields in your template

**Data not saving:**
- Check `data/` folder permissions (should be writable)
- Verify `data_entries.csv` isn't open in Excel (close it)
- Look for error messages in the terminal window

---

## Example Workflow Session

Here's a complete example of analyzing 3 videos:

### Setup (One-time)
1. Copied 3 videos to `drop_videos/`
2. Created template with 15 columns
3. Created base CSV with metadata for 3 videos
4. Launched app, loaded template and base CSV

### Video 1 Analysis (POINT_ID=1)
1. Clicked "Load Videos from drop_videos/"
2. Video 1 loads, form pre-fills with LAT/LONG/DEPTH
3. Watched video at 2x speed
4. Found interesting substrate at 00:30
   - Pressed 'S' to extract → `Video1_drop1.jpg` created
   - Entered: SUBSTRATE="Sand with coral rubble", SG_COVER=30, COMMENTS="Good visibility"
5. Found dense seagrass patch at 01:15
   - Pressed 'S' → `Video1_drop2.jpg` created
   - Entered: SUBSTRATE="Sand", SG_COVER=80, species codes
6. Continued through video, extracted 5 drops total

### Video 2 Analysis (POINT_ID=1, same location)
1. Clicked "Next Video ▶"
2. Form pre-fills with same LAT/LONG/DEPTH
3. **Drop counter shows drop6** (continues from Video 1)
4. Extracted 3 more drops → `Video2_drop6.jpg`, `Video2_drop7.jpg`, `Video2_drop8.jpg`
5. Total for POINT_ID=1: 8 drops across 2 videos

### Video 3 Analysis (POINT_ID=2, different location)
1. Clicked "Next Video ▶"
2. Form pre-fills with different LAT/LONG/DEPTH
3. **Drop counter resets to drop1** (new POINT_ID)
4. Extracted 4 drops for this location

### Review Session (Next day)
1. Clicked "Load All Entries"
2. Browsed through all 12 entries
3. Corrected a typo in drop3
4. Added more detailed comments to drop7
5. All changes auto-saved

### Final Output
- 12 still images in `drop_stills/`
- 12 data rows in `data/data_entries.csv`
- Ready for analysis in Excel, R, or Python!

---

## Next Steps

Now that you know how to use the tool:

1. **Test with a sample video** - Extract a few drops to practice the workflow
2. **Customize your template** - Add/remove fields as needed
3. **Set up your base CSV** - Gather GPS coordinates and metadata
4. **Start your analysis** - Process all your videos systematically
5. **Export your data** - Open `data_entries.csv` in Excel for analysis

Happy analyzing! 🌊🎥📊
