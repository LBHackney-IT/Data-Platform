## Running the tests

### Requirements

Ensure you have [docker][docker-install] installed on your computer and it is running locally before running the tests.

[docker-install]: https://docs.docker.com/get-docker/

### Running the tests

## On MacOS/Linux

From within this (the /scripts) folder run:
  - `make test` to run all the tests
  - `make test-watch` to run all the tests, in a loop whenever a file changes

You can add a filename option to either of these commands to only run one test file, for example `make filename=test_address_cleaning.py test`

## On Windows
There are three different options for running the tests, all must be run from inside the /scripts folder.

1. To run all of the tests:
```sh
docker compose up unit_tests
```

2. To run all the tests and have them automatically rerun when a file changes:
```sh
docker compose run --entrypoint "bash -c 'pip install -r requirements.txt  && pytest-watch'" unit_tests
```

3. To run a single test file, replace ./my-test-file.py with the name of the test file:

#### Using Bash shell
```sh
export filename=my-test-file.py && docker compose up unit_tests
```

#### Using PowerShell
```sh
$env:filename = 'my-test-file.py' ; docker-compose up unit_tests
```

It is recommended that you run the tests and confirm that they are all passing before writing your own tests.

### Within the pipeline

The tests are run as a step in GitHub Actions and will run when a commit is pushed to GitHub or when a Pull Request is created/merged.

If there is a failing test then the “Run tests” step will fail and this will need to be fixed before your change can be merged into the main branch.

## Debugging Spark portion of tests

While `make test` is running, you can access the [Spark Web UI][spark_web_ui] on http://localhost:4040

To inspect previous test runs, you can run the history server with `make history-server` and
access it on http://localhost:18080

[spark_web_ui]: https://spark.apache.org/docs/latest/monitoring.html#web-interfaces
