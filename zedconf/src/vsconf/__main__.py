"""Zed configuration manager."""

import sys
from .core.settings import write_all

def main():
    """Write Zed configuration files."""
    results = write_all()
    print("Wrote Zed configuration:")
    for config_type, path in results.items():
        print(f"  {config_type}: {path}")

if __name__ == "__main__":
    main()