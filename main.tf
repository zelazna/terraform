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

resource "outscale_subnet" "subnet_1" {
  subregion_name = "${var.region}a"
  ip_range       = "10.0.0.0/16"
  net_id         = outscale_net.user_vpc.net_id
}

resource "outscale_nic" "nic" {
  subnet_id = outscale_subnet.subnet_1.subnet_id
}

resource "outscale_public_ip" "nat_ip" {
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
  subnet_id      = outscale_subnet.subnet_1.subnet_id
  route_table_id = outscale_route_table.route_table.id
}

resource "outscale_route" "route" {
  destination_ip_range = "0.0.0.0/0"
  gateway_id           = outscale_internet_service.internet_service.internet_service_id
  route_table_id       = outscale_route_table.route_table.route_table_id
}

resource "outscale_nat_service" "nat_service" {
  depends_on   = [outscale_route.route]
  subnet_id    = outscale_subnet.subnet_1.subnet_id
  public_ip_id = outscale_public_ip.nat_ip.public_ip_id
}

output "nic_id" {
  value = outscale_nic.nic.nic_id
}
