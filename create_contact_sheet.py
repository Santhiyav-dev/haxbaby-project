from PIL import Image, ImageDraw
import os

folder = "assets/images/pip"
names = ["center.png"] + [f"dir_{i}.png" for i in range(16)]

thumb_w, thumb_h = 136, 204
label_h = 28
columns = 4
rows = 5

sheet = Image.new(
    "RGB",
    (thumb_w * columns, (thumb_h + label_h) * rows),
    "white"
)

draw = ImageDraw.Draw(sheet)

for i, name in enumerate(names):
    path = os.path.join(folder, name)

    with Image.open(path) as original:
        image = original.convert("RGBA")
        image.thumbnail((thumb_w - 8, thumb_h - 8))

    x = (i % columns) * thumb_w + (thumb_w - image.width) // 2
    y = (i // columns) * (thumb_h + label_h)

    sheet.paste(image, (x, y), image)
    draw.text(
        ((i % columns) * thumb_w + 8, y + thumb_h),
        name,
        fill="black"
    )

output = os.path.join(folder, "contact_sheet.jpg")
sheet.save(output)

print(f"Contact sheet created: {output}")