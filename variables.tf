variable "repos" {
  description = "Map of repositories and their configs. Refer to https://www.runatlantis.io/docs/server-side-repo-config.html#example-server-side-repo"
  type = list(object({
    id                            = optional(string, "/.*/")
    branch                        = optional(string)
    apply_requirements            = optional(list(string))
    allowed_overrides             = optional(list(string))
    allowed_workflows             = optional(list(string), [])
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
      enabled              = optional(bool)
      output               = optional(string)
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
      enabled              = optional(bool, false)
      output               = optional(string, "atlantis.yaml")
      automerge            = optional(bool)
      autoplan             = optional(bool)
      parallel             = optional(bool)
      cascade_dependencies = optional(bool)
      filter               = optional(string)
      use_project_markers  = optional(bool)
    }), {})
    infracost = optional(object({
      enabled = optional(bool, false)
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
          command    = string
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
          command    = string
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
          command    = string
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
          command    = string
          extra_args = optional(list(string))
        }))
      })))
    }))
    template = optional(string, "terragrunt-basic")
    asdf = optional(object({
      enabled = optional(bool, false)
    }), {})
    checkov = optional(object({
      enabled   = optional(bool, false)
      soft_fail = optional(bool, false)
      file      = optional(string, "$SHOWFILE")
    }), {})
    infracost = optional(object({
      enabled                    = optional(bool, false)
      platform                   = optional(string, "gitlab")
      token_environment_variable = optional(string)
      behavior                   = optional(string, "new")
    }), {})
    pull_gitlab_variables = optional(object({
      enabled = optional(bool, false)
    }), {})
    check_gitlab_approvals = optional(object({
      enabled = optional(bool, false)
    }), {}),
  }))
  default = {}

  validation {
    condition = alltrue(flatten([
      for workflow_name, workflow in var.workflows :
      [
        for stage_name, stage in [workflow.plan, workflow.apply, workflow.import, workflow.state_rm] :
        [
          for step in stage.steps : (length([
            for x in [step.env, step.run, step.multienv, step.atlantis_step] : x if x != null
          ]) == 1)
        ]
        if !contains([
          "asdf", "checkov", "infracost", "pull_gitlab_variables", "check_gitlab_approvals", "template"
        ], stage_name) && stage != null
      ]
    ]))
    error_message = "Exactly one of `env`, `run`, `multienv` or `atlantis_step` per stage must be specified"
  }

  validation {
    condition = alltrue(flatten([
      for workflow_name, workflow in var.workflows :
      [
        for stage_name, stage in [workflow.plan, workflow.apply, workflow.import, workflow.state_rm] :
        [
          for step in stage.steps : contains([
            "init", "plan", "show", "policy_check", "apply", "version", "import", "state_rm"
          ], step.atlantis_step.command)
          if lookup(step, "atlantis_step", null) != null
        ] if stage != null
      ]
    ]))
    error_message = "Invalid command in `atlantis_step`. Allowed values: init, plan, show, policy_check, apply, version, import, state_rm"
  }

  validation {
    condition     = alltrue([for workflow_name, workflow in var.workflows : contains(["github", "gitlab", "bitbucket"], workflow.infracost.platform)])
    error_message = "Invalid platform in `infracost`. Allowed values: github, gitlab, bitbucket"
  }

  validation {
    condition     = alltrue([for workflow_name, workflow in var.workflows : contains(["update", "hide-and-new", "delete-and-new", "new"], workflow.infracost.behavior)])
    error_message = "Invalid behavior in `infracost`. Allowed values: update, hide-and-new, delete-and-new, new"
  }
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
