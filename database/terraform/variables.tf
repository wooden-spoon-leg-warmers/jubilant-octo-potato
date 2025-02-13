variable "db_host" {
  description = "The hostname of the database"  
  default = "localhost"
}

variable "db_port" {
  description = "The port of the database"
  default = 5432
}

variable "db_user" {
  description = "The user to connect to the database"
  default = "postgres"
}

variable "db_password" {
  description = "The password to connect to the database"
}