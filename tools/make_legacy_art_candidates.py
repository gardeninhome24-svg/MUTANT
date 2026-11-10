#!/usr/bin/env python3
"""Draft art for previously static MUTANT actors using complete licensed in-project sprites.

66 boss (1-4 and two aliases) + 9 larva + 25 hazmat = 100 PNG candidates.
Output must be manually reviewed; NEVER label rigid transforms as hand keyframes.
"""
from io import BytesIO
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import argparse
from PIL import Image, ImageDraw, ImageFilter
from make_boss_candidate_pack import CHAPTERS, make_frame, encode_png, recolor, ACTIONS

CHAPTERS.update({
    1: ("hive_mother_reference.png", (103, 233, 103)),
    2: ("behemoth_boss_reference.png", (222, 150, 75)),
    3: ("cryo_king_boss.png", (92, 197, 250)),
    4: ("cryo_king_boss.png", (146, 162, 255)),
    11: ("behemoth_boss_reference.png", (248, 145, 59)),
    12: ("hive_mother_reference.png", (209, 92, 164)),
})
BOSS_OUTPUTS = {1:"boss_ch01",2:"boss_ch02",3:"boss_ch03",
                4:"boss_ch04",11:"miniboss_ch01",12:"matka_roju"}
HERO_FRAMES={"idle":4,"walk":6,"shoot":6,"hurt":3,"death":6}


def larva_frame(project, action, index):
    filename=project/"assets/mutantsurvivor_ch01/enemies/larva_idle_reference.png"
    with Image.open(filename) as source:
        image=source.convert("RGBA")
    box=image.getchannel("A").getbbox()
    if not box:
        raise ValueError("Larva reference has no body alpha")
    image=recolor(image.crop(box), (124,239,73),0.19)
    phase=[1.0,1.035,1.01,0.985][index-1]
    if action=="attack":
        phase*=1.10
    extent=min(200/image.width,192/image.height)*phase
    image=image.resize((max(1,int(image.width*extent)),max(1,int(image.height*extent))),Image.Resampling.LANCZOS)
    image=image.rotate([-3,1,4,-2][index-1] if action=="attack" else [0,-2,0,2][index-1],
                       resample=Image.Resampling.BICUBIC,expand=True)
    canvas=Image.new("RGBA",(256,256))
    canvas.alpha_composite(image,((256-image.width)//2,243-image.height))
    if action=="attack":
        fx=Image.new("RGBA",(256,256))
        d=ImageDraw.Draw(fx)
        d.arc((40,50,210,205),index*8,130+index*8,fill=(108,250,42,170),width=5)
        canvas=Image.alpha_composite(canvas,fx.filter(ImageFilter.GaussianBlur(5)))
        canvas=Image.alpha_composite(canvas,fx)
    return canvas


def hazmat_frame(project,action,index):
    source=project/f"assets/characters/soldier/{action}_{index}.png"
    if not source.is_file():
        raise FileNotFoundError(f"No existing soldier animation: {source}")
    with Image.open(source) as png:
        image=png.convert("RGBA")
    # Keep the original full-body frame and its dimensions, add a restrained
    # chemical protective-suit palette that stays consistent across poses.
    return recolor(image,(117,227,107),0.23)


def create(project,out):
    if not (project/"project.godot").is_file():
        raise ValueError("Expected project.godot")
    items={}
    for chapter,folder in BOSS_OUTPUTS.items():
        prefix=f"assets/bosses/{folder}"
        items[f"{prefix}/boss_portrait.png"]=encode_png(make_frame(project,chapter,"phase1_anim",1,True))
        for action,count in ACTIONS:
            for index in range(1,count+1):
                items[f"{prefix}/{action}_{index}.png"]=encode_png(make_frame(project,chapter,action,index))
    for action in ("walk","attack"):
        for index in range(1,5):
            items[f"assets/enemies/mutant_worm/{action}_{index}.png"]=encode_png(larva_frame(project,action,index))
    items["assets/enemies/mutant_worm/portrait.png"]=encode_png(larva_frame(project,"walk",1))
    for action,count in HERO_FRAMES.items():
        for index in range(1,count+1):
            items[f"assets/characters/toxic_soldier/{action}_{index}.png"]=encode_png(hazmat_frame(project,action,index))
    assert len(items)==100, len(items)
    out.parent.mkdir(parents=True,exist_ok=True)
    with ZipFile(out,"w",ZIP_DEFLATED,compresslevel=6) as archive:
        for path,data in sorted(items.items()):
            archive.writestr(path,data)
    print(f"LEGACY ART CANDIDATE GENERATED: 100 PNG images in {out}")
    print("ART QUALITY: candidate from existing assets; manual inspection still required")


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project",type=Path,default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--out",type=Path,default=Path("build/legacy_art_candidates.zip"))
    args=parser.parse_args()
    create(args.project.resolve(),args.out.resolve())


if __name__=="__main__":
    main()
