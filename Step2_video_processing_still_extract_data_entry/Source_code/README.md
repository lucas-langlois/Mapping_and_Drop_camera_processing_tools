# Drop Cam Video Analysis Tool

A comprehensive video player application with integrated data entry for marine/environmental video analysis. Built specifically for analyzing drop camera footage with customizable data collection forms.

## Features

### Video Player
✅ **Play/Pause Controls** - Spacebar or button to control playback  
✅ **Frame-by-Frame Navigation** - Arrow keys (← →) to step through frames  
✅ **Skip Navigation** - Shift+Arrow (±10 frames), Ctrl+Arrow (±100 frames)  
✅ **Timeline Slider** - Fast scrubbing through video with tooltips  
✅ **Variable Speed Control** - 0.25x to 12x playback speeds  
✅ **Video Zoom** - 50% to 400% zoom with smooth scroll/pan (great for detail work!)  
✅ **Auto-Load Video Queue** - Load multiple videos from `drop_videos/` folder  
✅ **Video Navigation** - Previous/Next video buttons for queue  
✅ **Dual-Screen Mode** - Detach data entry panel to separate window for 2-monitor setups  
✅ **Optimized UI** - Compact controls maximize video viewing area  
✅ **Helpful Tooltips** - Hover over any button for description  

### Data Entry System
✅ **Customizable Form** - Load any CSV template to define data fields  
✅ **Decimal Precision** - Support for decimal values (e.g., 0.7%) in percentage fields  
✅ **Auto-Population** - Pre-fill location/metadata from base CSV  
✅ **Smart Drop Numbering** - Sequential drop IDs based on POINT_ID  
✅ **Entry Navigation** - Browse and edit previous entries  
✅ **Auto-Save on Navigation** - Changes saved when moving between entries  
✅ **Still Image Integration** - Auto-create data entry when extracting frames  
✅ **Validation Rules** - Built-in QAQC system with visual rule builder  
✅ **Auto-Fill Rules** - Automatically populate fields based on conditions  
✅ **Conditional Sum Validation** - Validate sums only when conditions are met  
✅ **Calculated Fields** - Auto-calculate values from formulas with configurable decimals  
✅ **Copy from Previous** - Quickly reuse values from previous entries  
✅ **Project Save/Load** - Resume exactly where you left off  
✅ **Interactive Map View** - Visualize all sampling points on satellite imagery  

### Frame Extraction
✅ **Single Frame Export** - Extract current frame with 'S' key  
✅ **Auto-Named Files** - `[video_name]_drop1.jpg`, `drop2.jpg`, etc.  
✅ **Organized Output** - All stills saved to `drop_stills/` folder  

## Installation

### Prerequisites
- Windows 10/11
- Python 3.8 or higher
- 4GB RAM minimum

### Option 1: Run from Source (Recommended)

1. **Install Dependencies**
   ```powershell
   pip install -r requirements.txt
   ```
   
   Or install individually:
   ```powershell
   pip install opencv-python PyQt5 PyQtWebEngine numpy
   ```

2. **Prepare Directory Structure**
   The application will create these folders automatically:
   - `drop_videos/` - Place your video files here
   - `drop_stills/` - Extracted still images
   - `data/` - CSV templates and data entries

### Option 2: Build Standalone Executable

If you need a standalone `.exe` file (no Python required to run):

1. **Install PyInstaller**
   ```powershell
   pip install pyinstaller
   ```

2. **Run the Build Script**
   ```powershell
   python build_exe.py
   ```
   
   This will:
   - Clean up any previous builds
   - Package all dependencies
   - Create `VideoPlayer.exe` in the `dist/` folder
   - Build time: ~2-5 minutes depending on your system

3. **Distribute the Executable**
   - Find `VideoPlayer.exe` in `dist/` folder
   - Copy the entire parent directory structure (with `drop_videos/`, `drop_stills/`, `data/` folders)
   - The `.exe` can be run on any Windows machine without Python installed
   
   **Note**: The `.exe` file is ~500MB-3GB due to bundled Python runtime and OpenCV libraries. This is normal for PyInstaller applications.

