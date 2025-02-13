resource "postgresql_role" "api" {
  name     = "api"
  login    = true
  password = "password"
}

resource "postgresql_database" "api" {
  name  = "api"
  owner = "postgres"
  template = "template0"
}

resource "postgresql_schema" "api" {
  name     = "api"
  database = postgresql_database.api.name
  owner = "postgres"

  policy {
    create = true
    usage  = true
    role = postgresql_role.api.name
  }

  drop_cascade = true
}

resource "postgresql_grant" "grant_all_tables" {
  database = postgresql_database.api.name
  role     = postgresql_role.api.name
  schema = postgresql_schema.api.name

  privileges = [
    "ALL"
  ]

  object_type = "table"
}