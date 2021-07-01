.PHONY: install

install-requirements:
	cp ../../google_service_account_creds.json key_file.json
	python3 -m venv venv
	. venv/bin/activate && sudo pipenv lock --requirements > requirements.txt
	. venv/bin/activate && sudo pip install --target ./lib -r requirements.txt
