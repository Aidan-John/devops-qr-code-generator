FROM python:3.10

# Set the working directory
WORKDIR /usr/src/app

# Copy the requirements file into the container

COPY requirements.txt .

# Install the dependencies

RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code into the container

COPY . .

# Command to run the application

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]