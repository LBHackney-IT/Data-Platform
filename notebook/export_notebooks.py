# This script exports all the .ipynb files as python files into the scripts directory. To prevent overwrite of files I
# I have set the extension to be .notebook.py
import os
import glob
import nbformat
from nbconvert.exporters import PythonExporter
from nbconvert.preprocessors import TagRemovePreprocessor
from yapf.yapflib.yapf_api import FormatCode  # reformat a string of code

notebooks = glob.glob("./scripts/*.ipynb")

def write_lines(python_script_lines):
    with open("../scripts/" + filename.replace('-', '_') + ".notebook.py", 'w', encoding='utf-8') as output_file:
        for line in python_script_lines:
            if not line.strip().startswith("#") and not line.isspace():
                output_file.write(line + '\n')

def write_file(python_script):
    with open("../scripts/" + filename.replace('-', '_').lower() + ".notebook.py", 'w', encoding='utf-8') as output_file:
        output_file.writelines(python_script)

for notebook in notebooks:
    full_filename = os.path.split(os.path.realpath(notebook))[1].lower()
    filename = os.path.splitext(full_filename)[0]
    print(filename)

    with open("./scripts/" + full_filename, 'r', encoding='utf-8') as f:
        the_notebook_nodes = nbformat.read(f, as_version = 4)

    trp = TagRemovePreprocessor()
    trp.remove_cell_tags = ("remove",)

    pexp = PythonExporter()
    pexp.register_preprocessor(trp, enabled= True)

    the_python_script, meta = pexp.from_notebook_node(the_notebook_nodes)
    python_script_lines = the_python_script.split("\n")
    formatted_code, changed = FormatCode("\n".join(python_script_lines))
    write_file(formatted_code)