resource "aws_route53_zone" "zone" {
  name = "${var.app_name}-app"
}

resource "aws_route53_record" "alb_record" {
  zone_id = aws_route53_zone.zone.zone_id
  name    = "${var.app_name}-app"
  type    = "A"
  ttl     = "300"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
