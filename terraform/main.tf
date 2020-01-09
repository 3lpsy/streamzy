provider "aws" {
  version    = "~> 2.0"
  region     = var.aws_default_region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

provider "acme" {
  server_url = var.acme_server_url
}

### NETWORKING
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-ig"
  }
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, 0)

  tags = {
    Name = "${var.project_name}-subnet"
  }
}

resource "aws_network_acl" "main" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.main.id]

  tags = {
    Name = "${var.project_name}-acl"
  }
}

# ACLs are stateless, we'll rely on security groups
# could be more specific, but fine for now
resource "aws_network_acl_rule" "allow_all_in" {
  rule_number    = 100
  rule_action    = "allow"
  egress         = false
  from_port      = 0
  to_port        = 65535
  protocol       = -1
  cidr_block     = var.internet_cidr_block
  network_acl_id = aws_network_acl.main.id
}

resource "aws_network_acl_rule" "allow_all_out" {
  rule_number    = 100
  rule_action    = "allow"
  egress         = true
  from_port      = 0
  to_port        = 65535
  protocol       = -1
  cidr_block     = var.internet_cidr_block
  network_acl_id = aws_network_acl.main.id
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-rt"
  }
}

resource "aws_route" "egress" {
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}


### Security Groups 

resource "aws_security_group" "main" {
  name        = "${var.project_name}-sg"
  description = "A Generic Security Group for a ${var.project_name} server"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group_rule" "ssh_ingress" {
  security_group_id = aws_security_group.main.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = var.trusted_external_cidr_block
  from_port         = 22
  to_port           = 22
}

resource "aws_security_group_rule" "rtmp_ingress" {
  security_group_id = aws_security_group.main.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = var.trusted_external_cidr_block
  from_port         = 1935
  to_port           = 1935
}

resource "aws_security_group_rule" "icmp_ingress" {
  security_group_id = aws_security_group.main.id
  type              = "ingress"
  protocol          = "icmp"
  cidr_blocks       = var.trusted_external_cidr_block
  from_port         = 0
  to_port           = 8
}


resource "aws_security_group_rule" "client_ingress" {
  security_group_id = aws_security_group.main.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = [var.internet_cidr_block]
  from_port         = 80
  to_port           = 80
}


resource "aws_security_group_rule" "all_outbound_tcp" {
  security_group_id = aws_security_group.main.id
  type              = "egress"
  protocol          = "tcp"
  cidr_blocks       = [var.internet_cidr_block]
  from_port         = 0
  to_port           = 65535
}

resource "aws_security_group_rule" "all_outbound_udp" {
  security_group_id = aws_security_group.main.id
  type              = "egress"
  protocol          = "udp"
  cidr_blocks       = [var.internet_cidr_block]
  from_port         = 0
  to_port           = 65535
}

resource "aws_security_group_rule" "all_outbound_icmp" {
  security_group_id = aws_security_group.main.id
  type              = "egress"
  protocol          = "icmp"
  cidr_blocks       = [var.internet_cidr_block]
  from_port         = 0
  to_port           = 8
}



### SSH

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
}

resource "null_resource" "save_ssh_locally" {
  triggers = {
    public_key = tls_private_key.ssh.public_key_openssh
  }
  provisioner "local-exec" {
    command = "rm -rf ${path.root}/data/key.pem && echo '${tls_private_key.ssh.private_key_pem}' > ${path.root}/data/key.pem && chmod 600 ${path.root}/data/key.pem"
  }
}

resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.ssh.public_key_openssh
}

### Main Server ###

resource "aws_instance" "main" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.main.id]
  key_name               = aws_key_pair.main.key_name

  associate_public_ip_address = true

  tags = {
    Name = "${var.project_name}-server"
  }
}

data "aws_route53_zone" "main" {
  name = "${var.dns_root}."
}

resource "aws_route53_record" "arecord" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${var.dns_sub}.${var.dns_root}"
  type    = "A"
  ttl     = "5"
  records = [aws_instance.main.public_ip]
}


resource "null_resource" "install_packages" {
  triggers = {
    server_id = aws_instance.main.id
  }

  connection {
    host        = aws_instance.main.public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
    agent       = false # change to true if agent is required
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y php php-fpm",
      "sudo systemctl stop apache2 || echo 'Apache2 not installed'",
      "sudo systemctl disable apache2 || echo 'Apache2 not installed'",
      "sudo apt-get install -y nginx",
      "sudo apt-get install -y libnginx-mod-rtmp",
      "sudo systemctl stop nginx",
      "sudo apt-get install -y nodejs npm"
    ]
  }
}


resource "null_resource" "configure_nginx" {
  triggers = {
    server_id = aws_instance.main.id
  }

  connection {
    host        = aws_instance.main.public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
    agent       = false # change to true if agent is required
  }

  provisioner "file" {
    source      = "${path.root}/../nginx.conf.template"
    destination = "/tmp/nginx.conf.template"
  }

  provisioner "remote-exec" {
    inline = [
      "cat /tmp/nginx.conf.template | sed 's/SERVER_NAME/${var.dns_sub}.${var.dns_root}/g' | sudo tee /etc/nginx/nginx.conf"
    ]
  }
  depends_on = [null_resource.install_packages]

}

resource "null_resource" "configure_auth" {
  triggers = {
    server_id = aws_instance.main.id
  }

  connection {
    host        = aws_instance.main.public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
    agent       = false # change to true if agent is required
  }

  provisioner "file" {
    source      = "${path.root}/../auth"
    destination = "/tmp"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/auth /var/www/auth",
      "sudo php /var/www/auth/adduser.php '${var.streamer_username}' '${var.streamer_psk}'",
      "sudo chown -R www-data:www-data /var/www/auth"
    ]
  }
  depends_on = [null_resource.configure_nginx]

}

resource "null_resource" "configure_client" {
  triggers = {
    server_id = aws_instance.main.id
  }

  connection {
    host        = aws_instance.main.public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
    agent       = false # change to true if agent is required
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /opt/client",
      "sudo chown -R ubuntu:ubuntu /opt/client"
    ]
  }

  provisioner "file" {
    source      = "${path.root}/../client/src"
    destination = "/opt/client"
  }

  provisioner "file" {
    source      = "${path.root}/../client/public"
    destination = "/opt/client"
  }

  provisioner "file" {
    source      = "${path.root}/../client/package.json"
    destination = "/opt/client/package.json"
  }

  provisioner "file" {
    source      = "${path.root}/../client/babel.config.js"
    destination = "/opt/client/babel.config.js"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo npm install -g @vue/cli --silent",
      "cd /opt/client && npm install --silent",
      "cd /opt/client && npm run build",
      "sudo mkdir -p /var/www/client",
      "sudo rm -rf /var/www/client/public",
      "sudo cp -R /opt/client/dist /var/www/client/public",
      "sudo mkdir -p /var/www/client/streams",
      "sudo chown -R www-data:www-data /var/www/client"
    ]
  }
  depends_on = [null_resource.configure_auth]

}

resource "null_resource" "start" {
  triggers = {
    server_id = aws_instance.main.id
  }

  connection {
    host        = aws_instance.main.public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
    agent       = false # change to true if agent is required
  }


  provisioner "remote-exec" {
    inline = [
      "sudo systemctl enable nginx",
      "sudo systemctl restart nginx"
    ]
  }
  depends_on = [null_resource.configure_client]
}
