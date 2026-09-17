"""Zed configuration CLI."""

import sys
from ..core.settings import write_all

def main():
    """Main entry point for zedconf CLI."""
    if len(sys.argv) < 2:
        print("Usage: zedconf <command>")
        print("Commands:")
        print("  install  - Install Zed configuration")
        print("  help     - Show this help")
        return 1

    command = sys.argv[1]

    if command == "install":
        results = write_all()
        print("Wrote Zed configuration:")
        for config_type, path in results.items():
            print(f"  {config_type}: {path}")
        return 0
    elif command == "help":
        print("Usage: zedconf <command>")
        print("Commands:")
        print("  install  - Install Zed configuration")
        print("  help     - Show this help")
        return 0
    else:
        print(f"Unknown command: {command}")
        print("Available commands: install, help")
        return 1

if __name__ == "__main__":
    sys.exit(main())