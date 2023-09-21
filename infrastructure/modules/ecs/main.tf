########################################################
# ECS CLUSTER CONFIGURATION
########################################################
resource "aws_ecs_cluster" "cluster" {
  name = "${var.app_name}-cluster"
}


########################################################
# ECS TASK DEFINITIONS
########################################################
resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                    = "ecs-task-definition"
  requires_compatibilities  = ["FARGATE"]
  network_mode              = "awsvpc"
  cpu                       = var.fargate_cpu
  memory                    = var.fargate_mem
  task_role_arn             = aws_iam_role.ecs_task_role.arn
  execution_role_arn        = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode(
    [
      {
        name  = var.app_container_name
        image = var.app_image
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group = "/ecs/${var.app_name}-app",
            awslogs-region = var.region,
            awslogs-stream-prefix = "ecs"
          }
        }
        portMappings = [
          {
            containerPort = var.app_port
            hostPort      = var.app_port
          }
        ]
      }
    ]
  )
}

### Setup ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role.json
}

data "aws_iam_policy_document" "ecs_task_execution_role" {
  version = "2012-10-17"
  statement {
    sid = ""
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


### Setup ECS Task Role
resource "aws_iam_role" "ecs_task_role" {
  name                = "ecs-task-role"
  assume_role_policy  = data.aws_iam_policy_document.ecs_task_role.json
}

data "aws_iam_policy_document" "ecs_task_role" {
  version = "2012-10-17"
  statement {
    sid = ""
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

### Setup ECS Secrets Manager access
resource "aws_iam_policy" "secrets_policy" {
  name = "secrets-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds",
          "secretsmanager:ListSecrets",
          "secretsmanager:GetSecretValue"
        ],
        Effect = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secrets_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.secrets_policy.arn
}

### Setup ECS SSM access
resource "aws_iam_policy" "ssm_policy" {
  name = "ssm-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        Effect = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ssm_policy.arn
}

########################################################
# ECS SERVICE CONFIGURATION
########################################################
resource "aws_ecs_service" "ecs_service" {
  name            = "${var.app_name}-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  launch_type     = "FARGATE"
  desired_count   = var.ecs_task_count

  network_configuration {
    subnets           = var.private_subnets
    security_groups   = [
      aws_security_group.ecs_task_sg.id
    ]
    assign_public_ip  = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.alb_target_group.id
    container_name   = var.app_container_name
    container_port   = var.app_port
  }

  depends_on = [
    aws_lb_listener.alb_listener_forward1,
    aws_lb_listener.alb_listener_forward2,
    aws_lb_listener.alb_listener_redirect_http,
    aws_iam_role_policy_attachment.ecs_task_execution_role,
    #hopefully ensure that DB is provisioned first before the ECS service
    var.db_dependency,
  ]
}

resource "aws_security_group" "ecs_task_sg" {
  name        = "ecs-task-sg"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = var.app_port
    to_port     = var.app_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

########################################################
# LOAD BALANCER CONFIGURATION
########################################################
resource "aws_lb" "app_alb" {
  name                = "app-alb"
  internal            = false
  load_balancer_type  = "application"
  subnets             = var.public_subnets
  security_groups     = [aws_security_group.alb_sg.id]
}

resource "aws_alb_target_group" "alb_target_group" {
  name        = "alb-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }
}

resource "aws_lb_listener" "alb_listener_forward1" {
  load_balancer_arn = aws_lb.app_alb.id
  port              = var.app_port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.alb_target_group.id
    type             = "forward"
  }
}

resource "aws_lb_listener" "alb_listener_forward2" {
  load_balancer_arn = aws_lb.app_alb.id
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = module.acm.acm_certificate_arn

  default_action {
    target_group_arn = aws_alb_target_group.alb_target_group.id
    type             = "forward"
  }

  depends_on = [ module.acm ]
}

resource "aws_lb_listener" "alb_listener_redirect_http" {
  load_balancer_arn = aws_lb.app_alb.id
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

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = var.app_port
    to_port     = var.app_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

########################################################
# SITE CONFIGURATION
########################################################

# Adapted from official Terraform example
# https://github.com/terraform-aws-modules/terraform-aws-acm/blob/master/examples/complete-dns-validation/main.tf
locals {
  #Use existing Hosted Zone (via data source), or create a new zone
  #if zone is not reachable
  use_existing_route53_zone = true
  domain_name = trimsuffix(var.target_domain, ".")
  zone_id = try(data.aws_route53_zone.this[0].zone_id, aws_route53_zone.this[0].zone_id)
}

data "aws_route53_zone" "this" {
  count         = local.use_existing_route53_zone ? 1 : 0
  name          = local.domain_name
  private_zone  = false
}

resource "aws_route53_zone" "this" {
  count = !local.use_existing_route53_zone ? 1 : 0
  name  = local.domain_name
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "4.3.2"

  domain_name = local.domain_name
  zone_id     = local.zone_id

  subject_alternative_names = [
    "*.${local.domain_name}",
  ]

  wait_for_validation = true
}

resource "aws_route53_record" "alb_record" {
  zone_id = local.zone_id
  name    = local.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.app_alb.dns_name
    zone_id                = aws_lb.app_alb.zone_id
    evaluate_target_health = true
  }
}
