locals {
  broker_properties = ({
    container_name         = "broker"
    port                   = 9092
    cpu                    = 256
    memory                 = 2048
    load_balancer_required = false
  })
  datahub_actions = ({
    container_name         = "datahub-actions"
    port                   = 80
    cpu                    = 256
    memory                 = 2048
    load_balancer_required = false
  })
  datahub_frontend_react_properties = ({
    container_name         = "datahub-frontend-react"
    port                   = 9002
    cpu                    = 256
    memory                 = 2048
    load_balancer_required = true
  })
  datahub_gms = ({
    container_name         = "datahub-gms"
    port                   = 8080
    cpu                    = 256
    memory                 = 2048
    load_balancer_required = false
  })
}