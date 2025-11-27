output "environment_name" {
  description = "Name of the Elastic Beanstalk environment"
  value       = aws_elastic_beanstalk_environment.env.name
}

output "environment_url" {
  description = "URL of the Elastic Beanstalk environment"
  value       = "http://${aws_elastic_beanstalk_environment.env.cname}"
}

output "environment_cname" {
  description = "CNAME of the Elastic Beanstalk environment"
  value       = aws_elastic_beanstalk_environment.env.cname
}

output "application_name" {
  description = "Name of the Elastic Beanstalk application"
  value       = aws_elastic_beanstalk_application.app.name
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for EB artifacts"
  value       = aws_s3_bucket.eb_artifacts.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for EB artifacts"
  value       = aws_s3_bucket.eb_artifacts.arn
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for application logs"
  value       = aws_cloudwatch_log_group.app_logs.name
}

output "sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms"
  value       = var.enable_cloudwatch_alarms ? aws_sns_topic.alarms[0].arn : null
}

output "service_role_arn" {
  description = "ARN of the EB service role"
  value       = aws_iam_role.eb_service_role.arn
}

output "instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_instance_profile.name
}

output "vpc_id" {
  description = "VPC ID used for the environment"
  value       = data.aws_vpc.default.id
}

output "environment_id" {
  description = "ID of the Elastic Beanstalk environment"
  value       = aws_elastic_beanstalk_environment.env.id
}
