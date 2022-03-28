#! /bin/bash
set -eu -o pipefail


source .venv/bin/activate
python setup.py bdist_wheel
