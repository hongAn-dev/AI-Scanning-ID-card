from PIL import Image

img = Image.new('RGBA', (1, 1), (0, 0, 0, 0))
img.save('assets/transparent.png')
print("Created assets/transparent.png")
