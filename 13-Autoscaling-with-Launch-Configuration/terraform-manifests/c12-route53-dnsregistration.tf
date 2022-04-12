# DNS Registration
# Default DNS
resource "aws_route53_record" "apps_dns" {
    zone_id = data.aws_route53_zone.mydomain.zone_id
    name = "asg-lc.onspot.click"
    type = "A"
    alias {
        name = module.alb.lb_dns_name
        zone_id = module.alb.lb_zone_id
        evaluate_target_health = true
    }
}

