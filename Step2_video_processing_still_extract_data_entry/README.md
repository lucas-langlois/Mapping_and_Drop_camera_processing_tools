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
✅ **Video Folder Setup** - Set `drop_videos/` (or any folder) as the video source with one click  
✅ **Row-Driven Video Loading** - Videos load automatically as you navigate base CSV rows  
✅ **Dual-Screen Mode** - Detach data entry panel to separate window for 2-monitor setups  
✅ **Optimized UI** - Compact controls maximize video viewing area  
✅ **Helpful Tooltips** - Hover over any button for description  

### Data Entry System
✅ **Customizable Form** - Load any CSV template to define data fields  
✅ **Decimal Precision** - Support for decimal values (e.g., 0.7%) in percentage fields  
✅ **Auto-Population** - Pre-fill location/metadata from base CSV  
✅ **Smart Drop Numbering** - Sequential drop IDs keyed on **POINT_ID** (not video name) — carries across multiple videos for the same point  
✅ **Dropdown Fields** - `allowed_values` fields rendered as labelled dropdowns (e.g., "1 — Yes", "0 — No", "NA — Not applicable"); a separate `dropdown` rule type renders a plain list without numeric-style labels (used for text-valued fields like RANK_TYPE)  
✅ **Entry Navigation** - Browse and edit previous entries with ◀ Previous / Next ▶ buttons  
✅ **Draft Buffer** - Navigating away from a new unsaved entry saves a temporary draft; returning restores every field exactly  
✅ **Return-to-New-Entry** - Next ▶ is always enabled from any saved entry, stepping back to the new entry form  
✅ **Auto-Save on Navigation** - Edits to any saved entry are auto-saved before navigating to another entry or a different CSV row  
✅ **Row-Nav Auto-Save** - Clicking Prev/Next Row while editing a saved entry auto-saves those edits first; navigation is blocked if validation fails  
✅ **Browse Entries Draft Preservation** - Opening the Browse Entries dialog while on the new entry form snapshots the draft so it is restored when you return  
✅ **Clean New-Entry Mode on Row Switch** - Navigating to a different CSV row always resets to a clean new-entry state, preventing accidental overwrites of saved entries  
✅ **Still Image Integration** - Auto-create data entry when extracting frames  
✅ **Validation Rules** - Built-in QAQC system with visual rule builder  
✅ **Auto-Fill Rules** - Automatically populate fields based on conditions  
✅ **Conditional Sum Validation** - Validate sums only when conditions are met; NA and blank fields gracefully skipped  
✅ **Calculated Fields** - Auto-calculate values from formulas (read-only, green background); cascades correctly (e.g., BARE_COVER → TOTAL_COVER)  
✅ **Template-Driven Subgroup Normalization** - Species subgroups auto-fill blanks as 0 or NA based on rules  
✅ **Copy from Previous** - Quickly reuse values from previous entries  
✅ **Date-Sorted Row Navigation** - Base CSV rows are automatically sorted by DATE_TIME on load for consistent ordering  
✅ **Grab-Only Mode** - Enter data for points that have a grab photo but no video; DROP_ID uses `grab{N}` prefix  
✅ **GRAB_ONLY Sync** - Changing the GRAB_ONLY field live toggles between `drop{N}` and `grab{N}` and updates FILENAME automatically  
✅ **Grab-Only Auto-Advance** - After saving a grab entry, prompted to advance to next row immediately  
✅ **Grab Photos Folder** - Set a folder for grab photos once via the **📁 Set Folder** button; path is saved in the project and restored on load  
✅ **Inline Photo Viewer** - Grab photos for no-video points display directly in the video viewport — no popup required; Prev/Next Photo controls appear when multiple photos exist for the point  
✅ **Multi-Photo GRAB_FILENAME** - `GRAB_FILENAME` supports semicolon-separated lists (`photo1.jpg;photo2.jpg`) and numbered sibling auto-discovery (`photo_1.jpg`, `photo_2.jpg`, …)  
✅ **Multi-Photo Grab Popup** - The "View Grab Photo" button (used when a point has both video and grab photos) opens a navigable popup with Prev/Next buttons and a photo counter  
✅ **Smart No-Video Placeholder** - Points with no video show a contextual placeholder: photos display inline if available; a blue prompt appears if photos are referenced but no folder is set; a "NO VIDEO" screen shows if there are no photos — all video controls are disabled in each case  
✅ **Auto-Fill Reset** - When a trigger field changes away from its trigger value, the previously auto-filled fields are cleared automatically (e.g., switching SG_PRESENT back from 0 → 1 removes the "NA" fills ready for real values)  
✅ **Field Groups** - Organise complex forms into named groups; each group filters the data entry pane to show only its member fields, reducing visual clutter on large templates  
✅ **Project Save/Load** - Resume exactly where you left off; base CSV is always re-read fresh from disk on load  
✅ **Row Navigation Restored on Load** - Project open restores exact row position and re-enables Prev/Next Row buttons  
✅ **Interactive Map View** - 4-colour status map: amber = current, green = positive match, white = entered (no match), blue = pending; user-selectable colour field  
✅ **Batch Aggregation Method Editing** - Apply one aggregation method to selected or all fields in one click  

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

