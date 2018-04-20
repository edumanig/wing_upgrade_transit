# Create temp cloud account in Aviatrix controller with IAM roles
#
resource "aviatrix_account" "temp_account" {
  account_name = "${var.account_name}"
  account_password = "${var.account_password}"
  account_email = "${var.account_email}"
  cloud_type = "${var.cloud_type}"
  aws_account_number = "${var.aws_account_number}"
  aws_access_key = "${var.aws_access_key}"
  aws_secret_key = "${var.aws_secret_key}"

  provisioner "local-exec" {
       command = "sleep 1m"
  }
}

