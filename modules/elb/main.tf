resource "aws_elb" "this" {
  count = !var.network_lb ? 1 : 0

  name        = var.name
  name_prefix = var.name_prefix

  subnets         = var.subnets
  internal        = var.internal
  security_groups = var.security_groups

  cross_zone_load_balancing   = var.cross_zone_load_balancing
  idle_timeout                = var.idle_timeout
  connection_draining         = var.connection_draining
  connection_draining_timeout = var.connection_draining_timeout

  dynamic "listener" {
    for_each = var.listener
    content {
      instance_port      = listener.value.instance_port
      instance_protocol  = listener.value.instance_protocol
      lb_port            = listener.value.lb_port
      lb_protocol        = listener.value.lb_protocol
      ssl_certificate_id = lookup(listener.value, "ssl_certificate_id", null)
    }
  }

  dynamic "access_logs" {
    for_each = length(keys(var.access_logs)) == 0 ? [] : [var.access_logs]
    content {
      bucket        = access_logs.value.bucket
      bucket_prefix = lookup(access_logs.value, "bucket_prefix", null)
      interval      = lookup(access_logs.value, "interval", null)
      enabled       = lookup(access_logs.value, "enabled", true)
    }
  }

  dynamic "health_check" {
    for_each = length(keys(var.access_logs)) == 0 ? [] : [var.access_logs]
    content {
      healthy_threshold   = lookup(var.health_check, "healthy_threshold")
      unhealthy_threshold = lookup(var.health_check, "unhealthy_threshold")
      target              = lookup(var.health_check, "target")
      interval            = lookup(var.health_check, "interval")
      timeout             = lookup(var.health_check, "timeout")
    }
  }

  tags = merge(
    var.tags,
    {
      "Name" = format("%s", var.name)
    },
  )
}

# @TODO
#   - S2S, I think you might need to move this to a separate module - terraform-aws-lb
resource "aws_lb" "this" {
  count = var.network_lb ? 1 : 0

  name        = var.name
  name_prefix = var.name_prefix

  subnets         = var.subnets
  internal        = var.internal
  #security_groups = var.security_groups

  load_balancer_type = "network"

  enable_cross_zone_load_balancing = var.cross_zone_load_balancing
  idle_timeout                     = var.idle_timeout

  dynamic "access_logs" {
    for_each = length(keys(var.access_logs)) == 0 ? [] : [var.access_logs]
    content {
      bucket        = access_logs.value.bucket
      prefix = lookup(access_logs.value, "bucket_prefix", null)
      enabled       = lookup(access_logs.value, "enabled", true)
    }
  }

  tags = merge(
    var.tags,
    {
      "Name" = format("%s", var.name)
    },
  )
}

# @TODO - add other target types. See https://www.terraform.io/docs/providers/aws/r/lb_target_group.html
resource "aws_lb_target_group" "this" {
  count    = var.network_lb ? 1 : 0

  name     = "${var.name}-tg"
  port     = var.lb_target_group.port
  protocol = var.lb_target_group.protocol
  vpc_id   = var.vpc_id
}