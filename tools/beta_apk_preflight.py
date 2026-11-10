#!/usr/bin/env python3
"""Validate an exported MUTANT Android APK before handing it to beta testers.

This checks archive structure only; Android signature validation is performed
separately with apksigner in CI. No network or third-party Python packages.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys
import tempfile
from zipfile import BadZipFile, ZipFile, ZIP_STORED

EXPECTED_PACKAGE = "com.zielonadolina.mutantsurvivor"


def inspect(path: Path) -> dict:
    if not path.is_file() or path.stat().st_size < 1024 * 1024:
        raise ValueError("APK missing or implausibly small (<1 MiB)")
    with ZipFile(path, "r") as apk:
        broken = apk.testzip()
        if broken is not None:
            raise ValueError(f"Damaged APK entry: {broken}")
        names = apk.namelist()
        if len(names) != len(set(names)):
            raise ValueError("Duplicate ZIP entries")
        entries = set(names)
        if "AndroidManifest.xml" not in entries:
            raise ValueError("Android manifest missing")
        if not any(n.startswith("classes") and n.endswith(".dex") for n in entries):
            raise ValueError("Android DEX code missing")
        arm64 = [n for n in names if n.startswith("lib/arm64-v8a/") and n.endswith(".so")]
        if not arm64:
            raise ValueError("Missing ARM64 native libraries")
        if any(n.startswith("lib/x86/") or n.startswith("lib/x86_64/") for n in names):
            raise ValueError("Unexpected x86 native ABI in beta APK")
        if any(n.startswith("backups/") for n in names):
            raise ValueError("Backup files included in APK")
        return {
            "apk": str(path),
            "size_bytes": path.stat().st_size,
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            "zip_entries": len(names),
            "arm64_libraries": len(arm64),
            "package_expected": EXPECTED_PACKAGE,
            "result": "STRUCTURE PASS — signature, package and device install require separate checks",
        }


def self_test() -> None:
    with tempfile.TemporaryDirectory() as directory:
        apk = Path(directory) / "sample.apk"
        payload = b"0" * 1_050_000
        with ZipFile(apk, "w", ZIP_STORED) as out:
            out.writestr("AndroidManifest.xml", b"manifest")
            out.writestr("classes.dex", payload)
            out.writestr("lib/arm64-v8a/libgodot_android.so", b"native")
        assert inspect(apk)["arm64_libraries"] == 1
        with ZipFile(apk, "w", ZIP_STORED) as out:
            out.writestr("AndroidManifest.xml", payload)
            out.writestr("classes.dex", b"dex")
        try:
            inspect(apk)
            raise AssertionError("Missing ARM64 library was accepted")
        except ValueError as error:
            assert "ARM64" in str(error)
    print("BETA APK PREFLIGHT SELF-TEST PASS")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apk", nargs="?", type=Path)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    try:
        if args.self_test:
            self_test()
            return 0
        if args.apk is None:
            parser.error("APK path required")
        print(json.dumps(inspect(args.apk), indent=2))
        return 0
    except (OSError, ValueError, BadZipFile, AssertionError) as error:
        print("BETA APK PREFLIGHT FAIL:", error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
