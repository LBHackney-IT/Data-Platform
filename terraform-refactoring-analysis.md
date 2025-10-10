# Terraform Refactoring Analysis - Data Platform

## Executive Summary

Analysis of the Data Platform Terraform codebase reveals extensive use of `count` parameters for conditional resource deployment (376 usages across 97 files). The current architecture uses workspace-based environment detection to support multi-tenant development environments while maintaining separate AWS accounts for staging and production.

## Current Architecture

### Workspace Strategy
- `workspace == "default"` = Live environments (prod/stg) with dedicated AWS accounts
- `workspace == "developer-name"` = Individual dev environments in shared dev AWS account
- `count` used to prevent expensive/shared resources in dev workspaces

### Environment Detection
```hcl
# terraform/core/03-input-derived.tf
is_live_environment = terraform.workspace == "default" ? true : false
is_production_environment = var.environment == "prod"
```

### Current Deployment Pipeline
```
plans → stg → prod
```
Linear pipeline where all resources must pass through each stage sequentially.

## Key Findings

### Scale Challenge
- **114 Glue jobs** in production
- **376 count usages** across codebase
- **97 files** using conditional deployment logic

### Deployment Problems
1. **Two-step deployment issue**: Must add `count = var.environment == "stg" ? 1 : 0` for staging, then change to `count = local.is_live_environment ? 1 : 0` for production
2. **Tight coupling**: Single failure in staging blocks all production deployments
3. **No independent deployments**: Can't deploy stable jobs to prod while experimental jobs test in staging
4. **Hotfix bottlenecks**: Critical fixes must go through full pipeline

### Architecture Assessment
The current workspace-based approach is **architecturally sound** for multi-tenant development but creates operational challenges for staged deployments.

## Recommendations

### Primary Recommendation: Deployment Tiers + Parallel Pipelines

#### 1. Replace Individual Feature Flags with Deployment Tiers

**Instead of 114 individual flags:**
```hcl
# BAD: Unmanageable with 114 jobs
feature_flags = {
  enable_job_1 = true
  enable_job_2 = false
  # ... 112 more flags
}
```

**Use deployment tiers:**
```hcl
# terraform/config/stg.tfvars
deployment_tier = "experimental"  # Deploy all jobs for testing

# terraform/config/prod.tfvars  
deployment_tier = "stable"        # Deploy only proven jobs
```

#### 2. Tag Jobs by Stability in Code

```hcl
# terraform/etl/03-input-derived.tf
locals {
  job_tiers = {
    stable = [
      "Cash_Collection_Date",        # Proven in production
      "Cedar_Backing_Data",          # Proven in production
      # ... 110+ other stable jobs
    ]
    
    experimental = [
      "new_parking_analytics",       # Testing phase
      "advanced_ml_predictions",     # Testing phase
      # ... new jobs being tested
    ]
  }
  
  enabled_jobs = var.deployment_tier == "stable" ? 
    local.job_tiers.stable : 
    concat(local.job_tiers.stable, local.job_tiers.experimental)
}
```

#### 3. Implement Parallel Pipelines

```
┌─ Stable Pipeline ────┐    ┌─ Experimental Pipeline ─┐
│ plans → stg → prod   │    │ plans → stg             │
│ (stable jobs only)   │    │ (experimental jobs)     │
└─────────────────────┘    └─────────────────────────┘
```

**Benefits:**
- Stable jobs deploy independently of experimental jobs
- Experimental jobs can't block production deployments
- Hotfixes can bypass experimental testing
- Maintains current dev workspace model
- Scales to 1000+ jobs without complexity growth

### Implementation Approach

#### Phase 1: Add Deployment Tier Infrastructure (1 week)
1. Add `deployment_tier` variable to input files
2. Create job tier definitions in locals
3. Update tfvars files with tier specifications

#### Phase 2: Migrate High-Impact Resources (1 week)  
1. Start with expensive resources (MWAA, Redshift, DataHub)
2. Replace `count = local.is_live_environment ? 1 : 0` with tier-based logic
3. Test thoroughly in staging

#### Phase 3: Implement Parallel Pipelines (1 week)
1. Create separate CI/CD workflows for stable vs experimental
2. Add deployment gates and approvals
3. Update documentation and runbooks

## Alternative Approaches Considered

### Option 1: Full Refactor to Remove Count
- **Effort**: 7-11 weeks
- **Risk**: High (state migrations, cross-module dependencies)
- **Benefit**: Standard Terraform practices
- **Verdict**: Not recommended due to high risk and effort

### Option 2: Individual Feature Flags
- **Effort**: 1-2 weeks  
- **Risk**: Low
- **Problem**: Unmanageable with 114+ jobs
- **Verdict**: Not scalable

### Option 3: Git Branch Model (stg/prod branches)
- **Problems**: 
  - Terraform state conflicts
  - Dev workspace chaos
  - Constant merge conflicts
  - Hotfix complications
- **Verdict**: Not compatible with current architecture

## Deployment Workflow Example

### Current Problem
```bash
# Step 1: Add staging-only deployment
count = var.environment == "stg" ? 1 : 0

# Step 2: Change for production deployment  
count = local.is_live_environment ? 1 : 0
```

### Recommended Solution
```bash
# Single deployment - no code changes between environments
# Job automatically tagged as "experimental" in code

# Deploy to staging (gets experimental jobs)
terraform apply -var-file="config/stg.tfvars"

# Test and validate in staging

# Move job from experimental to stable list in code
# Deploy to production (now gets the job)
terraform apply -var-file="config/prod.tfvars"
```

## Conclusion

The current architecture is sound for development multi-tenancy but needs deployment decoupling. The recommended deployment tier approach provides:

- **Operational simplicity**: 2 variables instead of 114
- **Clear promotion path**: experimental → stable  
- **Emergency controls**: Department-level overrides
- **Scalability**: Works with 1000+ jobs
- **Risk mitigation**: Preserves current workspace benefits

**Total Implementation Effort**: 3 weeks
**Risk Level**: Low to Medium
**Business Impact**: Significantly improved deployment velocity and reliability