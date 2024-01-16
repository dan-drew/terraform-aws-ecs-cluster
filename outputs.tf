output "id" {
  value = aws_ecs_cluster.main.id
}

output "arn" {
  value = aws_ecs_cluster.main.arn
}

output "security_group_id" {
  value = aws_security_group.ecs_hosts.id
}

output "autoscale_role_arn" {
  value = aws_iam_role.ecs_autoscale.arn
}
