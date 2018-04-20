Description
-----------
Terraform configuration files to create transit network VPC, shared services VPC and simulated OnPrem Network

terraform plan -var-file=/home/ubuntu/54.177.55.54.secret.tfvars

What is Shared Services VPC
---------------------------
This VPC is where we deployed aviatrix gateway and with direct connection via encrypteed tunnel to all spoke gateways.  It is meant to deploy all shared services (i.e. database, web, jenkins, puppet, chef, saltstack, etc.).

What is simulated OnPrem Network
--------------------------------
It is Aviatrix gateway connected to VGW using static IPSec tunnel. Aviatrix feature called "Site2Cloud" where user is able
to establish an IPSec tunnel to a third party device in this case AWS VGW.   

Pre-Requisites
--------------
    * AWS Account and credentials
    # Aviatrix Controller credentials

Default configuration
---------------------
    1 - Transit Gateway
    1 - Spoke Gateway
    1 - Shared Gateway
    1 - OnPrem Gateway

Notes:
1. To advertise the onprem network from site2cloud, user needs to manually add the onprem CIDR
   from AWS Console > VGW Connection > Static Routes tab.

2. Edit spoke_gateways =<N> under terraform.tfvar file in order to increase spoke gateways.

For more information you can visit this link: http://docs.aviatrix.com/HowTos/transitvpc_workflow.html


