resource "aws_security_group" "kube_sg" {
  name        = "daveops-kube-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "daveops-web-sg"
  }
}


resource "aws_instance" "k3s_server" {
  ami                    = "ami-0e54f1b41c24e4f5e" # Amazon Linux 2 ARM64
  instance_type          = "t4g.small"
  subnet_id              = aws_subnet.private1.id
  vpc_security_group_ids = [aws_security_group.kube_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.kube_profile.name
  key_name               = "Dave_PEM"
  tags = {
    Name = "DaveOps-k3s_server"
  }

  user_data = templatefile("${path.module}/server_kube_userdata.tpl", {
    repo_url           = "https://github.com/dhiemer/earthquake-monitor"
    registration_token = data.github_actions_registration_token.runner.token
    runner_name        = "k3s-runner-1"
    runner_labels      = "k3s,ARM64"
  })

  lifecycle {
    ignore_changes = [user_data]
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
    instance_metadata_tags      = "enabled"
  }

}

