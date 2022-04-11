# DNS Registration
# Default DNS
resource "aws_route53_record" "default_dns" {
    zone_id = data.aws_route53_zone.mydomain.zone_id
    name = "myapps.onspot.click"
    type = "A"
    alias {
        name = module.alb.this_lb_dns_name
        zone_id = module.alb.this_lb_zone_id
        evaluate_target_health = true
    }
}

## Testing Host Header - Redirect to External Site from ALB HTTPS Listener Rules
resource "aws_route53_record" "app1_dns" {
  zone_id = data.aws_route53_zone.mydomain.zone_id
  name = "vineeth.onspot.click"
  type = "A"
  alias {
      name = module.alb.this_lb_dns_name
      zone_id = module.alb.this_lb_zone_id
      evaluate_target_health = true
  }
}
