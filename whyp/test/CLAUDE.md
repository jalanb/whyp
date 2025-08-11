# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Test Directory Overview

This directory contains doctests for the whyp Python modules, using a unique `.test` file format that pytest processes via doctest discovery.

## Test Framework

### Doctest Files
- ___File naming___: Tests use `.test` and `.tests` extensions 
- ___Format___: ReStructuredText-style headers with embedded doctests
- ___Discovery___: pytest finds tests via `--doctest-glob="*.test"` and `--doctest-glob="*.tests"`

### Test Dependencies
Tests depend on actual shell environment state:
- Aliases read from `/tmp/aliases` 
- Functions read from `/tmp/functions`
- Shell integration requires `whyp.sh` to be sourced

## Running Tests

### From Project Root
```bash
# Run all tests with tox
tox

# Run tests directly with pytest  
py.test --cov=whyp --doctest-modules --doctest-glob="*.test" --doctest-glob="*.tests"
```

### Single Test File
```bash
# Run specific test file
python -m doctest arguments.test

# Run with pytest for better output
py.test --doctest-modules arguments.test
```

## Test Patterns

### Module Testing Structure
Each `.test` file follows this pattern:
1. ___Module import___: `>>> from whyp import module_name`
2. ___Setup section___: Import dependencies, set up test data
3. ___Feature sections___: Test specific functionality with descriptive headers
4. ___Environment-dependent tests___: Conditional tests based on platform (`platforms.name == 'darwin'`)

### Environment Dependencies
- ___Platform-specific___: Some tests only run on specific platforms (e.g., Darwin)
- ___Shell state___: Tests expect certain aliases/functions to exist
- ___File system___: Tests may create temporary files in `/tmp/`

### Coverage Strategy
- ___Module doctests___: Each core module has a corresponding `.test` file
- ___Integration tests___: `why.tests` contains more complex integration scenarios
- ___Shell integration___: Tests verify shell function bridging works correctly