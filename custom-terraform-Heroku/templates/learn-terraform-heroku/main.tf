# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "heroku" {}

resource "heroku_app" "{{ .default_heroku_app_name }}" {
  name   = "learn-terraform-heroku"
  region = "us"
}

resource "heroku_addon" "postgres" {
  app  = heroku_app.example.id
  plan = "heroku-postgresql:hobby-dev"
}

resource "heroku_build" "{{ .default_heroku_build_domain }}" {
  app = heroku_app.example.id

  source {
    path = "./app"
  }
}

variable "app_quantity" {
  default     = 1
  description = "Number of dynos in your Heroku formation"
}

# Launch the app's web process by scaling-up
resource "heroku_formation" "example" {
  app        = heroku_app.example.id
  type       = "web"
  quantity   = var.app_quantity
  size       = "Standard-1x"
  depends_on = [heroku_build.example]
}