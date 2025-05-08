# Use AWS Lambda Python base image
FROM public.ecr.aws/lambda/python:3.11

# Set working directory inside the Lambda container
WORKDIR /var/task

# Copy and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Download the spaCy model inside the image
RUN python -m spacy download en_core_web_sm

COPY . .

CMD ["fetch_news.lambda_handler"]