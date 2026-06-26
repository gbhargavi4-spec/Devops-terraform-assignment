# Monitoring

## CloudWatch Alarms

Each environment has five alarms managed by `terraform/modules/cloudwatch`.

| Alarm | Metric | Threshold | Action |
|-------|--------|-----------|--------|
| EC2 CPU High | `AWS/EC2 CPUUtilization` | 80% (prod: 70%) | SNS |
| EC2 Memory High | `<project>/<env> mem_used_percent` | 85% | SNS |
| RDS CPU High | `AWS/RDS CPUUtilization` | 80% (prod: 70%) | SNS |
| RDS Storage Low | `AWS/RDS FreeStorageSpace` | 5 GiB (prod: 10 GiB) | SNS |
| RDS Connections High | `AWS/RDS DatabaseConnections` | 100 | SNS |

Alarm notifications go to the SNS topic ARN set in `var.alarm_sns_topic_arn`. Leave it empty in dev/qa to suppress notifications.

## CloudWatch Log Groups

| Log Group | Content |
|-----------|---------|
| `/<project>/<env>/app` | Application container stdout/stderr |
| `/<project>/<env>/ec2/system` | `/var/log/messages`, `/var/log/secure` |
| `/aws/rds/instance/<id>/postgresql` | PostgreSQL logs |
| `/aws/rds/instance/<id>/upgrade` | RDS upgrade logs |

The CloudWatch Agent on EC2 collects memory and disk metrics into the `<project>/<env>` namespace and forwards system logs.

## CloudWatch Dashboard

Each environment has a dashboard named `<project>-<environment>` with:
- EC2 CPU utilisation time series
- EC2 memory utilisation time series
- RDS CPU utilisation time series
- RDS free storage time series
- RDS database connections time series
- Alarm status widget

## Prometheus + Grafana (local / dev)

Run `docker compose up` inside `application/` to bring up:
- **Prometheus** at `:9090` — scrapes `/metrics` from the app every 30 seconds
- **Grafana** at `:3000` — pre-provisioned with Prometheus as the default datasource

Metrics exposed by the application:

| Metric | Type | Description |
|--------|------|-------------|
| `http_requests_total` | Counter | Total requests by method, endpoint, status |
| `http_request_duration_seconds` | Histogram | Latency per endpoint |
