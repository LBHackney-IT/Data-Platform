# Use the python docker image
FROM ubuntu:latest

# Install system dependencies, pipenv and zip
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y zip
RUN apt-get install -y python3.9 python3-pip

RUN pip3 install pipenv

# Set the working directory in the container

WORKDIR /app

# Copy the Pipfile, Pipfile.lock and main.py to the container
COPY Pipfile Pipfile.lock /app/
COPY main.py ./source/

# Install Python dependencies using pipenv
RUN pipenv install
RUN pipenv requirements > requirements.txt
RUN pip install -t ./source/lib -r requirements.txt

# Set the working directory to the container source
WORKDIR /app/source
RUN zip -r g_drive_folder_to_s3.zip .

CMD "pyhon3", "main.py"
