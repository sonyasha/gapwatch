resource "aws_ecr_repository" "gapwatch_ingestion" {
  name                 = var.repository_name
  image_tag_mutability = "MUTABLE"

  tags = {
    Name        = var.repository_name
    Environment = var.environment
  }
}

resource "aws_ecr_lifecycle_policy" "gapwatch_ingestion_policy" {
  repository = aws_ecr_repository.gapwatch_ingestion.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Expire untagged images after 7 days",
        selection = {
          tagStatus     = "untagged"
          countType     = "sinceImagePushed"
          countUnit     = "days"
          countNumber   = 7
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}