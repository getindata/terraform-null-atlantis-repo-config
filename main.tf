locals {
  custom_repo_options = ["allow_all_server_side_workflows"]
  repos = [for repo in var.repos :
    merge(
      {
        for k, v in merge(var.repos_common_config, var.repos_common_config.allow_all_server_side_workflows ? { allowed_workflows = keys(local.workflows) } : {}) : k => v
        if v != null && contains(local.custom_repo_options, k) == false
      },
      {
        for k, v in merge(repo, repo.allow_all_server_side_workflows ? { allowed_workflows = keys(local.workflows) } : {}) : k => v
        if v != null && contains(local.custom_repo_options, k) == false
      }
    )
  ]
  workflows = { for workflow_name, workflow in merge(
    var.use_predefined_workflows ? yamldecode(file("${path.module}/config/workflows.yaml")).workflows : {},
    var.workflows
    ) : workflow_name => {
    for k, v in workflow : k => v if v != null
  } }

  repo_config = {
    repos     = local.repos
    workflows = local.workflows
  }
}

resource "local_file" "repo_config" {
  count = var.repo_config_file_generation_enabled ? 1 : 0
  content = (var.repo_config_file_format == "json"
    ? jsonencode(local.repo_config)
    : replace(yamlencode(local.repo_config), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")
  )
  filename        = format("%s/%s", var.repo_config_file_path, var.repo_config_file_name)
  file_permission = "0644"
}
