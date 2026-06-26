# devops-app

Production-grade DevOps project: containerised FastAPI application on AWS, managed with Terraform and deployed via GitHub Actions.

## Repository Layout

```
.
├── application/                  # Docker application
│   ├── Dockerfile                # Multi-stage Alpine build
│   ├── docker-compose.yml        # Local stack (app + postgres + prometheus + grafana)
│   ├── source/                   # FastAPI source and requirements
│   └── config/                   # Prometheus & Grafana provisioning
├── terraform/
│   ├── modules/                  # Reusable modules (no backend, no state)
│   │   ├── networking/
│   │   ├── security/
│   │   ├── iam/
│   │   ├── rds/
│   │   ├── ecr/
│   │   ├── ec2/
│   │   └── cloudwatch/
│   └── environments/             # Deployable roots — one per env × module
│       ├── dev/
│       ├── qa/
│       └── prod/
├── .github/workflows/
│   ├── ci.yml                    # Lint, validate, build, scan — all branches
│   ├── deploy-dev.yml            # feature/** → dev
│   ├── deploy-qa.yml             # develop → qa
│   └── deploy-prod.yml           # main → prod (manual approval)
└── docs/
    ├── Architecture.md
    ├── Deployment.md
    ├── Monitoring.md
    ├── Security.md
    └── Challenges.md
```

## Quick Start

See [docs/Deployment.md](docs/Deployment.md) for full bootstrap instructions.

```bash
# Local development
cd application
cp .env.example .env
docker compose up
```

- App: http://localhost:8000
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000

## Architecture

See [docs/Architecture.md](docs/Architecture.md).

Three isolated environments (dev / qa / prod), each with independent Terraform state per module layer. Cross-layer dependencies resolved via `terraform_remote_state`.

Deployment order per environment:

```
networking → security → iam → rds → ecr → ec2 → cloudwatch
```

## CI/CD

- Every push runs fmt checks, module validation, Docker build, and Trivy security scan
- `feature/**` and `develop` branches deploy to dev automatically
- `develop` branch deploys to qa automatically
- `main` branch deploys to prod after a required manual approval

Authentication uses GitHub Actions OIDC — no long-lived AWS credentials stored in secrets.

## Documentation

| Doc | Contents |
|-----|----------|
| [Architecture](docs/Architecture.md) | AWS design, VPC layout, state management |
| [Deployment](docs/Deployment.md) | Bootstrap, CI/CD pipeline, local dev |
| [Monitoring](docs/Monitoring.md) | CloudWatch alarms, log groups, Prometheus metrics |
| [Security](docs/Security.md) | Secrets, IAM, network, container hardening |
| [Challenges](docs/Challenges.md) | Problems encountered and how they were solved |
