locals {
  #Repo attributes that are meant to simplify configuration rather than being actual repo options
  helper_options = ["allow_all_server_side_workflows", "terragrunt_atlantis_config", "infracost"]

  #Remove all options that are null
  repos_with_non_null_values = [
    for repo in var.repos : merge(
      { for k, v in var.repos_common_config : k => v if v != null },
      { for k, v in repo : k => v if v != null },
      { terragrunt_atlantis_config : merge(
        var.repos_common_config.terragrunt_atlantis_config,
        { for k, v in repo.terragrunt_atlantis_config : k => v if v != null }
      ) }
    )
  ]
  #Apply helper variables and then remove them
  repos = [
    for repo in local.repos_with_non_null_values : merge(
      {
        for k, v in repo : k => v if contains(local.helper_options, k) == false
      },
      repo.allow_all_server_side_workflows ? { allowed_workflows = concat(repo.allowed_workflows, keys(local.workflows)) } : { allowed_workflows = repo.allowed_workflows },
      {
        pre_workflow_hooks = concat(
          lookup(repo, "pre_workflow_hooks", []),
          repo.terragrunt_atlantis_config.enabled ? [
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
            }
          ] : [],
          lookup(repo, "workflow", "") != "" && lookup(local._workflows, lookup(repo, "workflow", ""), "") != "" ? (
            local._workflows[lookup(repo, "workflow", "")].infracost.enabled ? [
              { run : "rm -rf /tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM" },
              { run : "mkdir -p /tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM" }
          ] : []) : []
        ),
        post_workflow_hooks = concat(
          lookup(repo, "post_workflow_hooks", []),
          lookup(repo, "workflow", "") != "" && lookup(local._workflows, lookup(repo, "workflow", ""), "") != "" ? (
            local._workflows[lookup(repo, "workflow", "")].infracost.enabled ? [
              { run : <<EOT
JSON_DIRECTORY=/tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM
if [[ ! -d "$JSON_DIRECTORY" || -z "$(ls -A $JSON_DIRECTORY)" ]]; then
  exit 0
fi

infracost comment gitlab --repo $BASE_REPO_OWNER/$BASE_REPO_NAME \
                         --merge-request $PULL_NUM \
                         --path $JSON_DIRECTORY/'*'-infracost.json \
                         --gitlab-token $GITLAB_TOKEN \
                         --behavior new

rm -rf $JSON_DIRECTORY
EOT
              }
          ] : []) : []
        )
    })
  ]

  workflows_helper_options = ["asdf", "checkov", "pull_gitlab_variables", "check_gitlab_approvals", "template", "infracost"]

  # tflint-ignore: terraform_naming_convention
  _workflows = {
    for workflow_name, workflow in var.workflows : workflow_name => {
      plan = merge(
        local.null_workflow.plan,
        can(workflow.template) ? local.workflow_templates[workflow["template"]].plan : null,
      workflow.plan)
      apply = merge(
        local.null_workflow.apply,
        can(workflow.template) ? local.workflow_templates[workflow["template"]].apply : null,
      workflow.apply),
      import = merge(
        local.null_workflow.import,
        can(workflow.template) ? local.workflow_templates[workflow["template"]].import : null,
      workflow.import)
      state_rm = merge(
        local.null_workflow.state_rm,
        can(workflow.template) ? local.workflow_templates[workflow["template"]].state_rm : null,
      workflow.state_rm),
      pull_gitlab_variables  = workflow.pull_gitlab_variables
      asdf                   = workflow.asdf
      checkov                = workflow.checkov
      check_gitlab_approvals = workflow.check_gitlab_approvals
      infracost              = workflow.infracost
    }
  }

  asdf_steps                   = [{ run = "asdf install" }]
  pull_gitlab_variables_steps  = [{ multienv = "pull-gitlab-variables.sh" }]
  check_gitlab_approvals_steps = [{ run = "check-gitlab-approvals.sh" }]

  workflows = {
    for workflow_name, workflow in local._workflows : workflow_name => {
      for stage_name, stage in workflow : stage_name => { steps : concat(
        workflow.asdf.enabled && stage_name == "plan" ? local.asdf_steps : [],
        workflow.pull_gitlab_variables.enabled ? local.pull_gitlab_variables_steps : [],
        workflow.check_gitlab_approvals.enabled && stage_name == "apply" ? local.check_gitlab_approvals_steps : [],
        flatten([
          for step in stage.steps : [
            for name, object in step :
            jsondecode(
              name == "atlantis_step" ?
              (object.extra_args != null ? jsonencode({ (object.command) : { extra_args : object.extra_args } }) : jsonencode(object.command)) :
              jsonencode({ (name) : object })
            )
            if object != null
        ]]),
        workflow.checkov.enabled && stage_name == "plan" ? [
          { run = "terragrunt show -json $PLANFILE > $SHOWFILE" },
          {
            run = join(" ", compact(
              [
                "checkov",
                format("--file \"%s\"", workflow.checkov.file),
                "--output github_failed_only",
                workflow.checkov.soft_fail != null ? "--soft-fail" : null
              ]
            ))
          }
        ] : [],
        jsondecode(workflow.infracost.enabled && stage_name == "plan" ? jsonencode([
          { env = { name = "INFRACOST_OUTPUT", command = "echo /tmp/$BASE_REPO_OWNER-$BASE_REPO_NAME-$PULL_NUM/$WORKSPACE-`echo $REPO_REL_DIR | sed 's#/#-#g'`-infracost.json" } },
          { run = "infracost breakdown --path=$SHOWFILE --format=json --log-level=info --out-file=$INFRACOST_OUTPUT --project-name=$REPO_REL_DIR" }
        ]) : jsonencode([]))
      ) } if !contains(local.workflows_helper_options, stage_name) && lookup(stage, "steps", null) != null
    }
  }

  repo_config = {
    repos     = local.repos
    workflows = local.workflows
  }

  repo_config_json = jsonencode(local.repo_config)
  repo_config_yaml = replace(
    replace(yamlencode(local.repo_config), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:"),
  "/((?:^|\n)[\\s-]*)\"([\\w-]+)\"/", "$1$2")
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
