# Deployment Examples and Workflows

## Current vs Improved Deployment Workflows

### Current Problem: Two-Step Deployment

**Scenario**: Adding a new Glue job for parking analytics

**Step 1**: Deploy to staging only
```hcl
# Must modify code for staging-only deployment
module "new_parking_analytics" {
  count = var.environment == "stg" ? 1 : 0  # ← Staging-specific code
  source = "../modules/import-spreadsheet-file-from-g-drive"
  # ... configuration
}
```

**Step 2**: Modify code again for production
```hcl
# Must change code again for production deployment
module "new_parking_analytics" {
  count = local.is_live_environment ? 1 : 0  # ← Changed for prod
  source = "../modules/import-spreadsheet-file-from-g-drive"
  # ... configuration
}
```

**Problems:**
- Requires two code changes
- Risk of errors between environments
- Blocks other deployments during testing
- Manual process prone to mistakes

### Improved: Single Code, Tier-Based Deployment

**One-time code change:**
```hcl
# Add to experimental tier list
locals {
  job_tiers = {
    stable = [
      "Cash_Collection_Date",
      # ... existing jobs
    ]
    experimental = [
      "new_parking_analytics",  # ← Add once, controls deployment
    ]
  }
}

# Job definition (never changes)
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

**Deployment workflow:**
```bash
# Deploy to staging (gets experimental jobs)
terraform apply -var-file="config/stg.tfvars"

# Test and validate...

# Promote to production by moving in tier list
# (Move "new_parking_analytics" from experimental to stable)

# Deploy to production (now gets the job)
terraform apply -var-file="config/prod.tfvars"
```

## Real-World Scenarios

### Scenario 1: New ML-Based Parking Predictions

**Week 1**: Developer adds new experimental job
```hcl
locals {
  job_tiers = {
    stable = [
      "Cash_Collection_Date",
      "Cedar_Backing_Data",
      # ... 110+ existing stable jobs
    ]
    experimental = [
      "ml_parking_predictions",  # ← New job added
    ]
  }
}
```

**Week 2-4**: Testing in staging
- Job runs daily in staging environment
- Data scientists validate prediction accuracy
- Performance team checks resource usage
- Business stakeholders review outputs

**Week 5**: Promotion to production
```hcl
locals {
  job_tiers = {
    stable = [
      "Cash_Collection_Date",
      "Cedar_Backing_Data",
      "ml_parking_predictions",  # ← Moved from experimental
      # ... other stable jobs
    ]
    experimental = [
      # Job removed from experimental
    ]
  }
}
```

### Scenario 2: Emergency Department Shutdown

**Problem**: Housing data source has corruption, need to disable all housing jobs immediately

**Current approach**: Would require modifying dozens of job definitions

**Improved approach**: Single tfvars change
```hcl
# terraform/config/prod.tfvars
department_overrides = {
  housing = {
    enabled = false  # ← Disables ALL housing jobs instantly
  }
  parking = {
    enabled = true   # ← Other departments unaffected
  }
}
```

**Deploy emergency fix:**
```bash
terraform apply -var-file="config/prod.tfvars"
# All housing jobs disabled in ~5 minutes
```

### Scenario 3: Hotfix for Critical Stable Job

**Problem**: Critical bug in `Cedar_Parking_Payments` job affecting revenue reporting

**Current approach**: Must wait for all experimental jobs to pass staging tests

**Improved approach**: Independent stable pipeline
```bash
# Fix applied to stable job
# Stable pipeline deploys independently
terraform apply -var-file="config/stg.tfvars" -var="deployment_tier=stable"
# Test stable jobs only

