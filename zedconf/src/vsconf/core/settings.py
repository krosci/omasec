"""settings, keybindings, snippets for Zed editor."""

import json
from datetime import datetime
from pathlib import Path
from typing import Any, Optional

from ..data.loader import get_keybindings, get_runners, get_snippets, merge_settings
from .platform import detect_os, get_config_dir


def _backup(filepath: Path) -> Optional[Path]:
    if not filepath.exists():
        return None
    backup = filepath.with_suffix(f".bak-{int(datetime.now().timestamp())}")
    filepath.rename(backup)
    return backup


def _write_json(filepath: Path, data: Any) -> Path:
    filepath.parent.mkdir(parents=True, exist_ok=True)
    _backup(filepath)
    with open(filepath, "w") as f:
        json.dump(data, f, indent=4)
        f.write("\n")
    return filepath


def write_settings() -> Path:
    return _write_json(get_config_dir() / "settings.json", merge_settings(detect_os()))


def write_keybindings() -> Path:
    return _write_json(get_config_dir() / "keybindings.json", get_keybindings())


def write_runners() -> Path:
    settings = merge_settings(detect_os())
    settings.update(get_runners())
    return _write_json(get_config_dir() / "settings.json", settings)


def write_snippets() -> Path:
    snippets = get_snippets(detect_os())
    dst_dir = get_config_dir() / "snippets"
    dst_dir.mkdir(parents=True, exist_ok=True)
    for name, data in snippets.items():
        _write_json(dst_dir / f"{name}.json", data)
    return dst_dir


def write_all() -> dict[str, Path]:
    return {
        "settings": write_settings(),
        "keybindings": write_keybindings(),
        "snippets": write_snippets(),
    }