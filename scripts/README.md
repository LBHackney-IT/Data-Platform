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
docker run --rm -p "4040:4040" -w /root/scripts -v %cd%:/root/scripts amazon/aws-glue-libs:glue_libs_1.0.0_image_01 /home/aws-glue-libs/bin/gluepytest --durations=0
```

2. To run all the tests and have them autmatically rerun when a file changes:
```sh
docker run --rm -p "4040:4040" -w /root/scripts -v %cd%:/root/scripts amazon/aws-glue-libs:glue_libs_1.0.0_image_01 bash -c 'pip install pytest-watch && pytest-watch'
```

3. To run a single test file, replace ./my-test-file.py with the name of the test file:
```sh
docker run --rm -p "4040:4040" -w /root/scripts -v %cd%:/root/scripts amazon/aws-glue-libs:glue_libs_1.0.0_image_01 /home/aws-glue-libs/bin/gluepytest ./my-test-file.py --durations=0
```

It is recommended that you run the tests and confirm that they are all passing before writing your own tests.

### Within the pipeline

The tests are run as a step in GitHub Actions and will run when a commit is pushed to GitHub or when a PR is created/merged.

If there is a failing test then the “Python Unit Tests” step will fail and this will need to be fixed before your change is merged into the main branch.

## Debugging Spark portion of tests

While `make test` is running, you can access the [Spark Web UI][spark_web_ui] on http://localhost:4040

To inspect previous test runs, you can run the history server with `make history-server` and
access it on http://localhost:18080

[spark_web_ui]: https://spark.apache.org/docs/latest/monitoring.html#web-interfaces
