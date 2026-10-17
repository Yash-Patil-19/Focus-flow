# Reference repository review

Public reference inspected: `mohammed-972/terraform-ecs-pomodoro` (default branch `main`). Review was based on the README, app/Dockerfile, app/index.html, app/nginx.conf, infra main/provider/backend/variables/route53 files, the application and deploy workflows, and core Terraform modules for VPC, security groups, ALB, ECR, ECS, IAM, and ACM.

## Architecture observed

- Static Pomodoro HTML/CSS/JavaScript served through Nginx in a Docker container.
- VPC with two public and two private subnets, Internet Gateway, NAT Gateway, Application Load Balancer, ECS Fargate tasks, ECR, CloudWatch logs, IAM task execution role.
- ACM and Route 53 integrate TLS and custom DNS.
- GitHub Actions publishes an image tagged with the commit SHA; a manual Terraform deploy workflow takes the image tag; a destroy workflow removes infrastructure.

## Items corrected or intentionally simplified in this version

1. Original backend bucket and AWS account/role values are specific to the original author and must not be reused.
2. The original provider uses a specific region and task log configuration hard-codes that region. This version makes region a Terraform variable and uses it for logs.
3. The original VPC output values appear to mix up the second public and private subnet references. This version uses splat outputs from each subnet resource, keeping the lists correct.
4. The reference uses a fixed DNS zone and ACM certificate. This version starts with HTTP and the ALB DNS name to avoid requiring a domain before first deployment.
5. The reference IAM trust policy is pinned to the original account. This version derives the current account and partition for the ECS task execution role.
6. The original ECS app has no explicit Terraform-managed health check in its container definition. This version configures a container health check and ALB `/health` check.
7. The original has a long-lived NAT gateway and ALB, both potentially chargeable. This version documents cleanup prominently and uses one NAT gateway as a cost tradeoff.
8. The source destroy workflow path in the tree is `terrafrom-destroy.yml` (misspelled) although README documents `terraform-destroy.yml`; this project uses a consistent path.

## Scope choices

This is an original implementation patterned after the high-level architecture, with new UI, styles, JavaScript, Terraform module names, workflow files, identifiers, and documentation. It intentionally omits custom domain and ACM in the first pass. OIDC role provisioning is documented as an AWS account setup step because GitHub connector access cannot create infrastructure or secrets in the user's own account without their authorization.

## Verification caveat

Files are generated from source review, but Terraform has not been run against an AWS account in this environment. Run `terraform fmt -recursive`, `terraform init`, and `terraform validate` locally before `apply`; inspect the plan carefully. Provider/API changes or account-level SCP/permissions may require adjustment.