4. **Alternative: Manual PyInstaller Build**
   ```powershell
   pyinstaller --name=VideoPlayer --onefile --windowed video_player.py
   ```

## Usage

### First Time Setup

1. **Launch the Application**
   ```powershell
   python video_player.py
   ```

2. **Load Data Entry Template** (Required)
   - Select a CSV file that defines your data columns
   - The header row determines which fields appear in the form
   - Example: `data/data_entry_template.csv`

3. **Load Base CSV** (Optional)
   - Load a CSV with location/metadata for your videos
   - Must have columns like: POINT_ID, VIDEO_FILENAME, LATITUDE, LONGITUDE, DEPTH, VIDEO_TIMESTAMP
   - Data will auto-populate when extracting stills
   - Example: `data/Wuthathi_Subtidal_Nov25_data.csv`

### Workflow

**⚠️ Key Point:** Press 'S' to **"Save and Snapshot"** - it saves current form data + captures image

**Correct Order:** Find frame → Fill data → Press 'S' (saves + extracts)

1. **Load Videos**
   - Click "Load Videos from drop_videos/"
   - All videos in the folder are queued
   - Use Previous/Next Video buttons to navigate

2. **For Each Drop:**
   
   **A. Navigate to observation point**
   - Play/Pause, arrow keys, or timeline slider to find the frame
   - **STOP at the frame you want**
   
   **B. Fill in observation data**
   - Form pre-populated with metadata (POINT_ID, LAT, LONG, DATE, TIME)
   - For Drop 1: Enter all observations manually
   - For Drop 2+: Click **"◄ Copy All from Previous"** then adjust differences
   - Or use individual **◄** buttons to copy specific fields
   - Enter: SUBSTRATE, SG_PRESENT, coverage, species, COMMENTS
   - Auto-fill triggers if SG_PRESENT=0 (instant NA fill!)
   
   **C. Press 'S' to extract and save**
   - Saves data entry + still image
   - Form clears for next drop
   - Navigation: "Entry 1 of 1", "Entry 2 of 2", etc.

3. **Last Drop**
   - After extracting final frame, fill its data
   - Save by: Extracting again, clicking "Save Entry", or "Next Video"

4. **Review and Edit**
   - Click "Load All Entries" to browse
   - Use ◀ Previous / Next ▶ buttons
   - Edit fields - auto-saves on navigation

### Keyboard Shortcuts

| Key | Action |
|-----|--------|
| **Space** | Play/Pause |
| **←** | Previous frame |
| **→** | Next frame |
| **Shift+←** | Skip back 10 frames |
| **Shift+→** | Skip forward 10 frames |
| **Ctrl+←** | Skip back 100 frames |
| **Ctrl+→** | Skip forward 100 frames |
| **S** | Extract current frame |

### Video Zoom Feature

Zoom in to examine fine details in your video:

**Zoom Controls:**
- **Slider**: Horizontal zoom slider in control bar
- **Range**: 50% (zoom out) to 400% (zoom in)
- **Display**: Live percentage indicator (50%-400%)

**How to Use:**
1. Open a video
2. Find the "Zoom:" slider in the controls (between Speed and Extract)
3. Drag slider right to zoom in, left to zoom out
4. At zoom levels > 100%, scrollbars appear automatically
5. Click and drag or use scrollbars to pan around the zoomed video

**Perfect For:**
- Identifying small organisms or features
- Reading text or numbers in video
- Examining substrate texture in detail  
- Quality checking coral/seagrass identification16. Verifying species at close range**Tips:**
- Zoom to 200-300% for detailed species identification
- Use at 100% (default) for normal navigation
- Zoom persists across frames - set once, stays while navigating
- Works with all playback speeds
- Smooth transformation ensures quality at high zoom

### Dual-Screen Layout Mode

Perfect for users with 2+ monitors! Separate the video player and data entry panel into independent windows.

