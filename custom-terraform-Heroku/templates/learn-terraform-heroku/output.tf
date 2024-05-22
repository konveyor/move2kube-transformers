# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "app_url" {
  value       = heroku_app.example.web_url
  description = "Application URL"
}
