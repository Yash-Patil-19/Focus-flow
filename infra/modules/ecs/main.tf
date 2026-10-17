resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7
  tags              = { Name = "/ecs/${var.project_name}" }
}
resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = { Name = "${var.project_name}-cluster" }
}
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.project_name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = var.task_execution_role_arn
  container_definitions = jsonencode([{
    name      = "focusflow"
    image     = var.image_uri
    essential = true
    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]
    healthCheck = {
      command     = ["CMD-SHELL", "wget -q -O /dev/null http://127.0.0.1:${var.container_port}/health || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 10
    }
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.this.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
  tags = { Name = "${var.project_name}-task" }
}
resource "aws_ecs_service" "this" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  enable_execute_command = false
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  network_configuration {
    assign_public_ip = false
    security_groups  = [var.ecs_security_group_id]
    subnets          = var.private_subnet_ids
  }
  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "focusflow"
    container_port   = var.container_port
  }
  depends_on = [aws_cloudwatch_log_group.this]
  tags       = { Name = "${var.project_name}-service" }
}
