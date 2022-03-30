locals {
  datahub_frontend_react_properties = ({
    container_name         = "datahub-frontend-react"
    port                   = 9002
    cpu                    = 256
    memory                 = 2048
    load_balancer_required = true
  })
}