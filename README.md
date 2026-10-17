# FocusFlow: Dockerized Pomodoro on AWS ECS Fargate

An independently written portfolio project inspired by the architecture of a public Terraform/ECS example. It is not affiliated with or a copy of the original repository.

## What it includes

- Responsive Pomodoro timer with focus, short-break, and long-break sessions
- Nginx serving static content inside an unprivileged Docker container
- `/health` endpoint for ALB target-group health checks
- Terraform-managed VPC, two public and two private subnets, Internet Gateway, single NAT Gateway, security groups, ALB, ECR, ECS Fargate, CloudWatch logs, and IAM task-execution role
- GitHub Actions workflow to build and publish immutable SHA-tagged container images to ECR using GitHub OIDC
- Separate manual Terraform deploy and destroy workflows

## Important cost/safety notes

A NAT Gateway and an Application Load Balancer can incur charges while running, even with low traffic. The default infrastructure uses one NAT Gateway to keep cost lower than one-per-AZ, but it is still a billable resource. Run `terraform destroy` when finished. The ECR repository is intentionally retained by default; delete it separately if you do not need the images. This project does not configure a custom domain or HTTPS certificate: add those only after the basic deployment is verified.

Never commit AWS access keys, Terraform state, `.tfvars` files containing secrets, or downloaded credentials.

## Prerequisites

- AWS account with permission to create VPC, EC2 networking, ELB, ECS, ECR, CloudWatch Logs, IAM roles/policies, and S3 resources if using remote state
- AWS CLI configured locally (`aws sts get-caller-identity` works)
- Docker Desktop, Git, Terraform 1.8+
- GitHub repository under your account

## 1. Run locally

```powershell
docker build -t focusflow-app ./app
docker run --rm -p 8080:8080 focusflow-app
```

Open `http://localhost:8080`. Test health from another PowerShell window:

```powershell
curl.exe -i http://localhost:8080/health
```

Expected health body: `ok`.

## 2. Create your GitHub repository

Create an empty repository called `aws-ecs-focusflow` under your GitHub account, then:

```powershell
git init
git add .
git commit -m "Initial FocusFlow ECS Fargate project"
git branch -M main
git remote add origin https://github.com/YOUR_GITHUB_USERNAME/aws-ecs-focusflow.git
git push -u origin main
```

Replace `YOUR_GITHUB_USERNAME`. Do not push the reference repository into your account unchanged.

## 3. Bootstrap infrastructure locally

This starter uses local Terraform state for the first learning deployment so it can be started without already having a state bucket. Keep `infra/terraform.tfstate*` private and backed up. For team/production use, migrate to an S3 remote backend with a bucket you own and locking enabled.

```powershell
aws sts get-caller-identity
cd infra
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

`terraform apply` creates billable resources. Review the plan first. After successful apply, obtain the ECR URL and ECS service outputs:

```powershell
terraform output
```

For first-time bootstrap, Terraform creates ECR and ECS together, but the initial image must exist before ECS can start a healthy task. If the first apply leaves ECS tasks unable to pull an image, continue to the first-image step below, then run `terraform apply` again.

## 4. Build and push first image from your computer

Sign in to ECR using the account ID from `aws sts get-caller-identity`. Replace region and account ID as needed:

```powershell
$REGION = "eu-west-1"
$ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text)
$REPO = "focusflow-app"
$REGISTRY = "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REGISTRY
docker build -t "$REGISTRY/$REPO:bootstrap" ./app
docker push "$REGISTRY/$REPO:bootstrap"
```

Then deploy with image tag `bootstrap`:

```powershell
cd infra
terraform apply -var="image_tag=bootstrap"
```

## 5. Configure GitHub OIDC for CI/CD

1. In IAM, create an OIDC identity provider for `https://token.actions.githubusercontent.com` if your AWS account does not already have one. Audience: `sts.amazonaws.com`.
2. Create a dedicated IAM role with a trust policy restricted to your repository and `refs/heads/main`. Do not use the source repo's role ARN.
3. Attach only the permissions needed for ECR image push. To run Terraform deployments in Actions, the role also needs the carefully scoped infrastructure permissions for this project's resources. For a learning account, use a dedicated role and tighten permissions after validating the workflow; avoid using root credentials.
4. In GitHub repository Settings → Secrets and variables → Actions → Variables, add:
   - `AWS_ROLE_ARN`: ARN of your own OIDC role
   - `AWS_REGION`: e.g. `eu-west-1`
   - `ECR_REPOSITORY`: `focusflow-app`
5. In `infra/terraform.tfvars`, set `image_tag` to the tag you want deployed, or use the manual deploy workflow input.
6. Push a change under `app/`; the application workflow publishes the image tagged with the commit SHA. Run the manual Terraform Deploy workflow and enter that full commit SHA to deploy it.

GitHub Actions OIDC avoids storing static AWS access keys in GitHub secrets. Keep the trust policy narrowly scoped.

## 6. Verify deployment

```powershell
terraform output -raw alb_dns_name
```

Open the resulting `http://...elb.amazonaws.com` address. Test the health endpoint:

```powershell
curl.exe -i http://YOUR_ALB_DNS/health
```

## 7. Clean up

From `infra/`:

```powershell
terraform destroy
```

Review the destroy plan and type `yes` only if the listed resources belong to this project. The ECR repository may be retained intentionally. Empty/delete it and remove it in the AWS console if you want a fully clean account.

## Repository structure

```text
aws-ecs-focusflow/
├── app/
│   ├── index.html
│   ├── css/style.css
│   ├── js/app.js
│   ├── Dockerfile
│   └── nginx.conf
├── infra/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   ├── terraform.tfvars.example
│   └── modules/
│       ├── network/
│       ├── security/
│       ├── ecr/
│       ├── alb/
│       ├── iam/
│       └── ecs/
└── .github/workflows/
    ├── application.yml
    ├── terraform-deploy.yml
    └── terraform-destroy.yml
```