**Features:**
- **Toggle Button**: ⬌ button in control bar (orange = attached, green = detached)
- **Smart Positioning**: Auto-detects second monitor and positions data panel there
- **Synchronized State**: All functionality works identically in both modes
- **Easy Toggle**: Switch back and forth anytime

**How to Use:**

**Detach (Dual-Screen Mode):**
1. Click the **⬌** button in the video controls
2. Data entry panel opens in new window
3. If you have 2+ monitors: Window opens on second screen automatically
4. If you have 1 monitor: Window opens to the right of main window
5. Drag windows to your preferred positions
6. Button turns **green** when detached

**Reattach (Single Window Mode):**
1. Click **⬌** button again (or close the data panel window)
2. Data entry panel returns to main window
3. Button turns **orange** when attached

**Recommended Setup:**
- **Monitor 1**: Video player (maximized for large viewing area)
- **Monitor 2**: Data entry panel (full access to form fields)
- Eliminates scrolling and switching between video and data entry

**Benefits:**
- **More screen space**: Maximize both video and form visibility
- **Better workflow**: See entire form while watching video
- **Flexible positioning**: Arrange windows however you prefer
- **Maintains state**: All data, rules, and settings stay synchronized

**Note**: Both windows close together when you exit the application.

## File Organization

```
Drop_cam_video_analysis/
├── video_player.py          # Main application
├── requirements.txt         # Python dependencies
├── drop_videos/            # Place your videos here
├── drop_stills/            # Extracted still images
│   ├── Video1_drop1.jpg
│   ├── Video1_drop2.jpg
│   └── ...
└── data/
    ├── data_entry_template.csv              # Your column definitions
    ├── data_entry_template_rules.json       # Validation rules (auto-created)
    ├── seagrass_validation_example.json     # Example rules for seagrass surveys
    ├── Wuthathi_Subtidal_Nov25_data.csv     # Location metadata (optional)
    └── data_entries.csv                     # Your collected data
```

## CSV File Formats

### Data Entry Template
Defines the columns for your data collection. First row = field names.
```csv
POINT_ID,DROP_ID,YEAR,DATE,TIME,LATITUDE,LONGITUDE,FILENAME,SUBSTRATE,DEPTH,COMMENTS
```

### Base CSV (Optional)
Pre-populates fields with location/metadata matched by VIDEO_FILENAME.
```csv
POINT_ID,VIDEO_FILENAME,VIDEO_TIMESTAMP,LATITUDE,LONGITUDE,DEPTH
1,Wuthathi_Subtidal_20251127_ID001_092219.MP4,27/11/2025 9:22,143.134413,-11.90676302,15m
```

### Data Entries Output
Your collected observations, one row per extracted still.
```csv
POINT_ID,DROP_ID,YEAR,DATE,TIME,LATITUDE,LONGITUDE,FILENAME,SUBSTRATE,DEPTH,COMMENTS
1,drop1,2025,27/11/2025,9:22,143.134413,-11.90676302,Video_ID001_drop1.jpg,Sand,15m,Clear visibility
```

## Advanced Features

### Smart Drop Numbering
- Drop IDs sequence across multiple videos with same POINT_ID
- Example: Video 1 (ID001) creates drop1, drop2; Video 2 (ID001) continues with drop3, drop4
- Automatically resets to drop1 when POINT_ID changes

### Auto-Data Population
- Extracts POINT_ID from video filename (e.g., "ID001")
- Matches VIDEO_FILENAME in base CSV
- Parses VIDEO_TIMESTAMP for YEAR, DATE, TIME fields
- Continues drop numbering from existing entries

### Entry Navigation
- Browse through all saved entries
- Edit historical data
- Changes auto-save when navigating
- Visual indicator (*) shows unsaved changes

### Project Save/Load
Save your entire project state and resume exactly where you left off:

**Features:**
- Saves video queue, current video, and frame position
- Preserves all data entries and validation rules
- Stores base CSV data and template settings
- Auto-saves on close (if project exists)
- Startup prompt to load existing or create new project

