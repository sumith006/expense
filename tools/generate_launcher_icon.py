from PIL import Image, ImageDraw
from pathlib import Path

size = 1024
img = Image.new("RGBA", (size, size), (10, 38, 71, 255))
d = ImageDraw.Draw(img)
r = size // 2 - 128
d.ellipse(((size//2-r, size//2-r), (size//2+r, size//2+r)), fill=(255, 204, 0, 255))
d.rectangle((size*0.35, size*0.45, size*0.65, size*0.55), fill=(10, 38, 71, 255))
d.rectangle((size*0.45, size*0.35, size*0.55, size*0.65), fill=(10, 38, 71, 255))
path = Path("assets/images/app_icon.png")
path.parent.mkdir(parents=True, exist_ok=True)
img.save(path)
print(f"Wrote generated icon: {path} size={path.stat().st_size}")
