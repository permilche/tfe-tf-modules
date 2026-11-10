# TFE Run Task Module

This module creates and manages Terraform Enterprise/HCP Terraform run tasks that integrate external systems into the Terraform workflow for security scanning, cost estimation, policy validation, and custom checks.

## Features

- Creates organization-level run tasks
- Associates run tasks with workspaces
- Configurable enforcement levels (advisory or mandatory)
- Multiple execution stages (pre-plan, post-plan, pre-apply)
- HMAC key support for request verification
- Support for both task and test categories

## Usage

### Security Scanning with Snyk

```hcl
module "run_task_snyk" {
  source = "./run-task"

  organization = "my-org"
  name         = "snyk-security-scan"
  url          = "https://api.snyk.io/v1/terraform-cloud/run-task"
  description  = "Snyk security vulnerability scanning"
  hmac_key     = var.snyk_hmac_key

  workspace_run_tasks = {
    prod_app = {
      workspace_id      = module.workspace_prod.id
      enforcement_level = "mandatory"
      stage             = "post_plan"
    }
    staging_app = {
      workspace_id      = module.workspace_staging.id
      enforcement_level = "advisory"
      stage             = "post_plan"
    }
  }
}
```

### Cost Estimation with Infracost

```hcl
module "run_task_infracost" {
  source = "./run-task"

  organization = "my-org"
  name         = "infracost-estimation"
  url          = "https://dashboard.api.infracost.io/tfc/run-task"
  description  = "Infrastructure cost estimation"
  hmac_key     = var.infracost_hmac_key

  workspace_run_tasks = {
    prod_app = {
      workspace_id      = module.workspace_prod.id
      enforcement_level = "advisory"
      stage             = "post_plan"
    }
    prod_db = {
      workspace_id      = module.workspace_db.id
      enforcement_level = "advisory"
      stage             = "post_plan"
    }
  }
}
```

### Custom Compliance Check

```hcl
module "run_task_compliance" {
  source = "./run-task"

  organization = "my-org"
  name         = "custom-compliance-check"
  url          = "https://compliance.example.com/tfe/run-task"
  description  = "Custom compliance validation"
  hmac_key     = var.compliance_hmac_key
  category     = "task"

  workspace_run_tasks = {
    platform_workspace = {
      workspace_id      = module.workspace_platform.id
      enforcement_level = "mandatory"
      stage             = "post_plan"
    }
  }
}
```

### Pre-Plan Validation

```hcl
module "run_task_pre_validation" {
  source = "./run-task"

  organization = "my-org"
  name         = "pre-plan-validation"
  url          = "https://validator.example.com/run-task"
  description  = "Validate configuration before planning"

  workspace_run_tasks = {
    critical_workspace = {
      workspace_id      = module.workspace_critical.id
      enforcement_level = "mandatory"
      stage             = "pre_plan"
    }
  }
}
```

### Multiple Run Tasks on Same Workspace

```hcl
# Security scanning
module "run_task_security" {
  source = "./run-task"

  organization = "my-org"
  name         = "security-scan"
  url          = var.security_scanner_url
  hmac_key     = var.security_hmac_key

  workspace_run_tasks = {
    prod = {
      workspace_id      = module.workspace_prod.id
      enforcement_level = "mandatory"
      stage             = "post_plan"
    }
  }
}

# Cost estimation
module "run_task_cost" {
  source = "./run-task"

  organization = "my-org"
  name         = "cost-estimation"
  url          = var.cost_estimator_url
  hmac_key     = var.cost_hmac_key

  workspace_run_tasks = {
    prod = {
      workspace_id      = module.workspace_prod.id
      enforcement_level = "advisory"
      stage             = "post_plan"
    }
  }
}

# Compliance check
module "run_task_compliance" {
  source = "./run-task"

  organization = "my-org"
  name         = "compliance-check"
  url          = var.compliance_url
  hmac_key     = var.compliance_hmac_key

  workspace_run_tasks = {
    prod = {
      workspace_id      = module.workspace_prod.id
      enforcement_level = "mandatory"
      stage             = "pre_apply"
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| organization | Name of the organization | `string` | n/a | yes |
| name | Name of the run task | `string` | n/a | yes |
| url | URL of the run task endpoint | `string` | n/a | yes |
| description | A description of the run task | `string` | `null` | no |
| enabled | Whether the run task is enabled | `bool` | `true` | no |
| hmac_key | HMAC key for request verification | `string` | `null` | no |
| category | Category of the run task (task, test) | `string` | `"task"` | no |
| workspace_run_tasks | Workspace run task associations | `map(object)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the run task |
| name | The name of the run task |
| organization | The organization name |
| url | The URL of the run task |
| category | The category of the run task |
| enabled | Whether the run task is enabled |
| workspace_run_task_ids | Map of workspace associations |

## Run Task Stages

### pre_plan
- Executes **before** Terraform plan
- Use for: Configuration validation, pre-flight checks
- Cannot access plan output

### post_plan (default)
- Executes **after** Terraform plan
- Use for: Security scanning, cost estimation, policy checks
- Has access to plan JSON output
- Most common stage for run tasks

### pre_apply
- Executes **after** plan approval but **before** apply
- Use for: Final compliance checks, change approval workflows
- Has access to plan JSON output

## Enforcement Levels

### advisory
- Run task failures are **warnings only**
- Does not block the run from proceeding
- Use for: Cost estimates, informational checks, non-critical validations

