
resource "aws_instance" "ec2_instances" {
  for_each = var.instances

  ami           = each.value.ami
  instance_type = each.value.instance_type
  subnet_id     = each.value.subnet_id

  vpc_security_group_ids = each.value.security_group_ids
  key_name              = each.value.key_name

  root_block_device {
    volume_size = each.value.root_volume_size
    volume_type = each.value.root_volume_type
  }

  tags = merge(
    {
      Name        = each.key
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_autoscaling_group" "asg" {
  for_each = var.auto_scaling_groups

  name                = each.key
  desired_capacity    = each.value.desired_capacity
  max_size            = each.value.max_size
  min_size            = each.value.min_size
  target_group_arns   = each.value.target_group_arns
  vpc_zone_identifier = each.value.subnet_ids

  launch_template {
    id      = aws_launch_template.templates[each.key].id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = merge(
      {
        Name        = each.key
        Environment = var.environment
      },
      var.tags
    )
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_launch_template" "templates" {
  for_each = var.auto_scaling_groups

  name_prefix   = "${each.key}-template"
  image_id      = each.value.ami
  instance_type = each.value.instance_type

  network_interfaces {
    associate_public_ip_address = each.value.associate_public_ip
    security_groups            = each.value.security_group_ids
  }

  user_data = base64encode(each.value.user_data)

  tags = merge(
    {
      Name        = "${each.key}-template"
      Environment = var.environment
    },
    var.tags
  )
}
