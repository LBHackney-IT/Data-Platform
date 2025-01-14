# Use the Ubuntu latest image
FROM ubuntu:22.04

# Define a build-time variable
ARG L_N

# Install system dependencies and zip
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y zip python3.9 python3-pip

# Install pip
RUN python3.9 -m pip install --upgrade pip

# Create a non-root user and group
RUN addgroup --system docker_users \
    && adduser --system --ingroup docker_users docker_user

# Switch to non-root user
USER docker_user

# Set the working directory in the container
WORKDIR /app

# Copy the first requirements.txt to the container
COPY requirements${L_N}.txt /app/requirements${L_N}.txt

# Install Python dependencies for the first layer
RUN mkdir -p /app/layer${L_N}/python && \
    pip install -t /app/layer${L_N}/python -r requirements${L_N}.txt && \
    cd /app/layer${L_N} && \
    zip -r /app/layer${L_N}.zip .