### mandatory
- Run task failures **block** the run
- Run cannot proceed until task passes or is overridden (with permissions)
- Use for: Security vulnerabilities, compliance violations, critical validations

## Popular Run Task Integrations

### Security & Compliance
- **Snyk**: Vulnerability scanning for IaC
- **Checkov**: Policy-as-code security scanning
- **Bridgecrew**: Cloud security posture management
- **Aqua Security**: Container and IaC security
- **Prisma Cloud**: Cloud security and compliance

### Cost Management
- **Infracost**: Cloud cost estimation
- **CloudHealth**: Cost optimization
- **Vantage**: Cloud cost visibility

### Custom Integrations
- Internal compliance systems
- Change management workflows
- Custom validation logic
- Approval workflows

## HMAC Key Security

The HMAC key is used to verify that requests to your run task endpoint are authentic:

1. **Generate a secure key**: Use a cryptographically secure random string
2. **Store securely**: Use a secrets manager or encrypted storage
3. **Rotate regularly**: Update keys periodically for security
4. **Verify requests**: Your run task endpoint should validate the HMAC signature

Example HMAC verification (pseudo-code):
```python
import hmac
import hashlib

def verify_hmac(request_body, signature, hmac_key):
    expected = hmac.new(
        hmac_key.encode(),
        request_body.encode(),
        hashlib.sha512
    ).hexdigest()
    return hmac.compare_digest(expected, signature)
```

## Run Task Payload

Your run task endpoint receives a JSON payload with:

```json
{
  "payload_version": 1,
  "stage": "post_plan",
  "access_token": "...",
  "configuration_version_download_url": "...",
  "configuration_version_id": "...",
  "run_app_url": "...",
  "run_id": "...",
  "run_message": "...",
  "run_created_at": "...",
  "run_created_by": "...",
  "workspace_id": "...",
  "workspace_name": "...",
  "workspace_app_url": "...",
  "organization_name": "...",
  "plan_json_api_url": "..."
}
```

## Run Task Response

Your endpoint should respond with:

```json
{
  "data": {
    "type": "task-results",
    "attributes": {
      "status": "passed",
      "message": "All checks passed",
      "url": "https://example.com/results/123"
    }
  }
}
```

Status values:
- `passed`: Task succeeded
- `failed`: Task failed
- `running`: Task still processing (TFE will poll)

## Best Practices

1. **Use HMAC Keys**: Always configure HMAC keys for security
2. **Appropriate Enforcement**: Use `mandatory` for critical checks, `advisory` for informational
3. **Stage Selection**: Most tasks should use `post_plan` stage
4. **Multiple Workspaces**: Apply the same run task to multiple workspaces for consistency
5. **Multiple Tasks**: Combine different run tasks for comprehensive validation
6. **Error Handling**: Ensure your run task endpoint handles errors gracefully
7. **Timeouts**: Run tasks have a 10-minute timeout, optimize for performance
8. **Testing**: Test run tasks in non-production environments first

## Integration with Other Modules

```hcl
# Create project
module "project" {
  source = "./project"
  
  organization = "my-org"
  name         = "production"
}

# Create workspaces
module "workspace_app" {
  source = "./workspace"
  
  organization = "my-org"
  name         = "app-prod"
  project_id   = module.project.id
}

module "workspace_db" {
  source = "./workspace"
  
  organization = "my-org"
  name         = "db-prod"
  project_id   = module.project.id
}

# Apply run task to multiple workspaces
module "run_task_security" {
  source = "./run-task"
  
  organization = "my-org"
  name         = "security-scan"
  url          = var.security_url
  hmac_key     = var.security_hmac_key
  
  workspace_run_tasks = {
    app = {
      workspace_id      = module.workspace_app.id
      enforcement_level = "mandatory"
      stage             = "post_plan"
    }
    db = {
      workspace_id      = module.workspace_db.id
      enforcement_level = "mandatory"
      stage             = "post_plan"
    }
  }
}

# Apply different run task to specific workspace
module "run_task_cost" {
  source = "./run-task"
  
  organization = "my-org"
  name         = "cost-estimation"
  url          = var.cost_url
  
  workspace_run_tasks = {
    app = {
      workspace_id      = module.workspace_app.id
      enforcement_level = "advisory"
      stage             = "post_plan"
    }
  }
}
```

## Troubleshooting

### Run Task Failures

1. **Check endpoint availability**: Ensure URL is accessible from TFE
2. **Verify HMAC key**: Confirm key matches on both sides
3. **Review logs**: Check your run task service logs
4. **Test payload**: Use TFE's test feature to send sample payloads
5. **Timeout issues**: Optimize run task processing time

### Common Issues

- **403 Forbidden**: HMAC key mismatch or missing
- **Timeout**: Run task taking longer than 10 minutes
- **Invalid response**: Response format doesn't match expected schema
- **Connection refused**: Run task endpoint not accessible from TFE

## Additional Resources

- [Run Tasks API Documentation](https://developer.hashicorp.com/terraform/cloud-docs/api-docs/run-tasks)
- [Run Tasks Integration Guide](https://developer.hashicorp.com/terraform/cloud-docs/integrations/run-tasks)
- [Snyk Integration](https://docs.snyk.io/integrations/ci-cd-integrations/terraform-cloud-integration)
- [Infracost Integration](https://www.infracost.io/docs/integrations/terraform_cloud_enterprise/)
