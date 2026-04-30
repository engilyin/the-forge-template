---
name: "AWS ECS Fargate Runtime"
description: "Runtime and deployment guidance for ECS/Fargate services."
user-invocable: false
---

# AWS ECS Fargate Runtime and Deployments

Use this skill for AWS runtime and deployment work after the base infrastructure already exists. Apply it when the task is about ECS/Fargate services, task definitions, ALB integration, service discovery, image publishing, Jenkins runtime agents, or rollout safety.

Use `.github/skills/aws-terraform-jenkins-infrastructure.md` for stack boundaries and provisioning design.
Use this skill for what runs on top of those stacks.

---

## Core Model

Treat runtime delivery as a separate concern from infrastructure provisioning.

Typical separation:

- Terraform stack skill decides what infrastructure exists
- runtime skill decides how containers are built, published, configured, exposed, and rolled out

Prefer immutable container images, explicit task definitions, predictable health checks, and deployment flows that can be reviewed and repeated.

---

## Typical Runtime Topology

```text
Jenkins pipeline
  -> build image
  -> push image to ECR or public ECR
  -> update runtime inputs
  -> deploy ECS task/service changes
  -> verify health through ALB and logs

ECS/Fargate service
  -> target group behind ALB when HTTP traffic is exposed
  -> Cloud Map / service discovery when internal discovery is needed
  -> CloudWatch logs for container output
  -> SSM Parameter Store or Secrets Manager for runtime configuration
  -> EFS only when true shared persistent filesystem access is required
```

---

## ECS Task Definition Standards

Each task definition should declare runtime intent clearly.

Rules:

- set CPU and memory explicitly
- separate execution role and task role responsibilities
- pin the container name and keep it aligned with service/load balancer mappings
- use `awslogs` or another standard log driver intentionally
- keep container definitions readable; do not bury all runtime logic in one giant JSON blob
- keep image source explicit and environment-specific only where necessary

Example shape:

```hcl
resource "aws_ecs_task_definition" "service" {
  family                   = "customer-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "customer-api"
      image     = var.image
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/customer-api"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "app"
        }
      }
    }
  ])
}
```

---

## ECS Service Standards

Use ECS services to own steady-state runtime behavior.

Rules:

- keep `desired_count` intentional, not implied
- attach a target group only when the service is actually HTTP-addressable
- prefer private subnets for internal services; justify public IP assignment explicitly
- wire service discovery only when consumers truly need runtime registration
- set deployment behavior so failures surface early instead of hanging silently
- document whether zero-downtime rollout is required and what health gates enforce it

Example shape:

```hcl
resource "aws_ecs_service" "service" {
  name            = "customer-api"
  cluster         = var.cluster_arn
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.service.arn
  desired_count   = 2

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.service.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "customer-api"
    container_port   = 8080
  }
}
```

---

## Load Balancing and Health

ALB and target group configuration must match the actual runtime contract.

Rules:

- align target group port, protocol, and health path with the application
- use dedicated health endpoints, not business endpoints
- keep idle timeout, deregistration delay, and health thresholds intentional for the service type
- do not route production traffic to containers that have no readiness signal
- create alarms for unhealthy host counts and error-rate spikes on important services

---

## Service Discovery

Use Cloud Map or another discovery layer only when runtime consumers need it.

Good fit:

- internal service-to-service discovery without fixed endpoints
- stateful support services that need a stable internal DNS name

Avoid it when:

- an ALB hostname or a direct parameterized endpoint already solves the problem
- service names are being added "just in case"

---

## Runtime Configuration

Runtime configuration belongs outside the image.

Prefer:

- SSM Parameter Store for non-secret and moderately sensitive configuration
- Secrets Manager for secret rotation workflows that need it
- ECS task definition references or startup-time retrieval, depending on the operating model

Rules:

- never bake environment secrets into the image
- keep parameter names hierarchical and environment-scoped
- document which values are managed by Terraform versus rotated manually
- keep the mapping from runtime config key to application property obvious

---

## EFS Usage

EFS is valid when the workload genuinely needs shared persistent filesystem access.

Good fit:

- Jenkins home or agent caches
- shared tool caches
- runtime content that must survive task replacement

Rules:

- use access points when possible
- mount only the path the container actually needs
- scope security groups tightly
- do not add EFS to stateless services without a real persistence requirement

---

## Jenkins Image Build and Publish Pattern

Keep image build pipelines separate from infrastructure apply pipelines when the lifecycle differs.

Common pattern:

- Jenkins chooses a dedicated agent label
- pipeline computes a release version
- pipeline builds with Docker or Kaniko
- image is pushed to ECR or public ECR
- deployment inputs are updated explicitly afterward

Rules:

- version images predictably
- push immutable version tags first; move `latest` only if that is an intentional policy
- do not hide build metadata or version derivation inside opaque shell fragments
- if Kaniko or Fargate limitations exist, document the workaround instead of pretending the build is generic

Example Jenkins stages:

```groovy
stage('Define version') {
  steps {
    script {
      env.VERSION = '1.2.3'
    }
  }
}

stage('Build and publish image') {
  steps {
    sh 'kaniko-or-docker-build-command'
    sh 'push-versioned-image'
  }
}
```

---

## Deployment Flow

Prefer explicit deployment flow over magic restarts.

Recommended sequence:

1. Build and publish the image
2. Update the runtime input that selects the image or task definition
3. Deploy the ECS service change
4. Watch service events, ALB health, and logs
5. Confirm the old tasks drain cleanly

Do not treat "image published" as equivalent to "deployment complete."

---

## Observability and Rollout Safety

Minimum runtime checks:

- CloudWatch logs per container family
- alarms on unhealthy targets for externally exposed services
- alarms on repeated task restarts for critical services
- enough runtime metadata to identify deployed image version

When possible, record:

- image tag
- service name
- environment
- release time

---

## Anti-Patterns

Avoid:

- using public IPs for every service by default
- mixing build-image logic, Terraform apply, and runtime verification into one opaque stage
- storing real secrets in task definitions, `tfvars`, or Jenkinsfiles
- mounting EFS for stateless services without need
- task definitions with copy-pasted JSON that no one can review
- target groups without a real health endpoint contract
- assuming Fargate behaves like a privileged Docker host

---

## Review Checklist

- [ ] The runtime concern is clearly separate from provisioning concerns
- [ ] Task definition CPU, memory, roles, logs, and ports are explicit
- [ ] Service networking and public exposure are intentional
- [ ] ALB and target group health checks match the real application behavior
- [ ] Runtime configuration comes from managed external sources
- [ ] EFS is used only with a documented persistence reason
- [ ] Jenkins image build/publish flow is reviewable and versioned
- [ ] Deployment completion includes runtime verification, not just image push