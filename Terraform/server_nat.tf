resource "aws_security_group" "nat" {
  name        = "nat-sg"
  description = "Allow NAT traffic"
  vpc_id      = aws_vpc.main.id



  ingress {
    description = "private subnet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.3.0/24"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
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
    Name = "nat-sg"
  }
}

# Elastic Public IP
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "TEMP-nat-eip"
  }
}



# Create an Elastic Network Interface (ENI) for the NAT instance
resource "aws_network_interface" "nat" {
  subnet_id         = aws_subnet.public1.id
  security_groups   = [aws_security_group.nat.id]
  source_dest_check = false

  tags = {
    Name = "nat-instance-eni"
  }
}

# Associate Public IP to ENI
resource "aws_eip_association" "nat" {
  allocation_id        = aws_eip.nat.id
  network_interface_id = aws_network_interface.nat.id
}



# NAT Instance using the ENI
resource "aws_instance" "nat" {
  ami                  = data.aws_ami.amazon_linux.id
  instance_type        = "t4g.nano"
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  # Use the ENI we created instead of letting AWS create one automatically
  network_interface {
    network_interface_id = aws_network_interface.nat.id
    device_index         = 0
  }

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    cd /tmp
    wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_arm64/amazon-ssm-agent.rpm
    yum install -y /tmp/amazon-ssm-agent.rpm
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
    systemctl status amazon-ssm-agent
    
    # Enable IP forwarding
    echo 1 > /proc/sys/net/ipv4/ip_forward
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
    
    # Configure NAT
    yum update -y
    yum install -y iptables-services
    
    # Start iptables
    systemctl enable iptables
    systemctl start iptables
    
    # Set up NAT masquerading
    iptables -t nat -A POSTROUTING -o eth0 -s 0.0.0.0/0 -j MASQUERADE
    
    # Remove the default FORWARD chain REJECT rule
    iptables -D FORWARD -j REJECT --reject-with icmp-host-prohibited
    
    # Allow forwarded traffic
    iptables -A FORWARD -i eth0 -o eth0 -j ACCEPT
    
    # Save iptables rules properly
    service iptables save
    
    # Save sysctl settings for persistence
    sysctl -p

    # Harden
    systemctl stop postfix
    systemctl disable postfix
    systemctl stop rpcbind
    systemctl disable rpcbind
    systemctl stop gssproxy
    systemctl disable gssproxy
  EOF


  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
    instance_metadata_tags      = "enabled"
  }

  tags = {
    Name = "nat-instance"
  }
}

