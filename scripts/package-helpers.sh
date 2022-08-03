#! /bin/bash
set -eu -o pipefail


source .venv/bin/activate
python scripts/setup.py bdist_wheel
