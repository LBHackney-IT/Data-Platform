@echo off

call .venv\Scripts\activate
python "scripts\setup.py" "bdist_wheel"