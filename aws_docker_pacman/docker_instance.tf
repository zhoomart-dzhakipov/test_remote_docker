/* 
 Zhoomart
 August 2024
 Uploading pacman on docker AWS
*/


provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "pacman_on_docker" {
  # ami                    = "ami-0583d8c7a9c35822c"
  ami           = "ami-0b72821e2f351e396" #Amazon Linux 2023 AMI (64-bit (x86), uefi-preferred)
  instance_type = "t2.micro"              #i386, x86_64, CPU*1, RAM*1Gb
  #instance_type          = "t2.large" #x86_64, CPU*2, RAM*8
  vpc_security_group_ids = [aws_security_group.default_sec_group.id]
  key_name               = "test2"
  tags = {
    Name  = "pacman_on_docker"
    Owner = "Jomart"
  }
  user_data = <<EOF
#!/bin/bash
yum -y update
yum -y install docker 
curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
sudo usermod -aG docker ec2-user
echo 'services:
  nodejs-app:
    image: jessehoch/pacman-nodejs-app:latest
    ports:
      - "8081:8080"  # Map port 8080 of the container to port 8081 on the host
    environment:
      MONGO_SERVICE_HOST: mongo
      MONGO_AUTH_USER: pacman
      MONGO_AUTH_PWD: pacman
      MONGO_DATABASE: pacman
    restart: unless-stopped

  mongo:
   image: mongo:4.0.4
   ports:
     - "27017:27017" # Expose MongoDB on port 27017
   volumes:
     - mongo-db:/data/db
     - ./mongo-init-db/init_user_db.js:/docker-entrypoint-initdb.d/init_user_db.js:ro  # Mount the initialization script directory
   restart: unless-stopped
volumes:
  mongo-db:
    driver: local
  mongo-initdb:
    driver: local
    driver_opts:
      type: none
      device: $PWD/mongo-init-db # need folder mongo-init-db in the same folder as docker-compose.yml
      o: bind
networks:
  default:
    external:
      name: pacman-network
    restart: always                           # Перезапускает контейнер в случае сбоя' > /home/ec2-user/docker-pacman/docker-compose-pacman-mongo.yaml
chown -R ec2-user:ec2-user /home/ec2-user/docker-nginx
systemctl start docker.service
sudo -u ec2-user docker-compose -f /home/ec2-user/docker-nginx/docker-compose.yml up






EOF
}

resource "aws_security_group" "default_sec_group" {
  name        = "Sec_group_pacman"
  description = "Security group for docker pacman"

  # Creates ingress rules for TCP ports 22, 80, and 443.
  /* dynamic "ingress" {
    for_each = ["22", "80", "443"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Allow ICMP traffic (PING)
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
*/
  # Rule to allow all inbound traffic
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Rule to allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Security group for pacman"
  }
}

output "instance_public_ip" {
  value = aws_instance.pacman_on_docker.public_ip
}