**Usage:**
1. Click **"💾 Save Project"** at any time
2. Name your project (e.g., `Wuthathi_Nov2025.json`)
3. Project saved to `projects/` folder
4. On next launch, choose "Load Existing Project"
5. Resume exactly where you stopped!

**Benefits:**
- No need to reload videos, templates, or base CSV
- Preserves your exact frame position
- Maintains drop counter state
- Perfect for multi-day field work

### Interactive Map View
Visualize all your sampling points on a satellite map:

**Features:**
- 🗺️ Satellite basemap (Esri World Imagery)
- 📍 All Point IDs displayed with labeled markers
- 🔴 Current video point highlighted in red
- 🔵 Other points shown in blue
- ℹ️ Click markers for detailed popup info (coordinates, depth, date, location)
- 🏷️ Permanent white labels showing Point IDs
- 📊 Legend explaining marker colors

**Usage:**
1. Click **"🗺 Show on Map"** button (next to Save Project)
2. Interactive map opens in popup window
3. Pan/zoom to explore your survey area
4. Click any marker to see details
5. Red marker shows which point you're currently working on

**Requirements:**
- LATITUDE and LONGITUDE in base CSV (WGS84 decimal degrees)
- PyQtWebEngine installed (`pip install PyQtWebEngine`)

**Perfect for:**
- Verifying GPS coordinates are correct
- Planning which videos to process next
- Visualizing spatial coverage of your survey
- Sharing site locations with team members

## Data Validation Rules (QAQC)

### Overview

The application includes a built-in validation rules system to ensure data quality. Create custom rules using a visual interface - no coding required!

### Features

- **Visual Rule Builder** - Create rules using dropdown menus and forms
- **Auto-Save/Load** - Rules automatically saved with your template
- **Real-time Feedback** - Invalid fields highlighted in red
- **Flexible Validation** - Option to "Save Anyway" for edge cases

### How to Use

#### 1. Open the Rules Manager

After loading your template, click the **"⚙ Manage Validation Rules"** button in the data entry pane.

#### 2. Add Rules

Click **"+ Add New Rule"** and choose from 5 rule types:

**Allowed Values** - Restricts a field to specific values
- Example: SG_PRESENT can only be 0 or 1

**Numeric Range** - Ensures numeric fields are within a range
- Example: DEPTH must be between 0 and 100

**Required Field** - Makes a field mandatory (cannot be empty)
- Example: POINT_ID must be filled in

**Conditional (If-Then)** - Applies rules based on another field's value
- Example: If SG_PRESENT = 0, then SG_COVER must = 0
- Example: If SG_PRESENT = 1, then SG_COVER must be > 0

**Sum Equals** - Ensures multiple numeric fields sum to a target value
- Example: All cover percentages must sum to 100

#### 3. Save Rules

Rules are automatically saved as `[template_name]_rules.json` in the same directory as your template.

#### 4. Rules Auto-Load

Next time you load the same template, your rules will automatically load!

### Validation Behavior

**When Saving Manually:**
- Rules checked when clicking "Save Entry"
- Invalid fields highlighted in red
- List of all errors shown
- Option to "Save Anyway" or cancel

**When Extracting Stills:**
- Rules checked during auto-save
- Warnings shown but data still saved
- Invalid fields remain highlighted for correction

**When Navigating Entries:**
- Rules checked when moving between entries
- Same behavior as manual save

### Example Validation Rules

For seagrass surveys:

```json
{
  "rules": [
    {
      "type": "allowed_values",
      "field": "SG_PRESENT",
      "values": ["0", "1"],
      "error": "SG_PRESENT must be 0 or 1"
    },
    {
      "type": "conditional",
      "if_field": "SG_PRESENT",
      "if_value": "0",
      "then_field": "SG_COVER",
      "then_condition": "equals",
      "then_value": "0",
      "error": "If SG_PRESENT is 0, then SG_COVER must be 0"
    },
    {
      "type": "conditional",
      "if_field": "SG_PRESENT",
      "if_value": "1",
      "then_field": "SG_COVER",
      "then_condition": "greater_than",
      "then_value": "0",
      "error": "If SG_PRESENT is 1, then SG_COVER must be > 0"
    },
    {
      "type": "range",
      "field": "DEPTH",
      "min": 0,
      "max": 100,
      "error": "DEPTH must be between 0 and 100 meters"
    },
    {
      "type": "sum_equals",
      "fields": ["SG_COVER", "AL_COVER", "HC_COVER", "OPEN"],
      "target": 100,
      "tolerance": 0.5,
      "error": "Total cover must equal 100%"
    }
  ]
}
```

