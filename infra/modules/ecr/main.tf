resource "aws_ecr_repository" "this" {
  name                 = "${var.project_name}-app"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  # ECR is retained when the infrastructure is destroyed to avoid accidental image loss.
  force_delete = false
  tags         = { Name = "${var.project_name}-app" }
}
