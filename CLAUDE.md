# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`whyp` is a hybrid bash/Python shell tool that extends the standard `type` command with enhanced functionality. It discovers and displays the source behind shell commands, aliases, functions, and executables, with options to view their contents and edit them directly.

## Hybrid Architecture

### Core Integration Pattern
___Shell Functions + Python Analysis___:
- `whyp.sh`: Interactive bash functions (`whyp`, `w`, `ww`, `e`) for shell integration
- `whyp/` package: Python modules for command discovery, analysis, and PATH management
- Bridge mechanism: Shell exports state to temporary files, Python analyzes and reports back

### Critical Integration Points
- ___Environment variables___: `WHYP_SOURCE`, `WHYP_DIR`, `WHYP_PY` connect shell and Python layers
- ___State transfer___: Aliases (`/tmp/aliases`) and functions (`/tmp/functions`) exported before Python analysis
- ___Persistent tracking___: `whyp/sources/sources.yaml` maintains shell source file history

## Development Commands

### Installation and Setup
```bash
# Install Python package
python setup.py install

# Source shell functions into current session
source whyp.sh

# Add to ~/.bashrc permanently  
echo "source $(readlink -f whyp.sh)" >> ~/.bashrc
```

### Testing
```bash
# Run all tests with tox
tox

# Run tests directly with pytest
py.test --cov=whyp --doctest-modules --doctest-glob="*.test" --doctest-glob="*.tests"

# Run specific doctest file
python -m doctest whyp/test/arguments.test
```

### Documentation
```bash
# Build HTML documentation
cd docs && make html

# Run documentation doctests
cd docs && make doctest

# Clean documentation build
cd docs && make clean
```

## Architecture Deep Dive

### Command Discovery Pipeline
1. ___Shell layer___: User invokes `whyp`, `w`, `ww`, or `e` functions
2. ___State export___: Shell functions export aliases/functions to temp files  
3. ___Python analysis___: `whyp/why.py` analyzes command via `shell.py`, `sources.py`
4. ___Result display___: Python returns formatted output to shell function
5. ___Editor integration___: `e` function launches `$EDITOR` with discovered source location

### Module Responsibilities
- ___`whyp/why.py`___: Central command discovery orchestration and display logic
- ___`whyp/shell.py`___: PATH analysis and shell environment interaction
- ___`whyp/python.py`___: Python module discovery (equivalent to `which` for imports)
- ___`whyp/sources.py`___: Shell source file tracking and YAML persistence
- ___`whyp/arguments.py`___: Global command-line argument parsing and state management

### Directory Structure Context
- ___`bin/`___: Executable CLI scripts (`sources`, `whyp-python`) for standalone usage
- ___`whyp/test/`___: Doctest files (`.test` format) for pytest discovery with shell dependencies
- ___`whyp/sources/`___: YAML configuration and persistence system for shell integration
- ___`docs/`___: Sphinx documentation with executable examples and doctest validation

## Daily Usage Patterns

### Interactive Commands
- ___`w python`___: Show command type and location
- ___`ww cd`___: Show command content with verbose details
- ___`e whyp`___: Edit command source in `$EDITOR`
- ___`whyp up -v`___: Verbose alias expansion and analysis

### Python Module Discovery
```bash
# Find Python import locations
bin/whyp-python os sys

# Check module versions
bin/whyp-python -v requests
```

### Source Management
```bash
# Show tracked shell source files
bin/sources --all

# Clear source tracking
bin/sources --clear
```

## Dependencies and Requirements

- Python 3.7+ with packages: `pprintpp`, `pysyte`, `pyyaml`, `requests`
- Bash shell with standard utilities (`alias`, `declare`, `type`, `which`)
- Optional: `vimcat`, `bat` for enhanced file viewing

This hybrid architecture enables powerful command analysis while maintaining seamless bash shell integration.