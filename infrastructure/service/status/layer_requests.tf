# === status ===

# --- Lambda Layer, requests ---

resource "aws_lambda_layer_version" "requests" {
  filename            = "${var.stage_status_layer_requests}"
  layer_name          = "${var.stage_status_layer_requests_name}"
  compatible_runtimes = ["python3.8"]
  source_code_hash    = filebase64sha256("${var.stage_status_layer_requests}")
}
