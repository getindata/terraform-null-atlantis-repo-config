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
          { run = "terragrunt fmt -no-color -check=true -diff=true -write=false --terragrunt-non-interactive" },
          { run = "terragrunt hclfmt --terragrunt-check --terragrunt-non-interactive" },
          { run = "terragrunt plan -no-color -out $PLANFILE --terragrunt-non-interactive" }
        ]
      }
      apply = {
        steps = [
          { run = "terragrunt apply -no-color -input=false -compact-warnings -auto-approve $PLANFILE --terragrunt-non-interactive" }
        ]
      }
    })

    terragrunt-basic-check = merge(local.null_workflow, {
      plan = {
        steps = [
          { run = "terragrunt fmt -no-color -check=true -diff=true -write=false --terragrunt-non-interactive" },
          { run = "terragrunt hclfmt --terragrunt-check --terragrunt-non-interactive" },
          # Create fake terraform-plan...
          { run = "terragrunt show -json > $PLANFILE" }
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
