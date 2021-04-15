# Platform DNS
[![Platform DNS (Mgmt)](https://github.com/LBHackney-IT/infrastructure/actions/workflows/platform_dns.yml/badge.svg)](https://github.com/LBHackney-IT/infrastructure/actions/workflows/platform_dns.yml)

This repository contains all of the infrastructure-as-code for public Route 53 DNS records:

- `/zones` contains Terraform modules for each of the public DNS zones hosted in AWS, including:
- `/zones/uk-example` contains an example zone that is not real/live, useful as a starting point for new zones.
- `/zones/uk-org-hackney` contains the configuration for the hackney.org.uk zone.

Please see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record for information on the supported DNS record types. To add a new zone, please update `10-zones.tf` to add a reference to your zone modules. Assuming you followed the same pattern as the example zone, this would simply be a case of:

```
module "uk_example_your" {
  source = "./zones/uk-example-your"
  tags   = module.tags.values
}
```
This will ensure your zone module is deployed.

## Making Changes

Please make all changes on a branch and raise pull request. Once merged, you can run https://github.com/LBHackney-IT/infrastructure/actions/workflows/platform_dns.yml to deploy.

Take care with changes, as typos etc could potentially lead to production outages!
