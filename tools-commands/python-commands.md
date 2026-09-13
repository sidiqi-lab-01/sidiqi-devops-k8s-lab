# Python Command Reference

## Version

Command:

    python3 --version

Usage:

Displays the installed Python version.

## Run Script

Command:

    python3 script.py

Usage:

Executes a Python script.

## Interactive Interpreter

Command:

    python3

Usage:

Starts an interactive Python session.

## Syntax Compilation

Command:

    python3 -m py_compile app.py

Usage:

Checks whether Python source can be compiled successfully.

This does not guarantee runtime imports or application behavior will work.

## Create Virtual Environment

Command:

    python3 -m venv .venv

Usage:

Creates an isolated Python environment.

## Activate Virtual Environment

Command:

    source .venv/bin/activate

Usage:

Activates the virtual environment in the current shell.

## Deactivate

Command:

    deactivate

Usage:

Leaves the active virtual environment.

## Install Package

Command:

    python3 -m pip install requests

Usage:

Installs a Python package.

## Install Requirements

Command:

    python3 -m pip install -r requirements.txt

Usage:

Installs dependencies defined in requirements.txt.

## List Packages

Command:

    python3 -m pip list

Usage:

Displays installed Python packages and versions.

## Package Information

Command:

    python3 -m pip show flask

Usage:

Displays information about an installed package.

## Freeze Dependencies

Command:

    python3 -m pip freeze

Usage:

Outputs installed package versions in requirements-file format.

## Test Module Import

Command:

    python3 -c "import flask; print('Flask import successful')"

Usage:

Tests whether a Python module can be imported at runtime.

## Inline Python

Command:

    python3 -c "print('DevOps automation')"

Usage:

Runs a short Python expression from the shell.

## JSON Validation

Command:

    python3 -m json.tool file.json

Usage:

Validates and formats a JSON file.

## Simple Web Server

Command:

    python3 -m http.server 8000

Usage:

Starts a temporary HTTP server on port 8000 for testing.
