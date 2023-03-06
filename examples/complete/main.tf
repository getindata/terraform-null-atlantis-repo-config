module "repo_config" {
  source = "../../"

  repos = [
    {
      id                              = "gitlab.com/getindata/devops/playground/infracost"
      allowed_overrides               = ["workflow", "delete_source_branch_on_merge"]
      workflow                        = "terragrunt-basic-with-features"
      allow_custom_workflows          = true
      allow_all_server_side_workflows = true

      terragrunt_atlantis_config = {
        enabled  = true
        autoplan = true
      }
    }
  ]

  repos_common_config = {
    apply_requirements = ["approved", "mergeable"]
    branch             = "/main/"
  }

  workflows = {
    terraform-basic-with-fmt = {
      plan = {
        steps = [
          { run = "terraform fmt -no-color -check=true -diff=true -write=false" },
          { run = "echo \"Formatting done, start planning...\"" },
          { atlantis_step = { command = "plan", extra_args = ["-no-color"] } },
        ]
      }
      template = "null_workflow"
    }

    terragrunt-basic-with-features = {
      checkov                = { enabled = true, soft_fail = true }
      infracost              = { enabled = true }
      pull_gitlab_variables  = { enabled = true }
      check_gitlab_approvals = { enabled = true }
      asdf                   = { enabled = true }
    }

    terragrunt-basic-check-with-features = {
      template              = "terragrunt-basic-check"
      checkov               = { enabled = true }
      infracost             = { enabled = true }
      pull_gitlab_variables = { enabled = true }
      asdf                  = { enabled = true }
    }
  }

  repo_config_file = {
    enabled = true
  }
}
