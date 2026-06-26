output "instance_id" {
  description = "ID of the EC2 instance."
  value       = aws_instance.app.id
}

output "instance_arn" {
  description = "ARN of the EC2 instance."
  value       = aws_instance.app.arn
}

output "private_ip" {
  description = "Private IP address of the EC2 instance."
  value       = aws_instance.app.private_ip
}

output "public_ip" {
  description = "Public IP address of the EC2 instance, if assigned."
  value       = aws_instance.app.public_ip
}

output "ami_id" {
  description = "AMI used to launch the EC2 instance."
  value       = aws_instance.app.ami
}
