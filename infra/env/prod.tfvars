environment   = "prod"
instance_type = "t3.micro"  # Free tier eligible (preferred in eu-west-1)
min_instances = 1
max_instances = 4

# Enable CloudWatch alarms for monitoring
enable_cloudwatch_alarms = true

# Health check configuration
health_check_path = "/"