### Rule Types Reference

**Allowed Values**
```
Field: [dropdown of your fields]
Allowed Values: 0, 1  (comma-separated)
Error Message: Custom message
```

**Numeric Range**
```
Field: [dropdown]
Minimum Value: 0
Maximum Value: 100
Error Message: Custom message
```

**Required Field**
```
Field: [dropdown]
Error Message: Custom message
```

**Conditional (If-Then)**
```
If Field: [dropdown]
Equals: value
Then Field: [dropdown]
Must Be: [Equal to / Not equal to / Greater than / Less than / etc.]
Value: value
Error Message: Custom message
```

**Sum Equals**
```
Fields to Sum: FIELD1, FIELD2, FIELD3  (comma-separated)
Must Equal: 100
Tolerance (+/-): 0.5
Error Message: Custom message
```

### Tips for Validation Rules

1. **Start Simple** - Add a few critical rules first, then add more as needed
2. **Test Rules** - Add test data to verify your rules work as expected
3. **Clear Messages** - Write error messages that explain exactly what's wrong
4. **Use Tolerance** - For sum rules, add small tolerance (0.1-1.0) for rounding errors
5. **Share Rules** - Copy the `_rules.json` file to share rules with your team

### Validation Troubleshooting

**Rules don't load automatically:**
- Ensure the rules file is named `[template_name]_rules.json`
- Ensure it's in the same directory as your template CSV

**Validation too strict:**
- Edit rules and add tolerance for numeric comparisons
- Use "Save Anyway" option for edge cases

**Need to disable validation temporarily:**
- Open Rules Manager and delete all rules
- Or just click "Save Anyway" when prompted

**Advanced Users:**
If comfortable with JSON, you can edit the rules file directly in a text editor.

### Advanced Validation: Conditional Sum & Auto-Fill

#### Conditional Sum Rules

Validates that fields sum to a target, but ONLY when a condition is met.

**Example:** Species percentages must sum to 100%, but only when seagrass is present.

**Setup:**
```
Rule Type: Conditional Sum
If Field: SG_PRESENT
Equals: 1
Then Sum of Fields: CR, CS, HO, HD, HS, HU, SI, EA, TH, ZC
Must Equal: 100
Tolerance: 0.5
Treat Blanks As: 0 (zero)
```

**Blank Handling:**
- **"0 (zero)"** - Blank fields count as 0 (useful when users leave absent species blank)
- **"Skip field"** - Only counts fields with values

**💡 Decimal Support**: Tolerance allows for decimal precision. Use `0.1` for values like 0.7%, 33.3%, etc.

#### Calculated Fields

Automatically calculate field values from formulas. Perfect for auto-filling totals.

**Example:** Auto-calculate OPEN = 100 - (all other cover values)

**Setup:**
```
Rule Type: Calculated Field
Target Field: OPEN
Formula: 100 - SG_COVER - AL_COVER - HC_COVER - SC_COVER - SPONGE - WHIP - OTHER_COVER
Decimal Places: 1
```

**Decimal Places Options:**
- **0**: Whole numbers only (e.g., 99, 100, 23)
- **1**: One decimal (e.g., 99.3, 23.7) ← **Recommended** for percentage fields
- **2+**: Higher precision (e.g., 99.33, 23.77)

**⚠️ Important**: If you enter decimal values in fields (like SG_COVER = 0.7), set calculated field decimals to 1 or higher. Otherwise, rounding causes validation errors.

