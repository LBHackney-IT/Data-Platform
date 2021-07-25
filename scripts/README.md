## Running the tests

Prerequisites
  - You will need `docker` installed

Running the tests
  - `make test`

## Debugging Spark portion of tests

While `make test` is running, you can access the [Spark Web UI][spark_web_ui] on http://localhost:4040

To inspect previous test runs, you can run the history server with `make history-server` and
access it on http://localhost:18080

[spark_web_ui]: https://spark.apache.org/docs/latest/monitoring.html#web-interfaces
