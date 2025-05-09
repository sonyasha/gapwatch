# Auto-load ECR URI from Terraform output
ECR_URI := $(shell terraform -chdir=terraform output -raw ecr_repository_url)
IMAGE_NAME := gapwatch-ingestion
IMAGE_TAG := latest
IMAGE_FULL := $(ECR_URI):$(IMAGE_TAG)

.PHONY: docker-publish docker-build docker-tag docker-push ecr-login clean-ecr

ecr-login:
	@echo "Logging into ECR"
	aws ecr get-login-password | docker login --username AWS --password-stdin $(ECR_URI)

docker-build:
	@echo "Building image"
	docker build --no-cache -t $(IMAGE_NAME) ingestion/

docker-tag:
	@echo "Tagging image as $(IMAGE_FULL)"
	docker tag $(IMAGE_NAME):latest $(IMAGE_FULL)

docker-push:
	@echo "Pushing to ECR"
	docker push $(IMAGE_FULL)

docker-publish: ecr-login docker-build docker-tag docker-push

## Delete old image from ECR (by tag)
clean-ecr:
	@echo "Deleting image with tag 'latest' from ECR..."
	aws ecr batch-delete-image \
	  --repository-name $(IMAGE_NAME) \
	  --image-ids imageTag=$(IMAGE_TAG)
