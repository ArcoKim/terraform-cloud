resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "WSI_API"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            [
              "AWS/ApplicationELB",
              "HTTPCode_Target_5XX_Count",
              "LoadBalancer",
              "${aws_lb.web.arn_suffix}"
            ],
            [
              "AWS/ApplicationELB",
              "HTTPCode_ELB_5XX_Count",
              "LoadBalancer",
              "${aws_lb.web.arn_suffix}"
            ]
          ]
          period = 60
          stat   = "Sum"
          region = local.region
          title  = "HTTP_ERROR"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            [
              "AWS/ApplicationELB",
              "RequestCount",
              "LoadBalancer",
              "${aws_lb.web.arn_suffix}"
            ]
          ]
          period = 60
          stat   = "Sum"
          region = local.region
          title  = "HTTP_COUNT"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 7
        width  = 12
        height = 6

        properties = {
          metrics = [
            [
              "AWS/ApplicationELB",
              "TargetResponseTime",
              "LoadBalancer",
              "${aws_lb.web.arn_suffix}"
            ]
          ]
          period = 60
          stat   = "Average"
          region = local.region
          title  = "RESPONSE_TIME"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 7
        width  = 12
        height = 6

        properties = {
          metrics = [
            [
              "AWS/EC2",
              "CPUUtilization",
              "AutoScalingGroupName",
              "${aws_autoscaling_group.webapp.name}"
            ]
          ]
          period = 60
          stat   = "Average"
          region = local.region
          title  = "API_CPU"
        }
      }
    ]
  })
}