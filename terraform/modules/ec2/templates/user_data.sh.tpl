#!/bin/bash
set -euo pipefail

dnf update -y
dnf install -y docker amazon-cloudwatch-agent aws-cli jq

systemctl enable --now docker
usermod -aG docker ec2-user

DB_PASSWORD=$(aws ssm get-parameter \
  --name "${db_password_ssm_path}" \
  --with-decryption \
  --region "${aws_region}" \
  --query 'Parameter.Value' \
  --output text)

DB_USERNAME=$(aws ssm get-parameter \
  --name "${db_username_ssm_path}" \
  --region "${aws_region}" \
  --query 'Parameter.Value' \
  --output text)

DB_NAME=$(aws ssm get-parameter \
  --name "${db_name_ssm_path}" \
  --region "${aws_region}" \
  --query 'Parameter.Value' \
  --output text)

aws ecr get-login-password --region "${aws_region}" | \
  docker login --username AWS --password-stdin "${ecr_registry}"

docker pull "${ecr_registry}/${ecr_repository_name}:latest"

cat > /opt/app.env <<EOF
PROJECT=${project}
ENVIRONMENT=${environment}
AWS_REGION=${aws_region}
APP_PORT=${app_port}
DATABASE_HOST=${db_host}
DATABASE_PORT=${db_port}
DATABASE_NAME=$${DB_NAME}
DATABASE_USER=$${DB_USERNAME}
DATABASE_PASSWORD=$${DB_PASSWORD}
EOF
chmod 600 /opt/app.env

cat > /etc/systemd/system/app.service <<'SVCEOF'
[Unit]
Description=${project} ${environment} Application
After=docker.service
Requires=docker.service

[Service]
Restart=always
RestartSec=5
EnvironmentFile=/opt/app.env
ExecStartPre=-/usr/bin/docker stop app
ExecStartPre=-/usr/bin/docker rm app
ExecStart=/usr/bin/docker run --rm --name app \
  --env-file /opt/app.env \
  -p ${app_port}:${app_port} \
  --log-driver=awslogs \
  --log-opt awslogs-region=${aws_region} \
  --log-opt awslogs-group=/${project}/${environment}/app \
  --log-opt awslogs-stream=app \
  ${ecr_registry}/${ecr_repository_name}:latest
ExecStop=/usr/bin/docker stop app

[Install]
WantedBy=multi-user.target
SVCEOF

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<CWA
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "cwagent"
  },
  "metrics": {
    "namespace": "${project}/${environment}",
    "append_dimensions": {
      "InstanceId": "$${aws:InstanceId}",
      "Environment": "${environment}"
    },
    "metrics_collected": {
      "mem": {
        "measurement": ["mem_used_percent"]
      },
      "disk": {
        "measurement": ["disk_used_percent"],
        "resources": ["/"]
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/${project}/${environment}/ec2/system",
            "log_stream_name": "{instance_id}/messages"
          },
          {
            "file_path": "/var/log/secure",
            "log_group_name": "/${project}/${environment}/ec2/system",
            "log_stream_name": "{instance_id}/secure"
          }
        ]
      }
    }
  }
}
CWA

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

systemctl daemon-reload
systemctl enable --now app