**Example with Decimals:**
- SG_COVER = 0.7
- AL_COVER = 0
- HC_COVER = 0
- (other covers) = 0
- OPEN calculates as 99.3 (with decimals=1) ✓
- OPEN calculates as 99 (with decimals=0) ✗ → Sum = 99.7 ≠ 100

#### Auto-Fill Rules

Automatically populates multiple fields when you enter a trigger value.

**Example:** When SG_PRESENT = 0, auto-fill all species with "NA"

**Setup:**
```
Rule Type: Auto-Fill
When Field: SG_PRESENT
Equals: 0
Then Set Fields: SG_COVER=0, CR=NA, CS=NA, HO=NA, HD=NA, HS=NA, HU=NA, SI=NA, EA=NA, TH=NA, ZC=NA, EPI_COVER=NA
```

**Format:** `FIELD1=value1, FIELD2=value2` or multi-line

**Triggers:** Instantly when you type/paste the trigger value

**Benefits:**
- Saves typing "NA" in 10+ fields
- Ensures consistency
- Works with validation rules
- Can be combined with "Copy from Previous" feature

**Example Workflow:**
1. Extract still
2. Type `0` in SG_PRESENT
3. ✨ All species fields instantly fill with "NA"
4. Fill remaining fields (SUBSTRATE, COMMENTS, etc.)
5. Done!

## Copy from Previous Entry

### Overview

Save 67% of data entry time when analyzing multiple drops from the same video by copying values from the previous entry.

### Features

**1. Individual Field Copy (◄ Button)**
- Small ◄ button next to each observation field
- Click to copy that field's value from previous entry
- Only appears on copyable fields (not metadata)

**2. Copy All Button**
- Purple **"◄ Copy All from Previous Entry"** button
- Copies ALL observation fields at once
- Automatically preserves unique metadata (DROP_ID, POINT_ID, coordinates, dates)

### What Gets Copied vs. Preserved

**✅ Copied (Observation Fields):**
- SUBSTRATE, SG_PRESENT, SG_COVER
- All species percentages
- All coverage fields
- COMMENTS
- Any custom observation fields

**🔒 Preserved (Never Copied):**
- DROP_ID (unique per still)
- POINT_ID (from base CSV)
- FILENAME (unique per still)
- LATITUDE, LONGITUDE, GPS_MARK
- DATE, TIME, DATE_TIME, YEAR
- VIDEO_FILENAME, VIDEO_TIMESTAMP

### Typical Workflow

**Drop 1:**
```
Extract still → DROP_ID=drop1 auto-fills
Enter all observations
Time: 2 minutes
```

**Drop 2 (similar conditions):**
```
Extract still → DROP_ID=drop2 (new, unique)
Click "◄ Copy All from Previous Entry"
Observations copied, metadata preserved
Adjust minor differences
Time: 30 seconds (75% faster!)
```

**Time Savings:** 10 drops with copy feature = 6.5 min (vs 20 min without)

### Tips

1. **Use "Copy All"** when drops are similar, then adjust differences
2. **Use individual ◄** when only a few fields are similar
3. **Combine with auto-fill** - copy all, then change trigger field to auto-fill
4. **Work in batches** - process all drops from one video to maximize copying benefit
5. **Always review** - don't blindly copy; conditions can change between drops

## Troubleshooting

**Video won't open:**
- Ensure codec is supported (MP4 recommended)
- Try converting with VLC or HandBrake

**Can't see all fields:**
- Data entry pane is scrollable - scroll down
- Resize window for more space

**Drop numbering incorrect:**
- Check POINT_ID matches in base CSV and video filename
- Review existing entries in `data/data_entries.csv`

**Missing dependencies:**
```powershell
pip install -r requirements.txt --upgrade
```

## System Requirements

- **OS**: Windows 10/11
- **Python**: 3.8+
- **RAM**: 4GB minimum (8GB recommended)
- **Display**: 1600x900 or higher recommended for data entry pane

## License

Free to use and modify for research and commercial projects.