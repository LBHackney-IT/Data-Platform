.PHONY: install

install-requirements:
	python3 -m venv venv
	. venv/bin/activate && sudo pipenv lock --requirements > requirements.txt
	. venv/bin/activate && sudo pip install --target ./lib -r requirements.txt
