application = "delta"
env = "uat"
vpc_cidr = "192.168.0.0/16"
private_subnet = ["192.168.1.0/24", "192.168.2.0/24"]
public_subnet = ["192.168.3.0/24"]
tags = {
    env = "test"
    owner = "ganesh"
}
