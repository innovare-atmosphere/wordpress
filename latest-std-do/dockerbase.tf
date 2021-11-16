variable "database_password" {
    default = ""
}

variable "domain" {
    default = ""
    validation {
      # regex(...) fails if it cannot find a match
      condition     = can(regex("[0-9]*[a-z]+[a-z0-9]*", var.image_id))
      error_message = "The image_id value must be a valid AMI id, starting with \"ami-\"."
    }
}

variable "webmaster_email" {
    default = ""
}

resource "random_password" "database_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}


resource "digitalocean_droplet" "www-wordpress" {
  #This has pre installed docker
  image = "docker-20-04"
  name = "www-wordpress"
  region = "nyc3"
  size = "s-1vcpu-1gb"
  ssh_keys = [
    digitalocean_ssh_key.terraform.id
  ]

  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    private_key = var.pvt_key != "" ? file(var.pvt_key) : tls_private_key.pk.private_key_pem
    timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      # install nginx and docker
      "sleep 5s",
      "apt update",
      "sleep 5s",
      "apt install -y nginx",
      "apt install -y python3-certbot-nginx",
      # create wordpress installation directory
      "mkdir /root/wordpress",
      "mkdir /root/wordpress/themes",
      "mkdir /root/wordpress/plugins"
    ]
  }

  provisioner "file" {
    content      = templatefile("docker-compose.yml.tpl", {
      database_password = var.database_password != "" ? var.database_password : random_password.database_password.result
    })
    destination = "/root/wordpress/docker-compose.yml"
  }

  provisioner "file" {
    content      = templatefile("atmosphere-nginx.conf.tpl", {
      server_name = var.domain != "" ? var.domain : "0.0.0.0"
    })
    destination = "/etc/nginx/conf.d/atmosphere-nginx.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      # run compose
      "cd /root/wordpress",
      "docker-compose up -d",
      "rm /etc/nginx/sites-enabled/default",
      "systemctl restart nginx",
      "ufw allow http",
      "ufw allow https",
      "%{if var.domain!= ""}certbot --nginx --non-interactive --agree-tos --domains ${var.domain} --redirect %{if var.webmaster_email!= ""} --email ${var.webmaster_email} %{ else } --register-unsafely-without-email %{ endif } %{ else }echo NOCERTBOT%{ endif }"
    ]
  }
}