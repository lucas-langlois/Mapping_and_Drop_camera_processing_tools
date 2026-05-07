# Drop Cam Video Analysis - Detailed Tutorial

This tutorial will guide you through the complete workflow of using the Drop Cam Video Analysis tool for marine/environmental video annotation.

## Table of Contents
1. [Preparing Your Files](#preparing-your-files)
2. [First Launch Setup](#first-launch-setup)
3. [User Interface Layout Options](#user-interface-layout-options)
4. [Setting Up Validation Rules (QAQC)](#setting-up-validation-rules-qaqc)
5. [Field Groups](#field-groups)
6. [Loading Videos](#loading-videos)
7. [Video Zoom Feature](#video-zoom-feature)
8. [Extracting Stills and Entering Data](#extracting-stills-and-entering-data)
9. [Grab-Only Mode (No Video)](#grab-only-mode-no-video)
10. [Navigating and Editing Entries](#navigating-and-editing-entries)
11. [Project Save/Load](#project-saveload)
12. [Aggregated Export and Batch Methods](#aggregated-export-and-batch-methods)
13. [Interactive Map View](#interactive-map-view)
14. [Tips and Best Practices](#tips-and-best-practices)

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

### Step 2: Choose Project Type

A dialog appears: **"Start New Project or Load Existing?"**

**For First Time / New Survey:**
1. Click **"Start New Project"**
2. Continue to Step 3 below

**To Resume Previous Work:**
1. Click **"Load Existing Project"**
2. Select your project file from `projects/` folder
3. ✨ Everything loads automatically - skip to [Loading Videos](#loading-videos)!

### Step 3: Load Data Entry Template (New Projects Only)

1. A dialog appears: **"Load Data Entry Template"**
2. Click **OK**
3. Navigate to your `data/` folder
4. Select your template CSV (e.g., `data_entry_template.csv`)
5. Click **Open**

The application will read the column headers and create form fields for each one.

### Step 4: Load Base CSV (Optional, New Projects Only)

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

**💡 Pro Tip:** After loading your template and base CSV, immediately click **"💾 Save Project"** so you can quickly resume next time!

---

## User Interface Layout Options

The application offers two layout modes to suit your workspace setup.

### Single Window Mode (Default)

This is the standard layout when you first open the application:
- **Left side**: Video player with all controls
- **Right side**: Data entry form
- **Best for**: Single monitor setups, laptops

### Dual-Screen Mode (2+ Monitors)

Perfect for users with multiple monitors! Separates the video player and data entry into independent windows.

**To Enter Dual-Screen Mode:**

1. Look for the **⬌** button in the video control bar (orange colored)
2. Hover over it - tooltip says "Toggle Dual-Screen Mode"
3. Click the button
4. The data entry panel detaches into a new window
5. **If you have 2+ monitors**: The data entry window automatically appears on your second screen
6. **If you have 1 monitor**: The window opens to the right of the main window
7. The **⬌** button turns **green** (indicating detached mode)

**To Return to Single Window Mode:**

1. Click the **⬌** button again (now green)
2. OR close the detached data entry window
3. The data entry panel returns to the main window
4. Button turns **orange** again

**Recommended Setup for Dual Screens:**

- **Monitor 1 (Primary)**: Maximize the video player window
  - Large viewing area for video
  - Easy access to all playback controls
  - Timeline slider spans full width
  
- **Monitor 2 (Secondary)**: Position data entry window
  - Full visibility of all form fields (no scrolling!)
  - See all buttons and controls at once
  - Easy access to validation rules and copy buttons

**Benefits:**
- 🎯 **More screen real estate**: Both video and form fully visible
- ⚡ **Faster workflow**: No switching between video and form
- 👀 **Better visibility**: See entire form while watching video
- 📊 **Perfect for complex forms**: Many fields fully visible
- 🔄 **Synchronized** All data, rules, and state stay connected

**Note**: Both windows close together when you exit the application. Your layout preference is not saved - you'll default to single window on next launch.

---

## Setting Up Validation Rules (QAQC)

**Optional but highly recommended** - Set up data validation rules to ensure data quality and catch errors before they accumulate.

### What Are Validation Rules?

Validation rules automatically check your data for:
- Incorrect values (e.g., SG_PRESENT must be 0 or 1)
- Out-of-range numbers (e.g., DEPTH between 0-100)
- Missing required fields (e.g., POINT_ID cannot be empty)
- Logical inconsistencies (e.g., if SG_PRESENT=0, then SG_COVER must be 0)
- Incorrect totals (e.g., all cover percentages must sum to 100%)
- Cross-field consistency (e.g., if SG_COVER > 0 then RANK and RANK_TYPE must also be filled)

### Step 1: Open the Rules Manager

1. Click the **"⚙ Manage Validation Rules"** button (purple button in data entry pane)
2. The Validation Rules Manager window opens

### Step 2: Add Your First Rule

Let's create a simple rule to ensure SG_PRESENT is only 0 or 1:

1. Click **"+ Add New Rule"**
2. In "Rule Type" dropdown, select **"Allowed Values"**
3. In "Field" dropdown, select **"SG_PRESENT"**
4. In "Allowed Values" box, type: `0, 1`
5. In "Error Message" box, type: `SG_PRESENT must be 0 or 1`
6. Click **"Save Rule"**
7. The rule appears in the list: "1. SG_PRESENT must be one of: 0, 1"

### Step 3: Add a Conditional Rule

Now let's ensure that if SG_PRESENT is 0, then SG_COVER must also be 0:

1. Click **"+ Add New Rule"**
2. Select rule type: **"Conditional (If-Then)"**
3. Fill in the fields:
   - **If Field:** SG_PRESENT
   - **Equals:** 0
   - **Then Field:** SG_COVER
   - **Must Be:** Equal to
   - **Value:** 0
   - **Error Message:** If no seagrass is present, cover must be 0
4. Click **"Save Rule"**

And add the opposite rule (if present, cover must be > 0):

1. Click **"+ Add New Rule"**
2. Select rule type: **"Conditional (If-Then)"**
3. Fill in:
   - **If Field:** SG_PRESENT
   - **Equals:** 1
   - **Then Field:** SG_COVER
   - **Must Be:** Greater than
   - **Value:** 0
   - **Error Message:** If seagrass is present, cover must be greater than 0
4. Click **"Save Rule"**

### Step 4: Add a Range Rule

Ensure depth values are realistic:

1. Click **"+ Add New Rule"**
2. Select rule type: **"Numeric Range"**
3. Fill in:
   - **Field:** DEPTH
   - **Minimum Value:** 0
   - **Maximum Value:** 100
   - **Error Message:** Depth must be between 0 and 100 meters
4. Click **"Save Rule"**

### Step 5: Add a Sum Rule (Optional)

If you want to ensure all cover percentages sum to 100%:

1. Click **"+ Add New Rule"**
2. Select rule type: **"Sum Equals"**
3. Fill in:
   - **Fields to Sum:** SG_COVER, AL_COVER, HC_COVER, SC_COVER, OTHER_COVER, OPEN
   - **Must Equal:** 100
   - **Tolerance (+/-):** 0.5
   - **Error Message:** Total cover must equal 100%
4. Click **"Save Rule"**

### Step 6: Save and Close

1. Click **"Close"** button
2. Confirmation message shows: "Validation rules updated successfully! Total rules: X"
3. Rules are automatically saved as `[template_name]_rules.json`

### What Happens Now?

From now on, every time you:
- Click **"Save Entry"**
- Navigate between entries (Previous/Next)
- Extract a still (auto-save)

The system checks your data against these rules and:
- ✅ **If valid:** Saves normally
- ❌ **If invalid:** 
  - Highlights problem fields in **red**
  - Shows list of all errors
   - Blocks save/extract until issues are fixed

### Example Validation in Action

You extract a still and the form shows:
- SG_PRESENT: 1
- SG_COVER: 0 (you forgot to fill this in)

When navigating to next entry, you see:
```
❌ Validation Failed

• If seagrass is present, cover must be greater than 0
```

The SG_COVER field is highlighted in red. Correct the value to 30, then navigate - it saves successfully.

### Advanced: Conditional Sum & Auto-Fill

#### Conditional Sum (For Species Percentages)

If you need species percentages to sum to 100% only when seagrass is present:

1. Open Rules Manager
2. Add New Rule → **"Conditional Sum"**
3. Fill in:
   - **If Field:** SG_PRESENT
   - **Equals:** 1
   - **Then Sum of Fields:** CR, CS, HO, HD, HS, HU, SI, EA, TH, ZC
   - **Must Equal:** 100
   - **Tolerance:** 0.5
   - **Treat Blanks As:** 0 (zero) ← Users can leave absent species blank!
4. Save Rule

**What this does:**
- When SG_PRESENT = 1: Validates that species sum to 100% (blanks = 0)
- When SG_PRESENT = 0: Doesn't check the sum at all

#### Auto-Fill (Instant Population)

Save massive time by auto-filling fields based on conditions:

**Example: When No Seagrass Present**

1. Open Rules Manager
2. Add New Rule → **"Auto-Fill"**
3. Fill in:
   - **When Field:** SG_PRESENT
   - **Equals:** 0
   - **Then Set Fields:**
   ```
   SG_COVER=0, CR=NA, CS=NA, HO=NA, HD=NA, HS=NA, HU=NA, SI=NA, EA=NA, TH=NA, ZC=NA, EPI_COVER=NA
   ```
4. Save Rule

**What happens:**
1. You type `0` in SG_PRESENT
2. ✨ Instantly, all 12 fields auto-populate with correct values!
3. No more typing "NA" 10+ times per entry

**Auto-Fill Reset (clearing when trigger changes):**

Auto-fill works in both directions:
- Set SG_PRESENT → `0`: species fields fill with "NA", SG_COVER fills with 0
- Change SG_PRESENT → `1` (or clear it): the "NA" fills from the `=0` rule are cleared back to "" so you can enter real values
- If a second rule matches the new value (e.g., a rule for `SG_PRESENT = 1`), it fires and fills its own fields

This prevents stale "NA" values lingering in fields when you change your mind.

**Power Combo:** Conditional Sum + Auto-Fill = Fast entry + Quality control!

#### Dropdown Fields (Plain List)

Use a `dropdown` rule when you want a pick-list of text values **without** the numeric-style labels that `allowed_values` adds:

**Example: RANK_TYPE**

```json
{ "type": "dropdown", "field": "RANK_TYPE", "values": ["NA", "low", "high", "EA"] }
```

- The field renders as a combobox showing exactly `NA`, `low`, `high`, `EA`
- The selected value is stored as-is in the CSV (no label suffix)
- Combine with an `allowed_values` rule to also block invalid freeform entries if the user somehow bypasses the dropdown

#### Cross-Field (Conditional) Validation

Conditional rules can use comparison operators to validate consistency between related fields. This is useful for seagrass fields where `SG_COVER`, `RANK`, and `RANK_TYPE` must all agree:

**Example rules already configured in the NESP Subtidal templates:**

| Rule | Meaning |
|------|---------|
| `SG_COVER > 0` → `RANK > 0` | If cover is recorded, a rank must be assigned |
| `SG_COVER > 0` → `RANK_TYPE ≠ NA` | If cover is recorded, rank type must be set |
| `RANK_TYPE ≠ NA` → `SG_COVER > 0` | If rank type is set, cover must be > 0 |
| `RANK > 0` → `SG_COVER > 0` | If a rank is given, cover must be > 0 |

All six rules guard against any incomplete combination of the three fields, so if you fill in `SG_COVER = 30` but forget to set `RANK_TYPE`, the form highlights the inconsistency immediately.

### Tips for Validation Rules

**Start with essentials:**
- Required fields (POINT_ID, LOCATION)
- Critical conditional logic (presence/absence vs. cover)
- Obvious ranges (0-100 for percentages)

**Add more later:**
- After a few days of data entry, you'll discover more patterns
- Add rules for common mistakes you notice
- Share your rules file with team members

**Don't over-validate:**
- Avoid rules that are too strict for edge cases
- Use tolerances and practical ranges when needed
- Remember: you can always edit entries later

### Editing or Deleting Rules

1. Open Rules Manager again
2. Click on a rule in the list to select it
3. Click **"Edit Selected"** to modify
4. Click **"Delete Selected"** to remove
5. Changes save automatically

---

## Field Groups

For templates with many fields, **Field Groups** help you stay focused by filtering the data entry form to show only the fields in the current group.

### What Are Field Groups?

A field group is a named collection of fields — for example:
- **"Seagrass"** — SG_PRESENT, SG_COVER, CR, CS, HO, HD, HS, HU, SI, EA, TH, ZC, EPI_COVER
- **"Hard Coral"** — HC_COVER, HC_BRA, HC_DIG, HC_ENC, HC_COL, HC_FOL, HC_MAS, HC_SOL, HC_TAB
- **"Totals"** — OPEN, TOT_COVER, TOT_COVER_CAT_CHECK
- **"Metadata"** — POINT_ID, DATE, TIME, LATITUDE, LONGITUDE, DEPTH, SUBSTRATE, COMMENTS

Groups do not lock fields — you can still switch to "All fields" view and edit anything. Groups just reduce visual clutter when working on one section at a time.

### Creating Field Groups

1. Click the **"Manage Field Groups"** button in the data entry pane
2. The Field Groups Manager opens

**To create a new group:**
1. Click **"+ New Group"**
2. Enter a name (e.g., `Seagrass`)
3. In the field list on the right, tick the checkboxes for each field to include
4. Click **"Save Group"**

**To edit an existing group:**
1. Select the group in the left list
2. Tick/untick fields
3. Click **"Save Group"**

**To delete a group:**
1. Select the group in the left list
2. Click **"Delete Group"**

**To reorder groups:**
- Use the **↑ Up** / **↓ Down** buttons while a group is selected

### Using Field Groups During Data Entry

A **group selector dropdown** appears above the data entry form once at least one group is defined.

- Select a group to show only those fields
- Select **"All fields"** to return to the full form
- The current group is remembered while you navigate entries — only group changes reset the filter
- You can still use **◄ Copy All from Previous** and other buttons — they work on the full dataset regardless of which group is visible

### Groups File

Groups are saved automatically as `[template_name]_groups.json` in the same directory as your template CSV. Share this file with team members to give them the same group layout.

---

## Loading Videos

### Step 1: Set the Video Folder

Videos are no longer managed as a static queue. Instead, you point the app at a folder and videos load on demand as you navigate base CSV rows.

**Option A: Use the default `drop_videos/` folder**
1. Click the **"📁 Use drop_videos/"** button in the video controls
2. A confirmation message confirms the folder is set
3. The folder name appears in the status label next to the button

**Option B: Use a custom folder**
1. Click **"Choose Folder…"**
2. Browse to your video folder and click **OK**
3. The folder name updates in the status label

> **Note:** You only need to set the folder once per project — the path is saved automatically.

### Step 2: Navigate to a Row to Load a Video

With the video folder set and a base CSV loaded, use the row navigation buttons to step through your survey:

- **◀ Prev Row**: Go to the previous CSV row
- **Next Row ▶**: Go to the next CSV row
- **Go To Row…**: Jump directly to any row by number

The app matches the `VIDEO_FILENAME` column from the current row against files in the video folder. If a matching video is found, it loads automatically. If no match is found, a no-video placeholder is shown instead.

The status label shows your current position (e.g., `"3/152: Point ID003 | 🎥 Video"`) and the folder label confirms which folder is active.

### What Happens When a Video Loads

1. Video appears in the player window
2. Timeline slider shows video length
3. Frame counter shows: "Frame: 0 / [total frames]"
4. If you have a base CSV loaded:
   - Data entry form pre-fills with location data from the matching row
   - Drop counter shows the next sequential number for this POINT_ID

---

## Video Zoom Feature

The zoom feature helps you examine fine details in your video - crucial for identifying species, substrates, or small features.

### How to Access Zoom Controls

**Location**: In the video control bar, look for:
- Label: "Zoom:"
- Horizontal slider (between "Speed" and "Extract" buttons)
- Percentage display (shows current zoom level)

### Using the Zoom

**Step 1: Open a video**
- Zoom controls activate automatically when a video is loaded

**Step 2: Adjust zoom level**
- **Drag slider to the RIGHT** → Zoom IN (100% → 400%)
- **Drag slider to the LEFT** → Zoom OUT (100% → 50%)
- **Current level** displayed next to slider (e.g., "150%")

**Step 3: Navigate zoomed video**
- At zoom > 100%: Scrollbars appear automatically
- Click and drag the video to pan around
- OR use the scrollbars to navigate
- Video stays zoomed while you navigate frames

### Zoom Levels Guide

| Zoom Level | Best For |
|------------|----------|
| **50%** | Overview of entire scene |
| **100%** (default) | Normal viewing, general navigation |
| **150-200%** | Identifying substrate types, moderate detail |
| **250-350%** | Species identification, reading small text/numbers |
| **400%** | Maximum detail for tiny features, quality checks |

### Practical Example

**Scenario**: Identifying seagrass species in a dense meadow

1. Navigate to the frame showing seagrass
2. Zoom to **250%** using the slider
3. Scrollbars appear (video is now larger than viewport)
4. Click and drag to pan to the area of interest
5. Study the leaf shapes and structures in detail
6. Identify species with confidence
7. Zoom back to **100%** for next observation
8. OR keep zoom at 250% to examine next frame at same detail

### Zoom Tips

**✅ Do:**
- Set zoom level once, navigate frames normally - zoom persists
- Use high zoom (250-400%) for species ID, substrate texture
- Zoom to 100% for general navigation between points
- Combine with pause/frame-by-frame navigation (arrow keys)
- Zoom works at any playback speed

**⚠️ Note:**
- Higher zoom = smoother transformation (better quality)
- Lower zoom = faster transformation (better performance)
- Zoom applies to current frame and all subsequent frames until you change it

### Keyboard-Friendly Workflow

1. Find general area at 100% zoom (use arrow keys, timeline)
2. Press **←** or **→** to fine-tune frame position
3. Increase zoom to 200-300% using slider
4. Use click-and-drag to position the zoomed area
5. Fill in data entry form
6. Press **S** to extract still
7. Zoom resets are not automatic - manually return to 100% if desired

**Time Saver**: Leave zoom at a consistent level (like 150%) for an entire video if all observations need similar detail!

---

## Extracting Stills and Entering Data

This is the core workflow for data collection.

### ⚠️ **CRITICAL: Correct Workflow Order**

**The extract button ('S') does TWO things:**
1. 💾 Saves the data currently in the form
2. 📸 Captures the still image

**Therefore, you MUST fill in data BEFORE extracting!**

### ✅ **Correct Workflow:**
```
1. Find frame → Fill data → Press 'S' (saves + extracts)
2. Find frame → Fill data → Press 'S' (saves + extracts)
3. Find frame → Fill data → Press 'S' (saves + extracts)
```

### ❌ **Wrong Workflow:**
```
1. Find frame → Press 'S' → Fill data (saved with empty data!)
2. Find frame → Press 'S' → Fill data (saved with wrong data!)
```

**Memory aid:** Think of 'S' as "**S**ave and Snapshot" - it saves what's in the form, then takes a picture.

---

**Quick Start:**
1. Navigate to frame → Fill in data (or copy from previous) → Extract (saves + captures image)
2. Navigate to next frame → Fill in data (or copy from previous) → Extract (saves + captures image)
3. Repeat...

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

**🛑 STOP - Don't extract yet!**

### Step 2: Fill in Observation Data FIRST

The form is already pre-populated with metadata from base CSV:
- **POINT_ID**: From base CSV or video filename
- **LATITUDE, LONGITUDE, DEPTH**: From base CSV
- **YEAR, DATE, TIME**: Parsed from VIDEO_TIMESTAMP

**Now enter the observations for THIS frame:**

1. **LOCATION**: Location name (if not from base CSV)
2. **MODE**: Camera mode (if not from base CSV)
3. **SUBSTRATE**: Type of substrate (e.g., "Sand", "Coral rubble", "Rocky")
4. **SG_PRESENT**: Is seagrass present? (0 or 1)
   - If you type `0` → ✨ Auto-fill triggers! All species and EPI_COVER set to "NA", SG_COVER=0
   - If you type `1` → Enter SG_COVER and species percentages manually
5. **Coverage fields**: Enter percentages (SG_COVER, AL_COVER, HC_COVER, etc.)
6. **Species percentages**: CR, CS, HO, HD, HS, HU, SI, EA, TH, ZC (if SG_PRESENT=1)
7. **COMMENTS**: Any additional notes

### Step 3: NOW Extract to Save

1. **After filling in all the data**, press **'S'** (or click **"Extract Frame"**)
2. The following happens automatically:
   - Still image is saved to `drop_stills/` folder
     - Named: `[video_name]_drop1.jpg`
   - Data entry (with all the data you just entered) is saved to `data/data_entries.csv`
   - **DROP_ID** and **FILENAME** are auto-filled
   - Entry navigation shows: **"Entry 1 of 1"**
   - Form clears observation fields, keeps metadata
   - Confirmation message: "Frame saved to: [path]. Data entry auto-saved with DROP_ID: drop1"

**Important:** The extract button saves the data that's CURRENTLY in the form!

### Step 4: Navigate to Next Observation Point

1. Continue playing the video or navigate to the next observation point
2. **STOP at the frame** you want to capture
3. **The form is now cleared** (observation fields empty, metadata preserved)
4. Navigation shows: "Entry 1 of 1" (you've saved one entry so far)

### Step 5: Fill Data for Drop 2 (Use Copy for Speed! ⚡)

**If Drop 2 has similar conditions to Drop 1**, use the copy feature:

1. Click **"◄ Copy All from Previous Entry"**
2. ✨ All observation fields copy from drop1:
   - SUBSTRATE ✓
   - SG_PRESENT, SG_COVER ✓
   - All species percentages ✓
   - COMMENTS ✓
3. **DROP_ID and FILENAME stay unique** (will be drop2 when you extract!)
4. Adjust any fields that are different:
   - Change SG_COVER from 45 to 50
   - Modify species percentages
   - Update COMMENTS
5. **Time saved: 75%!** (30 seconds instead of 2 minutes)

**Alternative: Copy Individual Fields**

If only some fields are similar:
- Click **◄** button next to SUBSTRATE → Copies "Sand with coral rubble"
- Click **◄** next to SG_PRESENT → Copies "1"
- Enter new species data manually

**Or Enter Fresh Data:**

If conditions are completely different:
- Just type in all fields manually
- Use auto-fill if SG_PRESENT=0 (auto-fills species with NA)

### Step 6: Extract to Save Drop 2

1. **After filling/copying data**, press **'S'** to extract
2. The system:
   - Saves the still as `_drop2.jpg`
   - Saves the data entry with DROP_ID: drop2
   - Clears observation fields for next drop
   - Navigation shows: "Entry 2 of 2"

### Step 7: Repeat for All Drops

**For Drop 3:**
1. Navigate to frame
2. Copy from previous (if similar) OR enter fresh data
3. Extract to save
4. Repeat...

**For Last Drop:**
After extracting the final frame of the video, fill in its data then either:
- Click **"Save Entry"** manually
- Or extract another frame (which saves the last drop)
- Or advance to the next row (which auto-saves current data)

### Workflow Summary

```
🎬 DROP 1:
├─ Navigate to frame
├─ Fill in all data (LOCATION, MODE, SUBSTRATE, SG_PRESENT, species, etc.)
└─ Press 'S' → Saves drop1 + extracts image

🎬 DROP 2:
├─ Navigate to frame  
├─ Click "◄ Copy All from Previous" → Instantly fills most fields
├─ Adjust differences (change SG_COVER, update species, etc.)
└─ Press 'S' → Saves drop2 + extracts image

🎬 DROP 3:
├─ Navigate to frame
├─ Copy from previous OR enter: SG_PRESENT=0 → Auto-fill triggers!
├─ Adjust SUBSTRATE and COMMENTS
└─ Press 'S' → Saves drop3 + extracts image

Repeat until video complete!
```

### Step 5: Save the Last Drop

**Important:** After extracting your last frame, its data is in the form but NOT saved yet!

**Option A: Extract a dummy frame**
- Navigate to any frame
- Press 'S' → Saves the last drop's data

**Option B: Manual save**
- Click **"Save Entry"** button
- Confirm: "Data entry saved"

**Option C: Auto-save on row navigation**
- Click **"Next Row ▶"** 
- Current data is auto-saved before the next row loads

### Step 6: Move to the Next Point

1. Click **Next Row ▶** when finished with current video
2. Current data is auto-saved (if any)
3. If the next row has a video file, it loads automatically
4. **Drop counter continues** if the new video shares the same POINT_ID
   - Example: Point 5, Video A had drop1 and drop2 → Video B (same Point 5) starts at drop3
   - The counter looks at all entries with that POINT_ID regardless of which video they came from
5. **Drop counter resets to 1** if the new row has a different POINT_ID
6. Form pre-fills with new row’s metadata
7. Ready to start with the new video’s first drop!

---

## Grab-Only Mode (No Video)

For sampling points where you have a **grab photo** (still image taken in the field) but no drop camera video.

### When to Use

- Transects where no video was recorded but a physical sample or photo was taken
- Any row in the base CSV that has a `GRAB_FILENAME` but no `VIDEO_FILENAME`

---

### Step 0: Set Up the Grab Photos Folder (One-Time)

Before grab photos will display, tell the app where they are stored.

1. Click the **"📁 Set Folder"** button (near the video area)
2. Browse to the folder containing your grab photos
3. Click **OK**

The folder path is saved in your project file, so you only need to do this once per project. When you load a project that has a grab photos folder saved, it restores automatically.

> **If you see a blue screen that says "PHOTOS AVAILABLE – click 📁 Set Folder"**, that means the app found photo references in the CSV but doesn't know where the folder is yet. Click the button and select the folder.

**GRAB_FILENAME formats supported:**

| Format | How it works |
|--------|-------------|
| `photo1.jpg;photo2.jpg;photo3.jpg` | Semicolon-separated list — each filename is looked up directly |
| `photo_01.jpg` | Numbered single file — app auto-discovers `photo_02.jpg`, `photo_03.jpg`, … from the same folder |
| `photo.jpg` | Plain single file |

---

### Step 1: Navigate to the Point

Use the **◀ Prev Row** / **Next Row ▶** buttons to navigate to the grab-only row in the base CSV. The status bar shows the row number and POINT_ID.

### Step 2: Inline Photo Viewer

When the row has no video and photos are available, the **video area automatically switches to the inline photo viewer**:

- The grab photo fills the video viewport directly — no popup, no extra click
- If the point has **multiple photos**, a **Photo Navigation Bar** appears between the video info label and the timeline area, showing:
  - **◄ Prev Photo** button
  - **Photo X / N** counter
  - **Next Photo ▶** button
- Use Prev/Next Photo to browse all photos for that point
- All video controls (play, timeline, extract) are disabled while viewing grab photos

**What the video area shows depending on the situation:**

| Situation | Display |
|-----------|---------|
| Photos found and folder set | Photo fills viewport; nav bar shown if >1 photo |
| Photos in CSV but folder not set | Blue "PHOTOS AVAILABLE — click 📁 Set Folder" screen |
| No GRAB_FILENAME or no match in folder | Black "NO VIDEO" screen |

### Step 3: The Form Switches Automatically

When the row has no video and has a `GRAB_FILENAME`, the form enters grab-only mode automatically:
- **DROP_ID** is set to `grab1` (or the next grab number for that point)
- **FILENAME** is set from the `GRAB_FILENAME` column of the base CSV
- **GRAB_ONLY** dropdown shows `1 — Yes`

> **Tip:** You can also manually toggle grab mode by changing the `GRAB_ONLY` dropdown from `0 — No` to `1 — Yes` while viewing any point. The DROP_ID and FILENAME update immediately.

### Step 4: Fill in Observations

Enter observations as normal. Auto-fill rules still apply — for example, if `SG_PRESENT = 0`, species fields auto-fill with NA.

### Step 5: View Grab Photos on Video+Grab Points

For points that have **both** a video and grab photos, a **"View Grab Photo"** button appears in the data entry area. Clicking it opens a popup dialog:

- The photo (or photos) are shown in a scrollable image area
- If multiple photos exist, **◄ Prev Photo** and **Next Photo ▶** buttons and a counter appear
- A filename caption shows which file is currently displayed
- Click **Close** when done — the video is unaffected

### Step 6: Save — Auto-Advance Prompt

1. Click **"Save Entry"**
2. After saving, a dialog appears:
   > **"Advance to the next row now?"**
   - **Yes** → immediately loads the next row in the base CSV
   - **No** → stays on the same row (useful if you want to enter a second grab for the same spot)

### Grab DROP_ID Numbering

- Grab entries use a separate prefix: `grab1`, `grab2`, etc.
- Grab numbers are counted independently of `drop1`, `drop2` entries
- Changing `GRAB_ONLY` live re-calculates the correct prefix and number instantly

---

## Navigating and Editing Entries

After collecting data, you may want to review or edit previous entries.

### Step 1: Load All Entries

1. Click the **"Load All Entries"** button (orange button in data entry pane)
2. The system loads all rows from `data/data_entries.csv`
3. Entry counter shows: `"Entry 1 of X"` where X is total entries
4. The form displays the last entry’s data, ready to view

### Step 2: Navigate Through Entries

Use the navigation buttons at the top of the data entry pane:

- **◀ Previous Entry** — go back one entry (or, from the new entry form, step into the saved entries)
- **Next Entry ▶** — go forward one entry; from the last saved entry, steps back to the new entry form
- **Entry X of Y / New entry** — shows your current position
- **🔍 Browse Entries** — (green button) open a searchable list of all saved entries; click any row to jump directly to it

**The new entry form is always reachable:**  
The Next ▶ button is enabled even when you are on the last saved entry. One more press returns to the new entry form.

### Step 3: Draft Buffer — No Lost Work

When you are on the new entry form (fields partially filled) and click ◀ Previous Entry:
- The app automatically **snapshots your current form** (the draft)
- You can browse and edit saved entries freely
- When you click Next ▶ back to the new entry form, **every field is restored exactly as you left it**
- The draft is discarded only when you commit a new entry (extract or save)

**Browse Entries also preserves your draft:**  
If you click 🔍 Browse Entries while the new entry form has partially filled data, the draft is captured before the dialog opens. Returning via Next ▶ restores everything.

### Step 4: Edit Saved Data

1. Navigate to the entry you want to fix
2. Click into any field and change the value
3. An asterisk (*) appears in the position label: `"Entry 2 of 10 *"`
4. Navigate away — changes **auto-save** immediately
5. Or click **"Save Entry"** to save manually

> **Validation blocks saving:** If a field fails a validation rule, the save is blocked and the problem field is highlighted in red. Fix the value, then navigate or save again.

### Step 5: Navigating Rows While Editing a Saved Entry

If you clicked ◀ Previous Entry to review an older drop and made a correction, then want to move to the next video row:

- Click **Next Row ▶** (or Prev Row, or Go To Row…)
- The app **auto-saves your edits** to the current entry first
- If the entry fails validation, the row navigation is **blocked** — you must fix the error before leaving
- Once the edits are saved, the new row loads in clean new-entry mode

This prevents blank or corrupt rows from being written to the CSV when switching rows after browsing old entries.

### Step 6: Resuming the New Entry After Reviewing

Full workflow for review-then-resume:

```
[Working on new entry for Row 8, filled in SUBSTRATE]
↓ Click ◀ Previous Entry
   Draft saved. Entry 7 loads.
↓ Review / fix Entry 7
   Entry 7 auto-saves when you navigate away.
↓ Click Next Entry ▶ (as many times as needed to reach the new entry form)
   New entry form restored: SUBSTRATE field still shows your value.
↓ Continue filling in data and extract.
```

### Step 7: Manual Save (Optional)

1. Click **"Save Entry"** button
2. Confirmation: "Entry updated successfully."

---

## Project Save/Load

Save your entire project state and resume exactly where you left off — perfect for multi-day field work!

### What Gets Saved in a Project?

When you save a project, it stores:
- ✅ Data entry template path
- ✅ Path to the base CSV file (the file is always re-read fresh from disk on load)
- ✅ Current row index (so Prev/Next Row buttons are immediately active)
- ✅ Current video and frame position
- ✅ Drop counter state
- ✅ All validation rules
- ✅ Current entry index
- ✅ **Grab photos folder path** (restored automatically so photos display immediately)

> **Why re-read the base CSV from disk?**  
> The base CSV is not embedded in the project file. Instead, the path is saved. When you load the project, the app reads the file fresh from disk — so any corrections you made to the CSV (e.g., fixing a GPS coordinate) are automatically picked up without needing to reload manually.

### Starting a New Project

1. Launch the application: `python video_player.py`
2. Startup dialog: **"Start New Project or Load Existing?"**
3. Click **"Start New Project"**
4. Load your data entry template, then base CSV
5. Load videos: click **"📁 Use drop_videos/"** or set a custom folder
6. Immediately click **"💾 Save Project"** so you have a restore point

### Saving Your Project

**Manual Save (Recommended):**

1. Click **"💾 Save Project"** button (top of window)
2. Choose a location and filename (e.g., `Wuthathi_Nov2025.json`)
3. Project saved to `projects/` folder

**Auto-Save on Close:**

- When you close the app, it automatically offers to save your project
- If you already have a named project loaded, it auto-saves without prompting

### Loading an Existing Project

1. Launch the application
2. Startup dialog: **"Start New Project or Load Existing?"**
3. Click **"Load Existing Project"**
4. Select your project file from the `projects/` folder
5. ✨ Everything restored:
   - Template and validation rules loaded
   - Base CSV re-read fresh from disk — latest version picked up automatically
   - Row navigation position restored — Prev/Next Row buttons active immediately
   - Nav label shows: `"5/152: Point ID005 — resumed"` (exact row, not generic "Ready")
   - Video folder restored; current video opened at exact frame
   - Drop counter set correctly from existing entries
   - All previous entries loaded
   - **Grab photos folder restored** — photos display immediately for no-video points
   - If the project was saved before the grab photos folder feature was added, a prompt asks you to set it once
   - Ready to continue!

### Example Workflow

**Day 1 — Morning Session:**
```
9:00 AM — Start new project “Survey_Jan2025”
9:05 AM — Load template and base CSV
9:10 AM — Process points 1–10 (grabs + drops)
11:30 AM — Click “Save Project”
11:31 AM — Close app for lunch
```

**Day 1 — Afternoon Session:**
```
1:00 PM — Launch app
1:01 PM — Load “Survey_Jan2025” project
1:02 PM \u2014 Row nav label shows “10/152: Point ID010 — resumed”
1:02 PM — Video opens at exact frame; ready for next drop
1:05 PM \u2014 Continue processing from Row 11
3:30 PM — Save project and close
```

**Benefits:**
- No re-entering template or base CSV paths
- No re-loading video folder
- Base CSV updates (GPS fixes, etc.) picked up automatically
- Instant resume with correct point position
- Perfect continuation of drop numbering

### Project File Location

Projects are saved in: `projects/[your_project_name].json`

**Tip:** Back up your project files regularly along with your `data_entries.csv`!

---

## Aggregated Export and Batch Methods

When field-level data entry is complete, use aggregated export to produce one summary row per Site/Point.

### Step 1: Open aggregated export

1. Click **"Export Aggregated Data"** in the data panel
2. The **Aggregation Methods** dialog opens

### Step 2: Review or batch-edit methods

You can edit methods one field at a time, or apply one method to many fields at once:

1. Tick the field checkboxes you want to change
2. Choose a method in **Batch method**
3. Click **Apply to Selected**
4. Use **Select all** + **Apply to Selected** (or **Apply to All**) for global changes

### Step 3: Confirm export

1. Click **OK** to export
2. The app writes:
   - Aggregated CSV (`data_entries_aggregated_YYYYMMDD_HHMMSS.csv`)
   - Shapefile outputs (when lat/lon are valid and pyshp is available)

### Rule-driven normalization (important)

Before validation and aggregation, the app applies template rules to keep subgroup percentages consistent:

- Matching **Auto-Fill** rules are applied first
- **Conditional Sum** rules with `blank_as_zero = true` fill missing subgroup values as `0` when the condition is met
- For cover-driven subgroups where the condition is not met (for example cover `<= 0`), subgroup values are normalized to `NA`

This is template-driven, so new species groups work without code changes as long as the rules are configured.

---

## Interactive Map View

Visualize all your sampling points on an interactive satellite map — with **live colour-coded progress tracking**!

### Opening the Map

1. Ensure you have base CSV loaded (with LATITUDE and LONGITUDE columns)
2. Click **"🗺 Show on Map"** button (next to Save Project)
3. Map window opens showing all your points

### 4-Colour Progress Status

Each point is coloured according to your current data collection progress:

| Marker | Meaning |
|--------|---------|
| 🟠 **Amber** (larger circle) | Current active point |
| 🟢 **Dark green** | At least one entry with `SG_PRESENT = 1` (seagrass found) |
| ⚪ **White** | Entry exists — all `SG_PRESENT = 0` or NA (no seagrass) |
| 🔵 **Blue** | Not yet entered |

The status is computed from your saved entries every time you open the map, so progress is always up to date.

### Map Features

**Satellite Basemap:**
- High-resolution Esri World Imagery
- Perfect for verifying sampling locations
- Shows reef structures, seagrass beds, coastal features

**Point Markers:**
- Colour-coded circles (see table above)
- Permanent white labels showing Point IDs next to each marker
- Current point rendered larger so it stands out at a glance

**Interactive Popups:**

Click any marker to see detailed information:
- Point ID
- Latitude and Longitude (6 decimal precision)
- Location name, Depth, Date, Substrate, Camera mode
- (All available metadata from base CSV)

**Legend:**
Bottom-right corner explains all four colours.

### Navigation

- **Pan**: Click and drag the map
- **Zoom**: Mouse wheel or +/− buttons
- **Centre**: Map automatically centres on the current active point when opened

### Use Cases

**Progress Tracking:**
- See at a glance which points are complete (green/white), in progress (amber), or pending (blue)
- Plan the most efficient order to work through remaining points
- Share a screenshot with team members for status updates

**Quality Control:**
- Verify GPS coordinates are in the expected area
- Spot obvious coordinate errors (points in wrong location)
- Confirm spatial coverage of your survey

### Requirements

- `POINT_ID`, `LATITUDE`, `LONGITUDE` columns in base CSV (WGS84 decimal degrees)
- PyQtWebEngine installed: `pip install PyQtWebEngine`
- Internet connection (map tiles load from Esri servers)

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

**Speed Method (NEW - Recommended!):** ⚡
1. Extract first still and enter all observations (2 min)
2. Extract second still
3. Click **"◄ Copy All from Previous"** (5 seconds)
4. Adjust only what's different (15-30 seconds)
5. Repeat for similar drops → **Save 67% of time!**
6. Use auto-fill rules for common scenarios (e.g., no seagrass = instant NA fill)

**Multi-Day Method (With Project Save/Load):** 💾
1. Day 1: Start new project, load template/base CSV
2. Save project immediately (💾 Save Project button)
3. Process videos throughout the day
4. Save project before closing
5. Day 2: Load existing project → Resume instantly at exact frame!
6. Continue processing, save periodically
7. No need to reload anything - instant resume!

### Data Quality Tips

1. **Set up validation rules early** ⭐
   - Define rules before starting bulk data entry
   - Start with critical fields (required, allowed values, ranges)
   - Add conditional rules for logical consistency
   - **Add auto-fill rules for common patterns** (e.g., SG_PRESENT=0 → all species=NA)
   - **Add conditional sum rules** for percentage validations
   - Test rules with a few sample entries first

2. **Be consistent with codes/categories**
   - Decide on substrate codes beforehand (e.g., "Sand" vs "sand" vs "S")
   - Use validation rules to enforce allowed values
   - Keep a reference sheet nearby

3. **Use decimal precision for percentage fields** 🔢
   - Fields like SG_COVER, AL_COVER support decimals (e.g., 0.7, 33.3, 66.6)
   - **Important**: If using decimals, set calculated field rules to `decimals: 1` or higher
   - With `decimals: 0`, value 0.7 → OPEN calculates as 99 → Sum = 99.7 ≠ 100 ❌
   - With `decimals: 1`, value 0.7 → OPEN calculates as 99.3 → Sum = 100.0 ✓
   - Use tolerance in sum rules (e.g., 0.5) to handle minor rounding differences
   - Example: `{"type": "calculated", "target_field": "OPEN", "formula": "100 - SG_COVER - AL_COVER", "decimals": 1}`

4. **Leverage helpful tooltips** 💡
   - Every button has a tooltip - hover your mouse to see descriptions
   - Forgot what a button does? Just hover over it!
   - Especially useful for icon-only buttons (💾, 🗺, ❓, ⬌, etc.)
   - Tooltips appear with dark background and white text for easy reading

5. **Take advantage of dual-screen mode** 🖥️🖥️
   - If you have 2+ monitors, click the ⬌ button
   - Maximize video player on one screen
   - Full data entry form on second screen
   - Eliminates constant scrolling and window switching
   - ~20-30% workflow efficiency gain from better visibility

6. **Use Field Groups for complex templates** 📋
   - If your template has 40+ fields, create named groups (e.g., "Seagrass", "Hard Coral", "Totals")
   - Select a group before starting a section to hide unrelated fields
   - Switch to "All fields" any time you need to review everything
   - Share the `_groups.json` file with team members for consistent layout

7. **Use zoom strategically** 🔍
   - Set zoom level based on task (100% for navigation, 200-300% for ID)
   - Zoom persists across frames - set once for entire video if needed
   - Critical for species identification, substrate characterization
   - Combine with frame-by-frame (arrow keys) for detailed examination

7. **Use COMMENTS field liberally**
   - Note unusual features
   - Record uncertainties
   - Flag entries that need review

8. **Check your data periodically**
   - Click "Load All Entries" and browse through
   - Look for blank fields or typos
   - Watch for red-highlighted fields (validation warnings)
   - Verify coverage percentages add up correctly

9. **Pay attention to validation warnings**
   - Red highlights indicate rule violations
   - Fix issues immediately (invalid entries are blocked)
   - If rules block valid field scenarios, revise the rule
   - Use validation errors to identify systematic mistakes

10. **Use "Copy from Previous" for similar drops** ⚡
   - Process all drops from one video in sequence
   - Use **"◄ Copy All from Previous Entry"** when conditions are similar
   - Always review and adjust copied values - don't blindly copy!
   - Combine with auto-fill: copy all → change trigger field → auto-fill handles rest
   - **Time saved:** 10 drops × copy feature = 13.5 min saved (67% faster!)

7. **Backup your data**
   - `data/data_entries.csv` is your master file
   - Copy it regularly to another location
   - Consider version control (name it with date: `data_entries_2025-12-09.csv`)
   - Back up your `_rules.json` file too (your validation setup)
   - Save your project file (`projects/*.json`) for easy resume

8. **Use the map view for quality control** 🗺️
   - Click **"🗺 Show on Map"** to visualize all sampling points
   - Verify GPS coordinates are in the correct area
   - Spot obvious errors (points in wrong location/ocean)
   - Check spatial coverage of your survey
   - Red marker shows which point you're currently working on
   - Great for progress tracking and spatial planning

9. **Save your project frequently** 💾
   - Click **"💾 Save Project"** at regular intervals
   - Especially before lunch breaks or end of day
   - Auto-saves on close, but manual saves give peace of mind
   - Resume exactly where you left off next session
   - No need to reload videos, templates, or navigate to position

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

### 🎯 **Workflow Reminder:**

```
1. Navigate to frame (arrow keys, play/pause)
2. Fill in data (type observations OR copy from previous)
3. Press 'S' to extract (saves data + captures image)
4. Repeat!
```

**⚠️ Remember:** Press 'S' AFTER filling data, not before!

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

**Validation rules too strict:**
- Open Rules Manager and review your rules
- Edit rules to add tolerance (for sum rules)
- Delete problematic rules temporarily
- Relax conditions for legitimate edge cases

**Validation rules not loading:**
- Check that `[template_name]_rules.json` exists in `data/` folder
- Verify the rules file name matches your template name
- Try recreating rules in Rules Manager

**Fields stuck with red highlights:**
- Fix the validation error (check error message)
- Or clear the form and reload the entry
- Red highlights clear when you fix the issue or navigate away

---

## Example Workflow Session

Here's a complete example of analyzing 3 videos:

### Setup (One-time)
1. Copied 3 videos to `drop_videos/`
2. Created template with 15 columns
3. Created base CSV with metadata for 3 videos
4. Launched app, loaded template and base CSV
5. Set the video folder with **"📁 Use drop_videos/"**
6. Set up 8 validation rules:
   - SG_PRESENT allowed values: 0, 1
   - SG_COVER range: 0-100
   - Conditional: If SG_PRESENT=0, then SG_COVER=0
   - Conditional: If SG_PRESENT=1, then SG_COVER>0
   - POINT_ID required
   - **Auto-fill:** When SG_PRESENT=0, set all species and EPI_COVER=NA
   - **Conditional Sum:** When SG_PRESENT=1, species must sum to 100%
   - Sum rule: all cover fields must equal 100%

### Video 1 Analysis (POINT_ID=1)
1. Clicked **Next Row ▶** to navigate to row 1
2. Video 1 loads, form pre-fills with LAT/LONG/DEPTH from base CSV
3. Watched video at 2x speed to identify observation points

**Drop 1 (at 00:30 - interesting substrate):**
4. Paused at frame 450
5. **Filled in data FIRST:**
   - LOCATION="Shelbourne Bay", MODE="Drop-Cam"
   - SUBSTRATE="Sand with coral rubble"
   - SG_PRESENT=1, SG_COVER=30
   - Species: CR=40, HO=35, HS=25
   - COMMENTS="Good visibility"
   - Time: 2 minutes
6. **Pressed 'S' to extract** → Saves drop1 + extracts `Video1_drop1.jpg`
7. Form clears observation fields, keeps metadata

**Drop 2 (at 01:15 - similar area with more seagrass):**
8. Navigated to frame 890
9. **Clicked "◄ Copy All from Previous Entry"**
10. ✨ All fields copied: LOCATION, MODE, SUBSTRATE, SG_PRESENT, species, COMMENTS
11. **Adjusted differences:**
    - SG_COVER: 30 → 60
    - Species: 40/35/25 → 30/40/30
    - Time: 30 seconds ⚡
12. **Pressed 'S' to extract** → Saves drop2 + extracts `Video1_drop2.jpg`

**Drop 3 (at 02:00 - rocky area, no seagrass):**
13. Navigated to frame 1200
14. **Clicked ◄** next to LOCATION → Copied "Shelbourne Bay"
15. **Clicked ◄** next to MODE → Copied "Drop-Cam"
16. **Entered:** SUBSTRATE="Rocky", SG_PRESENT=0
17. ✨ **Auto-fill triggered!** All species → "NA", EPI_COVER → "NA", SG_COVER → 0
18. COMMENTS="Rocky substrate, no vegetation"
19. Time: 45 seconds ⚡
20. **Pressed 'S' to extract** → Saves drop3 + extracts `Video1_drop3.jpg`

**Drop 4 & 5 (similar to drop 2):**
21. For each drop:
    - Navigate to frame
    - Copy all from previous
    - Minor adjustments
    - Extract (saves)
    - Time: ~30 seconds each ⚡

**Total:** 5 drops in ~7 minutes (vs 10 minutes without copy/auto-fill features)
**Time saved: 30%!** 🎉

### Video 2 Analysis (POINT_ID=1, same location)
1. Clicked **Next Row ▶** (to the second video row for this point)
2. Form pre-fills with same LAT/LONG/DEPTH
3. **Drop counter shows drop6** (continues from Video 1)
4. Extracted 3 more drops → `Video2_drop6.jpg`, `Video2_drop7.jpg`, `Video2_drop8.jpg`
5. Total for POINT_ID=1: 8 drops across 2 videos

### Video 3 Analysis (POINT_ID=2, different location)
1. Clicked **Next Row ▶** to advance to the next row
2. Form pre-fills with different LAT/LONG/DEPTH
3. **Drop counter resets to drop1** (new POINT_ID)
4. Extracted 4 drops for this location

### Review Session (Next day)
1. Clicked "Load All Entries"
2. Browsed through all 12 entries
3. Found validation warning on drop3 (SG_COVER field highlighted red)
   - Error: "If seagrass is present, cover must be greater than 0"
   - Changed SG_COVER from 0 to 15
   - Red highlight cleared automatically
4. Corrected a typo in substrate field
5. Added more detailed comments to drop7
6. All changes auto-saved with validation passing

### Final Output
- 12 still images in `drop_stills/`
- 12 data rows in `data/data_entries.csv`
- Ready for analysis in Excel, R, or Python!

---

## Next Steps

Now that you know how to use the tool:

1. **Test with a sample video** - Extract a few drops to practice the workflow
2. **Customize your template** - Add/remove fields as needed
3. **Set up validation rules** - Define QAQC rules for data quality
4. **Set up your base CSV** - Gather GPS coordinates and metadata
5. **Start your analysis** - Process all your videos systematically
6. **Review with validation** - Use "Load All Entries" to check for validation warnings
7. **Export your data** - Open `data_entries.csv` in Excel for analysis

**Pro Tip:** Share your template, base CSV, and rules JSON file with team members to ensure everyone uses the same data structure and quality standards!

Happy analyzing! 🌊🎥📊
