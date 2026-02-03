"""
Build script to create standalone .exe for Video Player
Run this script to create a distributable executable
"""

import PyInstaller.__main__
import os
import shutil

# Get the directory of this script
script_dir = os.path.dirname(os.path.abspath(__file__))
video_player_path = os.path.join(script_dir, 'video_player.py')

# Clean up old build artifacts
print("Cleaning up old build files...")
build_dir = os.path.join(script_dir, 'build')
dist_dir = os.path.join(script_dir, 'dist')
spec_file = os.path.join(script_dir, 'VideoPlayer.spec')

if os.path.exists(build_dir):
    print(f"  Removing: {build_dir}")
    shutil.rmtree(build_dir, ignore_errors=True)

if os.path.exists(dist_dir):
    print(f"  Removing: {dist_dir}")
    shutil.rmtree(dist_dir, ignore_errors=True)

if os.path.exists(spec_file):
    print(f"  Removing: {spec_file}")
    os.remove(spec_file)

print("Clean complete!\n")

# PyInstaller arguments
PyInstaller.__main__.run([
    video_player_path,
    '--name=VideoPlayer',
    '--onefile',
    '--windowed',  # No console window
    '--icon=NONE',  # You can add an icon file here if you have one
    '--hidden-import=cv2',
    '--hidden-import=PyQt5',
    '--hidden-import=numpy',
    '--collect-all=cv2',
    '--collect-all=PyQt5',
    '--noconsole',
])

print("\n" + "="*60)
print("Build complete!")
print("="*60)
print(f"\nExecutable created in: {os.path.join(script_dir, 'dist', 'Video_processing_app.exe')}")
print("\nYou can distribute this .exe file to any Windows computer.")
print("The drop_videos and drop_stills folders will be created automatically.")
