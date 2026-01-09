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
            print(f"Original Size: {img.size}")
            print(f"Cropping to Valid Area: {bbox}")
            cropped = img.crop(bbox)
            
            # Save
            cropped.save(out_path, "PNG")
            print(f"Successfully cropped {path} to {out_path} (Size: {cropped.size})")
        else:
            print("Image is fully transparent!")
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    input_path = os.path.join("assets", "unnamed-removebg-preview.png")
    output_path = os.path.join("assets", "icon_optimized.png")
    
    print(f"Processing: {os.path.abspath(input_path)}")
    
    # Check if PIL is installed, if not try simple copy or warn
    try:
        crop_transparency(input_path, output_path)
    except ImportError:
        print("Pillow not installed. Please install pillow.")
