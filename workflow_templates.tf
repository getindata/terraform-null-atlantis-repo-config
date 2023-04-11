locals {
  null_workflow = {
    plan = {
      steps = null
    }
    apply = {
      steps = null
    }
    import = {
      steps = null
    }
    state_rm = {
      steps = null
    }
  }

  workflow_templates = {
    null_workflow = local.null_workflow

    terragrunt-basic = merge(local.null_workflow, {
      plan = {
        steps = [
          { run = "terragrunt fmt --terragrunt-non-interactive -no-color -check=true -diff=true -write=false" },
          { run = "terragrunt hclfmt --terragrunt-non-interactive --terragrunt-check" },
          { run = "terragrunt plan --terragrunt-non-interactive -no-color -out $PLANFILE" }
        ]
      }
      apply = {
        steps = [
          { run = "terragrunt apply --terragrunt-non-interactive -no-color -input=false -compact-warnings -auto-approve $PLANFILE " }
        ]
      }
    })

    terragrunt-basic-check = merge(local.null_workflow, {
      plan = {
        steps = [
          { run = "terragrunt fmt --terragrunt-non-interactive -no-color -check=true -diff=true -write=false" },
          { run = "terragrunt hclfmt --terragrunt-non-interactive --terragrunt-check" },
          # Create fake terraform-plan...
          { run = "terragrunt show --terragrunt-non-interactive -json > $PLANFILE" }
        ]
      }
      apply = {
        steps = [
          # fake successful apply to avoid `not automerging because project at dir "", workspace "default" has status "planned"` error
          { run = "echo 'This is CHECK-ONLY workflow - run `terragrunt apply` manually'" }
        ]
      }
    })
  }
}
