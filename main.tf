terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

provider "aws" {
  profile                 = "default"
  region                  = "us-east-2"
  shared_credentials_file = "/root/.aws/credentials"
}


resource "aws_instance" "web" {
  ami           = "ami-08962a4068733a2b6"
  instance_type = "t2.micro"
  #security_groups = [ aws_security_group.ec2.name ]
  vpc_security_group_ids = ["${aws_security_group.ec2.id}"]
  key_name               = "epam"
  subnet_id              = aws_subnet.web_subnet1.id

  tags = {
    Name = "web"
    key  = "PROD"
    value = "env"
    }


  connection {
    host        = self.public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("./epam")
  }
}

# bastion server

resource "aws_instance" "bastion" {
  ami = "ami-08962a4068733a2b6"
  # The public SG is added for SSH and ICMP
  vpc_security_group_ids = ["${aws_security_group.ec2.id}", "${aws_security_group.allout.id}"]
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet1.id
  # my private key for testing
  key_name = "epam"
  #get public ip
  associate_public_ip_address = true

  tags = {
    Name = "bastionhost"
    }
}

output "bastion" {
  value = aws_instance.bastion.public_ip
}

data "template_file" "config" {
  template = "${file("./config.tpl")}"

  vars = {
    bastion_ip = aws_instance.bastion.public_ip
    web_ip = aws_instance.web.private_ip

    }
}

#resource "local_file" "update_ssh_config" {
  #content  = "${data.template_file.config.rendered}"
  #filename = "/root/.ssh/config"
#}

### The Ansible inventory file
resource "local_file" "AnsibleInventory" {
 content = templatefile("inventory.tmpl",
 {
  private-dns = aws_instance.web.*.private_dns,
  private-ip = aws_instance.web.*.private_ip,
  private-id = aws_instance.web.*.id
 }
 )
 filename = "./ansible/inventory"
}

resource "null_resource" "ansible_automation" {
  #triggers = {
    #build_number = "${timestamp()}"
    #}

  provisioner "local-exec" {
    command = "ansible-playbook -i ./ansible/inventory play.yml"
  }
}