1. **Set Video Folder**
   - Click **"📁 Use drop_videos/"** (or **"Choose Folder…"** for a custom path)
   - The folder is set as the video source; videos load automatically as you navigate rows
   - Use **◀ Prev Row / Next Row ▶** to step through base CSV rows and load the matching video

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
   - Save by: Extracting again, clicking "Save Entry", or advancing to the next row

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
- Drop IDs are based entirely on **POINT_ID**, not the video filename
- Carries across multiple videos: if Point 5 already has drop1 and drop2 (from Video A), switching to Video B (same point) will produce drop3
- Grab-only entries use a separate `grab{N}` counter and never affect the drop number
- Automatically resets to drop1 when POINT_ID changes

### Dropdown Fields for Constrained Values
Any field with an `allowed_values` rule is automatically rendered as a dropdown instead of a text box:
- Values displayed with friendly labels: `1 — Yes`, `0 — No`, `NA — Not applicable`
- Raw values (0, 1, NA) stored in CSV — display labels never contaminate data
- Changing GRAB_ONLY live immediately updates DROP_ID and FILENAME fields

### Entry Navigation & Draft Buffer
- **◀ Previous Entry** — from the new entry form, saves a draft snapshot before stepping back into saved entries
- **Next Entry ▶** — always active from any saved entry; the last step returns to your new entry form exactly as you left it
- If you navigate away without saving, every field in the form is restored when you come back
- Draft is automatically discarded when you commit an entry (extract or save)
- **Prev/Next Row with unsaved edits** — if you were editing a saved entry and click a row-navigation button, edits are auto-saved first; if validation fails the navigation is blocked so no data is lost
- **Browse Entries draft** — opening the Browse Entries (🔍) dialog while the new entry form has typed data snapshots a draft; returning via Next ▶ restores the form
- **Row switch resets state** — changing to a different CSV row always resets `current_entry_index` to new-entry mode, preventing the blank-row-overwrite bug that could occur after browsing saved entries

### Grab-Only Mode
For sampling points where you have a grab photo but no drop video:
1. Navigate to the point using **◀ Prev Row / Next Row ▶**
2. Set `GRAB_ONLY = 1` — the form switches to grab entry mode:
   - DROP_ID changes to `grab1` (or next sequential grab number)
   - FILENAME is set from the GRAB_FILENAME column of the base CSV
   - AL_COVER and FRESH_VEG_COVER auto-fill to NA
3. Fill in observations and click **Save Entry**
4. Prompted: **"Advance to next row?"** — Yes skips immediately to the next base CSV row

**Inline Photo Viewer (automatic for no-video points):**

When navigating to a point that has no video, the video area automatically switches to one of three contextual displays:

| Situation | Display |
|-----------|---------|
| Grab photos found | Photos shown directly in video area; Prev/Next Photo bar appears if >1 photo |
| Photos referenced but folder not set | Blue screen: "PHOTOS AVAILABLE — click 📁 Set Folder" |
| No photos referenced | Black "NO VIDEO" screen |

All video controls (play, timeline, extract) are disabled while in placeholder mode.

**Setting the Grab Photos Folder:**

Click the **📁 Set Folder** button (near the video area) to tell the app where your grab photos live. The path is saved in the project file and restored automatically on next load. If you load an old project that didn't store a path, you'll be prompted to set it.

**GRAB_FILENAME formats supported:**

| Format | Example |
|--------|---------|
| Semicolon-separated list | `photo1.jpg;photo2.jpg;photo3.jpg` |
| Numbered siblings (auto-discovered) | `photo_01.jpg` → finds `photo_01.jpg`, `photo_02.jpg`, … |
| Single file | `photo.jpg` |

**View Grab Photo popup (points with both video and grab photos):**

The **"View Grab Photo"** button opens a popup dialog. For points with multiple photos, the dialog includes Prev/Next Photo buttons and a photo counter so you can browse all images without closing and reopening.

### Project Save/Load (Enhanced)
- **Base CSV is always re-read fresh from disk** on project load — any updates made to the file outside the app are picked up automatically
- Row navigation position (`current_base_csv_row_index`) is saved and restored — Prev/Next Row buttons enabled immediately on load
- On load, the nav label shows exactly where you left off (e.g., `"5/152: Point ID005 — resumed"`) instead of the generic "Ready" message
- **Grab Photos Folder path** is saved and restored — no need to re-set it each session
- If loading an older project that didn't save the grab photos folder, a prompt asks you to set it
- Fallback: if loading an old project file that did not store row index, the app locates the correct row by matching the saved POINT_ID

