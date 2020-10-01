provider "outscale" {
  access_key_id = var.access_key_id
  secret_key_id = var.secret_key_id
  region        = var.region
  endpoints {
    api = "https://api.${var.region}.outscale.com/api/v1"
  }
}

resource "outscale_net" "user_vpc" {
  ip_range = "10.0.0.0/16"
  tags {
    key   = "name"
    value = "user-network"
  }
}

resource "outscale_subnet" "subnet_public" {
  subregion_name = "${var.region}a"
  ip_range       = "10.0.0.0/24"
  net_id         = outscale_net.user_vpc.net_id
}

resource "outscale_subnet" "subnet_prive" {
  subregion_name = "${var.region}a"
  ip_range       = "10.0.1.0/24"
  net_id         = outscale_net.user_vpc.net_id
}

resource "outscale_nic" "nic" {
  subnet_id = outscale_subnet.subnet_prive.subnet_id
}

resource "outscale_public_ip" "nat_ip" {
}

resource "outscale_public_ip" "bastion_ip" {
}

resource "outscale_keypair" "bastion" {
  keypair_name = "bastion-keypair"
  public_key   = file("~/.ssh/id_rsa.pub")
}


resource "outscale_vm" "bastion" {
  keypair_name       = outscale_keypair.bastion.keypair_name
  image_id           = "ami-1b3c87fd"
  vm_type            = "tinav3.c2r4"
  security_group_ids = [outscale_security_group.ssh.id]
  subnet_id          = outscale_subnet.subnet_public.subnet_id
}

resource "outscale_public_ip_link" "bastion_server" {
  vm_id     = outscale_vm.bastion.vm_id
  public_ip = outscale_public_ip.bastion_ip.public_ip
}


resource "outscale_internet_service" "internet_service" {
}

resource "outscale_internet_service_link" "internet_service_link" {
  net_id              = outscale_net.user_vpc.net_id
  internet_service_id = outscale_internet_service.internet_service.id
}

resource "outscale_route_table" "route_table" {
  net_id = outscale_net.user_vpc.net_id
}

resource "outscale_route_table_link" "route_table_link" {
  subnet_id      = outscale_subnet.subnet_public.subnet_id
  route_table_id = outscale_route_table.route_table.id
}

resource "outscale_route" "route" {
  destination_ip_range = "0.0.0.0/0"
  gateway_id           = outscale_internet_service.internet_service.internet_service_id
  route_table_id       = outscale_route_table.route_table.route_table_id
}


resource "outscale_nat_service" "nat_service" {
  depends_on   = [outscale_route.route]
  subnet_id    = outscale_subnet.subnet_public.subnet_id
  public_ip_id = outscale_public_ip.nat_ip.public_ip_id
}

resource "outscale_route_table" "route_table_prive" {
  net_id = outscale_net.user_vpc.net_id
}


resource "outscale_route_table_link" "route_table_link_prive" {
  subnet_id      = outscale_subnet.subnet_prive.subnet_id
  route_table_id = outscale_route_table.route_table_prive.id
}

resource "outscale_route" "route_prive" {
  destination_ip_range = "0.0.0.0/0"
  nat_service_id       = outscale_nat_service.nat_service.nat_service_id
  route_table_id       = outscale_route_table.route_table_prive.route_table_id
}

output "nic_id" {
  value = outscale_nic.nic.nic_id
}

output "ssh_bastion" {
  value = "${outscale_public_ip.bastion_ip.public_ip}"
}
