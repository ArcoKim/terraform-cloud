resource "aws_cloudwatch_metric_alarm" "error" {
  alarm_name                = "ALB-4XX-high"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = "HTTPCode_Target_4XX_Count"
  namespace                 = "AWS/ApplicationELB"
  period                    = 60
  statistic                 = "Sum"
  threshold                 = 55

  dimensions = {
    LoadBalancer = aws_lb.web.arn_suffix
  }
}