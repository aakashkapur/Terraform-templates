terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 4.0"
    }
  }
}
provider "aws" {
    profile = "terraform-partners"  
    region = "us-west-2"
  }

module "project_vpc" {
    source = "../20221219"

}

data "aws_ami_ids" "ubuntu" {
    owners = ["amazon"]
    filter {
        name   = "name"
        values = ["ubuntu/images/ubuntu-*-*-x86_64-server-*"]
    }
}

data "aws_subnets" "project_public_subnet" {
    filter {
    name   = "vpc-id"
    values = ["${module.project_vpc.vpc_id}"]
  }
    filter {
      name = "tag:Public"
      values = ["true"]
    }
}
data "cloudinit_config" "server_config" {
    gzip          = true
    base64_encode = true
    part {
        content_type = "text/cloud-config"
        content = file("${path.module}/server.yaml")
    }
  
}
resource "random_id" index {
  byte_length = 2
}

locals {
    subnet_ids_string = join(",", data.aws_subnets.project_public_subnet.ids)
    subnet_ids_list = split(",", local.subnet_ids_string)
    subnet_ids_random_index = random_id.index.dec % length(data.aws_subnets.project_public_subnet.ids)
    depends_on = data.aws_subnets.project_public_subnet
    instance_subnet_id = local.subnet_ids_list[local.subnet_ids_random_index]
    path = "~/.ssh"
}

resource "aws_key_pair" "aakash_key" {
  key_name = "aakash_key"
  public_key = file("${local.path}/id_rsa.pub")        
}

resource "aws_security_group" "app-sg" {
    name = "Allow SSH and ICMP"
    vpc_id = "${module.project_vpc.vpc_id}"
    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
    ingress {
        description      = "SSH from VPC"
        from_port        = 22
        to_port          = 22
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }
    ingress {
        description      = "SSH from VPC"
        from_port        = 80
        to_port          = 80
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }
  
}

resource "aws_instance" "app-ec2" {
    ami = "ami-0ecc74eca1d66d8a6"
    instance_type = "t3.micro"
    key_name = "${aws_key_pair.aakash_key.key_name}"
    user_data = data.cloudinit_config.server_config.rendered
    subnet_id = local.instance_subnet_id
    security_groups = ["${aws_security_group.app-sg.id}"]
    lifecycle {
        ignore_changes = [subnet_id,security_groups]
    }
    tags = {
      "Name" = "app-ec2"
    }
    connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
    }
    provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait"
    ]
  }

}