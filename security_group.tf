resource "outscale_security_group" "ssh" {
  description         = "ssh"
  security_group_name = "bastion-ssh"
  net_id              = outscale_net.user_vpc.net_id
}

resource "outscale_security_group_rule" "ssh" {
  flow              = "Inbound"
  security_group_id = outscale_security_group.ssh.id

  from_port_range = "22"
  to_port_range   = "22"

  ip_protocol = "tcp"
  ip_range    = "0.0.0.0/0"
}
