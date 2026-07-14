# Phase 3 Capstone: Terraform Rebuild of Phase 1 + Phase 2 Infrastructure

## Overview

This project rebuilds the core AWS architecture from Phase 1 and Phase 2 — originally built manually through the AWS Console — entirely as code, using Terraform. The goal: prove that a real, multi-service, multi-resource environment can be deployed (and destroyed) with a single command, fully version-controlled, instead of relying on memory and manual clicks.

This is the culmination of Phase 3's three topics: Terraform (Topic 1), Ansible (Topic 2), and CloudFormation (Topic 3) — bringing the Terraform skills from Topic 1 to bear on a real, complete architecture rather than a toy example.

## Architecture

- **VPC** (`10.2.0.0/16`) spanning two Availability Zones (`ap-south-1a`, `ap-south-1b`)
- **4 subnets**: 2 public (EC2, internet-facing), 2 private (RDS, no direct internet route)
- **Internet Gateway** + public route table, associated only with the public subnets
- **Two security groups**, following the security-group-to-security-group reference pattern from the real Phase 2 build:
  - `gujju-capstone-ec2-sg` — 80/443/22 open
  - `gujju-capstone-rds-sg` — 3306 open **only** to traffic from the EC2 security group, not by raw IP/CIDR
- **EC2 instance** (`t3.micro`) in the public subnet, AMI resolved dynamically via a Terraform data source (always picks the current Ubuntu 22.04 LTS image, rather than a hardcoded, eventually-stale AMI ID)
- **RDS instance** (`db.t3.micro`, MySQL) in the private subnets via a DB subnet group, `publicly_accessible = false`
- **S3 bucket** with static website hosting configuration, for the portfolio site
## Diagram

![Capstone Architecture](./Capstone-diagram.png)

## Design decisions

- **No NAT Gateway** — same cost-conscious call made in the real Phase 2 build. Private subnets have no outbound internet route at all, which is fine since RDS doesn't need one.
- **AMI resolved via `data "aws_ami"`, not hardcoded** — ensures the template always deploys against a current, patched Ubuntu image rather than a value that silently goes stale over time.
- **RDS password handled via a `sensitive = true` variable, sourced from `terraform.tfvars`** — never hardcoded in `main.tf`, never committed to git (`terraform.tfvars` is `.gitignore`'d at the repo root).
- **`skip_final_snapshot = true` on RDS** — appropriate for a learning/teardown environment; would be reconsidered for anything holding real data.
- **Variables refactor done before first deploy**, not after — all environment-specific values (region, instance sizes, key name, bucket name) live in `variables.tf` with sensible defaults, keeping `main.tf` focused purely on resource structure.

## Deployment

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

`terraform.tfvars` (gitignored, not included in this repo) must contain:
```hcl
db_password = "your-chosen-password"
```

To tear down:
```bash
terraform destroy
```

## Status

Fully written, validated, and plan-verified against a live AWS account (`terraform plan` confirms all 15 resources create cleanly with correct dependency ordering). `apply` intentionally not run for this specific version to conserve AWS credits, following successful, verified `apply`/`destroy` cycles already completed earlier in Phase 3 (Topic 1's Terraform project, and twice in Topic 3's CloudFormation stacks).