### Auto-Fill Rules (Reset Behaviour)
When a trigger field is changed **away** from its trigger value, the fields that were previously auto-filled by that rule are automatically cleared (reset to empty). This means:
- Set SG_PRESENT = 0 → species fields fill with "NA", SG_COVER fills with 0
- Change SG_PRESENT back to 1 → those fields clear back to "", ready for real values
- If two rules share target fields, the rule that matches wins; if neither matches, the fields clear

### Field Groups
Field Groups let you organise large templates into manageable sections:
- Open the **Field Groups Manager** via button in the data entry pane
- Create named groups (e.g., "Seagrass", "Hard Coral", "Cover Totals") and assign fields to each
- Selecting a group in the dropdown filters the data entry form to show only that group's fields
- "All fields" view is always available
- Groups are saved as `[template_name]_groups.json` alongside the template and rules files

### Interactive Map View (User-Selectable Colour Field)
The map reflects your data collection progress in real time and works with **any survey type** — seagrass, coral, fish, grab samples, etc.

**Colour field selector (new in v1.1.2):**

At the top of the map dialog a toolbar lets you choose:
- **Colour points by field** — dropdown populated from your template fields; pick any field (e.g. `SG_PRESENT`, `CORAL_PRESENT`, `SPECIES_FOUND`)
- **equals** — the value that should register as "positive" (default `1`; change to `yes`, `present`, etc. as needed)
- **Refresh Map** — instantly re-colours all points based on the new selection

The chosen field and value are saved in the project file and restored next session. On first open, the app auto-detects common presence/absence field names (`SG_PRESENT`, `SG_PA`, `PRESENCE`, `PRESENT`, `PA`) and pre-selects the first match found.

| Colour | Meaning |
|--------|---------|
| 🟠 Amber (larger) | Current active point |
| 🟢 Dark green | At least one entry where the chosen field = chosen value |
| ⚪ White | Entry exists — chosen field did not match |
| 🔵 Blue | Not yet entered |

The legend in the bottom-right updates dynamically to show the field name and value you selected. Status is computed from `all_data_entries` every time you hit **Refresh Map**.


## Data Validation Rules (QAQC)

### Overview

The application includes a built-in validation rules system to ensure data quality. Create custom rules using a visual interface - no coding required!

### Features

- **Visual Rule Builder** - Create rules using dropdown menus and forms
- **Auto-Save/Load** - Rules automatically saved with your template
- **Real-time Feedback** - Invalid fields highlighted in red
- **Blocking Validation** - Invalid entries are blocked until fixed

### How to Use

#### 1. Open the Rules Manager

After loading your template, click the **"⚙ Manage Validation Rules"** button in the data entry pane.

#### 2. Add Rules

Click **"+ Add New Rule"** and choose from rule types:

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

**Conditional Sum** - Validates a sum only when a condition is true
- Example: Species percentages must sum to 100 only when SG_PRESENT = 1

**Auto-Fill** - Automatically populates fields when a trigger is matched
- Example: If SG_PRESENT = 0, set SG species fields to NA and SG_COVER to 0

**Calculated Field** - Automatically computes a field from a formula
- Example: OPEN = 100 - SG_COVER - AL_COVER - HC_COVER - ...

#### 3. Save Rules

Rules are automatically saved as `[template_name]_rules.json` in the same directory as your template.

#### 4. Rules Auto-Load

Next time you load the same template, your rules will automatically load!

### Validation Behavior

**When Saving Manually:**
- Rules checked when clicking "Save Entry"
- Invalid fields highlighted in red
- List of all errors shown
- Save is blocked until fields are corrected

**When Extracting Stills:**
- Rules checked during auto-save
- Extract + save is blocked until fields are corrected
- Invalid fields remain highlighted for correction

**When Navigating Entries:**
- Rules checked when moving between entries
- Navigation save is blocked until fields are corrected

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
- Relax/adjust rules for legitimate edge cases

**Need to disable validation temporarily:**
- Open Rules Manager and delete all rules
- Or temporarily disable/adjust strict rules

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

### Aggregated Export: Batch Method Editing

When using **Export Aggregated Data**, the **Aggregation Methods** dialog now supports batch editing:

- **Select all** checkbox
- **Batch method** dropdown
- **Apply to Selected** button
- **Apply to All** button

This is useful when setting many related species fields (for example all SG, AL, or HC subgroups) to the same method quickly.

### Template-Driven Percentage Group Handling

The save and export pipeline now applies your rules directly to row data before aggregation.

- If a `conditional_sum` rule uses `blank_as_zero = true` and its condition is met, missing subgroup values are set to `0`.
- If a subgroup condition (such as cover > 0) is not met, subgroup values are set to `NA`.
- Matching `autofill` rules are also applied before validation and export.

This means new templates with additional species groups work automatically as long as the rules are defined in the template rules JSON.

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