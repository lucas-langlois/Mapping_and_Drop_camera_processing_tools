# Drop Cam Video Analysis Tool

A comprehensive video player application with integrated data entry for marine/environmental video analysis. Built specifically for analyzing drop camera footage with customizable data collection forms.

## Features

### Video Player
✅ **Play/Pause Controls** - Spacebar or button to control playback  
✅ **Frame-by-Frame Navigation** - Arrow keys (← →) to step through frames  
✅ **Skip Navigation** - Shift+Arrow (±10 frames), Ctrl+Arrow (±100 frames)  
✅ **Timeline Slider** - Fast scrubbing through video  
✅ **Variable Speed Control** - 0.25x to 12x playback speeds  
✅ **Auto-Load Video Queue** - Load multiple videos from `drop_videos/` folder  
✅ **Video Navigation** - Previous/Next video buttons for queue  

### Data Entry System
✅ **Customizable Form** - Load any CSV template to define data fields  
✅ **Auto-Population** - Pre-fill location/metadata from base CSV  
✅ **Smart Drop Numbering** - Sequential drop IDs based on POINT_ID  
✅ **Entry Navigation** - Browse and edit previous entries  
✅ **Auto-Save on Navigation** - Changes saved when moving between entries  
✅ **Still Image Integration** - Auto-create data entry when extracting frames  

### Frame Extraction
✅ **Single Frame Export** - Extract current frame with 'S' key  
✅ **Auto-Named Files** - `[video_name]_drop1.jpg`, `drop2.jpg`, etc.  
✅ **Batch Extraction** - Extract frames at custom intervals  
✅ **Organized Output** - All stills saved to `drop_stills/` folder  

## Installation

### Prerequisites
- Windows 10/11
- Python 3.8 or higher
- 4GB RAM minimum

### Setup

1. **Install Dependencies**
   ```powershell
   pip install -r requirements.txt
   ```
   
   Or install individually:
   ```powershell
   pip install opencv-python PyQt5 numpy
   ```

2. **Prepare Directory Structure**
   The application will create these folders automatically:
   - `drop_videos/` - Place your video files here
   - `drop_stills/` - Extracted still images
   - `data/` - CSV templates and data entries

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

1. **Load Videos**
   - Click "Load Videos from drop_videos/"
   - All videos in the folder are queued
   - Use Previous/Next Video buttons to navigate

2. **Extract and Annotate Stills**
   - Navigate to an interesting frame
   - Press 'S' or click "Extract Frame"
   - Still is saved and data entry form auto-populates with:
     - Location data (POINT_ID, LAT, LONG, DEPTH)
     - Timestamp (YEAR, DATE, TIME)
     - Drop ID (sequential: drop1, drop2, etc.)
     - Filename (auto-generated)

3. **Fill in Observation Data**
   - Enter substrate type, coverage percentages, etc.
   - Data auto-saves when you navigate or extract next still
   - All entries saved to `data/data_entries.csv`

4. **Review and Edit Entries**
   - Click "Load All Entries" to browse saved data
   - Use ◀ Previous Entry / Next Entry ▶ buttons
   - Edit any field - changes auto-save when navigating

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
    ├── data_entry_template.csv      # Your column definitions
    ├── Wuthathi_Subtidal_Nov25_data.csv  # Location metadata (optional)
    └── data_entries.csv             # Your collected data
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