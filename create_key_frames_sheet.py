from PIL import Image, ImageDraw
import glob
import os
import math

folder = "assets/images/videos/key_frames"
files = sorted(glob.glob(os.path.join(folder, "frame_*.jpg")))

thumb_w, thumb_h = 100, 150
label_h = 24
columns = 8
rows = math.ceil(len(files) / columns)

sheet = Image.new(
    "RGB",
    (columns * thumb_w, rows * (thumb_h + label_h)),
    "white"
)
draw = ImageDraw.Draw(sheet)

for index, path in enumerate(files):
    with Image.open(path) as img:
        img.thumbnail((thumb_w - 6, thumb_h - 6))
        x = (index % columns) * thumb_w
        y = (index // columns) * (thumb_h + label_h)
        sheet.paste(img, (x + (thumb_w - img.width)//2, y))
        draw.text((x + 5, y + thumb_h), os.path.basename(path), fill="black")

output = "assets/images/videos/key_frames_contact_sheet.jpg"
sheet.save(output, quality=90)
print("Created:", output)
print("Frames:", len(files))
