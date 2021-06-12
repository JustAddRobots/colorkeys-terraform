### VPC ###

resource "aws_vpc" "stage_colorkeys" {
  cidr_block  = "10.0.0.0/16"
  enable_dns_support    = true
  enable_dns_hostnames  = true
  tags        = var.default_tags
}

resource "aws_subnet" "stage_colorkeys_public_0" {
  vpc_id                  = "${aws_vpc.stage_colorkeys.id}"
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-1a"
  map_public_ip_on_launch = true
  tags                    = "${merge(var.default_tags, tomap({"type"="public"}))}"
}

resource "aws_subnet" "stage_colorkeys_public_1" {
  vpc_id                  = "${aws_vpc.stage_colorkeys.id}"
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-1c"
  map_public_ip_on_launch = true
  tags                    = "${merge(var.default_tags, tomap({"type"="public"}))}"
}

resource "aws_internet_gateway" "stage_colorkeys_igw" {
  vpc_id  = "${aws_vpc.stage_colorkeys.id}"
  tags    = var.default_tags
}

resource "aws_route_table" "stage_colorkeys_public" {
  vpc_id  = "${aws_vpc.stage_colorkeys.id}"
  tags    = var.default_tags
}

resource "aws_route" "stage_colorkeys_public_igw" {
  route_table_id          = "${aws_route_table.stage_colorkeys_public.id}"
  destination_cidr_block  = "0.0.0.0/0"
  gateway_id              = "${aws_internet_gateway.stage_colorkeys_igw.id}"
}

resource "aws_route_table_association" "stage_colorkeys_public_0" {
  subnet_id       = aws_subnet.stage_colorkeys_public_0.id
  route_table_id  = aws_route_table.stage_colorkeys_public.id
}

resource "aws_route_table_association" "stage_colorkeys_public_1" {
  subnet_id       = aws_subnet.stage_colorkeys_public_1.id
  route_table_id  = aws_route_table.stage_colorkeys_public.id
}

resource "aws_security_group" "stage_colorkeys_http" {
  name        = "stage-colorkeys-http"
  vpc_id      = "${aws_vpc.stage_colorkeys.id}"
  tags        = var.default_tags

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "stage_colorkeys_https" {
  name        = "stage-colorkeys-https"
  vpc_id      = "${aws_vpc.stage_colorkeys.id}"
  tags        = var.default_tags

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "stage_colorkeys_egress" {
  name        = "stage-colorkeys-egress"
  description = "Allow all outbound traffic"
  vpc_id      = "${aws_vpc.stage_colorkeys.id}"
  tags        = var.default_tags

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = "${aws_vpc.stage_colorkeys.id}"
  service_name      = "com.amazonaws.us-west-1.s3"
  vpc_endpoint_type = "Gateway"
  tags              = var.default_tags
}

resource "aws_vpc_endpoint_route_table_association" "stage_colorkeys_s3" {
  route_table_id  = "${aws_route_table.stage_colorkeys_public.id}"
  vpc_endpoint_id = "${aws_vpc_endpoint.s3.id}"
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = "${aws_vpc.stage_colorkeys.id}"
  service_name      = "com.amazonaws.us-west-1.dynamodb"
  vpc_endpoint_type = "Gateway"
  tags              = var.default_tags
}

resource "aws_vpc_endpoint_route_table_association" "stage_colorkeys_dynamodb" {
  route_table_id  = "${aws_route_table.stage_colorkeys_public.id}"
  vpc_endpoint_id = "${aws_vpc_endpoint.dynamodb.id}"
}
