# data "aws_lb" "lb" {
#   for_each = toset(var.load_balancers)
#   name     = each.value
# }

# locals {
#   load_balancer_security_groups = {
#     for i, lb in var.load_balancers :
#     lb => data.aws_lb.lb[lb]
#   }
# }

# resource "aws_security_group_rule" "ecs_hosts_lb" {
#   for_each = merge(
#     [
#       for lb_name, lb in local.load_balancer_security_groups :
#       { for i, sg in lb.security_groups : "${lb_name}_${i}" => { name = lb_name, security_group = sg } }
#     ]...
#   )
#   security_group_id        = aws_security_group.ecs_hosts.id
#   from_port                = 0
#   to_port                  = 0
#   protocol                 = "-1"
#   type                     = "ingress"
#   source_security_group_id = each.value.security_group
#   description              = "Load balancer ${each.value.name} (${var.tagging.managed_by})"
# }
