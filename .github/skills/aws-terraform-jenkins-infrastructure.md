# ---
title: "AWS Terraform + Jenkins Infrastructure Skill"
description: "Guidance for Terraform provisioning, stack boundaries, remote state, and Jenkins pipeline integration on AWS."
tags: [skill, aws, terraform, jenkins]
type: skill
---

# AWS Terraform Jenkins Infrastructure Skill

Use this skill for AWS infrastructure work that is provisioned with Terraform and deployed through Jenkins pipelines. It is the primary quality reference for maintaining and designing stack-based AWS infrastructure in FORGE projects that use one Terraform stack per directory and a Jenkins approval flow for `plan` and `apply`.

This skill is based on a proven pattern used in a real AWS IaC repository with:

- one Jenkins pipeline per infrastructure stack
- one `terraform/` directory per deployable infrastructure unit
- S3 remote state configured at pipeline runtime
- environment-specific `tfvars` files under `terraform/env/`
- AWS Parameter Store stacks for application configuration
- service stacks for ALB, CloudFront, S3, EventBridge, EFS, and database infrastructure

---

## Core Model

Treat infrastructure as a set of small, reviewable stacks instead of one giant Terraform root.

Typical stack categories:

- foundational infrastructure stacks such as database, ALB, EventBridge, EFS, and shared storage
- parameter/configuration stacks that publish application settings into SSM Parameter Store
- service or delivery stacks such as CDN, S3 website hosting, CI images, and Jenkins support infrastructure

Each stack should be independently planable and applyable, with a clear ownership boundary and minimal cross-stack coupling.

---

## Repository Structure

Prefer a stack-per-directory layout like this when the repository is infrastructure-focused:

```text
infra-repo/
├── <stack-name>/
│   ├── Jenkinsfile
│   └── terraform/
│       ├── env/
│       │   ├── dev.tfvars
│       │   ├── demo.tfvars
│       │   └── prod.tfvars
│       ├── provider.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── <resource-files>.tf
├── <another-stack>/
│   ├── Jenkinsfile
│   └── terraform/
└── README.md
```

Keep stacks small enough that a single plan is understandable. If a directory starts representing unrelated domains, split it.

---

## Stack Boundaries

### Parameter stacks

Use dedicated parameter stacks when multiple services depend on environment-scoped configuration.

Good fit:

- application URLs
- feature flags
- non-secret runtime configuration
- placeholders for secrets that are manually rotated later

Example shape:

```hcl
locals {
  app_name = "customer-api"
}

resource "aws_ssm_parameter" "base_url" {
  name  = "/${local.app_name}/${var.env}/app/base-url"
  type  = "String"
  value = var.app_base_url
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/${local.app_name}/${var.env}/spring/r2dbc/password"
  type  = "SecureString"
  value = "SET_MANUALLY"

  lifecycle {
    ignore_changes = [value]
  }
}
```

Rules:

- keep parameter naming hierarchical and predictable
- group parameters by application and environment
- use `SecureString` only for sensitive values
- if secret values are managed manually, document that explicitly in the stack README and outputs

### Foundational infrastructure stacks

Use separate stacks for durable shared infrastructure such as:

- RDS or Aurora
- ALB and WAF
- EFS
- EventBridge buses and rules
- shared buckets or CDN distribution layers

Rules:

- isolate blast radius for destructive resources
- prefer explicit inputs over hidden data lookups when the dependency chain matters
- avoid combining unrelated foundational resources just because they share a VPC

### Service and delivery stacks

Use service stacks for infrastructure that exists to deliver one application surface, such as:

- website hosting via S3 + CloudFront
- build/agent images
- application-specific buckets
- per-service routing or listener rules

---

## Terraform Layout Standards

### Provider and backend pattern

Use a minimal provider file and inject backend specifics from Jenkins.

```hcl
provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    region = "us-east-1"
  }
}
```

Do not hardcode per-environment bucket names or state keys in Terraform files when the pipeline is already the deployment boundary.

### Resource file organization

