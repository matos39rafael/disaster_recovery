resource "aws_iam_role" "ec2_dr" {
  count = var.deploy_dr ? 1 : 0

  name = "${var.project_name}_ec2_dr_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = {
    Name        = "${var.project_name}-ec2-dr-role"
    Environment = "dr"
    ManagedBy   = "terraform"
  }

}

resource "aws_iam_role_policy_attachment" "ec2_dr_ssm" {
  count      = var.deploy_dr ? 1 : 0
  role       = aws_iam_role.ec2_dr[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_iam_policy" "ec2_dr_s3" {
  count       = var.deploy_dr ? 1 : 0
  name        = "${var.project_name}_ec2_dr_s3"
  description = "Policy to allow ec2 dr instance access SQLite data stored in S3 Bucket"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "GetBucketLocation"
        Effect = "Allow"

        Action = [
          "s3:GetBucketLocation"
        ]

        Resource = aws_s3_bucket.disaster_recovery.arn
      },

      {
        Sid    = "ListReplicaPrefix"
        Effect = "Allow"

        Action = [
          "s3:ListBucket"
        ]

        Resource = aws_s3_bucket.disaster_recovery.arn

        Condition = {
          StringLike = {
            "s3:prefix" = [
              "sqlite/epauta",
              "sqlite/epauta/*"
            ]
          }
        }
      },

      {
        Sid    = "ManageReplicaObjects"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:DeleteObject"
        ]

        Resource = "${aws_s3_bucket.disaster_recovery.arn}/sqlite/epauta/*"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-ec2-dr-s3"
    Environment = "dr"
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "ec2_dr_s3" {
  count      = var.deploy_dr ? 1 : 0
  role       = aws_iam_role.ec2_dr[0].name
  policy_arn = aws_iam_policy.ec2_dr_s3[0].arn

}

resource "aws_iam_policy" "epauta_parameters" {
  count = var.deploy_dr ? 1 : 0
  name  = "${var.project_name}_parameter_store"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]

        Resource = [
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/epauta/dr/SECRET_KEY",
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/epauta/dr/ADMIN_USER",
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/epauta/dr/ADMIN_PASSWORD"
        ]
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}_epauta_parameters_policy"
    Environment = "dr"
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "epauta_parameters" {
  count      = var.deploy_dr ? 1 : 0
  role       = aws_iam_role.ec2_dr[0].name
  policy_arn = aws_iam_policy.epauta_parameters[0].arn

}


resource "aws_iam_instance_profile" "ec2_dr" {
  count = var.deploy_dr ? 1 : 0
  name  = "${var.project_name}_ec2_dr_profile"
  role  = aws_iam_role.ec2_dr[0].name

  tags = {
    Name        = "${var.project_name}-ec2-dr-profile"
    Environment = "dr"
    ManagedBy   = "terraform"
  }

}

resource "aws_iam_user" "litestream" {
  name = "${var.project_name}-litestream"


  tags = {
    Name        = "${var.project_name}-litestream"
    Environment = "on-premises"
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_policy" "litestream_s3" {
  name = "${var.project_name}-litestream_s3"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "GetBucketLocation"
        Effect = "Allow"

        Action = [
          "s3:GetBucketLocation"
        ]

        Resource = aws_s3_bucket.disaster_recovery.arn
      },

      {
        Sid    = "ListReplicaPrefix"
        Effect = "Allow"

        Action = [
          "s3:ListBucket"
        ]

        Resource = aws_s3_bucket.disaster_recovery.arn

        Condition = {
          StringLike = {
            "s3:prefix" = [
              "sqlite/epauta",
              "sqlite/epauta/*"
            ]
          }
        }
      },

      {
        Sid    = "ManageReplicaObjects"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:DeleteObject"
        ]

        Resource = "${aws_s3_bucket.disaster_recovery.arn}/sqlite/epauta/*"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}_litestream_s3"
    Environment = "on-premises"
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_user_policy_attachment" "litestream_s3" {
  user       = aws_iam_user.litestream.name
  policy_arn = aws_iam_policy.litestream_s3.arn
}
