output "db_master_user_secret_arn" {
  value       = module.db.db_instance_master_user_secret_arn
}

output "db_ssm_path" {
  value       = "/${var.app_name}/database"
}
