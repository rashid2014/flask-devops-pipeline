provider "aws" {
  region = "ca-central-1"
}


resource "aws_ecs_cluster" "app_cluster" {
  name = "${var.app_name}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "app_taskd" {
  family                   = "${var.app_name}-task-definition"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = "256"
  memory                   = "512"
  container_definitions = jsonencode([
    {
      name      = "${var.app_name}-container"
      image     = var.image_uri
      essential = true
      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
        }
      ]
    },
  ])
}


resource "aws_ecs_service" "app_service" {
  name            = "${var.app_name}-ecs-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app_taskd.arn
  desired_count   = 3
  #iam_role        = aws_iam_role.foo.arn
  #depends_on      = [aws_iam_role_policy.foo]
  launch_type = "FARGATE"
  network_configuration {
    subnets          = [var.subnet1a_id, var.subnet1b_id]
    security_groups  = [aws_security_group.alb_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_alb_tg.arn
    container_name   = "${var.app_name}-container"
    container_port   = 5000
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.app_name}-alb-sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.app_name}-alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_sg_inbound" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "alb_sg_outbound" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_lb" "app_alb" {
  name               = "${var.app_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [var.subnet1a_id, var.subnet1b_id]

  #enable_deletion_protection = true

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "app_alb_tg" {
  name        = "${var.app_name}-albtg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}

resource "aws_lb_listener" "alb_listener_frontend" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP"
  #port              = "443"
  #protocol          = "HTTPS"
  #ssl_policy        = "ELBSecurityPolicy-2016-08"
  #certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_alb_tg.arn
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.app_name}-ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
