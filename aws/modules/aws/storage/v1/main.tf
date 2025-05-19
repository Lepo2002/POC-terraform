
resource "aws_s3_bucket" "buckets" {
  for_each = var.buckets

  bucket = each.key
  acl    = each.value.acl

  versioning {
    enabled = each.value.enable_versioning
  }

  dynamic "server_side_encryption_configuration" {
    for_each = each.value.enable_encryption ? [1] : []
    content {
      rule {
        apply_server_side_encryption_by_default {
          sse_algorithm = "AES256"
        }
      }
    }
  }

  tags = merge(
    {
      Name        = each.key
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_efs_file_system" "efs" {
  for_each = var.efs_file_systems

  creation_token = each.key
  encrypted      = each.value.encrypted

  lifecycle_policy {
    transition_to_ia = each.value.transition_to_ia
  }

  tags = merge(
    {
      Name        = each.key
      Environment = var.environment
    },
    var.tags
  )
}
