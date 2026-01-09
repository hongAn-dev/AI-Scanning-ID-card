from PIL import Image
import os
import sys

def crop_transparency(path, out_path):
    try:
        img = Image.open(path)
        img = img.convert("RGBA")
        datas = img.getdata()

        newData = []
        for item in datas:
            if item[3] == 0:
                newData.append((255, 255, 255, 0)) # Make sure transparent is consistent
            else:
                newData.append(item)
        
        img.putdata(newData)
        
        # GetBoundingBox returns box of non-zero regions
        bbox = img.getbbox()
        if bbox:
            cropped = img.crop(bbox)
            # Add a small padding (optional, but good for Apple icons not to touch edge)
            # Actually user wants "Zoom 200%", so NO padding is best to fill the square.
            cropped.save(out_path, "PNG")
            print(f"Successfully cropped {path} to {out_path}")
        else:
            print("Image is fully transparent!")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    input_path = os.path.join("assets", "unnamed-removebg-preview.png")
    output_path = os.path.join("assets", "icon_optimized.png")
    
    # Check if PIL is installed, if not try simple copy or warn
    try:
        crop_transparency(input_path, output_path)
    except ImportError:
        print("Pillow not installed. Please install pillow.")
