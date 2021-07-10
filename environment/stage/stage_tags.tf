# --- stage_tags ---

variable "default_tags" {
  type    = map(string)
  default = {
    project     = "colorkeys"
    environment = "stage"
    terraform   = "true"
    serverless  = "true"
  }
}