terraform apply -var-file="config/prod.tfvars" -var="deployment_tier=stable"  
# Deploy fix to production immediately
```

**Experimental jobs continue testing separately without blocking the hotfix**

### Scenario 4: Gradual Rollout of New Department

**Scenario**: Adding new "Environmental Services" department with 15 new jobs

**Phase 1**: Add all as experimental
```hcl
locals {
  job_tiers = {
    stable = [
      # ... existing stable jobs
    ]
    experimental = [
      "env_waste_collection_analytics",
      "env_recycling_predictions", 
      "env_carbon_footprint_tracking",
      # ... 12 more environmental jobs
    ]
  }
}
```

**Phase 2**: Promote proven jobs gradually
```hcl
locals {
  job_tiers = {
    stable = [
      # ... existing stable jobs
      "env_waste_collection_analytics",  # ← Proven, moved to stable
      "env_recycling_predictions",       # ← Proven, moved to stable
    ]
    experimental = [
      "env_carbon_footprint_tracking",   # ← Still testing
      # ... remaining experimental jobs
    ]
  }
}
```

## Deployment Commands Reference

### Standard Deployments

**Deploy all jobs to staging (for testing):**
```bash
cd terraform/core
terraform workspace select default
terraform apply -var-file="../config/stg.tfvars"
```

**Deploy stable jobs to production:**
```bash
cd terraform/core  
terraform workspace select default
terraform apply -var-file="../config/prod.tfvars"
```

### Tier-Specific Deployments

**Deploy only stable jobs to staging (for hotfix testing):**
```bash
terraform apply -var-file="../config/stg.tfvars" -var="deployment_tier=stable"
```

**Deploy experimental jobs to staging (for new feature testing):**
```bash
terraform apply -var-file="../config/stg.tfvars" -var="deployment_tier=experimental"
```

### Emergency Procedures

**Disable department in production:**
```bash
# Update prod.tfvars with department override
terraform apply -var-file="../config/prod.tfvars"
```

**Quick rollback to previous stable state:**
```bash
git checkout HEAD~1 -- terraform/etl/03-input-derived.tf
terraform apply -var-file="../config/prod.tfvars"
```

## CI/CD Integration Examples

### GitHub Actions Workflow Triggers

**Stable job changes trigger production pipeline:**
```yaml
on:
  push:
    branches: [main]
    paths: 
      - 'terraform/**'
  pull_request:
    paths:
      - 'terraform/**'

jobs:
  detect-changes:
    outputs:
      stable-changed: ${{ steps.changes.outputs.stable }}
      experimental-changed: ${{ steps.changes.outputs.experimental }}
    steps:
      - uses: dorny/paths-filter@v2
        id: changes
        with:
          filters: |
            stable:
              - 'terraform/etl/03-input-derived.tf'
            experimental:
              - 'terraform/etl/**'
  
  deploy-stable:
    needs: detect-changes
    if: needs.detect-changes.outputs.stable-changed == 'true'
    # ... deploy stable jobs to both stg and prod
    
  deploy-experimental:
    needs: detect-changes  
    if: needs.detect-changes.outputs.experimental-changed == 'true'
    # ... deploy experimental jobs to stg only
```

### Slack Integration for Deployment Notifications

```yaml
- name: Notify deployment success
  if: success()
  uses: 8398a7/action-slack@v3
  with:
    status: success
    text: |
      ✅ Stable jobs deployed to production
      Jobs: ${{ env.DEPLOYED_JOBS }}
      Deployment tier: ${{ env.DEPLOYMENT_TIER }}
```

## Monitoring and Validation

### Post-Deployment Checks

**Verify expected jobs are running:**
```bash
# Check Glue jobs in staging
aws glue get-jobs --query 'Jobs[?contains(Name, `stg`)].Name' --output table

# Check Glue jobs in production  
aws glue get-jobs --query 'Jobs[?contains(Name, `prod`)].Name' --output table
```

**Validate job counts match expectations:**
```bash
# Count stable jobs
terraform show -json | jq '.values.root_module.resources[] | select(.type=="aws_glue_job") | .values.name' | wc -l
```

### Alerting on Deployment Issues

**CloudWatch alarms for missing expected jobs:**
```hcl
resource "aws_cloudwatch_metric_alarm" "missing_critical_jobs" {
  alarm_name          = "missing-critical-glue-jobs"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "RunningJobs"
  namespace           = "AWS/Glue"
  period              = "300"
  statistic           = "Sum"
  threshold           = "110"  # Expected number of stable jobs
  alarm_description   = "Critical Glue jobs are missing"
}
```

This comprehensive approach provides clear workflows for common scenarios while maintaining the flexibility needed for a large-scale data platform.