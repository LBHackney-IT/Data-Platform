.PHONY: install-requirements

install-requirements:
	python3 -m venv venv
	# the requirements are generated so that the packages
	# could be downloaded and packaged up for the lambda
	. venv/bin/activate && sudo pipenv lock --requirements > requirements.txt
	. venv/bin/activate && sudo pip install --target ./lib -r requirements.txt
	rm -rf venv/
