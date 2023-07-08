# Create EC2 instance

resource "aws_instance" "instance_1" {
  ami             = "ami-01dd271720c1ba44f"
  instance_type   = "t2.medium"
   # Instance Storage Configuration
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
  }
  key_name        = "capstone-keys"
  security_groups = [aws_security_group.gp19-instances-sg.id]
  subnet_id       = aws_subnet.gp19-public-subnet-1.id
}

# Create EC2 instance

resource "aws_instance" "instance_2" {
  ami             = "ami-01dd271720c1ba44f"
  instance_type   = "t2.medium"
   # Instance Storage Configuration
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
  }
  key_name        = "capstone-keys"
  security_groups = [aws_security_group.gp19-instances-sg.id]
  subnet_id       = aws_subnet.gp19-public-subnet-2.id
}

# Create Security Group for EC2 Instance

resource "aws_security_group" "gp19-instances-sg" {
  name   = "allow_http_https_ssh"
  vpc_id = aws_vpc.g19capstone_vpc.id

  ingress {
    description = "HTTP"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.gp19-lb-sg.id]
  }

  ingress {
    description     = "HTTPS"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.gp19-lb-sg.id]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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
    Name = "gp19-instances-sg"
  }
}

# Create Security Group for Load Balaancer

resource "aws_security_group" "gp19-lb-sg" {
  name   = "gp19-lb-sg"
  vpc_id = aws_vpc.g19capstone_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Listener for Load Balancer

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.gp19-load-balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.g19capstone-tg.arn
  }
}

# Create Target Group for Load Balancer

resource "aws_lb_target_group" "g19capstone-tg" {
  name       = "g19capstone-tg"
  target_type = "instance"
  port       = 80
  protocol   = "HTTP"
  vpc_id     = aws_vpc.g19capstone_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

# Create Target Group Attachment for Load Balancer

resource "aws_lb_target_group_attachment" "gp19-tg-attachment-1" {
  target_group_arn = aws_lb_target_group.g19capstone-tg.arn
  target_id        = aws_instance.instance_1.id
  port             = 80
}

# Create Target Group Attachment for Load Balancer

resource "aws_lb_target_group_attachment" "gp19-tg-attachment-2" {
  target_group_arn = aws_lb_target_group.g19capstone-tg.arn
  target_id        = aws_instance.instance_2.id
  port             = 80
}

# Create Listener Rule for Load Balancer

resource "aws_lb_listener_rule" "gp19-listener-rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 1

  condition {
    path_pattern {
      values = ["/"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.g19capstone-tg.arn
  }
}

# Create Load Balancer

resource "aws_lb" "gp19-load-balancer" {
  name                       = "gp19-load-balancer"
  load_balancer_type         = "application"
  subnets                    = [aws_subnet.gp19-public-subnet-1.id, aws_subnet.gp19-public-subnet-2.id]
  security_groups            = [aws_security_group.gp19-lb-sg.id]
  enable_deletion_protection = false

}

# Create Route53 Zone to link Domain

resource "aws_route53_zone" "primary" {
  name = "altgroup19.tech"
}

# Create A record in Route53 for Domain

resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "terraform-test.altgroup19.tech"
  type    = "A"

  alias {
    name                    = aws_lb.gp19-load-balancer.dns_name
    zone_id                 = aws_lb.gp19-load-balancer.zone_id
    evaluate_target_health  = true
  }
}

# Create Launch Template for Auto Scaling Group

resource "aws_launch_template" "g19capstone-lt" {
  name_prefix   = "g19capstone-lt"
  image_id      = "ami-01dd271720c1ba44f" 
  instance_type = "t2.medium"

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 30
      volume_type = "gp3"
    }
  }
}

# Create Auto Scaling Group

resource "aws_autoscaling_group" "gp19capstone-asgp" {
  name                      = "gp19capstone-asgp"
  max_size                  = 4
  min_size                  = 0
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 3
  force_delete              = true
  vpc_zone_identifier       = [aws_subnet.gp19-public-subnet-1.id, aws_subnet.gp19-public-subnet-2.id]

  launch_template {
    id      = aws_launch_template.g19capstone-lt.id
    version = "$Latest"
  }

}

# Create S3 Bucket

resource "aws_s3_bucket" "gp19capstone-s3" {
  bucket = "gp19-capstone-bucket"

  tags = {
    Name        = "GP19 bucket"
    Environment = "Dev"
  }
}