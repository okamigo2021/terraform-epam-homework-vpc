# NLB definition
resource "aws_lb" "web-lb" {
  name               = "web-lb-tf"
  internal           = false
  #load_balancer_type = "network"
  security_groups    = [aws_security_group.lb-sec.id]
  subnets = [aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id]
}


#Target group definition for NLB
resource "aws_lb_target_group" "targetgrp" {
  name     = "tf-web-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.web_vpc.id
}

# NLB attachment
resource "aws_lb_target_group_attachment" "attach_web" {
  target_group_arn = aws_lb_target_group.targetgrp.arn
  target_id        = element(aws_instance.web.*.id, count.index)
  port             = 80
  count            = "1"
}

# Listener for NLB
resource "aws_lb_listener" "webport" {
  load_balancer_arn = aws_lb.web-lb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.targetgrp.arn
    type             = "forward"
  }
}