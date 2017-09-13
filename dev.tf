provider "openstack" {
  user_name   = "automation"
  tenant_name = "automation"
  password    = "${var.ospassword}"
  auth_url    = "https://cloud.thoughtwave.net:5000/v2.0"
  region      = "RegionOne"
}

provider "cloudflare" {
  email = "${var.cloudflare_email}"
  token = "${var.cloudflare_token}"
}

resource "openstack_compute_keypair_v2" "jonny" {
  name       = "jonny"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1YTga0O/sPZNPPm76R1uSGsXG8HdzSOhaTW8R0sUjmQncTOICkBT1j2nOTzJQHprQB87cdO58fiV3Gox0D5WQH3QIa46AiKY8yiz6exedNVfQWSd1leob8pM8rXWrEz6jLGgMxL8r5l+ipmAW0Db/AqNyT4pWAHt9GLzw9ack6aSxQxXRY/qQQyezrVrLAh5tKxjcCquhWQgTNM1l+T2GVohgJzUBycdAuki/tHPjQKG+Ru9+UlogG+spBBKf6eJnXTz+X2j3alI1DayFiBEtsCasA0+8rp7a5OLeQ/3kooiLW8Rf+e9bB/NUnH03J6BuvPCAxPH316z2IKt4ufvz jonny"
}

resource "openstack_networking_secgroup_v2" "admins_sg" {
  name        = "admins_sg"
  description = "Admin access levels"
}

resource "openstack_networking_secgroup_rule_v2" "admins_sg_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.admins_sg.id}"
}

resource "openstack_networking_secgroup_rule_v2" "admins_sg_rule_5" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.admins_sg.id}"
}

resource "openstack_networking_secgroup_rule_v2" "admins_sg_rule_6" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.admins_sg.id}"
}

resource "openstack_networking_floatingip_v2" "dev_ip" {
  pool = "admin_floating_net"
}

resource "cloudflare_record" "dev" {
  domain = "${var.cloudflare_domain}"
  name   = "dev"
  value  = "${openstack_networking_floatingip_v2.dev_ip.address}"
  type   = "A"
  ttl    = 3600
}

resource "openstack_compute_instance_v2" "dev" {
  name = "dev"
  image_id   = "9f9d86b7-85f6-48a6-af04-b096dfecee11"
  flavor_name   = "c1.large"
  key_pair        = "jonny"
  security_groups = ["default","admins_sg"]
  user_data = "${file("user_data_dev")}"
}


resource "openstack_compute_floatingip_associate_v2" "dev_ip" {
  floating_ip = "${openstack_networking_floatingip_v2.dev_ip.address}"
  instance_id = "${openstack_compute_instance_v2.dev.id}"
}
