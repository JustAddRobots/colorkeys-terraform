# === storage ===

resource "aws_s3_bucket" "this" {
  bucket        = "${var.codepipeline_artifact_bucket}"
  acl           = "private"
  tags          = var.default_tags
  force_destroy = true
}

resource "aws_s3_bucket" "tmp_colorkeys" {
  bucket        = "${var.codepipeline_tmp_bucket}"
  acl           = "private"
  tags          = var.default_tags
  force_destroy = true
}

resource "aws_s3_bucket" "stage_colorkeys_samples" {
  bucket        = "${var.codepipeline_samples_bucket}"
  acl           = "private"
  tags          = var.default_tags
  force_destroy = true
}

resource "aws_s3_bucket_object" "samples" {
  bucket  = "${aws_s3_bucket.stage_colorkeys_samples.id}"
  key     = "${var.codepipeline_samples_key}"
  acl     = "private"
  source  = "${var.codepipeline_samples_source}"
  etag    = filemd5("${var.codepipeline_samples_source}")
}
