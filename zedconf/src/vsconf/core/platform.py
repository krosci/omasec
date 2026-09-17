"""platform detection and path resolution for Zed."""

import os
import platform
from pathlib import Path
from typing import Optional

from ..data.loader import get_paths


def detect_os() -> str:
    system = platform.system().lower()
    os_map = {"linux": "linux", "darwin": "macos", "windows": "windows"}
    if system not in os_map:
        raise OSError(f"unsupported platform: {system}")
    return os_map[system]


def _expand(path_str: str) -> Path:
    expanded = os.path.expanduser(path_str)
    expanded = os.path.expandvars(expanded)
    return Path(expanded)


def get_config_dir() -> Path:
    os_name = detect_os()
    paths = get_paths()
    os_paths = paths[os_name]
    if os_name == "linux":
        snap = _expand(os_paths["snap_path"])
        if snap.exists():
            return snap
    return _expand(os_paths["config_path"])


def get_extensions_dir() -> Optional[Path]:
    os_name = detect_os()
    paths = paths = get_paths()
    for path_str in paths[os_name]["extensions_paths"]:
        expanded = _expand(path_str)
        if expanded.exists():
            return expanded
    return None


def get_platform_config_dir() -> Path:
    os_name = detect_os()
    return Path(__file__).parent.parent.parent.parent / "data" / os_name