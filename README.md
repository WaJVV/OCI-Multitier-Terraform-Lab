# 3-Tier Cloud Architecture on OCI

![Architecture Diagram](./img/LabArchitecture.drawio.jpg)

[![Repository](https://img.shields.io/badge/GitHub-Repository-181717?logo=github)](https://github.com/WaJVV/OCI-Multitier-Terraform-Lab.git)
[![Terraform](https://img.shields.io/badge/Terraform-1.0+-623CE4?logo=terraform)](https://www.terraform.io/)
[![OCI](https://img.shields.io/badge/Cloud-Oracle%20Cloud-FF0000?logo=oracle)](https://www.oracle.com/cloud/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

##  Professional Overview
This repository showcases a **Production-Ready** multi-tier infrastructure deployment on Oracle Cloud Infrastructure (OCI). By leveraging **Infrastructure as Code (IaC)** with Terraform, this project implements a robust "Defense in Depth" strategy, isolating critical data while maintaining operational agility through automated provisioning.

##  Architectural Design & Traffic Flow
The environment is architected into three distinct logical segments to minimize the attack surface:

1.  **Presentation Layer (Public Subnet - DMZ):**
    * **Resource:** Web Server acting as both a Front-end and a secure **Bastion Host**.
    * **Connectivity:** Attached to an **Internet Gateway (IGW)** for public reachability (HTTP/S) and administrative SSH access.
2.  **Logic Layer (Private Subnet):**
    * **Resource:** Application Server (Back-end).
    * **Security:** Completely isolated from the public internet. It utilizes a **NAT Gateway** for secure, outbound-only traffic (system updates and library patches), preventing unsolicited inbound connections.
3.  **Data Layer (Private Subnet):**
    * **Resource:** Database System.
    * **Strict Isolation:** Zero internet access. Inbound traffic is restricted exclusively to the Application Layer via stateful Security Lists, ensuring the data sanctuary remains untouched.

## Advanced Security & Engineering Standards
* **Principle of Least Privilege (PoLP):** Security Lists are granularly configured to allow only specific ports (e.g., TCP 3000 for App, 3306 for DB) from verified source CIDRs.
* **Bastion Hopping Strategy:** Implements secure administrative access to private instances using the Web Server as a controlled, audited entry point.
* **Network Segmentation:** Logical separation using a VCN with a `172.16.0.0/20` block, optimized for high availability and future scaling across Availability Domains.
* **Automated State Management:** Clean Terraform logic with variable-driven configurations for rapid environment replication and disaster recovery.

##  Tech Stack
* **Provider:** Oracle Cloud Infrastructure (OCI)
* **IaC Tool:** Terraform
* **Networking:** VCN, Internet Gateway, NAT Gateway, Route Tables, Security Lists.
* **Compute:** Flexible Shapes (VM.Standard.E3.Flex/A1.Flex) and Micro Instances.

##  Deployment Guide
1.  **Clone the Repository:**
    ```bash
    git clone [https://github.com/WaJVV/OCI-Multitier-Terraform-Lab.git](https://github.com/WaJVV/OCI-Multitier-Terraform-Lab.git)
    cd OCI-Multitier-Terraform-Lab
    ```
2.  **Configuration:** Create a `terraform.tfvars` file and populate it with your OCI credentials:
    * `tenancy_ocid`, `user_ocid`, `fingerprint`, `private_key_path`, and `region`.
3.  **Execution:**
    ```bash
    terraform init
    terraform plan
    terraform apply
    ```

##  Important Compatibility Note
> **Note on Micro Instances:** Per OCI constraints, `ocid_image` compatibility must be strictly verified when using `VM.Standard.E2.1.Micro` shapes. Specific logic has been implemented to handle shape-specific configurations and ensure architectural performance.

---
*Developed by [WaJVV](https://github.com/WaJVV) as part of a Cloud Engineering Portfolio.*
