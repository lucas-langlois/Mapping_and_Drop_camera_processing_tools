# MP4 Video Player & Frame Extractor

A feature-rich Windows application for playing MP4 videos and extracting frames.

## Features

✅ **Play/Pause Controls** - Spacebar or button to control playback  
✅ **Frame-by-Frame Navigation** - Use arrow keys (← →) to step through frames  
✅ **Timeline Slider** - Fast scrubbing through the video  
✅ **Speed Control** - Play at 0.25x, 0.5x, 1x, 2x, or 4x speed  
✅ **Export Current Frame** - Save any frame as PNG (press 'S' key or button)  
✅ **Batch Frame Extraction** - Extract frames at custom intervals  

## Installation

### 1. Install Python
Make sure you have Python 3.8 or higher installed on your Windows machine.

### 2. Install Dependencies

Open PowerShell in this directory and run:

```powershell
pip install -r requirements.txt
```

Or install individually:

```powershell
pip install opencv-python PyQt5 numpy
```

## Usage

### Running the Application

```powershell
python video_player.py
```

### Controls

- **Open Video**: Click "Open Video" button to select an MP4 file
- **Play/Pause**: Spacebar or "Play" button
- **Previous Frame**: ← (Left Arrow) or "◀ Frame" button
- **Next Frame**: → (Right Arrow) or "Frame ▶" button
- **Extract Frame**: 'S' key or "Extract Frame" button
- **Speed Control**: Dropdown menu (0.25x to 4x)
- **Batch Extract**: Set interval and click "Batch Extract"

### Extracting Frames

**Single Frame:**
1. Navigate to desired frame
2. Press 'S' or click "Extract Frame"
3. Frame saved to `[video_name]_frames/` folder

**Batch Extract:**
1. Set frame interval (e.g., 30 = every 30th frame)
2. Click "Batch Extract"
3. Frames saved to `[video_name]_batch_frames/` folder

## Output

Extracted frames are saved as PNG files in subdirectories next to your video file:
- Single frames: `[video_name]_frames/frame_000123_20251208_143052.png`
- Batch frames: `[video_name]_batch_frames/frame_000123.png`

## System Requirements

- Windows 10/11
- Python 3.8+
- 4GB RAM minimum
- Display resolution: 1280x720 or higher recommended

## Troubleshooting

**Video won't open:**
- Ensure the video codec is supported (most MP4, AVI, MOV files work)
- Try converting video with VLC or HandBrake

**Slow performance:**
- Reduce playback speed
- Close other applications
- Use lower resolution videos

**Missing modules error:**
- Reinstall dependencies: `pip install -r requirements.txt --upgrade`

## License

Free to use and modify for personal and commercial projects.
