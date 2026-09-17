---
name: conventional-commits
description: >-
  Rules and procedures for writing conventional git commit messages with strictly formatted targets and single colon delimiters.
---

# Conventional Commits

## Overview
This skill defines commit message standards for the repository. All commits must follow the Conventional Commits specification.

## Format Rules
* Format: `<type>: <description>` or `<type>(<scope>): <description>`
* The colon `:` after the target/type is the only allowed separator symbol.
* Do not use emojis, exclamation marks, or extra punctuation characters in commit summaries.
* Keep commit headers under 72 characters.
* Use imperative mood in descriptions (e.g. `add`, `fix`, `update`, `remove`).

## Allowed Types
* `feat`: A new feature or capability.
* `fix`: A bug fix.
* `docs`: Documentation changes only.
* `style`: Formatting changes that do not affect code logic.
* `refactor`: Code changes that neither fix a bug nor add a feature.
* `perf`: Performance improvements.
* `test`: Adding or updating test suites.
* `chore`: Maintenance, build tasks, and skill configurations.
