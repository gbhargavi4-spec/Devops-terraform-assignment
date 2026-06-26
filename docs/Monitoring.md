# Monitoring

## CloudWatch Alarms

Five alarms are managed by `terraform/modules/cloudwatch` for the dev environment.

| Alarm | Metric | Threshold | Action |
|-------|--------|-----------|--------|
| EC2 CPU High | `AWS/EC2 CPUUtilization` | 80% | SNS |
| EC2 Memory High | `devops-app/dev mem_used_percent` | 85% | SNS |
| RDS CPU High | `AWS/RDS CPUUtilization` | 80% | SNS |
| RDS Storage Low | `AWS/RDS FreeStorageSpace` | 5 GiB | SNS |
| RDS Connections High | `AWS/RDS DatabaseConnections` | 100 | SNS |

SNS topic ARN is set via `var.alarm_sns_topic_arn`. It is left empty in dev, so alarms trigger but no notifications are sent.

## CloudWatch Log Groups

| Log Group | Content |
|-----------|---------|
| `/devops-app/dev/app` | Application container stdout/stderr |
| `/devops-app/dev/ec2/system` | `/var/log/messages`, `/var/log/secure` |
| `/aws/rds/instance/devops-app-dev-postgres/postgresql` | PostgreSQL logs |

The CloudWatch Agent on EC2 collects memory and disk metrics into the `devops-app/dev` namespace and forwards system logs. Log retention is set to 30 days in dev.

## CloudWatch Dashboard

The dashboard `devops-app-development` (or `devops-app-dev`) contains:

- EC2 CPU utilisation (time series)
- EC2 memory utilisation (time series)
- RDS CPU utilisation (time series)
- RDS free storage (time series)
- RDS database connections (time series)

All metric widgets include the `region` property explicitly set to `ap-south-1`. This is required by the CloudWatch dashboard API — omitting it causes validation errors during `terraform apply`.

Access the dashboard at:
`AWS Console → CloudWatch → Dashboards → devops-app-dev`

## Application Endpoints

The FastAPI application exposes Prometheus-compatible metrics at `/metrics`:

| Metric | Type | Description |
|--------|------|-------------|
| `http_requests_total` | Counter | Total requests by method, endpoint, HTTP status |
| `http_request_duration_seconds` | Histogram | Request latency per endpoint |

Scrape target: `http://devops-app-dev-alb-64195356.ap-south-1.elb.amazonaws.com/metrics`

## Health Checks

The ALB performs health checks every 30 seconds against `/health` on port 8000.

- **Healthy threshold:** 2 consecutive 200 responses
- **Unhealthy threshold:** 3 consecutive failures
- **Timeout:** 5 seconds

The `/ready` endpoint also validates the database connection and returns 503 if the DB is unreachable.

## Local Monitoring Stack

Run `docker compose up` inside `application/` to bring up:
- **Prometheus** at `:9090` — scrapes `/metrics` every 30 seconds
- **Grafana** at `:3000` — pre-provisioned with Prometheus as the default datasource
