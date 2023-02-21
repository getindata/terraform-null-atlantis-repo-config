variable "repos" {
  description = "Map of repositories and their configs. Refer to https://www.runatlantis.io/docs/server-side-repo-config.html#example-server-side-repo"
  type = list(object({
    id                            = optional(string, "/.*/")
    branch                        = optional(string)
    apply_requirements            = optional(list(string))
    allowed_overrides             = optional(list(string))
    allowed_workflows             = optional(list(string))
    allow_custom_workflows        = optional(bool)
    delete_source_branch_on_merge = optional(bool)
    pre_workflow_hooks = optional(list(object({
      run = string
    })))
    post_workflow_hooks = optional(list(object({
      run = string
    })))
    workflow = optional(string)
    ######### Helpers #########
    allow_all_server_side_workflows = optional(bool, false)
    terragrunt_atlantis_config = optional(object({
      enabled              = optional(bool, false)
      output               = optional(string, "atlantis.yaml")
      automerge            = optional(bool)
      autoplan             = optional(bool)
      parallel             = optional(bool)
      cascade_dependencies = optional(bool)
      filter               = optional(string)
      use_project_markers  = optional(bool)
    }), {})
  }))
  default = []
}

variable "repos_common_config" {
  description = "Common config that will be merged into each item of the repos list"
  type = object({
    id                            = optional(string)
    branch                        = optional(string)
    apply_requirements            = optional(list(string))
    allowed_overrides             = optional(list(string))
    allowed_workflows             = optional(list(string))
    allow_custom_workflows        = optional(bool)
    delete_source_branch_on_merge = optional(bool)
    pre_workflow_hooks = optional(list(object({
      run = string
    })))
    post_workflow_hooks = optional(list(object({
      run = string
    })))
    workflow = optional(string)
    ######### Helpers #########
    allow_all_server_side_workflows = optional(bool, false)
    terragrunt_atlantis_config = optional(object({
      enabled  = optional(bool, false)
      output   = optional(string, "atlantis.yaml")
      autoplan = optional(bool, false)
      parallel = optional(bool, false)
      filter   = optional(string)
    }), {})
  })
  default = {}
}

variable "workflows" {
  description = "List of custom workflow that will be added to the repo config file"
  type = map(object({
    plan = optional(object({
      steps = optional(list(object({
        env = optional(object({
          name    = string
          command = string
        }))
        run      = optional(string)
        multienv = optional(string)
        atlantis_step = optional(object({
          command    = string // one of: [init, plan, apply, import, state_rm]
          extra_args = optional(list(string))
        }))
      })))
    }))
    apply = optional(object({
      steps = optional(list(object({
        env = optional(object({
          name    = string
          command = string
        }))
        run      = optional(string)
        multienv = optional(string)
        atlantis_step = optional(object({
          command    = string // one of: [init, plan, apply, import, state_rm]
          extra_args = optional(list(string))
        }))
      })))
    }))
    import = optional(object({
      steps = optional(list(object({
        env = optional(object({
          name    = string
          command = string
        }))
        run      = optional(string)
        multienv = optional(string)
        atlantis_step = optional(object({
          command    = string // one of: [init, plan, apply, import, state_rm]
          extra_args = optional(list(string))
        }))
      })))
    }))
    state_rm = optional(object({
      steps = optional(list(object({
        env = optional(object({
          name    = string
          command = string
        }))
        run      = optional(string)
        multienv = optional(string)
        atlantis_step = optional(object({
          command    = string // one of: [init, plan, apply, import, state_rm]
          extra_args = optional(list(string))
        }))
      })))
    }))
    template = optional(string, "terragrunt-basic")
    asdf = optional(object({
      enabled = optional(bool, false)
    }))
    checkov = optional(object({
      enabled = optional(bool, false)
    }))
    pull_gitlab_variables = optional(object({
      enabled = optional(bool, false)
    }))
    check_gitlab_approvals = optional(object({
      enabled = optional(bool, false)
    })),
  }))
  default = {}
}

variable "repo_config_file" {
  description = "Configures config file generation if enabled"
  type = object({
    enabled = optional(bool, false)
    path    = optional(string, ".")
    name    = optional(string, "repo_config.yaml")
    format  = optional(string, "yaml")
  })
  default = {}

  validation {
    condition     = contains(["yaml", "json"], var.repo_config_file.format)
    error_message = "Invalid format provided. Allowed values: yaml, json"
  }
}
