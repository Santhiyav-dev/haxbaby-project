import cv2
from PIL import Image, ImageDraw
import os

video_path = "assets/images/videos/pip_cursor.mp4"
output_path = "assets/images/videos/video_contact_sheet.jpg"

cap = cv2.VideoCapture(video_path)

if not cap.isOpened():
    print("ERROR: Video could not be opened")
    raise SystemExit

frames = []
frame_number = 0

while True:
    success, frame = cap.read()
    if not success:
        break

    if frame_number % 6 == 0:
        frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        image = Image.fromarray(frame)
        image.thumbnail((120, 160))
        frames.append((frame_number, image))

    frame_number += 1

cap.release()

cell_w, cell_h = 140, 190
columns = 5
rows = (len(frames) + columns - 1) // columns

sheet = Image.new("RGB", (columns * cell_w, rows * cell_h), "white")
draw = ImageDraw.Draw(sheet)

for i, (number, image) in enumerate(frames):
    x = (i % columns) * cell_w
    y = (i // columns) * cell_h

    sheet.paste(image, (x + (cell_w - image.width) // 2, y))
    draw.text((x + 8, y + 164), f"Frame {number}", fill="black")

sheet.save(output_path)
print(f"Created: {output_path}")
print(f"Sampled frames: {len(frames)}")
