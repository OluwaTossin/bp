environment   = "prod"
instance_type = "t2.micro"  # Free tier eligible
min_instances = 1
max_instances = 4

# Enable CloudWatch alarms for monitoring
enable_cloudwatch_alarms = true

# Health check configuration
health_check_path = "/"
