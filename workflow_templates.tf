locals {
  null_workflow = {
    init = {
      steps = null
    }
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
      init = {
        steps = [
           { run = "terragrunt init" }
        ]
      }
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
      import = {
        steps = [
          { env = { name = "IMPORT_ARGS", command = "printf \"%s\" $COMMENT_ARGS | sed \"s/,/ /\" | tr -d \"\\\\\"" } },
          { run = "terragrunt import --terragrunt-non-interactive -no-color -input=false -compact-warnings $IMPORT_ARGS" }
        ]
      }
      state_rm = {
        steps = [
          { env = { name = "STATE_RM_ARGS", command = "printf \"%s\" $COMMENT_ARGS | sed \"s/,/ /\" | tr -d \"\\\\\"" } },
          { run = "terragrunt state rm --terragrunt-non-interactive -no-color $STATE_RM_ARGS" }
        ]
      }
    })

    terragrunt-basic-check = merge(local.null_workflow, {
      init = {
        steps = [
          { run = "terragrunt init" }
        ]
      }
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
