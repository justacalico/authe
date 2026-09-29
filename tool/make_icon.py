import math
from PIL import Image, ImageDraw

S = 4096          # supersampled canvas
C = S // 2
R = int(S * 0.293)      # ring radius ~300/1024
W = int(S * 0.094)      # ring stroke ~96/1024
TILE = int(S * 0.0625)  # 64/1024 margin
RAD = int(S * 0.203)    # corner radius ~208/1024

img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(img)

d.rounded_rectangle([TILE, TILE, S - TILE, S - TILE], radius=RAD, fill="#19191C")

# PIL angles: 0 = 3 o'clock, increasing clockwise. Gap ~40deg centered on top (270).
d.arc([C - R, C - R, C + R, C + R], start=290, end=610, fill="#30D158", width=W)

# Comet head at the clockwise end of the arc (upper right).
a = math.radians(290)
hx, hy = C + R * math.cos(a), C + R * math.sin(a)
hr = int(W * 0.72)
d.ellipse([hx - hr, hy - hr, hx + hr, hy + hr], fill="#30D158")

img.resize((1024, 1024), Image.LANCZOS).save("assets/icon.png")

# Round-corner masked variant for the web favicon bundle
img.resize((512, 512), Image.LANCZOS).save("web/icons/Icon-512.png")
img.resize((192, 192), Image.LANCZOS).save("web/icons/Icon-192.png")
img.resize((32, 32), Image.LANCZOS).save("web/favicon.png")
