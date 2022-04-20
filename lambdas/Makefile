.PHONY: test

.venv/bin/python:
	python3 -m venv .venv

.venv/.install.stamp: .venv/bin/python requirements.test.txt
	.venv/bin/python -m pip install -r requirements.test.txt
	touch .venv/.install.stamp

test: .venv/.install.stamp
	.venv/bin/python -m unittest */test.py
