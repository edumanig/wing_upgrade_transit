# Upgrade Aviatrix controller 
#
resource "aviatrix_upgrade" "upgrade32" {
    version = "${var.custom_version}"
}

