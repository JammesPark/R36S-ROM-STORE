#!/usr/bin/env python3
"""Compatibility entry point for the project history audit."""
from pathlib import Path
from audit_history import Audit

if __name__ == "__main__":
    raise SystemExit(Audit().repository(Path.cwd()))
