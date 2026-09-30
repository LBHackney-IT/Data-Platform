# Build on the Lambda python3.11 base image (Amazon Linux 2, glibc 2.26) so pip
# only selects wheels the runtime can load. Keep in step with the layers'
# compatible_runtimes and lambdas/.python-version.
FROM public.ecr.aws/lambda/python:3.11

# Define a build-time variable
ARG L_N

# Set the working directory in the container, owned by a non-root user
WORKDIR /app
RUN chown 1000 /app
USER 1000

COPY requirements${L_N}.txt smoke_test.py /app/

# Install the layer's dependencies, check they import on this runtime, then zip
RUN mkdir -p /app/layer${L_N}/python && \
    pip install --no-cache-dir --prefer-binary -t /app/layer${L_N}/python -r requirements${L_N}.txt && \
    PYTHONPATH=/app/layer${L_N}/python python3 smoke_test.py requirements${L_N}.txt && \
    cd /app/layer${L_N} && \
    python3 -m zipfile -c /app/layer${L_N}.zip python

# Reset the Lambda entrypoint so `docker run <image> env` exits immediately
ENTRYPOINT []
