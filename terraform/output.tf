output "streamzy_server_public_ip" {
  value = aws_instance.main.public_ip
}

output "streamzy_server_http_url" {
  value = "http://${var.dns_sub}.${var.dns_root}"
}

output "streamzy_rtmp_url" {
  value = "rtmp://${var.dns_sub}.${var.dns_root}/live?username=${var.streamer_username}&psk=${var.streamer_psk}"
}

output "streamzy_ssh_command" {
  value = "ssh -i data/key.pem ubuntu@${aws_instance.main.public_ip}"
}

