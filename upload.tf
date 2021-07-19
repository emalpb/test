resource "aws_s3_bucket_object" "object" {
  for_each = fileset("${path.module}", "*.txt")

  bucket = "test-prueba-derito"
  key    = each.value
  source = "${path.module}/${each.value}"
  etag   = filemd5("${each.value}")
}
