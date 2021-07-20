resource "aws_s3_bucket" "onebucket" {
  bucket = "test-prueba-derito"
  acl    = "private"
  versioning {
    enabled = true
  }
  tags = {
    Name        = "Flugel-test"
    Environment = "Dev"
  }
}

data "local_exe" "time" {
    program=["bash","date"]	
}

resource "local_file" "test1" {
  content  = data.local_exe.time
  filename = "${path.module}/test1.txt"
}

resource "local_file" "test2" {
  content  = data.local_exe.time
  filename = "${path.module}/test2.txt"
}

