# Deployment Tier Implementation Guide

## Overview

This guide provides step-by-step instructions for implementing deployment tiers to improve staged deployments while maintaining the current workspace architecture.

## Implementation Plan

### Phase 1: Add Deployment Tier Infrastructure

#### Step 1: Add Deployment Tier Variable

**File: `terraform/core/01-inputs-required.tf`**
```hcl
variable "deployment_tier" {
  description = "Deployment tier: 'stable' for production-ready jobs, 'experimental' for testing"
  type        = string
  default     = "stable"
  
  validation {
    condition     = contains(["stable", "experimental"], var.deployment_tier)
    error_message = "Deployment tier must be either 'stable' or 'experimental'."
  }
}
```

**File: `terraform/etl/01-inputs-required.tf`**
```hcl
variable "deployment_tier" {
  description = "Deployment tier: 'stable' for production-ready jobs, 'experimental' for testing"
  type        = string
  default     = "stable"
  
  validation {
    condition     = contains(["stable", "experimental"], var.deployment_tier)
    error_message = "Deployment tier must be either 'stable' or 'experimental'."
  }
}
```

#### Step 2: Create Job Tier Definitions

**File: `terraform/etl/03-input-derived.tf`**
```hcl
locals {
  # Define job stability tiers
  job_tiers = {
    # Stable jobs - proven in production (add your 110+ existing jobs here)
    stable = [
      "Cash_Collection_Date",
      "Cedar_Backing_Data", 
      "Cedar_Parking_Payments",
      "Citypay_Import",
      "housing_rent_position",
      "Ringgo_Daily_Transactions",
      # TODO: Add all existing stable jobs
    ]
    
    # Experimental jobs - testing phase (start empty, add new jobs here)
    experimental = [
      # New jobs start here, then move to stable after testing
    ]
  }
  
  # Determine which jobs to deploy based on tier
  enabled_jobs = var.deployment_tier == "stable" ? 
    local.job_tiers.stable : 
    concat(local.job_tiers.stable, local.job_tiers.experimental)
    
  # Department-level emergency controls
  department_controls = {
    parking_enabled = lookup(var.department_overrides, "parking", {enabled = true}).enabled
    housing_enabled = lookup(var.department_overrides, "housing", {enabled = true}).enabled
    data_insight_enabled = lookup(var.department_overrides, "data_and_insight", {enabled = true}).enabled
  }
}
```

#### Step 3: Add Department Override Support

**File: `terraform/core/01-inputs-optional.tf`**
```hcl
variable "department_overrides" {
  description = "Department-level deployment overrides for emergency control"
  type = map(object({
    enabled = optional(bool, true)
  }))
  default = {}
}
```

#### Step 4: Update tfvars Files

**File: `terraform/config/stg.tfvars`**
```hcl
# ... existing configuration ...

# Deploy all jobs (stable + experimental) for testing
deployment_tier = "experimental"

# Department overrides (optional)
department_overrides = {
  parking = {
    enabled = true
  }
  housing = {
    enabled = true  
  }
  data_and_insight = {
    enabled = true
  }
}
```

**File: `terraform/config/prod.tfvars`**
```hcl
# ... existing configuration ...

# Deploy only stable jobs in production
deployment_tier = "stable"

# Department overrides (optional)
department_overrides = {
  parking = {
    enabled = true
  }
  housing = {
    enabled = true
  }
  data_and_insight = {
    enabled = true
  }
}
```

### Phase 2: Migrate Resources to Use Deployment Tiers

#### Example: MWAA Resource Migration

**Before:**
```hcl
resource "aws_mwaa_environment" "mwaa" {
  count = local.is_live_environment ? 1 : 0
  # ... configuration
}
```

**After:**
```hcl
resource "aws_mwaa_environment" "mwaa" {
  count = var.deployment_tier == "stable" && local.is_live_environment ? 1 : 0
  # ... configuration
}
```

#### Example: Glue Job Migration

**Before:**
```hcl
module "Cash_Collection_Date" {
  count = local.is_live_environment ? 1 : 0
  source = "../modules/import-spreadsheet-file-from-g-drive"
  # ... configuration
}
```

**After:**
```hcl
module "Cash_Collection_Date" {
  count = (
    contains(local.enabled_jobs, "Cash_Collection_Date") &&
    local.department_controls.parking_enabled &&
    local.is_live_environment
  ) ? 1 : 0
  source = "../modules/import-spreadsheet-file-from-g-drive"
  # ... configuration
}
```

