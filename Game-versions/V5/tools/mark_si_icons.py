#!/usr/bin/env python3
"""Estampa una marca visible «SI» en los iconos recortados de la hoja del equipo (y, con --logo,
en el logotipo). Úsalo SOLO si el equipo confirma que esas imágenes se generaron con IA: la guía
de NASA Space Apps 2026 exige marca de agua visible en imágenes generadas con SI.

  python3 tools/mark_si_icons.py            # marca assets/icons/*.png
  python3 tools/mark_si_icons.py --logo     # marca también assets/brand/logo_2mars.png
  python3 tools/mark_si_icons.py --undo     # restaura las copias sin marca

Guarda las originales en tools/backup_sin_marca/ (carpeta ignorada por Godot)."""
import glob, os, shutil, sys
from PIL import Image, ImageDraw, ImageFont
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BACKUP = os.path.join(ROOT, "tools", "backup_sin_marca")
FONT = os.path.join(ROOT, "assets", "fonts", "Nunito.ttf")
targets = sorted(glob.glob(os.path.join(ROOT, "assets", "icons", "*.png")))
if "--logo" in sys.argv: targets.append(os.path.join(ROOT, "assets", "brand", "logo_2mars.png"))
os.makedirs(BACKUP, exist_ok=True)
open(os.path.join(BACKUP, ".gdignore"), "w").close()
for path in targets:
    keep = os.path.join(BACKUP, os.path.relpath(path, ROOT).replace(os.sep, "__"))
    if "--undo" in sys.argv:
        if os.path.exists(keep): shutil.copyfile(keep, path)
        continue
    if not os.path.exists(keep): shutil.copyfile(path, keep)
    image = Image.open(keep).convert("RGBA")
    side = max(image.size)
    size = max(12, side // 6)
    font = ImageFont.truetype(FONT, size)
    draw = ImageDraw.Draw(image)
    box = draw.textbbox((0, 0), "SI", font=font)
    w, h = box[2] - box[0] + size // 2, box[3] - box[1] + size // 2
    x, y = image.width - w - 2, image.height - h - 2
    draw.rounded_rectangle([x, y, x + w, y + h], radius=size // 3, fill=(25, 25, 34, 235), outline=(255, 245, 220, 255), width=max(1, size // 10))
    draw.text((x + size // 4 - box[0], y + size // 4 - box[1]), "SI", font=font, fill=(255, 245, 220, 255))
    image.save(path)
print(("Restaurados" if "--undo" in sys.argv else "Marcados"), len(targets), "archivos. Reimporta el proyecto en Godot.")
