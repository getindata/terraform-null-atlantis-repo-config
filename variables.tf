variable "repos" {
  description = "Map of repositories and their configs. Refer to https://www.runatlantis.io/docs/server-side-repo-config.html#example-server-side-repo"
  type = list(object({
    id                              = optional(string, "/.*/")
    branch                          = optional(string)
    apply_requirements              = optional(list(string))
    allowed_overrides               = optional(list(string))
    allowed_workflows               = optional(list(string))
    allow_all_server_side_workflows = optional(bool, false)
    allow_custom_workflows          = optional(bool)
    delete_source_branch_on_merge   = optional(bool)
    pre_workflow_hooks = optional(list(object({
      run = string
    })))
    post_workflow_hooks = optional(list(object({
      run = string
    })))
    workflow = optional(string)
  }))
  default = []
}

variable "repos_common_config" {
  description = "Common config that will be merged into each item of the repos list"
  type = object({
    id                              = optional(string)
    branch                          = optional(string)
    apply_requirements              = optional(list(string))
    allowed_overrides               = optional(list(string))
    allowed_workflows               = optional(list(string))
    allow_all_server_side_workflows = optional(bool, false)
    allow_custom_workflows          = optional(bool)
    delete_source_branch_on_merge   = optional(bool)
    pre_workflow_hooks = optional(list(object({
      run = string
    })))
    post_workflow_hooks = optional(list(object({
      run = string
    })))
    workflow = optional(string)
  })
  default = {}
}

variable "workflows" {
  description = "List of custom workflow that will be added to the repo config file"
  type = map(object({
    plan = optional(object({
      steps = any
    }))
    apply = optional(object({
      steps = any
    }))
    policy_check = optional(object({
      steps = any
    }))
  }))
  default = {}
}

variable "use_predefined_workflows" {
  description = "Indicates wherever predefined workflows should be added to the generated repo config file"
  type        = bool
  default     = true
}

variable "repo_config_file_generation_enabled" {
  description = "Indicates wherever the config file should be generated"
  type        = bool
  default     = false
}

variable "repo_config_file_path" {
  description = "Path where the repo config file should be generated"
  type        = string
  default     = "."
}

variable "repo_config_file_name" {
  description = "Name of the repo config file"
  type        = string
  default     = "repo_config.yaml"
}

variable "repo_config_file_format" {
  description = "Format of the repo config file that will be generated. Possible values: yaml or json"
  type        = string
  default     = "yaml"

  validation {
    condition     = contains(["yaml", "json"], var.repo_config_file_format)
    error_message = "Invalid format provided. Allowed values: yaml, json"
  }
}
