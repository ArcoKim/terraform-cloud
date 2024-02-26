resource "aws_cloudwatch_dashboard" "worker" {
  dashboard_name = "worker"

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
              "AWS/EC2",
              "CPUUtilization",
              "AutoScalingGroupName",
              "${aws_eks_node_group.app.resources[0].autoscaling_groups[0].name}"
            ]
          ]
          period = 60
          stat   = "Average"
          region = local.region
          title  = "WORKER CPU"
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
              "AWS/EC2",
              "NetworkOut",
              "AutoScalingGroupName",
              "${aws_eks_node_group.app.resources[0].autoscaling_groups[0].name}"
            ],
            [
              "AWS/EC2",
              "NetworkIn",
              "AutoScalingGroupName",
              "${aws_eks_node_group.app.resources[0].autoscaling_groups[0].name}"
            ]
          ]
          period = 60
          stat   = "Average"
          region = local.region
          title  = "WORKER NETWORK"
        }
      }
    ]
  })
}

resource "aws_cloudwatch_dashboard" "stress" {
  dashboard_name = "stress"

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
              "RequestCount",
              "LoadBalancer",
              "${data.aws_lb.stress.arn_suffix}"
            ]
          ]
          period = 60
          stat   = "Sum"
          region = local.region
          title  = "STRESS REQ COUNT"
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
              "TargetResponseTime",
              "LoadBalancer",
              "${data.aws_lb.stress.arn_suffix}"
            ]
          ]
          period = 60
          stat   = "Average"
          region = local.region
          title  = "STRESS RES TIME"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            [
              "AWS/ApplicationELB",
              "HTTPCode_ELB_5XX_Count",
              "LoadBalancer",
              "${data.aws_lb.stress.arn_suffix}"
            ]
          ]
          period = 60
          stat   = "Sum"
          region = local.region
          title  = "STRESS 5xx"
        }
      }
    ]
  })
}