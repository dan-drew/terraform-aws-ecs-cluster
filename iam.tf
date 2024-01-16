module "ecs_host_assume_role" {
  source = "github.com/dan-drew/terraform-aws-assume-role-policy"
  type   = "ecs_host"
}

module "autoscaling_assume_role" {
  source = "github.com/dan-drew/terraform-aws-assume-role-policy"
  type   = "appautoscaling"
}

resource "aws_iam_role" "ecs_host" {
  name               = "${var.name}_ecs_host"
  description        = var.tagging.managed_by
  assume_role_policy = module.ecs_host_assume_role.policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_host_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  role       = aws_iam_role.ecs_host.id
}

resource "aws_iam_role_policy_attachment" "ecs_host_ssm_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
  role       = aws_iam_role.ecs_host.id
}

resource "aws_iam_instance_profile" "ecs" {
  name = "${var.name}_ecs_instance_profile"
  role = aws_iam_role.ecs_host.name
}

resource "aws_iam_role" "ecs_autoscale" {
  name               = "${var.name}_ecs_autoscale"
  description        = var.tagging.managed_by
  assume_role_policy = module.autoscaling_assume_role.policy.json
}

resource "aws_iam_role_policy" "ecs_autoscale" {
  name   = "${var.name}_ecs_autoscale"
  role   = aws_iam_role.ecs_autoscale.name
  policy = data.aws_iam_policy_document.ecs_autoscale.json
}

data "aws_iam_policy_document" "ecs_autoscale" {
  statement {
    sid       = "DescribeCluster"
    actions   = ["ecs:DescribeServices"]
    resources = [aws_ecs_cluster.main.arn]
  }
  statement {
    sid       = "UpdateService"
    actions   = ["ecs:UpdateService"]
    resources = [replace(aws_ecs_cluster.main.arn, "/cluster.*$/", "service/*")]
  }
  statement {
    sid       = "Alarms"
    actions   = ["cloudwatch:DescribeAlarms", "cloudwatch:PutMetricAlarm"]
    resources = ["*"]
  }
}
