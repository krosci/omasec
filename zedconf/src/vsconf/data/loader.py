"""data loader for Zed editor."""

import json
from pathlib import Path
from typing import Any

DATA_DIR = Path(__file__).parent.parent.parent.parent / "data"


def load(name: str) -> Any:
    filepath = DATA_DIR / f"{name}.json"
    try:
        with open(filepath) as f:
            return json.load(f)
    except FileNotFoundError:
        raise FileNotFoundError(f"data file not found: {filepath}") from None
    except json.JSONDecodeError as e:
        raise ValueError(f"invalid JSON in {filepath}: {e}") from e


def get_messages() -> dict[str, Any]:
    return load("global")  # type: ignore[no-any-return]


def get_paths() -> dict[str, Any]:
    return load("paths")  # type: ignore[no-any-return]


def get_extensions_list() -> list[str]:
    ext_dir = Path(__file__).parent.parent.parent.parent / "extensions"
    extensions: list[str] = []
    for json_file in sorted(ext_dir.glob("*.json")):
        with open(json_file) as f:
            extensions.extend(json.load(f))
    return extensions


def _load_json(filepath: Path) -> dict[str, Any]:
    try:
        with open(filepath) as f:
            return json.load(f)  # type: ignore[no-any-return]
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def merge_settings(os_name: str) -> dict[str, Any]:
    base = _load_json(DATA_DIR / "settings.json")
    override = _load_json(DATA_DIR / os_name / "settings.json")
    base.update(override)
    return base


def get_keybindings() -> list[dict[str, Any]]:
    return load("keybindings")  # type: ignore[no-any-return]


def get_runners() -> dict[str, Any]:
    return load("runners")  # type: ignore[no-any-return]


def get_snippets(os_name: str) -> dict[str, Any]:
    base_dir = DATA_DIR / "snippets"
    os_dir = DATA_DIR / os_name / "snippets"
    result: dict[str, Any] = {}
    for snippet_dir in [base_dir, os_dir]:
        if not snippet_dir.exists():
            continue
        for json_file in sorted(snippet_dir.glob("*.json")):
            with open(json_file) as f:
                result[json_file.stem] = json.load(f)
    return result