Split large stacks into focused `.tf` files by resource concern.

Good examples:

- `alb.tf`
- `security-groups.tf`
- `alerts.tf`
- `cloudfront.tf`
- `outputs.tf`

Avoid one huge `main.tf` for complex stacks.

### Variable design

- keep `variables.tf` typed and explicit
- use `list(string)`, `map(string)`, and object types intentionally
- mark sensitive values as sensitive where appropriate
- keep defaults only for stable, low-risk values
- do not hide required environment-specific values behind misleading defaults

Example:

```hcl
variable "env" {
  type        = string
  description = "Target environment name"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for internal resources"
}

variable "release_versions" {
  type        = map(string)
  description = "Maps environment to release path"
  default = {
    dev  = ""
    demo = ""
    prod = ""
  }
}
```

---

## Environment Handling

### tfvars convention

When each environment has materially different values, use:

```text
terraform/env/dev.tfvars
terraform/env/demo.tfvars
terraform/env/prod.tfvars
```

For stacks that intentionally manage multiple environments in one apply, a shared file such as `env/params.tfvars` is acceptable if the Terraform code already loops over an explicit `envs` input.

Example:

```hcl
project             = "customer-portal"
acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abc..."
```

### Environment naming discipline

Pick one environment vocabulary and reuse it consistently.

Examples of acceptable sets:

- `dev`, `demo`, `prod`
- `dev`, `staging`, `prod`

Do not casually mix these within one platform unless the distinction is intentional and documented. Inconsistent environment naming increases state, routing, and deployment mistakes.

### Multi-environment loops

For CDN or website stacks, using `for_each = toset(var.envs)` can be appropriate when one Terraform apply truly owns all environments for that surface.

Use it only when:

- shared ownership is intentional
- the blast radius is acceptable
- the state file is meant to own all those environments together

---

## Jenkins Pipeline Standards

Each infrastructure stack should have its own declarative Jenkins pipeline.

### Required stage pattern

```groovy
pipeline {
    agent {
       label 'linux-java-fargate'
    }

    parameters {
        choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Choose action')
        choice(name: 'ENVIRONMENT', choices: ['dev', 'demo', 'prod'], description: 'Target environment')
    }

    environment {
        AWS_REGION = 'us-east-1'
        WORK_DIR = 'customer-api/terraform'
    }

    stages {
        stage('Init') {
            steps {
                dir(env.WORK_DIR) {
                    withAWS(credentials: 'CLI_AWS_CREDENTIALS_ID', region: env.AWS_REGION) {
                        sh 'terraform init -backend-config="key=customer-api/terraform.tfstate" -backend-config="bucket=my-tf-state-bucket"'
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir(env.WORK_DIR) {
                    withAWS(credentials: 'CLI_AWS_CREDENTIALS_ID', region: env.AWS_REGION) {
                        sh 'terraform plan -out=tfplan -var-file="./env/dev.tfvars"'
                    }
                }
            }
        }

        stage('Confirm Apply') {
            steps {
                input message: 'Do you want to apply these changes?', ok: 'Apply'
            }
        }

        stage('Terraform Apply') {
            steps {
                dir(env.WORK_DIR) {
                    withAWS(credentials: 'CLI_AWS_CREDENTIALS_ID', region: env.AWS_REGION) {
                        sh 'terraform apply "tfplan"'
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
```

### Pipeline rules

- always separate `plan` from `apply`
- keep a manual approval gate before `apply` or `destroy`
- parameterize `ACTION` explicitly; do not hide destroy behavior in ad hoc scripts
- set `WORK_DIR` once and keep shell commands relative to it
- print `terraform version` during pipeline execution
- clean workspaces after the run
- keep pipeline behavior consistent across stacks so operators do not have to relearn each stack

### State bucket routing

If state bucket selection differs by environment, centralize that in a helper function instead of scattering string logic.

```groovy
String stateBucket(String env) {
    String baseBucketName = 'platform-terraform-state'
    if ('demo'.equals(env)) {
        return baseBucketName + '-demo'
    }
    return baseBucketName
}
```

