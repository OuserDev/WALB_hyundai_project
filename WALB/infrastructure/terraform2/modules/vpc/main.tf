# infrastructure/terraform/modules/vpc/main.tf
# VPC 네트워크 구성을 위한 Terraform 모듈

# 데이터 소스: 가용 영역 정보 가져오기
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC 생성
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-vpc"
    Type = "Main VPC"
  })
  lifecycle {
    ignore_changes = [tags_all]
  }
}

# 인터넷 게이트웨이 생성
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-igw"
  })
  lifecycle {
    ignore_changes = [tags_all]
  }
}

# 퍼블릭 서브넷 생성 (Multi-AZ)
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
    Type = "Public"
    Tier = "Web"
  })
  lifecycle {
    ignore_changes = [tags_all]
  }
}

# 프라이빗 서브넷 생성 (Multi-AZ)
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
    Type = "Private"
    Tier = "Application"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${var.project_name}-eks" = "shared"
  })
  lifecycle {
    ignore_changes = [tags_all]
  }
}

# 데이터베이스 서브넷 생성 (Multi-AZ)
resource "aws_subnet" "database" {
  count             = length(var.database_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-db-subnet-${count.index + 1}"
    Type = "Database"
    Tier = "Data"
  })
  lifecycle {
    ignore_changes = [tags_all]
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  depends_on = [aws_internet_gateway.main]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-nat-eip-${count.index + 1}"
  })
}

# NAT Gateway 생성 (각 AZ마다)
resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  depends_on = [aws_internet_gateway.main]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-nat-gw-${count.index + 1}"
  })
}

# 퍼블릭 라우팅 테이블
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-public-rt"
    Type = "Public"
  })
  lifecycle {
    ignore_changes = [tags_all]
  }
}

# 프라이빗 라우팅 테이블 (각 AZ마다)
resource "aws_route_table" "private" {
  count = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-private-rt-${count.index + 1}"
    Type = "Private"
  })
  lifecycle {
    ignore_changes = [tags_all]
  }
}

# 데이터베이스 라우팅 테이블
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-db-rt"
    Type = "Database"
  })
  lifecycle {
    ignore_changes = [tags_all]
  }
}

# 퍼블릭 서브넷과 라우팅 테이블 연결
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# 프라이빗 서브넷과 라우팅 테이블 연결
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.enable_nat_gateway ? aws_route_table.private[count.index].id : aws_route_table.private[0].id
}

# 데이터베이스 서브넷과 라우팅 테이블 연결
resource "aws_route_table_association" "database" {
  count          = length(var.database_subnet_cidrs)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

# VPC Flow Logs (보안 모니터링용)
#resource "aws_flow_log" "vpc" {
#  count           = var.enable_vpc_flow_logs ? 1 : 0
#  iam_role_arn    = aws_iam_role.flow_log[0].arn
# log_destination = aws_cloudwatch_log_group.vpc_flow_log[0].arn
#  traffic_type    = "ALL"
#  vpc_id          = aws_vpc.main.id
#  
#  tags = merge(var.common_tags, {
#    Name = "${var.project_name}-vpc-flow-logs"
#    Type = "Network Security"
#  })
#}

resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  count             = var.enable_vpc_flow_logs ? 1 : 0
  name              = "/aws/vpc/flowlogs/${var.project_name}"
  retention_in_days = var.flow_log_retention_days

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-vpc-flow-logs"
    Type = "Network Security"
  })
}

# IAM Role for VPC Flow Logs
resource "aws_iam_role" "flow_log" {
  count = var.enable_vpc_flow_logs ? 1 : 0
  name  = "${var.project_name}-vpc-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

# IAM Policy for VPC Flow Logs
resource "aws_iam_role_policy" "flow_log" {
  count = var.enable_vpc_flow_logs ? 1 : 0
  name  = "${var.project_name}-vpc-flow-log-policy"
  role  = aws_iam_role.flow_log[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}