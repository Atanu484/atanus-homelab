#!/usr/bin/env python3
"""Remove full-line and inline comments from YAML/yml and shell scripts.
Skips: .git, README, JSON. Preserves shell shebang (#!/bin/sh etc.).
"""
import re
import sys
from pathlib import Path

# Full-line comment: optional whitespace, then #, then rest of line
FULL_LINE_COMMENT = re.compile(r"^\s*#.*$")

# Inline comment: at least one space before #, then comment to EOL (avoid stripping # inside URLs)
INLINE_COMMENT = re.compile(r"\s+#\s+[^\n]*$")


def process_yaml(content: str) -> str:
    out = []
    for line in content.splitlines():
        if FULL_LINE_COMMENT.match(line):
            continue
        # Strip inline " # comment" at end of line
        line = INLINE_COMMENT.sub("", line).rstrip()
        out.append(line)
    result = "\n".join(out)
    # Remove multiple consecutive blank lines (leave at most one)
    result = re.sub(r"\n{3,}", "\n\n", result)
    return result.rstrip() + "\n" if result else ""


def process_shell(content: str) -> str:
    lines = content.splitlines()
    out = []
    for i, line in enumerate(lines):
        if i == 0 and line.strip().startswith("#!"):
            out.append(line)
            continue
        if FULL_LINE_COMMENT.match(line):
            continue
        out.append(line)
    result = "\n".join(out)
    result = re.sub(r"\n{3,}", "\n\n", result)
    return result.rstrip() + "\n" if result else ""


def main() -> None:
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
    root = root.resolve()
    changed = []
    for path in root.rglob("*"):
        if path.is_file() and ".git" not in path.parts:
            suf = path.suffix.lower()
            if suf in (".yaml", ".yml"):
                content = path.read_text(encoding="utf-8", errors="replace")
                new_content = process_yaml(content)
                if new_content != content:
                    path.write_text(new_content, encoding="utf-8")
                    changed.append(str(path))
            elif path.name.endswith(".sh"):
                content = path.read_text(encoding="utf-8", errors="replace")
                new_content = process_shell(content)
                if new_content != content:
                    path.write_text(new_content, encoding="utf-8")
                    changed.append(str(path))
    for c in changed:
        print(c)
    if not changed:
        print("No files modified.", file=sys.stderr)


if __name__ == "__main__":
    main()
