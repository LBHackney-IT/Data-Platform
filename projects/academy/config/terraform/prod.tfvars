# AppStream Infrastructure
# AppStream Infrastructure - 10-network
appstream_azs = ["eu-west-1a", "eu-west-1b"]

appstream_cidr = "10.132.0.0/16"

appstream_enable_nat_gateway = true

appstream_private_subnets = ["10.132.0.0/24", "10.132.1.0/24"]

appstream_public_subnets = ["10.132.2.0/24", "10.132.3.0/24"]

appstream_security_group_ingress = [{}]

appstream_security_group_egress = [
  {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "Allow egress anywhere."
  }
]

# Core Infrastructure
# Core Infrastructure - 10-network
core_azs = ["eu-west-2a", "eu-west-2b"]

core_cidr = "10.120.23.0/24"

core_enable_nat_gateway = true

core_private_subnets = ["10.120.23.0/26", "10.120.23.64/26"]

core_public_subnets = ["10.120.23.128/26", "10.120.23.192/26"]

core_security_group_ingress = [
  {
    from_port   = 21064
    to_port     = 21064
    protocol    = "TCP"
    cidr_blocks = "10.132.0.0/24,10.132.1.0/24"
    description = "Allow Ingres from private subnets in the AppStream VPC."
  }
]

core_security_group_egress = [
  {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "Allow egress anywhere."
  }
]

# Core Infrastructure - 20-academy
academy_user_data = <<-EOF
    #! /bin/bash
    sudo cp -a /home/ec2-user/. /tmp/ec2-user/

    # Partition
    sudo /sbin/parted /dev/xvdb mklabel gpt
    sudo /sbin/parted /dev/xvdb mkpart build ext4 1MB 10241MB
    sudo /sbin/parted /dev/xvdb mkpart apps ext4 10241MB 71681MB
    sudo /sbin/parted /dev/xvdb mkpart ckp ext4 71681MB 378881MB
    sudo /sbin/parted /dev/xvdb mkpart data ext4 378881MB 1402881MB
    sudo /sbin/parted /dev/xvdb mkpart jnl ext4 1402881MB 1423361MB
    sudo /sbin/parted /dev/xvdb mkpart work ext4 1423361MB 1464321MB
    sudo /sbin/parted /dev/xvdb mkpart home ext4 1464321MB 1617921MB
    sudo /sbin/parted /dev/xvdb mkpart spare ext4 1617921MB 2539521MB

    # Format
    sudo mkfs -t ext4 /dev/xvdb1
    sudo mkfs -t ext4 /dev/xvdb2
    sudo mkfs -t ext4 /dev/xvdb3
    sudo mkfs -t ext4 /dev/xvdb4
    sudo mkfs -t ext4 /dev/xvdb5
    sudo mkfs -t ext4 /dev/xvdb6
    sudo mkfs -t ext4 /dev/xvdb7
    sudo mkfs -t ext4 /dev/xvdb8

    # Directories
    sudo mkdir -p /build
    sudo mkdir -p /apps
    sudo mkdir -p /ckp
    sudo mkdir -p /data
    sudo mkdir -p /jnl
    sudo mkdir -p /work
    sudo mkdir -p /spare

    # Mount
    sudo mount -t auto /dev/xvdb1 /build
    sudo mount -t auto /dev/xvdb2 /apps
    sudo mount -t auto /dev/xvdb3 /ckp
    sudo mount -t auto /dev/xvdb4 /data
    sudo mount -t auto /dev/xvdb5 /jnl
    sudo mount -t auto /dev/xvdb6 /work
    sudo mount -t auto /dev/xvdb7 /home
    sudo mount -t auto /dev/xvdb8 /spare

    sudo cp -a /tmp/ec2-user/. /home/ec2-user/

    restorecon -Rv /home
	EOF

# General
application = "academy"

department = "revenues_and_benefits"

environment = "prod"

key_name = "academy-prod"

whitelist = ["82.37.184.229/32", "86.139.244.37/32", "85.115.52.0/24", "85.115.53.0/24", "85.115.54.0/24", "194.70.246.0/24", "51.140.133.223/32", "51.140.229.240/32"]
