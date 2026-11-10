#!/usr/bin/env python3
"""Validate/install MUTANT chapter 05–10 concept PNGs; no external libraries."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import struct
import sys
import tempfile
from zipfile import ZipFile, BadZipFile

ROOT = Path(__file__).resolve().parent.parent
CHAPTERS = tuple(range(5, 11))
PNG_MAGIC = b"\x89PNG\r\n\x1a\n"
FRAMES = ("boss_portrait.png",) + tuple(
    f"{kind}_{i}.png" for kind, count in
    (("phase1_anim", 4), ("phase2_attack", 4), ("death", 2))
    for i in range(1, count + 1)
)
EXPECTED = tuple(f"assets/bosses/boss_ch{ch:02d}/{name}"
                 for ch in CHAPTERS for name in FRAMES)
MAX_BYTES = 4_000_000
MAX_ARCHIVE_BYTES = 30_000_000


def inspect_png(data, name):
    if not (data.startswith(PNG_MAGIC) and len(data) >= 45):
        raise ValueError(f"{name}: bad PNG signature")
    size = struct.unpack(">I", data[8:12])[0]
    if data[12:16] != b"IHDR" or size != 13:
        raise ValueError(f"{name}: invalid PNG IHDR")
    width, height, bits, color = struct.unpack(">IIBB", data[16:26])
    expected_size = (320, 360) if name.endswith("boss_portrait.png") else (256, 256)
    if (width, height) != expected_size:
        raise ValueError(f"{name}: got {width}x{height}; expected {expected_size}")
    if bits != 8 or color != 6:
        raise ValueError(f"{name}: only 8-bit RGBA PNG supported")
    if len(data) > MAX_BYTES or b"IEND" not in data[-16:]:
        raise ValueError(f"{name}: oversized or incomplete PNG")
    return hashlib.sha256(data).hexdigest()


def inspect_zip(path):
    if not path.is_file() or path.stat().st_size > MAX_ARCHIVE_BYTES:
        raise ValueError("Archive missing or exceeds the allowed size")
    with ZipFile(path) as archive:
        infos = {item.filename: item for item in archive.infolist()
                 if not item.is_dir() and item.filename.startswith("assets/")}
        missing = sorted(set(EXPECTED) - set(infos))
        unknown = sorted(set(infos) - set(EXPECTED))
        duplicates = len(infos) != sum(
            item.filename.startswith("assets/") and not item.is_dir()
            for item in archive.infolist())
        if missing or unknown or duplicates:
            raise ValueError(f"Unsafe or incomplete art pack: missing={missing[:4]}, "
                             f"unknown={unknown[:4]}, duplicated={duplicates}")
        if sum(item.file_size for item in infos.values()) > MAX_ARCHIVE_BYTES:
            raise ValueError("Uncompressed archive exceeds size limit")
        checksums = {}
        for name in EXPECTED:
            info = infos[name]
            if info.file_size < 150 or info.file_size > MAX_BYTES:
                raise ValueError(f"{name}: invalid data length")
            data = archive.read(name)
            checksums[name] = inspect_png(data, name)
        for chapter in CHAPTERS:
            chapter_paths = [n for n in EXPECTED if f"boss_ch{chapter:02d}/" in n]
            if len(set(checksums[n] for n in chapter_paths)) < 6:
                raise ValueError(f"Boss {chapter}: repeated frames indicate an incomplete set")
        # Enforce geometry consistency; a structurally valid ZIP can still
        # contain a cropped or shrunken animation frame.
        from boss_art_geometry import analyze_zip
        geometry_errors, _ = analyze_zip(path)
        if geometry_errors:
            raise ValueError("Boss sprite geometry rejected: " + "; ".join(geometry_errors[:4]))
        return checksums


def install_zip(archive_path, project, replace=False):
    project = project.resolve()
    if not (project / "project.godot").is_file():
        raise ValueError(f"Not a Godot project root: {project}")
    digests = inspect_zip(archive_path)
    targets = [project / rel for rel in EXPECTED]
    existing = [str(t) for t in targets if t.exists()]
    if existing and not replace:
        raise ValueError(f"{len(existing)} files already exist; use --replace to upgrade")
    # Validate all source bytes first; stage new images before touching project files.
    with tempfile.TemporaryDirectory(prefix="mutant_boss_art_") as temp_dir:
        staging = Path(temp_dir)
        with ZipFile(archive_path) as archive:
            for rel in EXPECTED:
                staged = staging / rel
                staged.parent.mkdir(parents=True, exist_ok=True)
                staged.write_bytes(archive.read(rel))
        for rel, target in zip(EXPECTED, targets):
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(staging / rel, target.with_suffix(".png.tmp"))
            os.replace(target.with_suffix(".png.tmp"), target)
    return {"installed": len(EXPECTED), "chapters": len(CHAPTERS),
            "project": str(project), "fingerprint": hashlib.sha256(
                "".join(digests[n] for n in EXPECTED).encode("ascii")).hexdigest()[:16]}


def self_test():
    import zlib
    from io import BytesIO
    from zipfile import ZIP_DEFLATED
    def chunk(code, payload):
        data = code + payload
        return struct.pack(">I", len(payload)) + data + struct.pack(">I", zlib.crc32(data))
    def png(w, h):
        raw = b"".join(b"\x00" + b"\x00\x00\x00\x00" * w for _ in range(h))
        return PNG_MAGIC + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b"")
    with tempfile.TemporaryDirectory() as t:
        path = Path(t) / "sprites.zip"
        with ZipFile(path, "w", ZIP_DEFLATED) as archive:
            for rel in EXPECTED:
                wh = (320, 360) if rel.endswith("portrait.png") else (256, 256)
                archive.writestr(rel, png(*wh))
        # Self-test intentionally does not install these empty synthetic images.
        try:
            inspect_zip(path)
            raise AssertionError("Repeated synthetic sprites escaped validation")
        except ValueError as exc:
            if "repeated frames" not in str(exc):
                raise
        assert len(FRAMES) == 11 and len(EXPECTED) == 66
        assert len(inspect_png(png(256, 256), "walk.png")) == 64
    print("BOSS ART PREFLIGHT PASS: path safety, 66 frame contracts, PNG and duplicates")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--zip", dest="archive", type=Path)
    parser.add_argument("--project", type=Path, default=ROOT)
    parser.add_argument("--install", action="store_true")
    parser.add_argument("--replace", action="store_true")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    try:
        if args.self_test:
            self_test()
            return 0
        if args.archive is None:
            parser.error("--zip is required unless --self-test is specified")
        results = inspect_zip(args.archive)
        if args.install:
            print(json.dumps(install_zip(args.archive, args.project, args.replace), indent=2))
        else:
            print(f"BOSS ART PACK PASS: {len(results)} PNGs, {len(CHAPTERS)} boss folders")
        print("ART QUALITY: candidate, manual frame continuity and Godot screenshots required")
        return 0
    except (ValueError, BadZipFile, OSError) as exc:
        print(f"BOSS ART PACK FAIL: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
