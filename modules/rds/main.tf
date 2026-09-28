resource "aws_db_subnet_group" "main" {
  name       = "three-tier-prod-db-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name = "three-tier-prod-db-subnet-group"
  }
}

resource "aws_db_instance" "main" {
  identifier = var.db_identifier

  engine         = "mysql"
  instance_class = var.instance_class

  allocated_storage = 20
  storage_type       = "gp3"
  storage_encrypted  = true

  username                    = var.master_username
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_security_group_id]

  port = 3306

  multi_az            = false
  publicly_accessible = false

  backup_retention_period = 1
  copy_tags_to_snapshot    = true

  auto_minor_version_upgrade = true

  deletion_protection = false
  skip_final_snapshot = true

  tags = {
    Name = "3tier-prod-mysql"
    Tier = "database"
  }
}