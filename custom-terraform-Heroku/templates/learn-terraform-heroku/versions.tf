# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_providers {
    heroku = {
      source  = "heroku/heroku"
      version = "~> 4.6.0"
    }
  }

  required_version = ">= 0.14"
}