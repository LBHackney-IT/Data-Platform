.PHONY: test test-watch

.venv/bin/python:
	python3 -m venv .venv

.venv/.install.stamp: .venv/bin/python requirements.txt
	.venv/bin/python -m pip install -r requirements.txt
	touch .venv/.install.stamp

test: .venv/.install.stamp
	.venv/bin/python -m unittest test_install_kafka_connectors.py

test-watch: .venv/.install.stamp
	.venv/bin/pytest-watch .
