terraform {
  required_version = "~> 1.0"
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.0"
    }
  }
}