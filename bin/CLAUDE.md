# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Bin Directory Overview

This directory contains executable Python scripts that provide CLI interfaces to the whyp system's core functionality. These scripts serve as the primary entry points for command-line usage of whyp's Python modules.

## Executable Scripts

### `sources`
___Shell source file management utility___
- Manages the persistent tracking of shell files that have been sourced
- Interfaces with `whyp/sources.py` module for YAML-based persistence
- Used by shell functions for discovering alias/function source files

___Key Commands___:
```bash
# Show all tracked source files
./sources --all

# Check if any sources are tracked  
./sources --any

# Clear all tracked sources
./sources --clear

# Check if specific file is tracked
./sources --found /path/to/file.sh

# Allow graceful operation when no sources exist
./sources --optional
```

### `whyp-python`
___Python module discovery utility___
- Python equivalent to `which` for module imports
- Exposes Python's import mechanism to bash scripts
- Searches `sys.path` for modules and reports import locations

___Key Commands___:
```bash
# Find where Python will import a module
./whyp-python os sys

# Quiet mode (no output, just exit codes)
./whyp-python -q module_name

# Show module version information
./whyp-python -v module_name
```

## Integration Architecture

### Shell Function Bridge
These scripts are called from bash functions in `../whyp.sh`:
- ___`sources_()` function___: Wraps `./sources` with `whyp_bin_run`
- ___Python discovery___: Enables shell functions to query Python import paths
- ___Persistent state___: Maintains shell source tracking across sessions

### Module Interface
Both scripts follow the same pattern:
1. Import corresponding whyp module (`sources`, `python`)
2. Use `whyp.arguments` for consistent CLI parsing
3. Delegate core functionality to the imported module
4. Return appropriate exit codes for shell integration

### Setup Integration
The `setup.py` configuration declares `scripts=['bin/whyp']`, but the actual executables are:
- `sources`: Standalone source management
- `whyp-python`: Python module discovery
- Main entry point via `python -m whyp` (not a bin script)

These scripts enable the whyp system to bridge shell state management with Python's analytical capabilities, providing the CLI interfaces needed for the hybrid bash/Python architecture.