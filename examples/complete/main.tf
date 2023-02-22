module "repo_config" {
  source = "../../"

  repos = [
    {
      id       = "github.com/getindata/foo"
      workflow = "terraform-basic"
    },
    {
      id                = "github.com/getindata/bar"
      workflow          = "terraform-basic-with-fmt"
      allowed_overrides = ["delete_source_branch_on_merge"]
    },
    {
      id                              = "github.com/getindata/baz"
      allowed_overrides               = ["workflow", "delete_source_branch_on_merge"]
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
    branch             = "main"
  }

  workflows = {
    terraform-basic-with-fmt = {
      plan = {
        steps = [
          {
            run = "terraform fmt -no-color -check=true -diff=true -write=false"
          },
          {
            run = "terraform plan -no-color -input=false -out $PLANFILE"
          }
        ]
      }
      template = "terragrunt-basic-check"
    }
    terragrunt-my-basic = {
      plan = {
        steps = [
          {
            run : "echo \"before plan\""
          },
          {
            atlantis_step : { command : "plan", extra_args : ["-no-color"] }
          }
        ]
      }
      checkov                = { enabled = true, soft_fail = true }
      check_gitlab_approvals = { enabled = true }
      asdf                   = { enabled = true }
    }
  }

  repo_config_file = {
    enabled = true
  }
}
