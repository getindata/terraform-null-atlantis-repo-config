# Terraform Atlantis Repo Config Module 

![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)

<!--- Replace repository name -->
![License](https://badgen.net/github/license/getindata/terraform-null-atlantis-repo-config/)
![Release](https://badgen.net/github/release/getindata/terraform-null-atlantis-repo-config/)

<p align="center">
  <img height="150" src="https://getindata.com/img/logo.svg">
  <h3 align="center">We help companies turn their data into assets</h3>
</p>

---

This module generates a server side repo config that cab be passed to Atlantis server.
It also contains a set of opinionated custom workflows that are ready for usage. 

## USAGE

```terraform
module "template" {
  source = "github.com/getindata/terraform-null-atlantis-repo-config"

  repos = [
    {
      id                              = "/.*/"
      allowed_overrides               = ["workflow", "delete_source_branch_on_merge"]
      allow_custom_workflows          = true
      allow_all_server_side_workflows = true
    }
  ]

  repos_common_config = {
    apply_requirements = ["approved", "mergeable"]
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
    }
  }
}
```
## EXAMPLES

- [Complete example](examples/complete)

<!-- BEGIN_TF_DOCS -->




## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_repo_config_file"></a> [repo\_config\_file](#input\_repo\_config\_file) | Configures config file generation if enabled | <pre>object({<br>    enabled = optional(bool, false)<br>    path    = optional(string, ".")<br>    name    = optional(string, "repo_config.yaml")<br>    format  = optional(string, "yaml")<br>  })</pre> | `{}` | no |
| <a name="input_repos"></a> [repos](#input\_repos) | Map of repositories and their configs. Refer to https://www.runatlantis.io/docs/server-side-repo-config.html#example-server-side-repo | <pre>list(object({<br>    id                            = optional(string, "/.*/")<br>    branch                        = optional(string)<br>    apply_requirements            = optional(list(string))<br>    allowed_overrides             = optional(list(string))<br>    allowed_workflows             = optional(list(string))<br>    allow_custom_workflows        = optional(bool)<br>    delete_source_branch_on_merge = optional(bool)<br>    pre_workflow_hooks = optional(list(object({<br>      run = string<br>    })))<br>    post_workflow_hooks = optional(list(object({<br>      run = string<br>    })))<br>    workflow = optional(string)<br>    ######### Helpers #########<br>    allow_all_server_side_workflows = optional(bool, false)<br>    terragrunt_atlantis_config = optional(object({<br>      enabled              = optional(bool, false)<br>      output               = optional(string, "atlantis.yaml")<br>      automerge            = optional(bool)<br>      autoplan             = optional(bool)<br>      parallel             = optional(bool)<br>      cascade_dependencies = optional(bool)<br>      filter               = optional(string)<br>      use_project_markers  = optional(bool)<br>    }), {})<br>  }))</pre> | `[]` | no |
| <a name="input_repos_common_config"></a> [repos\_common\_config](#input\_repos\_common\_config) | Common config that will be merged into each item of the repos list | <pre>object({<br>    id                            = optional(string)<br>    branch                        = optional(string)<br>    apply_requirements            = optional(list(string))<br>    allowed_overrides             = optional(list(string))<br>    allowed_workflows             = optional(list(string))<br>    allow_custom_workflows        = optional(bool)<br>    delete_source_branch_on_merge = optional(bool)<br>    pre_workflow_hooks = optional(list(object({<br>      run = string<br>    })))<br>    post_workflow_hooks = optional(list(object({<br>      run = string<br>    })))<br>    workflow = optional(string)<br>    ######### Helpers #########<br>    allow_all_server_side_workflows = optional(bool, false)<br>    terragrunt_atlantis_config = optional(object({<br>      enabled  = optional(bool, false)<br>      output   = optional(string, "atlantis.yaml")<br>      autoplan = optional(bool, false)<br>      parallel = optional(bool, false)<br>      filter   = optional(string)<br>    }), {})<br>  })</pre> | `{}` | no |
| <a name="input_use_predefined_workflows"></a> [use\_predefined\_workflows](#input\_use\_predefined\_workflows) | Indicates wherever predefined workflows should be added to the generated repo config file | `bool` | `true` | no |
| <a name="input_workflows"></a> [workflows](#input\_workflows) | List of custom workflow that will be added to the repo config file | <pre>map(object({<br>    plan = optional(object({<br>      steps = any<br>    }))<br>    apply = optional(object({<br>      steps = any<br>    }))<br>    policy_check = optional(object({<br>      steps = any<br>    }))<br>  }))</pre> | `{}` | no |

## Modules

No modules.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_repo_config"></a> [repo\_config](#output\_repo\_config) | Repo config object |
| <a name="output_repos"></a> [repos](#output\_repos) | List of repos config |
| <a name="output_repos_config_json"></a> [repos\_config\_json](#output\_repos\_config\_json) | Repo config converted to json string |
| <a name="output_repos_config_yaml"></a> [repos\_config\_yaml](#output\_repos\_config\_yaml) | Repo config converted to json string |
| <a name="output_workflows"></a> [workflows](#output\_workflows) | Custom Atlantis workflows |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_local"></a> [local](#provider\_local) | >= 1.3 |

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 1.3 |

## Resources

| Name | Type |
|------|------|
| [local_file.repo_config](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
<!-- END_TF_DOCS -->

## CONTRIBUTING

Contributions are very welcomed!

Start by reviewing [contribution guide](CONTRIBUTING.md) and our [code of conduct](CODE_OF_CONDUCT.md). After that, start coding and ship your changes by creating a new PR.

## LICENSE

Apache 2 Licensed. See [LICENSE](LICENSE) for full details.

## AUTHORS

<!--- Replace repository name -->
<a href="https://github.com/getindata/terraform-null-atlantis-repo-config/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=getindata/terraform-null-atlantis-repo-config" />
</a>

Made with [contrib.rocks](https://contrib.rocks).
