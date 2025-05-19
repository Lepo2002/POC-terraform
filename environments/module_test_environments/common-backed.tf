terraform {
  backend "gcs" {
    bucket  = "terraform-state-saas-app"
    prefix  = "terraform/state/module-tests"
  }
}