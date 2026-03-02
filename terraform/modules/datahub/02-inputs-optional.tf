variable "enable_load_balancer" {
  type    = bool
  default = false
}

variable "hub_firewall_ips" {
  type    = list(string)
  default = ["192.168.20.0/28", "192.168.21.0/28"]
}