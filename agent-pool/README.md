# TFE Agent Pool Module

This module creates a Terraform Enterprise/HCP Terraform agent pool for running Terraform operations on self-hosted agents instead of TFE's managed infrastructure.

## Features

- Creates a TFE agent pool
- Generates agent tokens for authentication
- Configures workspace access (organization-wide or specific workspaces)
- Supports multiple agent tokens for different agent deployments

## Usage

### Organization-Scoped Agent Pool

```hcl
module "agent_pool_default" {
  source = "./agent-pool"

  organization        = "my-org"
  name                = "default-agents"
  organization_scoped = true

  agent_tokens = {
    production = {
      description = "Token for production agent deployment"
    }
    staging = {
      description = "Token for staging agent deployment"
    }
  }
}
```

### Workspace-Scoped Agent Pool

```hcl
module "agent_pool_private" {
  source = "./agent-pool"

  organization        = "my-org"
  name                = "private-network-agents"
  organization_scoped = false

  allowed_workspace_ids = [
    module.workspace_database.id,
    module.workspace_internal_api.id
  ]

  agent_tokens = {
    primary = {
      description = "Primary agent token for private network"
    }
  }
}
```

### Multiple Agent Pools for Different Environments

```hcl
module "agent_pool_prod" {
  source = "./agent-pool"

  organization        = "my-org"
  name                = "production-agents"
  organization_scoped = false

  allowed_workspace_ids = [
    module.workspace_prod_app.id,
    module.workspace_prod_db.id
  ]

  agent_tokens = {
    k8s_cluster_1 = {
      description = "Token for Kubernetes cluster 1"
    }
    k8s_cluster_2 = {
      description = "Token for Kubernetes cluster 2"
    }
  }
}

module "agent_pool_dev" {
  source = "./agent-pool"

  organization        = "my-org"
  name                = "development-agents"
  organization_scoped = false

  allowed_workspace_ids = [
    module.workspace_dev_app.id
  ]

  agent_tokens = {
    dev_agent = {
      description = "Token for development agent"
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| organization | Name of the organization | `string` | n/a | yes |
| name | Name of the agent pool | `string` | n/a | yes |
| organization_scoped | Available to all workspaces | `bool` | `true` | no |
| allowed_workspace_ids | Workspace IDs allowed to use pool | `set(string)` | `[]` | no |
| agent_tokens | Map of agent tokens to create | `map(object)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the agent pool |
| name | The name of the agent pool |
| organization | The organization name |
| organization_scoped | Whether the pool is organization scoped |
| agent_tokens | Map of agent token details (sensitive) |

## Agent Token Management

Agent tokens are used to authenticate agents with TFE:

1. **Create tokens** via the `agent_tokens` variable
2. **Retrieve tokens** from the sensitive output `agent_tokens`
3. **Deploy agents** using the tokens (see deployment section below)
4. **Rotate tokens** by creating new ones and removing old ones

**Security Best Practice**: Store agent tokens securely (e.g., in a secrets manager) and rotate them regularly.

## Deploying TFE Agents

After creating an agent pool and tokens, deploy agents using one of these methods:

### Docker

```bash
docker run -e TFC_AGENT_TOKEN="<token>" \
  -e TFC_AGENT_NAME="agent-1" \
  hashicorp/tfc-agent:latest
```

### Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tfc-agent
spec:
  replicas: 3
  selector:
    matchLabels:
      app: tfc-agent
  template:
    metadata:
      labels:
        app: tfc-agent
    spec:
      containers:
      - name: tfc-agent
        image: hashicorp/tfc-agent:latest
        env:
        - name: TFC_AGENT_TOKEN
          valueFrom:
            secretKeyRef:
              name: tfc-agent-token
              key: token
        - name: TFC_AGENT_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
```

### Systemd Service

```ini
[Unit]
Description=HCP Terraform Agent
After=network.target

[Service]
Type=simple
User=tfc-agent
Environment="TFC_AGENT_TOKEN=<token>"
Environment="TFC_AGENT_NAME=agent-1"
ExecStart=/usr/local/bin/tfc-agent
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

## Use Cases

### Private Network Access

Run agents in private networks to access resources not reachable from TFE's infrastructure:

```hcl
module "agent_pool_private" {
  source = "./agent-pool"

  organization        = "my-org"
  name                = "private-datacenter"
  organization_scoped = false

  allowed_workspace_ids = [
    module.workspace_on_prem_db.id,
    module.workspace_legacy_app.id
  ]

  agent_tokens = {
    datacenter_agent = {
      description = "Agent running in private datacenter"
    }
  }
}
```

### Custom Tools and Dependencies

Run agents with specific tools, SDKs, or dependencies not available in TFE's managed environment:

```hcl
module "agent_pool_custom" {
  source = "./agent-pool"

  organization = "my-org"
  name         = "custom-tooling"

  agent_tokens = {
    custom_agent = {
      description = "Agent with custom tools and dependencies"
    }
  }
}
```

### Compliance and Data Residency

Keep Terraform execution within specific geographic regions or compliance boundaries:

```hcl
module "agent_pool_eu" {
  source = "./agent-pool"

  organization        = "my-org"
  name                = "eu-compliant-agents"
  organization_scoped = false

  allowed_workspace_ids = [
    module.workspace_eu_prod.id
  ]

  agent_tokens = {
    eu_agent = {
      description = "Agent running in EU region"
    }
  }
}
```

## Integration with Workspace Module

```hcl
# Create agent pool
module "agent_pool" {
  source = "./agent-pool"

  organization = "my-org"
  name         = "private-agents"

  agent_tokens = {
    primary = {
      description = "Primary agent token"
    }
  }
}

# Create workspace using agent pool
module "workspace" {
  source = "./workspace"

  organization   = "my-org"
  name           = "private-infrastructure"
  execution_mode = "agent"
  agent_pool_id  = module.agent_pool.id
}
```

## Best Practices

1. **Descriptive Names**: Use clear names that indicate the agent pool's purpose or location
2. **Scope Appropriately**: Use workspace-scoped pools for sensitive or isolated workloads
3. **Multiple Tokens**: Create separate tokens for different agent deployments for easier rotation
4. **Token Rotation**: Regularly rotate agent tokens for security
5. **High Availability**: Deploy multiple agents per pool for redundancy
6. **Monitoring**: Monitor agent health and connectivity
7. **Resource Sizing**: Size agent infrastructure based on workspace concurrency needs
8. **Network Security**: Ensure agents can reach TFE endpoints and required resources

## Agent Pool Sizing

Consider these factors when sizing your agent pool:

- **Concurrent Runs**: Number of simultaneous Terraform runs
- **Run Duration**: Average time for plan/apply operations
- **Workspace Count**: Number of workspaces using the pool
- **Resource Requirements**: CPU/memory needs of your Terraform configurations

**Example**: For 10 workspaces with average 5-minute runs and 2 runs per hour per workspace:
- Peak concurrent runs: ~2-3
- Recommended agents: 3-5 (for redundancy)
