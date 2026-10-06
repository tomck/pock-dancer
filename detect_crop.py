#!/usr/bin/env python3
"""Prints "x1 x2 y1 y2": the area a dancer occupies in a video.

Samples the video at 10fps, boxes the non-black pixels in each frame, then takes the
extremes across frames while ignoring the rare outlier frame (0.2% each end).
Usage: detect_crop.py <video> <width> <height> <threshold 0-255>
"""
import subprocess
import sys

path, w, h, thr = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4])
to_binary = bytes(255 if i >= thr else 0 for i in range(256))
cmd = ["ffmpeg", "-nostdin", "-v", "error", "-i", path, "-an", "-vf", "fps=10,format=gray",
       "-f", "rawvideo", "-pix_fmt", "gray", "-"]
proc = subprocess.Popen(cmd, stdout=subprocess.PIPE)
size = w * h
boxes = []

while True:
    buf = b""
    while len(buf) < size:
        chunk = proc.stdout.read(size - len(buf))
        if not chunk:
            break
        buf += chunk
    if len(buf) < size:
        break
    f = buf.translate(to_binary)
    if not f.strip(b"\0"):
        continue
    y1 = next(y for y in range(h) if f[y * w:(y + 1) * w].strip(b"\0"))
    y2 = next(y for y in range(h - 1, -1, -1) if f[y * w:(y + 1) * w].strip(b"\0"))
    x1 = next(x for x in range(w) if f[x::w].strip(b"\0"))
    x2 = next(x for x in range(w - 1, -1, -1) if f[x::w].strip(b"\0"))
    if x2 - x1 >= 3 and y2 - y1 >= 3:
        boxes.append((x1, x2, y1, y2))

if not boxes:
    sys.exit(1)

trim = int(len(boxes) * 0.002)
cols = list(zip(*boxes))
print(sorted(cols[0])[trim], sorted(cols[1])[len(boxes) - 1 - trim],
      sorted(cols[2])[trim], sorted(cols[3])[len(boxes) - 1 - trim])
