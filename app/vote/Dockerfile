# Using official python runtime base image
FROM python:2.7-alpine

MAINTAINER laurent.bernaille@d2-si.eu

ARG version

ADD Dockerfile /Dockerfile
LABEL eu.d2-si.python_version="2.7"
LABEL eu.d2-si.application="vote"
LABEL eu.d2-si.version="${version}"

# Set the application directory
WORKDIR /app

# Install our requirements.txt
ADD requirements.txt /app/requirements.txt
RUN pip install -r requirements.txt

# Copy our code from the current folder to /app inside the container
ADD . /app

# Make port 80 available for links and/or publish
EXPOSE 80

# Define our command to be run when launching the container
CMD ["gunicorn", "app:app", "-b", "0.0.0.0:80", "--log-file", "-", "--access-logfile", "-", "--workers", "4", "--keep-alive", "0"]
