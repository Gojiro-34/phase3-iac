# AWS Cloud Engineering — Phase 3: Infrastructure as Code

A three-tool exploration of Infrastructure as Code, followed by a capstone that rebuilds the entire Phase 1 + Phase 2 architecture from code instead of console clicks. Same principle as every phase before it: full theory before touching anything, one real deployed project per topic, nothing skipped.

## What this is

Phase 2 was built entirely by hand in the AWS Console. Phase 3 asks the obvious next question: what if none of that had to be clicked at all? This repo covers three different ways to answer that — Terraform, Ansible, and CloudFormation — each learned with a real, deployed, torn-down project, then closes with a capstone that expresses the full Phase 1+2 stack as a single one-command Terraform deploy.

## Repo structure

```
phase3-iac/
├── terraform-ec2-s3/         Topic 1 — Terraform fundamentals
├── ansible-playbooks/        Topic 2 — Ansible configuration management
├── cloudformation-templates/ Topic 3 — AWS-native IaC
└── capstone/                 Full Terraform rebuild of Phase 1 + 2
```

## Topic 1 — Terraform

A minimal EC2 + S3 project, built to learn the actual mechanics: providers, resources, state, and the `init → plan → apply → destroy` lifecycle. Variables were split into `variables.tf` and `terraform.tfvars` rather than hardcoded, once the pattern was understood. The AMI ID was looked up live via the AWS CLI rather than trusted from memory, since AMIs go stale as AWS patches them.

**Why `plan` matters as much as `apply`.** `terraform plan` is a dry run — it shows exactly what would be created, changed, or destroyed before anything touches real infrastructure. Reading that output before every `apply` is the habit that catches mistakes while they're still free to fix, same instinct as `git diff` before a commit.

## Topic 2 — Ansible

Ansible answers a different question than Terraform: not "does this server exist," but "what's actually configured on it." A playbook installs Nginx, Node.js, and Docker on the Phase 2 EC2 instance, clones the app repository, and builds and runs its container — all from one YAML file, over SSH, with no agent installed on the target.

**Idempotency is the core idea.** A task like installing Nginx checks whether it's already there before doing anything. Re-running the same playbook against an already-configured server correctly does nothing on the install steps — proven directly, since the target instance already had Nginx, Node, and Docker from earlier manual Phase 2 work. The Docker build/run steps deliberately use a simpler `shell` + `|| true` approach rather than the fully idempotent `docker_container` module, trading some idempotency for consistency with the existing GitHub Actions deploy pattern.

## Topic 3 — CloudFormation

AWS's own native IaC service — no separate tool to install, no state file to manage or lose, since AWS tracks everything internally per stack. Built in two stages: a warmup S3 bucket, then a full VPC + RDS deployment.

The VPC + RDS template exists in two versions. The first used public subnets for RDS with `PubliclyAccessible: false` as the only real barrier. The second rebuilds it with RDS in genuinely private subnets — no route to an Internet Gateway at all — which is the correct pattern and the one actually used in Phase 2 and the capstone. Keeping both versions in the repo as a deliberate before/after comparison of the same architectural question.

## Capstone — Terraform rebuild of Phase 1 + 2

```
Users
  │
  └──> EC2 (public subnet, Docker container running Express)
           │
           └──> RDS MySQL (private subnets, no internet route)

Security groups reference each other:
  gujju-capstone-ec2-sg (80/443/22) ──trusted by──> gujju-capstone-rds-sg (3306)

S3 bucket (static website config) — separate, outside the VPC boundary
```

The same four-subnet, two-AZ, public/private split from the real Phase 2 network, an EC2 instance whose AMI is resolved at plan-time via a Terraform data source instead of a hardcoded ID, an RDS instance in the private subnets, and an S3 bucket configured for static hosting. `terraform plan` confirms all 15 resources create cleanly with correct dependency ordering.

**Why the password is a variable, not a value.** `db_password` is declared as a `sensitive` variable with no default, and its real value lives only in a local `terraform.tfvars` — excluded from git by the repo's `.gitignore`. The template itself stays safe to commit and share; the actual secret never does.

**Why the AMI isn't hardcoded.** A `data "aws_ami"` block queries AWS directly for the current Ubuntu 22.04 image at plan time, filtered to Canonical's official publishing account. This means the template stays correct indefinitely instead of silently pointing at an increasingly outdated image months later.

**Why `apply` wasn't run on this final version.** The full `apply → destroy` cycle was already proven for real, twice over — once in the Topic 1 Terraform project, and twice across the CloudFormation stacks in Topic 3. A clean `terraform plan` against a live AWS account, showing all 15 resources with correct dependencies and zero errors, demonstrates the same competency without spending AWS credits on a fourth real deployment of architecture that's already been deployed for real in Phase 2.

## What I'd do differently at scale

- Use `for_each` for the repeated subnet/route-table-association resources instead of writing each one out explicitly, once comfortable with the pattern
- Move Terraform state to a remote S3 backend with locking, rather than local state, for anything beyond solo learning
- Add an IAM role scoped to the EC2 instance (deliberately scoped out of this capstone to keep it focused, but the trust-policy/permissions-policy pattern is understood from the theory covered)
- Use Ansible's `community.docker` collection for the container deploy steps, trading setup complexity for genuine idempotency on every run, not just the package installs

## Cost notes

Networking resources (VPC, subnets, route tables, IGW, security groups) are free regardless of how many exist. The only real cost drivers across this repo are RDS and EC2 compute time while actually running — every deployed stack or apply in this repo was verified, then torn down (`terraform destroy` / `aws cloudformation delete-stack`) rather than left running, to stay within the AWS free-tier credit budget for the rest of the roadmap.
