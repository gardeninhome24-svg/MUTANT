#!/usr/bin/env python3
"""Validate non-interlaced RGBA PNG silhouettes and boss frame continuity."""
import argparse
import json
import struct
import sys
import zlib
from pathlib import Path
from zipfile import ZipFile

PNG = b"\x89PNG\r\n\x1a\n"
ACTIONS = (("phase1_anim", 4), ("phase2_attack", 4), ("death", 2))


def alpha_bounds(content, name):
    if content[:8] != PNG:
        raise ValueError(f"{name}: invalid PNG signature")
    pos, chunks, dimensions, ended = 8, [], None, False
    while pos < len(content):
        if pos + 12 > len(content):
            raise ValueError(f"{name}: incomplete PNG chunk")
        length = struct.unpack_from(">I", content, pos)[0]
        kind = content[pos + 4:pos + 8]
        end = pos + 12 + length
        if length > 24000000 or end > len(content):
            raise ValueError(f"{name}: broken PNG chunk length")
        data = content[pos + 8:pos + 8 + length]
        stored_crc = struct.unpack_from(">I", content, pos + 8 + length)[0]
        if zlib.crc32(kind + data) & 0xffffffff != stored_crc:
            raise ValueError(f"{name}: corrupt PNG CRC")
        if kind == b"IHDR":
            if dimensions is not None or len(data) != 13:
                raise ValueError(f"{name}: repeated or incomplete IHDR")
            w, h, depth, col, comp, flt, inter = struct.unpack(">IIBBBBB", data)
            if not (2 <= w <= 2048 and 2 <= h <= 2048) or (depth, col, comp, flt, inter) != (8, 6, 0, 0, 0):
                raise ValueError(f"{name}: expected RGBA 8-bit non-interlaced PNG")
            dimensions = (w, h)
        if kind == b"IDAT":
            chunks.append(data)
        if kind == b"IEND":
            ended = True
            if end != len(content):
                raise ValueError(f"{name}: trailing data beyond IEND")
            break
        pos = end
    if not (ended and dimensions and chunks):
        raise ValueError(f"{name}: PNG missing image data")
    w, h = dimensions
    try:
        raster = zlib.decompress(b"".join(chunks))
    except zlib.error as exc:
        raise ValueError(f"{name}: invalid compressed raster ({exc})") from exc
    stride = w * 4
    if len(raster) != (stride + 1) * h:
        raise ValueError(f"{name}: raster dimensions do not match PNG IHDR")
    previous = bytearray(stride)
    min_x, min_y, max_x, max_y, occupied = w, h, -1, -1, 0
    for y in range(h):
        start = y * (stride + 1)
        filter_code = raster[start]
        source = raster[start + 1:start + 1 + stride]
        if filter_code not in (0, 1, 2, 3, 4):
            raise ValueError(f"{name}: unsupported PNG scanline filter")
        row = bytearray(stride)
        if filter_code == 0:
            row[:] = source
        else:
            for byte_idx, value in enumerate(source):
                left = row[byte_idx - 4] if byte_idx >= 4 else 0
                above = previous[byte_idx]
                corner = previous[byte_idx - 4] if byte_idx >= 4 else 0
                if filter_code == 1:
                    predict = left
                elif filter_code == 2:
                    predict = above
                elif filter_code == 3:
                    predict = (left + above) // 2
                else:
                    best = left + above - corner
                    a, b, c = abs(best-left), abs(best-above), abs(best-corner)
                    predict = left if a <= b and a <= c else above if b <= c else corner
                row[byte_idx] = (value + predict) & 255
        for byte_idx in range(3, stride, 4):
            if row[byte_idx] >= 36:
                x = byte_idx // 4
                min_x, max_x = min(min_x, x), max(max_x, x)
                min_y, max_y = min(min_y, y), max(max_y, y)
                occupied += 1
        previous = row
    if occupied < 200:
        raise ValueError(f"{name}: empty or nearly transparent character")
    return {"height": round((max_y-min_y+1)/h, 4),
            "width": round((max_x-min_x+1)/w, 4),
            "feet": round((max_y+1)/h, 4),
            "alpha_pct": round(100*occupied/(w*h), 2)}


def analyze_zip(archive_path):
    issues, frames = [], {}
    with ZipFile(archive_path) as archive:
        for chapter in range(5, 11):
            key = f"boss_ch{chapter:02d}"
            frames[key] = {}
            for action, count in ACTIONS:
                result = []
                for idx in range(1, count+1):
                    name = f"assets/bosses/{key}/{action}_{idx}.png"
                    try:
                        values = alpha_bounds(archive.read(name), name)
                        result.append(values)
                        if values["feet"] < 0.88:
                            issues.append(f"{name}: feet unanchored; too much empty space below actor")
                    except (KeyError, ValueError) as exc:
                        issues.append(str(exc))
                frames[key][action] = result
                if len(result) != count:
                    continue
                heights = [v["height"] for v in result]
                if action != "death" and min(heights)/max(heights) < 0.82:
                    issues.append(f"{key}/{action}: inconsistent character scale")
            walk = frames[key]["phase1_anim"]
            attack = frames[key]["phase2_attack"]
            if len(walk) == 4 and len(attack) == 4:
                median_walk = sum(sorted(f["height"] for f in walk)[1:3])/2
                median_attack = sum(sorted(f["height"] for f in attack)[1:3])/2
                if median_attack < 0.70*median_walk:
                    issues.append(f"{key}: attack silhouette is less than 70% of movement height")
    return issues, frames


def self_test():
    import io
    def chunk(kind, data):
        b = kind+data
        return struct.pack(">I",len(data))+b+struct.pack(">I",zlib.crc32(b))
    def fixture(w=8, h=8):
        raw = b"".join(b"\x00"+b"\x10\x60\x20\xff"*w for _ in range(h))
        ihdr = struct.pack(">IIBBBBB",w,h,8,6,0,0,0)
        return PNG+chunk(b"IHDR",ihdr)+chunk(b"IDAT",zlib.compress(raw))+chunk(b"IEND",b"")
    assert alpha_bounds(fixture(32,32),"synthetic")["height"] == 1.0
    try:
        alpha_bounds(fixture(32,32)[:-1]+b"X","corrupt")
        raise AssertionError("CRC corruption not detected")
    except ValueError:
        pass
    try:
        alpha_bounds(b"not a png","invalid")
        raise AssertionError("Invalid header not detected")
    except ValueError:
        pass
    print("BOSS GEOMETRY SELF-TEST PASS: filters, CRC, alpha bounds and invalid PNGs")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--zip", type=Path)
    parser.add_argument("--report", type=Path)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return 0
    if args.zip is None:
        parser.error("--zip required")
    try:
        issues, data = analyze_zip(args.zip)
    except (OSError, ValueError) as exc:
        print("BOSS GEOMETRY FAIL:", exc, file=sys.stderr)
        return 1
    if args.report:
        args.report.write_text(json.dumps({"issues": issues, "chapters": data}, indent=2), encoding="utf-8")
    for issue in issues:
        print("BOSS GEOMETRY FAIL:", issue, file=sys.stderr)
    if issues:
        return 1
    print("BOSS GEOMETRY PASS: 60 animation frames, RGBA alpha, footprints and relative size")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
