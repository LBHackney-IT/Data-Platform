.PHONY: test test-watch

.venv/bin/python:
	python3 -m venv .venv

.venv/.install.stamp: .venv/bin/python requirements.txt
	.venv/bin/python -m pip install -r requirements.txt
	touch .venv/.install.stamp

.venv-test/bin/python:
	python3 -m venv .venv-test

.venv-test/.install.stamp: .venv-test/bin/python requirements.test.txt
	.venv-test/bin/python -m pip install -r requirements.test.txt
	touch .venv-test/.install.stamp

test: .venv-test/.install.stamp
	.venv-test/bin/python -m unittest test_install_kafka_connectors.py

test-watch: .venv-test/.install.stamp
	.venv-test/bin/pytest-watch .
