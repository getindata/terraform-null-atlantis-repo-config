locals {
  #Repo attributes that are meant to simplify configuration rather than being actual repo options
  helper_options = ["allow_all_server_side_workflows", "terragrunt_atlantis_config"]

  #Remove all options that are null
  repos_with_non_null_values = [
    for repo in var.repos : merge(
      { for k, v in var.repos_common_config : k => v if v != null },
      { for k, v in repo : k => v if v != null }
    )
  ]
  #Apply helper variables and then remove them
  repos = [
    for repo in local.repos_with_non_null_values : merge(
      {
        for k, v in repo : k => v if contains(local.helper_options, k) == false
      },
      repo.allow_all_server_side_workflows ? { allowed_workflows = keys(local.workflows) } : {},
      repo.terragrunt_atlantis_config.enabled ? { pre_workflow_hooks = concat(lookup(repo, "pre_workflow_hooks", []), [
        {
          run : join(" ", compact(
            [
              "terragrunt-atlantis-config",
              "generate",
              format("--output \"%s\"", repo.terragrunt_atlantis_config.output),
              repo.terragrunt_atlantis_config.filter != null ? format("--filter \"%s\"", repo.terragrunt_atlantis_config.filter) : null,
              repo.terragrunt_atlantis_config.parallel != null ? format("--parallel=%s", repo.terragrunt_atlantis_config.parallel) : null,
              repo.terragrunt_atlantis_config.autoplan != null ? format("--autoplan=%s", repo.terragrunt_atlantis_config.autoplan) : null,
              repo.terragrunt_atlantis_config.automerge != null ? format("--automerge=%s", repo.terragrunt_atlantis_config.automerge) : null,
              repo.terragrunt_atlantis_config.cascade_dependencies != null ? format("--cascade-dependencies=%s", repo.terragrunt_atlantis_config.cascade_dependencies) : null,
              repo.terragrunt_atlantis_config.use_project_markers != null ? format("--use-project-markers=%s", repo.terragrunt_atlantis_config.use_project_markers) : null,
            ]
          ))
      }]) } : {},
  )]

  workflows_helper_options = ["asdf", "checkov", "pull_gitlab_variables", "check_gitlab_approvals"]

  default_workflow_features = {
    pull_gitlab_variables  = { enabled = false },
    asdf                   = { enabled = false },
    checkov                = { enabled = false },
    check_gitlab_approvals = { enabled = false },
  }

  #Remove all options that are null
  predefined_workflows = var.use_predefined_workflows ? yamldecode(file("${path.module}/config/workflows.yaml")).workflows : null
  merged_workflows = merge(
    {
      for workflow_name, workflow in merge({}, local.predefined_workflows) : workflow_name =>
        merge(local.default_workflow_features, workflow)
    },
    {
      for workflow_name, workflow in var.workflows : workflow_name => {
        for k, v in workflow : k => v if v != null
      }
    }
  )

  workflows = {
    for workflow_name, workflow in local.merged_workflows : workflow_name => {
      for k, v in workflow : k => {
        for nk, nv in v : nk =>
        concat(
          workflow.pull_gitlab_variables.enabled ? [{ multienv = "pull_gitlab_variables.sh" }] : [],
          workflow.check_gitlab_approvals.enabled && k == "apply" ? [{ run = "check_gitlab_approvals.sh" }] : [],
          nv,
          workflow.checkov.enabled && k == "plan" ? [{ run = "checkov run" }] : [])
        if nk == "steps"
      } if v != null && !contains(local.workflows_helper_options, k)
    }
  }

  repo_config = {
    repos     = local.repos
    workflows = local.workflows
  }

  repo_config_json = jsonencode(local.repo_config)
  repo_config_yaml = replace(yamlencode(local.repo_config), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")
}

resource "local_file" "repo_config" {
  count = var.repo_config_file.enabled ? 1 : 0
  content = (var.repo_config_file.format == "json"
    ? local.repo_config_json
    : local.repo_config_yaml
  )
  filename        = format("%s/%s", var.repo_config_file.path, var.repo_config_file.name)
  file_permission = "0644"
}
