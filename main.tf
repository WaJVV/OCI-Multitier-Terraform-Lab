terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }

  }

}

provider "oci" {
  region              = "mx-queretaro-1"
  auth                = "SecurityToken"
  config_file_profile = "learn-terraform"
}


#NETWORK
resource "oci_core_vcn" "vcn_hub" {
  dns_label      = "portfolio"
  cidr_block     = "172.16.0.0/20"
  compartment_id = var.compartment_id
  display_name   = "portfolio-prod-vcn-main"
}
#GATEWAY
resource "oci_core_internet_gateway" "igw_first_portfolio" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn_hub.id
  display_name   = "portfolio-prod-igw-edge"
  enabled        = true
}
#PUBLIC ROUTE TABLE
resource "oci_core_route_table" "rt_public" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn_hub.id
  display_name   = "portfolio-prod-rt-public"
  route_rules {
    network_entity_id = oci_core_internet_gateway.igw_first_portfolio.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

#NAT GATEWAY
resource "oci_core_nat_gateway" "nat_gtw" {
  compartment_id = var.compartment_id
  vcn_id = oci_core_vcn.vcn_hub.id
  display_name = "portfolio-prod-nat-gateway"
}

#PRIVATE ROUTE TABLE
resource "oci_core_route_table" "rt_private" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn_hub.id
  display_name   = "portfolio-prod-rt-private"
  route_rules {
    destination = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nat_gtw.id
    
  }
}
#SECURITY LIST WEB
resource "oci_core_security_list" "sl_web" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn_hub.id
  display_name   = "portfolio-prod-sl-web"
  #ALLOW SSH PORT 22 FROM EVERYWHERE
  ingress_security_rules {
    protocol = "6" #TCP = 6  UDP = 17 ICMP(ping) = 1
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }
  #ALLOW HTTP PORT 80 
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      max = 80
      min = 80
    }
  }
  #ALLOW OUTBONDS
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    description = "Let us update the system"
  }
}

#SECURITY LIST APP
resource "oci_core_security_list" "sl_app" {
  compartment_id = var.compartment_id
  vcn_id = oci_core_vcn.vcn_hub.id
  display_name = "portfolio-prod-sl-app"

  ingress_security_rules {
    protocol = "6"
    source = "172.16.1.0/24" #CIDR from sb_web_tier
    description = "Allow traffic from Web"
    tcp_options {
      min = 3000 #Port where the app will run
      max = 3000
    }
  }

  ingress_security_rules {
    protocol = "6"
    source = "172.16.1.0/24"
    description = "Allow SSH from Web Server (Bastion host)"
    tcp_options {
      min = 22
      max = 22
    }
  }

  egress_security_rules {
    protocol = "all"
    destination = "0.0.0.0/0"
  }
  
}
#SECURITY LIST DATABASE
resource "oci_core_security_list" "sl_db" {
  compartment_id = var.compartment_id
  vcn_id = oci_core_vcn.vcn_hub.id
  display_name = "portfolio-prod-sl-db"
  ingress_security_rules {
    protocol = "6"
    source = "172.16.2.0/24"
    description = "Allow DB connection from App"

    tcp_options {
      min = 3306
      max = 3306
    }
  }

  ingress_security_rules {
    protocol = "6"
    source = "172.16.2.0/24"
    description = "Allow SSH from App"
    tcp_options {
      min = 22
      max = 22
    }
  }
  egress_security_rules {
    protocol = "all"
    destination = "0.0.0.0/0"
  }
  
}
#PUBLIC SUBNET WEB
resource "oci_core_subnet" "sb_web_tier" {
  cidr_block                 = "172.16.1.0/24"
  display_name               = "portfolio-prod-sub-web"
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.vcn_hub.id
  route_table_id             = oci_core_route_table.rt_public.id
  dns_label                  = "web"
  security_list_ids          = [oci_core_security_list.sl_web.id]
  prohibit_public_ip_on_vnic = false
}
#PRIVATE SUBNET BACK-END
resource "oci_core_subnet" "sb_app_tier" {
  cidr_block                 = "172.16.2.0/24"
  display_name               = "portfolio-prod-sub-app"
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.vcn_hub.id
  route_table_id             = oci_core_route_table.rt_private.id
  dns_label                  = "app"
  security_list_ids = [oci_core_security_list.sl_app.id]
  prohibit_public_ip_on_vnic = true #!!Security!!

}
#PRIVATE SUBNET DATABASE
resource "oci_core_subnet" "sb_db_tier" {
  cidr_block                 = "172.16.3.0/24"
  display_name               = "portfolio-prod-sub-data"
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.vcn_hub.id
  route_table_id             = oci_core_route_table.rt_private.id
  dns_label                  = "data"
  security_list_ids = [oci_core_security_list.sl_db.id]
  prohibit_public_ip_on_vnic = true #!!Security!!
}


# WEB INSTANCE
resource "oci_core_instance" "inst_web_server" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  display_name        = "portfolio-vm-web-01"
  shape               = var.instance_shape
  shape_config {
    ocpus         = 1
    memory_in_gbs = 1
  }
  create_vnic_details {
    subnet_id              = oci_core_subnet.sb_web_tier.id
    assign_public_ip       = true
    display_name           = "vnic-web"
    skip_source_dest_check = false
  }
  source_details {
    source_type             = "image"
    source_id               = var.ocid_image
  }
  metadata = {
    ssh_authorized_keys = trimspace(var.ssh_public_key)
  }
}

 #BACK-END INSTANCE
 resource "oci_core_instance" "inst_app_server" {
  availability_domain = var.availability_domain
  compartment_id = var.compartment_id
  display_name = "portfolio-vm-app-01"
  shape = var.instance_shape
  shape_config {
    ocpus = 1
    memory_in_gbs = 3
  }
  create_vnic_details {
    subnet_id = oci_core_subnet.sb_app_tier.id
    assign_public_ip = false
    display_name = "vnic-app"
  }
  source_details {
    source_type = "image"
    source_id = var.ocid_image
  }
  metadata = {
    ssh_authorized_keys = trimspace(var.ssh_public_key)
  }
}

#DB INSTANCE
 resource "oci_core_instance" "inst_db_server" {
  availability_domain = var.availability_domain
  compartment_id = var.compartment_id
  display_name = "portfolio-vm-db-01"
  shape = var.instance_shape
  shape_config {
    ocpus = 1
    memory_in_gbs = 3
  }
  create_vnic_details {
    subnet_id = oci_core_subnet.sb_db_tier.id
    assign_public_ip = false
    display_name = "vnic-db"
  }
  source_details {
    source_type = "image"
    source_id = var.ocid_image
  }
  metadata = {
    ssh_authorized_keys = trimspace(var.ssh_public_key)
  }
}
