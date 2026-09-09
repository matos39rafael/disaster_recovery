resource "aws_instance" "DR_instance" {
  count = var.deploy_dr ? 1 : 0

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_subnet[0].id
  vpc_security_group_ids      = [aws_security_group.dr_instance[0].id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_dr[0].name


  user_data = templatefile("${path.module}/user_data.sh", {

    compose     = file("${path.module}/../docker/compose.yml")
    litestream  = file("${path.module}/../docker/litestream.yml")
    bootstrap   = file("${path.module}/../scripts/dr/bootstrap.sh")
    healthcheck = file("${path.module}/../scripts/dr/healthcheck.sh")
    restore     = file("${path.module}/../scripts/dr/restore.sh")

    aws_region        = var.aws_region
    litestream_bucket = aws_s3_bucket.disaster_recovery.bucket
    epauta_host       = var.domain_name
    tunnel_token      = data.cloudflare_zero_trust_tunnel_cloudflared_token.aws[0].token
    app_image         = var.app_image
  })

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }


  root_block_device {
    volume_size = 20
    volume_type = "gp3"

    encrypted = true
  }

  tags = {
    Name      = "${var.project_name}_DR_instance"
    SSMAccess = true

  }
}
