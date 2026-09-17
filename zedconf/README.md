# zedconf

Pure code Zed editor setup for omarchy.

## Install

```bash
sudo pacman -S --needed base-devel git wget
python -m venv .venv
source .venv/bin/activate
pip install -e .
zedconf install
```

## Features

- Configures Zed editor with Catppuccin Mocha theme
- Sets up proper keybindings and runners
- Integrates with omarchy theming system
- Creates Zed configuration files in the correct location

## Configuration

The configuration is split into:
- Base settings in `zedconf/data/settings.json`
- Linux overrides in `zedconf/data/linux/settings.json`
- Keybindings in `zedconf/data/keybindings.json`
- Runners in `zedconf/data/runners.json`
- Snippets in `zedconf/data/snippets/`

## Development

```bash
# Install dev dependencies
pip install -e .[dev]

# Run tests
pytest

# Format code
ruff check .
ruff format .

# Type check
mypy .
```