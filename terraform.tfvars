aws_account_id = "430861662740"
aws_ami        = "ami-00305d2fa3c93abfc"
region         = "ap-south-1"
env            = "poc"

availability_zone1a = "ap-south-1a"
availability_zone1b = "ap-south-1b"

vpc_cidr = "10.15.0.0/16"
vpc_name = "vpc-poc"

web_sub_cidr = "10.15.2.0/23"
web_sub_name = "web-subnet"

app_sub_cidr_1a = "10.15.4.0/23"
app_sub_cidr_1b = "10.15.6.0/23"

app_sub_name_1a = "app-subnet-1a"
app_sub_name_1b = "app-subnet-1b"

db_sub_cidr = "10.15.8.0/23"
db_sub_name = "db-subnet" # corrected here

pub_route_name = "pub_route"
pri_route_name = "pri_route"

my_igw_name    = "poc_igw"
vpc_route_cidr = "0.0.0.0/0"

nodename = "myeks"

eks_cluster_name   = "my-eks-cluster"
eks_nodegroup_name = "my-nodegroup"

# key_administrators = [
#   "arn:aws:iam::430861662740:role/my-eks-role"
# ]

# key_users = [
#   "arn:aws:iam::430861662740:user/admin"
# ]

admin_cidr = "45.119.28.236/32" # corrected CIDR mask