resource "aws_ecs_cluster" "main" {
  name = var.name
}

resource "aws_ecs_capacity_provider" "capacity_provider" {
  count = var.auto_scale ? 1 : 0
  name  = "${var.name}-capacity-provider"

  auto_scaling_group_provider {
    # NOTE: If adding to an existing aws_autoscaling_group, do the following:
    # 1.) Add termination protection to the existing ec2 instances in the target cluster.
    # 2.) Run `terraform plan/apply -target=module.app.module.ecs_cluster.aws_ecs_cluster.main -target=module.app.module.ecs_cluster.aws_ecs_capacity_provider.capacity_provider -target=module.app.module.ecs_cluster.aws_autoscaling_group.ecs_hosts`
    # 3.) Allow AWS to spin up new instances using the new capacity provider.
    # 4.) Terminate the old instances manually.
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_hosts.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      minimum_scaling_step_size = var.min_scaling_step
      maximum_scaling_step_size = var.max_scaling_step
      status                    = "ENABLED"
      target_capacity           = coalesce(var.target_capacity, var.tagging.production ? 99 : 100)
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  count              = var.auto_scale ? 1 : 0
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = aws_ecs_capacity_provider.capacity_provider.*.name
}

data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

data "template_cloudinit_config" "host_user_data" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/files/host_user_data.yml.tftpl", { cluster_name = var.name, users = var.users })
  }
}

resource "aws_launch_template" "ecs_host" {
  name                   = "${var.name}_ecs_host"
  image_id               = data.aws_ssm_parameter.ecs_ami.value
  instance_type          = var.instance_type
  user_data              = base64encode(data.template_cloudinit_config.host_user_data.rendered)
  update_default_version = true

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs.name
  }

  network_interfaces {
    security_groups             = [aws_security_group.ecs_hosts.id]
    delete_on_termination       = true
    associate_public_ip_address = var.assign_public_ips
  }

  tag_specifications {
    resource_type = "instance"
    tags = { Name = "${var.name}_ecs_host" }
  }

  tag_specifications {
    resource_type = "volume"
    tags = { Name = "${var.name}_ecs_host" }
  }
}

resource "aws_autoscaling_group" "ecs_hosts" {
  name                 = "${var.name}_ecs_hosts"
  desired_capacity     = var.initial_hosts
  max_size             = var.max_hosts
  min_size             = var.min_hosts
  vpc_zone_identifier  = var.type == "public" ? var.vpc.public_subnet_ids : var.vpc.private_subnet_ids
  termination_policies = ["OldestLaunchConfiguration", "OldestInstance"]

  launch_template {
    id = aws_launch_template.ecs_host.id
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }

  # Required for capacity provider
  dynamic "tag" {
    for_each = toset(var.auto_scale ? ["AmazonECSManaged"] : [])
    content {
      key                 = tag.value
      value               = true
      propagate_at_launch = true
    }
  }
}