Do not allow two environments to share a state key accidentally.

---

## State And Backend Design

### Required conventions

- one state file per stack
- state key pattern based on stack path, such as `<stack-name>/terraform.tfstate`
- remote state stored in S3
- state configuration injected during `terraform init`

### Recommendations for new stacks

- enable S3 state encryption for new stacks
- use state locking if the platform provides it
- document bucket ownership and retention rules
- keep state buckets separate from application data buckets

### Current-risk awareness

If an existing repository uses `encrypt = false` in the backend block, treat that as legacy behavior to improve, not as a model to copy into new stacks.

---

## AWS Design Guidance

### Naming

Use deterministic naming across stacks:

- stack-level prefixes such as `customer-api`, `customer-portal`, `platform-alb`
- environment suffixes for env-owned resources such as buckets and parameter paths
- hierarchical parameter paths like `/<app>/<env>/...`

Examples:

- `/customer-api/dev/spring/r2dbc/url`
- `customer-portal-oac-dev`
- `customer-avatars-prod`

### Tagging

Every managed AWS resource should receive consistent tags when the service supports them.

```hcl
locals {
  common_tags = {
    Project   = var.project_name
    Env       = var.env
    ManagedBy = "terraform"
  }
}
```

Prefer merging tags into every resource or module input rather than redefining them ad hoc.

### CDN and website stacks

For S3 + CloudFront stacks:

- use Origin Access Control instead of public buckets
- set aliases per environment explicitly
- keep certificate usage aligned to `us-east-1` for CloudFront
- document any `lifecycle.ignore_changes` decisions for mutable release paths

### ALB and routing stacks

For large ALB stacks:

- separate listeners, target groups, roles, security groups, and alarms into focused files
- keep numeric priority handling explicit and readable
- document listener-rule ownership so new services do not collide with existing priorities

### Parameter Store

Parameter stacks should be deployed before the services that consume them.

Rules:

- keep non-secret and secret parameters clearly separated
- prefer stable parameter paths over frequent renames
- do not commit real secrets into `tfvars`
- if a secret is created as a placeholder and rotated manually later, that must be an explicit operating model, not an accident

---

## Maintenance Rules

### Before changing a stack

- identify the stack boundary and the dependent services
- inspect the environment files that will be affected
- confirm the backend key and state bucket
- review outputs and downstream parameter consumers
- decide whether the change belongs in an existing stack or a new one

### When adding a new stack

- create a new top-level directory with its own `Jenkinsfile`
- create a `terraform/` subdirectory with typed variables and env files
- use a unique backend key
- keep the first plan small and reviewable
- document the stack purpose in a local README when the stack is non-obvious

### When modifying secrets or config stacks

- never replace real secret values in source-controlled files
- keep placeholders obvious, such as `SET_MANUALLY`
- document manual post-apply steps if `ignore_changes` is used
- avoid churn in parameter paths because services often depend on them directly

---

## Anti-Patterns

- do not create one giant Terraform stack for the whole platform
- do not commit real secrets or passwords into `tfvars`
- do not reuse the same state key across environments
- do not hide state bucket rules in multiple unrelated Jenkinsfiles
- do not mix unrelated environment naming schemes without documentation
- do not put unrelated services into one ALB or parameter stack just because it is convenient once
- do not copy legacy insecure backend settings into new stacks
- do not let manual secret processes exist without documenting them beside the stack

---

## Checklist

- the stack boundary is clear and limited in scope
- Jenkins uses explicit `init`, `plan`, approval, and `apply` stages
- backend key naming is unique and predictable
- environment files exist only where they are actually needed
- secrets are not stored directly in repo-managed values
- parameter paths are hierarchical and environment-scoped
- AWS naming and tagging are consistent across the stack
- large stacks are split into readable `.tf` files by concern
- any `ignore_changes` usage is intentional and documented
- new stacks do not repeat known legacy risks such as unencrypted state defaults