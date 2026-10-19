import cv2
from PIL import Image
import os

video_path = "assets/images/videos/pip_cursor.mp4"
output_folder = "assets/images/videos/key_frames"

os.makedirs(output_folder, exist_ok=True)

cap = cv2.VideoCapture(video_path)

for i in range(0, 240, 3):
    cap.set(cv2.CAP_PROP_POS_FRAMES, i)
    success, frame = cap.read()

    if success:
        frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        image = Image.fromarray(frame)
        output_path = os.path.join(output_folder, f"frame_{i:03d}.jpg")
        image.save(output_path, quality=90)

cap.release()
print("Key frames extracted successfully!")
print("Folder:", output_folder)
