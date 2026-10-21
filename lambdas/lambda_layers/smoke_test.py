"""Import every top-level module provided by the packages in a layer's
requirements file, so a layer the Lambda runtime can't load fails the build.

Usage: PYTHONPATH=<layer>/python python3 smoke_test.py requirements<N>.txt
"""

import importlib
import re
import sys
from importlib.metadata import packages_distributions


def normalise(name):
    return re.sub(r"[-_.]+", "-", name).lower()


def requirement_names(path):
    with open(path) as file:
        for line in file:
            line = line.split("#", 1)[0].strip()
            if line:
                yield normalise(re.split(r"[\s\[<>=!~;]", line, maxsplit=1)[0])


def main(path):
    modules_by_dist = {}
    for module, dists in packages_distributions().items():
        for dist in dists:
            modules_by_dist.setdefault(normalise(dist), set()).add(module)

    for name in requirement_names(path):
        modules = modules_by_dist.get(name)
        if not modules:
            sys.exit(f"No importable modules found for {name}")
        for module in sorted(modules):
            importlib.import_module(module.replace("/", "."))
            print(f"Imported {module} from {name}")


if __name__ == "__main__":
    main(sys.argv[1])
