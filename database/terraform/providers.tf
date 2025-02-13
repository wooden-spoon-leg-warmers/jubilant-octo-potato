provider "postgresql" {
  host = var.db_host
  port = var.db_port
  username = var.db_user
  password = var.db_password
  sslmode = "disable"
}