#variable.tf
variable "compartment_id" {
  description = "OCID from the compartment where you'll create the resources"
  type        = string
}
variable "region" {
  description = "OCI Region"
}
variable "ssh_public_key" {
  description = "public key to access the instances"
}
variable "instance_shape" {
  description = "Free Tier instance"
  type        = string
}
variable "availability_domain" {
  description = "Availability Domain to deploy resources"
  type        = string
}
variable "ocid_image" {
  description = "Image for the instance"
  type        = string
}