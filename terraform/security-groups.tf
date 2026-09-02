resource "aws_security_group" "dr_instance" {
  count = var.deploy_dr ? 1 : 0

  name   = "${var.project_name}_dr_instance_sg"
  vpc_id = aws_vpc.principal[0].id


  egress {
    description = "traffic to Internet"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.project_name}_dr_instance_sg"
  }
}
