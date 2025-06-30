resource "null_resource" "run_launcher" {
  provisioner "local-exec" {
    command = "set -a && source .env"
  }
  triggers = {
    always_run = timestamp()
  }
}

resource "null_resource" "docker_compose_down" {
  depends_on = [null_resource.run_launcher]
  provisioner "local-exec" {
    command = "docker compose down -v"
  }
  triggers = {
    always_run = timestamp()
  }
}

resource "null_resource" "docker_compose_build" {
  depends_on = [null_resource.docker_compose_down]
  provisioner "local-exec" {
    command = "docker compose build"
  }
  triggers = {
    always_run = timestamp()
  }
}

resource "null_resource" "docker_compose_up" {
  depends_on = [null_resource.docker_compose_build]
  provisioner "local-exec" {
    command = "docker compose up"
  }
  triggers = {
    always_run = timestamp()
  }
}


