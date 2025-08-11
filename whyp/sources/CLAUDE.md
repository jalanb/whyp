# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Sources Directory Overview

This directory contains configuration data for tracking shell source files that provide aliases and functions to the whyp system. It serves as the persistent storage mechanism for bash integration.

## Architecture

### YAML Configuration
- ___Single data file___: `sources.yaml` contains a list of shell script paths
- ___User-specific paths___: Tracks personal shell configuration files, virtualenv activations, and project-specific scripts
- ___Persistent tracking___: Maintains knowledge of which shell files have been sourced

### Integration Points

___Shell Integration Chain___:
1. User sources shell scripts (bashrc, virtualenvs, project scripts)
2. `sources.yaml` tracks these sourced files persistently  
3. `whyp/sources.py` module loads this configuration
4. Shell functions in `whyp.sh` use this data for alias/function discovery

### Data Structure
The `sources.yaml` file contains a flat list of absolute file paths to shell scripts:
- Personal configuration files (`.bashrc`, `.profile`)
- Virtual environment activation scripts
- Project-specific shell utilities  
- Git completion and status scripts
- Keyboard shortcut definitions

## Core Functionality

### Sources Management (`whyp/sources.py`)
- ___Load/Save___: YAML persistence of source file paths
- ___Validation___: Checks file existence before tracking
- ___Optional mode___: Graceful handling when files don't exist

### CLI Tool (`bin/sources`)  
```bash
# Show all tracked source files
sources --all

# Check if any sources are tracked
sources --any  

# Clear all tracked sources
sources --clear

# Check if specific file is tracked
sources --found /path/to/file.sh
```

## Development Patterns

### Source File Discovery
The system expects shell integration where:
1. User sources various shell scripts during session setup
2. These get registered in `sources.yaml` for persistence
3. `whyp` commands can then analyze aliases/functions from these files

### Error Handling
- ___YAML dependency___: Raises `YamlNotFoundError` if PyYAML not available
- ___Optional mode___: `--optional` flag allows graceful degradation
- ___File validation___: Filters non-existent files during save operations

This directory bridges the gap between dynamic shell state and persistent Python analysis.