#### Example: New Experimental Job

**Add to experimental list:**
```hcl
locals {
  job_tiers = {
    stable = [
      # ... existing stable jobs
    ]
    experimental = [
      "new_parking_analytics",  # ← Add new job here
    ]
  }
}
```

**Create job module:**
```hcl
module "new_parking_analytics" {
  count = (
    contains(local.enabled_jobs, "new_parking_analytics") &&
    local.department_controls.parking_enabled &&
    local.is_live_environment
  ) ? 1 : 0
  source = "../modules/import-spreadsheet-file-from-g-drive"
  # ... configuration
}
```

### Phase 3: Implement Parallel Pipelines

#### GitHub Actions Workflow

**File: `.github/workflows/deploy-stable.yml`**
```yaml
name: Deploy Stable Jobs
on:
  push:
    branches: [main]
    paths: ['terraform/**']
  workflow_dispatch:

jobs:
  deploy-stable-stg:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
      
      - name: Deploy Stable Jobs to Staging
        run: |
          cd terraform/core
          terraform init
          terraform workspace select default
          terraform apply -auto-approve \
            -var-file="../config/stg.tfvars" \
            -var="deployment_tier=stable"
  
  deploy-stable-prod:
    needs: deploy-stable-stg
    runs-on: ubuntu-latest
    environment: production  # Requires approval
    steps:
      - uses: actions/checkout@v3
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
      
      - name: Deploy Stable Jobs to Production
        run: |
          cd terraform/core
          terraform init
          terraform workspace select default
          terraform apply -auto-approve \
            -var-file="../config/prod.tfvars" \
            -var="deployment_tier=stable"
```

**File: `.github/workflows/deploy-experimental.yml`**
```yaml
name: Deploy Experimental Jobs
on:
  push:
    branches: [main]
    paths: ['terraform/**']
  workflow_dispatch:

jobs:
  deploy-experimental-stg:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
      
      - name: Deploy All Jobs to Staging
        run: |
          cd terraform/core
          terraform init
          terraform workspace select default
          terraform apply -auto-approve \
            -var-file="../config/stg.tfvars" \
            -var="deployment_tier=experimental"
```

## Migration Strategy

### Week 1: Infrastructure Setup
1. Add deployment tier variables and locals
2. Update tfvars files
3. Test with a few non-critical resources

### Week 2: High-Impact Resources
1. Migrate expensive resources (MWAA, Redshift, DataHub)
2. Test deployments thoroughly
3. Document any issues

### Week 3: Glue Jobs Migration
1. Migrate Glue jobs in batches (20-30 at a time)
2. Test each batch before proceeding
3. Update job tier lists as you go

### Week 4: Pipeline Implementation
1. Implement parallel CI/CD workflows
2. Add deployment gates and approvals
3. Update team documentation

## Testing Strategy

### Validation Steps
1. **Staging Deployment**: Verify experimental tier deploys all jobs
2. **Production Deployment**: Verify stable tier deploys only stable jobs
3. **Department Override**: Test emergency department disabling
4. **New Job Workflow**: Add a test experimental job and verify it only deploys to staging

### Rollback Plan
If issues arise, you can quickly rollback by:
1. Setting `deployment_tier = "experimental"` in prod.tfvars (deploys everything)
2. Reverting to original count logic for specific resources
3. Using department overrides to disable problematic areas

## Benefits After Implementation

1. **Independent Deployments**: Stable jobs can deploy to prod while experimental jobs test in staging
2. **Faster Hotfixes**: Critical fixes bypass experimental job testing
3. **Clearer Promotion Path**: experimental → stable → production
4. **Emergency Controls**: Department-level disabling for incidents
5. **Scalable**: Works with 1000+ jobs without complexity growth

## Maintenance

### Adding New Jobs
1. Add job name to `experimental` list in `job_tiers`
2. Create job module with tier-based count logic
3. Test in staging
4. Move from `experimental` to `stable` list when ready
5. Deploy to production

### Emergency Procedures
```hcl
# Disable all parking jobs due to data source issue
department_overrides = {
  parking = {
    enabled = false
  }
}
```

### Monitoring
- Track deployment success rates by tier
- Monitor job execution in each environment
- Alert on failed deployments or missing expected jobs