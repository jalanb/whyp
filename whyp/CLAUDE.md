# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Python Package Overview

This directory contains the core Python modules for the whyp command discovery system. These modules handle the heavy computational work of analyzing shell environments, discovering commands, and interfacing with the shell integration layer.

## Module Architecture

### Core Discovery Engine
- ___`why.py`___: Central command discovery and display logic with shell integration
- ___`shell.py`___: Environment PATH analysis and shell command detection
- ___`python.py`___: Python module discovery system (equivalent to `which` for imports)

### Support Infrastructure  
- ___`arguments.py`___: Global command-line argument parsing and state management
- ___`sources.py`___: Shell source file tracking and persistence via YAML
- ___`__main__.py`___: Primary CLI entry point for `python -m whyp`

## Key Integration Patterns

### Shell State Bridge
The modules expect shell state to be pre-exported to temporary files:
- Aliases written to `/tmp/aliases` via shell `alias > /tmp/aliases`
- Functions written to `/tmp/functions` via `declare -f > /tmp/functions`
- Source files tracked in `sources/sources.yaml` for persistence

### Command Discovery Flow
1. ___`arguments.py`___ processes CLI options and stores globally
2. ___`why.py`___ orchestrates discovery: aliases → functions → PATH → files
3. ___`shell.py`___ handles PATH analysis and executable detection
4. ___`sources.py`___ provides persistence for shell integration tracking

### Python Module Discovery
___`python.py`___ provides parallel functionality for Python imports:
- Searches `sys.path` for modules/packages
- Handles importability testing
- Supports version-specific Python discovery

## Development Context

### Shell Integration Requirements
These modules are designed to be called from bash functions in `../whyp.sh`:
- Environment variables `WHYP_DIR`, `WHYP_PY` provide integration points
- Temporary file paths are coordinated between shell and Python layers
- Shell functions export state before calling Python analysis

### Child Directory Context
- ___`test/`___: Contains doctest files (`.test` format) for pytest discovery
- ___`sources/`___: Houses YAML configuration and persistence logic

This package serves as the computational backend for the hybrid bash/Python whyp system, handling command analysis while relying on shell integration for state management.