# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Documentation Overview

This directory contains Sphinx-based documentation for the whyp project, providing comprehensive user guides and examples. The documentation is written in reStructuredText and built to HTML for web viewing.

## Documentation Build System

### Sphinx Configuration
- ___Build tool___: Sphinx with standard Makefile
- ___Source format___: reStructuredText (`.rst`)
- ___Extensions___: `autodoc`, `doctest`, `viewcode` for Python integration
- ___Theme___: Default Sphinx theme

### Build Commands
```bash
# Build HTML documentation
make html

# Clean build artifacts  
make clean

# Run doctests in documentation
make doctest

# Check external links
make linkcheck

# View available targets
make help
```

## Content Architecture

### Main Documentation (`index.rst`)
___Comprehensive user guide___ covering:
- Installation instructions for both bash and Python
- Daily usage examples with `w`, `ww`, `e` commands  
- Detailed `whyp` functionality with verbose/quiet flags
- Python module discovery via `whypyp`
- Platform compatibility information

### Historical Context
The documentation reflects the project's evolution:
- ___Original name___: "what" (extends `which`)
- ___Current name___: "whyp" (combination of "what" + "type") 
- ___Configuration artifacts___: Some config still references "what"

### Content Highlights
___Usage patterns___:
- `w python` - show command type
- `ww cd` - show command content  
- `e whyp` - edit command source
- `whyp up -v` - verbose alias expansion

## Build Artifacts

### Generated Output
- ___HTML files___: `_build/html/` directory
- ___Static assets___: CSS, JavaScript, images in `_build/html/_static/`
- ___Search index___: Generated searchindex.js for documentation search

### Images Directory
Contains project assets:
- `logo.png`: Project logo
- `jetbrains.png`: JetBrains PyCharm acknowledgment

## Development Integration

### Version Synchronization
- Documentation version (0.6/0.7.26) should match `whyp/__init__.py` version
- Configuration references need updating from "what" to "whyp"

### Doctest Integration  
Documentation includes executable examples that can be tested:
```bash
make doctest  # Validates code examples in documentation
```

This documentation serves as both user guide and validation system, ensuring examples stay current with the codebase through Sphinx's doctest integration.