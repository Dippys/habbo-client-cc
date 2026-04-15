#!/usr/bin/env python3
"""Migrate Habbo flat .txt gamedata to nested JSON.

Usage:
    python migrate_gamedata_to_json.py [--strict] [--gamedata DIR]

Mirrors the AS3 parser semantics exactly and round-trip verifies
(parse .txt -> nest -> flatten -> diff against original). Produces
zero diff or fails non-zero. Writes alongside the .txt files; does
not delete originals.
"""
import argparse
import json
import re
import sys
from pathlib import Path

LINE_SPLIT = re.compile(r"\n\r+|\n+|\r+")
TRIM = re.compile(r"^\s+|\s+$")
SENTINEL = "$"
META_READONLY = "_readonly"


def parse_flat(text, is_texts):
    """Exact-AS3 flat parse. Returns (collapsed_dict, readonly_flag, duplicates)."""
    pairs = []
    seen = {}
    duplicates = []
    readonly = False
    readonly_flag_set = False
    lines = LINE_SPLIT.split(text)
    for lineno, raw in enumerate(lines, 1):
        if raw == "" or raw.startswith("#"):
            continue
        if "=" not in raw:
            continue
        idx = raw.index("=")
        key = TRIM.sub("", raw[:idx])
        val = TRIM.sub("", raw[idx + 1:])
        if is_texts:
            if not key:
                continue
            val = val.replace("\\n", "\n")
            if not val:
                continue
        else:
            if not key or not val:
                continue
            if key == "configuration.readonly" and val == "true":
                readonly = True
                readonly_flag_set = True
                continue  # do NOT emit as a real key
        if key in seen:
            duplicates.append((key, seen[key], lineno))
        seen[key] = lineno
        pairs.append((key, val))
    collapsed = {}
    for k, v in pairs:
        collapsed[k] = v
    return collapsed, readonly_flag_set, duplicates


def insert(root, key, value):
    parts = key.split(".")
    node = root
    for i, part in enumerate(parts):
        last = i == len(parts) - 1
        if last:
            if part in node and isinstance(node[part], dict):
                node[part][SENTINEL] = value
            else:
                node[part] = value
        else:
            if part not in node:
                node[part] = {}
            elif isinstance(node[part], str):
                node[part] = {SENTINEL: node[part]}
            node = node[part]


def build_tree(collapsed):
    root = {}
    for k, v in collapsed.items():
        insert(root, k, v)
    return root


def flatten(node, prefix, out):
    if isinstance(node, dict):
        if SENTINEL in node:
            out[prefix] = node[SENTINEL]
        for k, v in node.items():
            if k == SENTINEL:
                continue
            new_prefix = f"{prefix}.{k}" if prefix else k
            flatten(v, new_prefix, out)
    else:
        out[prefix] = node


def migrate(src_path, dst_path, is_texts, strict):
    if not src_path.exists():
        print(f"SKIP [{src_path}]: not found", file=sys.stderr)
        return
    text = src_path.read_text(encoding="utf-8", errors="replace")
    collapsed, readonly_flag, dupes = parse_flat(text, is_texts)
    for k, first, last in dupes:
        print(
            f"WARN [{src_path.name}]: duplicate key {k!r} at lines {first} and {last} (keeping last)",
            file=sys.stderr,
        )
    tree = build_tree(collapsed)
    if readonly_flag:
        tree[META_READONLY] = True
    # Round-trip verify
    reparsed = {}
    flatten(tree, "", reparsed)
    reparsed.pop(META_READONLY, None)
    diffs = [
        k for k in set(collapsed) | set(reparsed)
        if collapsed.get(k) != reparsed.get(k)
    ]
    if diffs:
        print(
            f"ERROR [{src_path.name}]: round-trip mismatch on {len(diffs)} keys",
            file=sys.stderr,
        )
        for k in diffs[:20]:
            print(
                f"  {k!r}: original={collapsed.get(k)!r} reparsed={reparsed.get(k)!r}",
                file=sys.stderr,
            )
        sys.exit(1)
    dst_path.parent.mkdir(parents=True, exist_ok=True)
    dst_path.write_text(
        json.dumps(tree, indent=2, ensure_ascii=False, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(f"OK [{src_path.name}] -> {dst_path.name} ({len(collapsed)} keys, {len(dupes)} dupes)")
    if dupes and strict:
        sys.exit(2)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--strict", action="store_true",
                    help="exit non-zero if duplicates found")
    ap.add_argument("--gamedata", default=r"C:\habbo\client\habbo-swfs\gamedata")
    args = ap.parse_args()
    gd = Path(args.gamedata)
    migrate(gd / "external_variables.txt",
            gd / "external_variables.json", False, args.strict)
    migrate(gd / "external_flash_texts.txt",
            gd / "external_flash_texts.json", True, args.strict)
    ov = gd / "override"
    migrate(ov / "external_override_variables.txt",
            ov / "external_override_variables.json", False, args.strict)
    migrate(ov / "external_flash_override_texts.txt",
            ov / "external_flash_override_texts.json", True, args.strict)


if __name__ == "__main__":
    main()
