---
name: idempotent-bash-automation
description: >-
  Procedures and coding standards for authoring safe, idempotent Bash scripts, verification suites, and foreground execution pipelines.
---

# Idempotent Bash Automation

## Overview
This skill defines standards for writing system administration scripts and test suites for the omasec project.

## Scripting Guidelines
* Always run with strict shell flags: `set -euo pipefail`.
* Never use `|| true` to silence failures.
* Use `|| warn "message"` for non-critical steps that are permitted to fail gracefully.
* Do not use `systemd-run` or background execution; all operations must execute in the foreground.
* Derive paths dynamically using `$HOME` or `/home/*` rather than hardcoding user paths.
* Ensure all actions are idempotent so multiple runs produce identical system states.

## Verification Suite Standards
* Run verification with `bash scripts/verify.sh` or `make verify`.
* Use test counters (`PASS`, `FAIL`) and assert exit code 0 only when `FAIL` is 0.
