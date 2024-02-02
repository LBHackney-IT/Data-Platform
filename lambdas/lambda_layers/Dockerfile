# Use the Ubuntu latest image
FROM ubuntu:latest

# Install system dependencies and zip
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y zip python3.11 python3-pip

# Install pip
RUN python3.11 -m pip install --upgrade pip

# Set the working directory in the container
WORKDIR /app

# Copy the first requirements.txt to the container
COPY requirements1.txt /app/requirements1.txt
# Install Python dependencies for the first layer
RUN mkdir -p /app/layer1/python && \
    pip install -t /app/layer1/python -r requirements1.txt && \
    cd /app/layer1 && \
    zip -r /app/layer1.zip .

# Copy the second requirements.txt to the container
COPY requirements2.txt /app/requirements2.txt
# Install Python dependencies for the second layer
RUN mkdir -p /app/layer2/python && \
    pip install -t /app/layer2/python -r requirements2.txt && \
    cd /app/layer2 && \
    zip -r /app/layer2.zip .

# Copy the third requirements.txt to the container
COPY requirements3.txt /app/requirements3.txt
# Install Python dependencies for the third layer
RUN mkdir -p /app/layer3/python && \
    pip install -t /app/layer3/python -r requirements3.txt && \
    cd /app/layer3 && \
    zip -r /app/layer3.zip .

# Copy the forth requirements.txt to the container
COPY requirements4.txt /app/requirements4.txt
# Install Python dependencies for the forth layer
RUN mkdir -p /app/layer4/python && \
    pip install -t /app/layer4/python -r requirements4.txt && \
    cd /app/layer4 && \
    zip -r /app/layer4.zip .

# Copy the fith requirements.txt to the container
COPY requirements5.txt /app/requirements5.txt
# Install Python dependencies for the fith layer
RUN mkdir -p /app/layer5/python && \
    pip install -t /app/layer5/python -r requirements5.txt && \
    cd /app/layer5 && \
    zip -r /app/layer5.zip .

# Copy the sixth requirements.txt to the container
COPY requirements6.txt /app/requirements6.txt
# Install Python dependencies for the sixth layer
RUN mkdir -p /app/layer6/python && \
    pip install -t /app/layer6/python -r requirements6.txt && \
    cd /app/layer6 && \
    zip -r /app/layer6.zip .

# Copy the seventh requirements.txt to the container
COPY requirements7.txt /app/requirements7.txt
# Install Python dependencies for the seventh layer
RUN mkdir -p /app/layer7/python && \
    pip install -t /app/layer7/python -r requirements7.txt && \
    cd /app/layer7 && \
    zip -r /app/layer7.zip .

