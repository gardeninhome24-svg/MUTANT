#!/usr/bin/env python3
"""Produce 66 reviewable boss sprites derived from existing MUTANT boss art.

This uses complete HD boss silhouettes with transform animation; it is an ART CANDIDATE, not hand-animated production art.
Requires Pillow. Never changes existing source images.
"""
import argparse
from io import BytesIO
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

# Use the complete production reference silhouettes, not the fragmented
# legacy boss animation PNGs (those contain isolated body parts).
CHAPTERS = {
    5: ("hive_mother_reference.png", (76, 222, 90)),
    6: ("hive_mother_reference.png", (180, 226, 48)),
    7: ("behemoth_boss_reference.png", (242, 103, 78)),
    8: ("behemoth_boss_reference.png", (184, 78, 238)),
    9: ("architect_zero_boss.png", (70, 208, 255)),
    10: ("architect_zero_boss.png", (254, 116, 193)),
}
ACTIONS = (("phase1_anim", 4), ("phase2_attack", 4), ("death", 2))


def encode_png(image):
    output = BytesIO()
    image.save(output, "PNG", compress_level=8, optimize=True)
    return output.getvalue()


def recolor(image, tint, amount):
    rgb = ImageEnhance.Color(image.convert("RGB")).enhance(1.16)
    pixels, source = rgb.load(), image.load()
    target = Image.new("RGBA", image.size)
    dest = target.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b = pixels[x, y]
            a = source[x, y][3]
            if a:
                blend = amount * (0.30 + 0.70 * max(r, g, b) / 255.0)
                dest[x, y] = (
                    int(r * (1-blend) + tint[0]*blend),
                    int(g * (1-blend) + tint[1]*blend),
                    int(b * (1-blend) + tint[2]*blend), a
                )
    return target


def make_frame(root, chapter, action, index, portrait=False):
    source_name, tint = CHAPTERS[chapter]
    path = root / "assets" / "mutantsurvivor_ch01" / "bosses" / source_name
    if not path.is_file():
        raise FileNotFoundError(f"Source boss animation missing: {path}")
    with Image.open(path) as src:
        image = src.convert("RGBA")
    box = image.getchannel("A").getbbox()
    if not box:
        raise ValueError(f"Empty alpha on {path}")
    image = recolor(image.crop(box), tint, 0.26 + 0.05*(chapter % 3))
    canvas_size = (320, 360) if portrait else (256, 256)
    max_size = (248, 298) if portrait else (208, 205)
    scale = min(max_size[0]/image.width, max_size[1]/image.height)
    if action == "phase1_anim":
        scale *= [1.0, 1.022, 1.0, .985][index-1]
    if action == "phase2_attack":
        scale *= [1.025, 1.05, 1.035, 1.0][index-1]
    image = image.resize((max(1,int(image.width*scale)),max(1,int(image.height*scale))), Image.Resampling.LANCZOS)
    if action == "phase2_attack":
        image = image.rotate([-3,2,3,-2][index-1], Image.Resampling.BICUBIC, expand=True)
    canvas = Image.new("RGBA", canvas_size)
    x = (canvas_size[0]-image.width)//2
    y = int(canvas_size[1]*0.95) - image.height
    canvas.alpha_composite(image, (x,y))
    if action == "phase2_attack" and not portrait:
        fx = Image.new("RGBA", canvas_size)
        drawing = ImageDraw.Draw(fx)
        phase = [0.7,0.95,1.0,0.55][index-1]
        cx,cy = canvas_size[0]*0.53,canvas_size[1]*0.55
        bbox=[int(cx-77*phase),int(cy-68*phase),int(cx+77*phase),int(cy+68*phase)]
        drawing.arc(bbox,20+index*6,135+index*8,fill=(*tint,145),width=4+index%2)
        canvas = Image.alpha_composite(canvas, fx.filter(ImageFilter.GaussianBlur(6)))
        canvas = Image.alpha_composite(canvas, fx)
    if action=="death" and index==2:
        canvas=Image.blend(canvas,Image.new("RGBA",canvas_size),0.14)
    return canvas


def create(project, output):
    if not (project/"project.godot").is_file():
        raise ValueError(f"No project.godot under {project}")
    images = {}
    for chapter in range(5,11):
        prefix=f"assets/bosses/boss_ch{chapter:02d}"
        images[f"{prefix}/boss_portrait.png"]=encode_png(make_frame(project,chapter,"phase1_anim",1,True))
        for action,count in ACTIONS:
            for frame in range(1,count+1):
                images[f"{prefix}/{action}_{frame}.png"]=encode_png(make_frame(project,chapter,action,frame))
    assert len(images)==66
    output.parent.mkdir(parents=True,exist_ok=True)
    with ZipFile(output,"w",ZIP_DEFLATED,compresslevel=6) as archive:
        for path,data in sorted(images.items()):
            archive.writestr(path,data)
    # Render one contact sheet for human inspection; this also helps spot
    # palette repetition and missing limbs before any Android install.
    contact = Image.new("RGBA", (3*340, 2*392), (13, 17, 25, 255))
    painter = ImageDraw.Draw(contact)
    for chapter in range(5, 11):
        column, row = (chapter-5)%3, (chapter-5)//3
        x, y = column*340, row*392
        portrait_data = images[f"assets/bosses/boss_ch{chapter:02d}/boss_portrait.png"]
        with Image.open(BytesIO(portrait_data)) as png_source:
            portrait = png_source.convert("RGBA")
        contact.alpha_composite(portrait, (x+10,y+20))
        painter.text((x+16,y+365), f"CHAPTER {chapter:02d} — ART CANDIDATE", fill=(205,221,236,255))
    contact_path = output.with_name("boss_contact_sheet.png")
    contact.save(contact_path)
    print(f"BOSS CONTACT SHEET: {contact_path}")
    print(f"BOSS CANDIDATE GENERATED: {len(images)} PNGs in {output}")
    print("ART QUALITY: candidate derived from existing sprite poses; review before claiming final animation")


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project",type=Path,default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--out",type=Path,default=Path("build/boss_candidate_05_10.zip"))
    args=parser.parse_args()
    create(args.project.resolve(),args.out.resolve())


if __name__=="__main__":
    main()
