variables {
  image_name    = "pfsense-metrics"
  instance_type = "t3a.micro"
  region        = "eu-west-2"
}

packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  ami_name      = var.image_name
  instance_type = var.instance_type
  region        = var.region
  ssh_username  = "ubuntu"
  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      name                = "ubuntu/images/*ubuntu-noble-24.04-amd64-server-*"
      root-device-type    = "ebs"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  vpc_filter {
    filters = {
      "tag:PackerBuildVPC" : "true"
    }
  }
  subnet_filter {
    filters = {
      "tag:PackerBuildSubnet" : "true"
    }
    most_free = true
  }
  associate_public_ip_address               = true
  temporary_security_group_source_public_ip = true
  tags = {
    Name = var.image_name
  }


}

build {
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "file" {
    destination = "/tmp/config/"
    source      = "config"
  }

  provisioner "shell" {
    execute_command = "echo 'packer' | {{ .Vars }} bash '{{ .Path }}'"
    script          = "scripts/provisioners/copy-config.sh"
  }

  provisioner "shell" {
    execute_command = "echo 'packer' | {{ .Vars }} bash '{{ .Path }}'"
    script          = "scripts/provisioners/snmp-exporter.sh"
  }

  provisioner "shell" {
    execute_command = "echo 'packer' | {{ .Vars }} bash '{{ .Path }}'"
    script          = "scripts/provisioners/grafana-alloy.sh"
  }

  provisioner "shell" {
    execute_command = "echo 'packer' | {{ .Vars }} bash '{{ .Path }}'"
    script          = "scripts/provisioners/syslog-proxy.sh"
  }

  provisioner "shell" {
    execute_command = "echo 'packer' | {{ .Vars }} bash '{{ .Path }}'"
    script          = "scripts/provisioners/cleanup.sh"
  }
}