output "public-subnet-ids" {
  value = aws_subnet.public[*].id
}

output "private-subnet-ids" {
  value = aws_subnet.private[*].id
}

output "vpc-id" {
  value = aws_vpc.this.id
}

# output "public-subnet-id" {
#   value = [
#     for subnet in aws_subnet.public : subnet[0].id
#   ]
# }
