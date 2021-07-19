resource "aws_s3_bucket" "onebucket" {
   bucket = "test-prueba-derito"
   acl = "private"
   versioning {
      enabled = true
   }
   tags = {
     Name = "Flugel-test"
     Environment = "Dev"
   }
}

resource "local_file" "test1" {
    content     = "foo!"
    filename = "${path.module}/test1.txt"
}

resource "local_file" "test2" {
    content     = "foo!"
    filename = "${path.module}/test2.txt"
}

