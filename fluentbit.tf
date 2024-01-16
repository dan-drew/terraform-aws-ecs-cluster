# module "fluentbit" {
#   source           = "../fluentbit"
#   ecs_cluster_name = var.name
#   env              = terraform.workspace
#   enable_fluentbit = coalesce(var.logging, "fluentbit") == "fluentbit"
#   log_group        = aws_cloudwatch_log_group.cluster.name
# }
