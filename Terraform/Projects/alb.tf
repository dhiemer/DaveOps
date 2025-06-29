locals {
  sites = {

    #main = {
    #  url      = "daveops.pro"
    #  priority = 100
    #  Port     = 30081
    #  conditions = [
    #    {
    #      type   = "host_header"
    #      values = ["daveops.pro"]
    #    }
    #  ]
    #}

    earthquakes = {
      url      = "earthquakes.daveops.pro"
      priority = 200
      Port     = 30080
      conditions = [
        {
          type   = "host_header"
          values = ["earthquakes.daveops.pro"]
        }
      ]
    }

    sedaro-web = {
      url      = "sedaro-nano.daveops.pro"
      priority = 310
      Port     = 30180
      conditions = [
        {
          type   = "host_header"
          values = ["sedaro-nano.daveops.pro"]
        }
      ]
    }

    sedaro-api = {
      url      = "sedaro-nano.daveops.pro"
      priority = 301
      Port     = 30181
      conditions = [
        {
          type   = "host_header"
          values = ["sedaro-nano.daveops.pro"]
        },
        {
          type   = "path_pattern"
          values = ["/simulation"]
        }
      ]
    }

    sedaro-grafana = {
      url      = "sedaro-nano.daveops.pro"
      priority = 302
      Port     = 30000
      conditions = [
        {
          type   = "path_pattern"
          values = ["/grafana", "/grafana/*"]
        },
        {
          type   = "host_header"
          values = ["sedaro-nano.daveops.pro"]
        }
      ]
    }
    
  }
}

resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Allow inbound traffic to ALB"
  vpc_id      = aws_vpc.main.id

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
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

resource "aws_lb" "alb" {
  name               = "main-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]

  tags = {
    Name = "main-alb"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn   = aws_acm_certificate.wildcard.arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404 Not Found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_target_group" "this" {
  for_each = local.sites

  name     = "tg-${each.key}"
  port     = each.value.Port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = each.key == "sedaro-api" ? "/simulation" : "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "tg-${each.key}"
  }
}

resource "aws_lb_listener_rule" "this" {
  for_each = local.sites

  listener_arn = aws_lb_listener.https.arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }

  dynamic "condition" {
    for_each = [for c in each.value.conditions : c if c.type == "host_header"]
    content {
      host_header {
        values = condition.value.values
      }
    }
  }

  dynamic "condition" {
    for_each = [for c in each.value.conditions : c if c.type == "path_pattern"]
    content {
      path_pattern {
        values = condition.value.values
      }
    }
  }
}

resource "aws_alb_target_group_attachment" "tg_kube_tgattachment" {
  for_each         = local.sites
  target_group_arn = aws_lb_target_group.this[each.key].arn
  target_id        = aws_instance.k3s_server.id
  port             = each.value.Port
}
