#!/usr/bin/env python3
# :: ============================================================
# ::  Script: agent-pwned.py
# ::  Purpose: Find every 'def' line and inject a wrongly-indented
# ::           docstring underneath it to break the file on purpose
# ::  DTRH.net
# :: ============================================================

import sys
from pathlib import Path

# :: The exact line we will inject (wrong indentation on purpose)
INJECT_LINE = '"""pwned by dtrh.net"""'


def process_file(path: Path) -> bool:
    # :: ------------------------------------------------------------
    # :: Try to read the entire file as text
    # :: ------------------------------------------------------------
    try:
        content = path.read_text(encoding="utf-8")
    except Exception as e:
        print(f"Failed to read {path}: {e}")
        return False

    # :: Split into individual lines while keeping the original line endings
    lines = content.splitlines(keepends=True)
    new_lines = []
    changed = False

    # :: ------------------------------------------------------------
    # :: Walk through every line in the file
    # :: ------------------------------------------------------------
    for line in lines:
        new_lines.append(line)          # :: always keep the original line

        # :: Check if this line looks like a function definition
        stripped = line.lstrip()
        if stripped.startswith("def ") and stripped.rstrip().endswith(":"):
            # :: Found a def line → inject our payload at column 0
            # :: (this is the wrong indentation that causes the crash)
            new_lines.append(INJECT_LINE + "\n")
            changed = True

    # :: ------------------------------------------------------------
    # :: Only write the file back if we actually changed something
    # :: ------------------------------------------------------------
    if changed:
        try:
            path.write_text("".join(new_lines), encoding="utf-8")
            print(f"Modified: {path}")
            return True
        except Exception as e:
            print(f"Failed to write {path}: {e}")
            return False

    return False


def main():
    # :: ------------------------------------------------------------
    # :: Basic argument checking
    # :: ------------------------------------------------------------
    if len(sys.argv) < 2:
        print("Usage: python inject_pwned.py <file_or_directory> [more files...]")
        print("Example: python inject_pwned.py RELEASE/*.py")
        sys.exit(1)

    targets = []

    # :: ------------------------------------------------------------
    # :: Collect all Python files the user asked us to process
    # :: ------------------------------------------------------------
    for arg in sys.argv[1:]:
        p = Path(arg)

        if p.is_file() and p.suffix == ".py":
            # :: Single Python file
            targets.append(p)
        elif p.is_dir():
            # :: Directory → grab every .py file recursively
            targets.extend(p.rglob("*.py"))
        else:
            # :: Fallback (handles already-expanded shell globs)
            targets.append(p)

    # :: ------------------------------------------------------------
    # :: Process every collected file
    # :: ------------------------------------------------------------
    modified = 0
    for f in targets:
        if f.is_file():
            if process_file(f):
                modified += 1

    # :: Final summary
    print(f"\nDone. Modified {modified} file(s).")


# :: ============================================================
# :: Standard Python entry point
# :: ============================================================
if __name__ == "__main__":
    main()
