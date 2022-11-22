output "workflows" {
  description = "Custom Atlantis workflows"
  value       = local.workflows
}

output "repos" {
  description = "List of repos config"
  value       = local.repos
}

output "repo_config" {
  description = "Repo config object"
  value       = local.repo_config
}

output "repos_config_json" {
  description = "Repo config converted to json string"
  value       = jsonencode(local.repo_config)
}
