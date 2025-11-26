"""
Convert WebP images to actual JPEG format for Create ML compatibility.
The downloaded images are WebP format but named .jpg
"""
import os
from pathlib import Path
from PIL import Image
import sys

def convert_webp_to_jpg(root_dir):
    """Convert all .jpg files that are actually WebP to real JPEG"""
    
    root_path = Path(root_dir)
    converted = 0
    errors = 0
    
    print(f"🔍 Scanning {root_dir} for WebP images...")
    
    # Find all .jpg files
    jpg_files = list(root_path.rglob("*.jpg"))
    total = len(jpg_files)
    
    print(f"📦 Found {total:,} .jpg files to check")
    
    for i, jpg_file in enumerate(jpg_files, 1):
        try:
            # Try to open as image
            with Image.open(jpg_file) as img:
                # Check if it's actually WebP
                if img.format == 'WEBP':
                    # Convert to RGB (in case it has alpha channel)
                    if img.mode in ('RGBA', 'LA', 'P'):
                        img = img.convert('RGB')
                    
                    # Save as actual JPEG
                    img.save(jpg_file, 'JPEG', quality=95, optimize=True)
                    converted += 1
                    
                    if converted % 100 == 0:
                        progress = (i / total) * 100
                        print(f"⏳ Progress: {i:,}/{total:,} ({progress:.1f}%) - Converted: {converted:,}")
                        
        except Exception as e:
            errors += 1
            if errors <= 5:  # Only print first 5 errors
                print(f"❌ Error converting {jpg_file}: {e}")
    
    print(f"\n✅ Conversion complete!")
    print(f"   Converted: {converted:,} images")
    print(f"   Errors: {errors:,}")
    print(f"   Already JPEG: {total - converted - errors:,}")

if __name__ == "__main__":
    root_dir = "createml_training_data"
    
    # Check if PIL is available
    try:
        from PIL import Image
    except ImportError:
        print("❌ Pillow (PIL) not installed!")
        print("Installing Pillow...")
        os.system("pip3 install Pillow --user")
        print("\n✅ Pillow installed. Run this script again.")
        sys.exit(1)
    
    convert_webp_to_jpg(root_dir)
    print("\n🎉 All images ready for Create ML!")
