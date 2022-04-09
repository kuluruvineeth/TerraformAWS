# EC2 Instance
resource "aws_instance" "myec2vm" {
  ami = data.aws_ami.amzlinux2.id
  instance_type = var.instance_type
  #instance_type = var.instance_type_list[1] # For List
  #instance_type = var.instance_type_map["prod"] # For Map
  user_data = file("${path.module}/app1-install.sh")
  key_name = var.instance_keypair
  vpc_security_group_ids = [aws_security_group.vpc-ssh.id,aws_security_group.vpc-web.id]
  # Create EC2 Instance in all Availability Zones of a VPC
  #for_each = toset(data.aws_availability_zones.my_azones.names)
  for_each = toset(keys({for az, details in data.aws_ec2_instance_type_offerings.my_ins_type:
   az => details.instance_types if length(details.instance_types) != 0 }))
  availability_zone = each.key
  tags = {
      "Name" = "for_each-Demo-${each.value}"
  }
}