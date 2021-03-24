# Tags

## Overview
This module ensures your AWS resources follow the Hackney standard for tags.

## Usage
Declare the module and provide the required inputs and optional inputs as needed:
``` terraform
module "tags" {
  source = "../../modules/audit/tags"
  environment = var.your_environment_variable
  department  = var.your_department_variable
  application = var.your_application_variable
  team        = var.your_team_variable
}
```

There is a `custom_tags` variable exposed to allow you add any additional custom tags that you might wish to assign for your project specific purpose. This can be used as follows:
``` terraform
module "tags" {
  source = "../../modules/audit/tags"
  environment = var.your_environment_variable
  department  = var.your_department_variable
  application = var.your_application_variable
  team        = var.your_team_variable
  custom_tags = map("custom_tag1", "my_custom_value1",
                    "custom_tag2", "my_custom_value2")
}
```

When declaring AWS resources, use the module output for the tag values:
``` terraform
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags       = module.tags.values
}
```
If you wish to ignore any `custom_tags` on any specific resources, you can use `module.tags.values_no_custom` instead of `module.tags.values`

Validation is applied to the module variables to ensure they are consistent. Values cannot be a blank string, and must contain only lowercase alphabet (`a-z`), numeric (`0-9`) or underscore (`_`) characters. `null` is permitted for optional variables, in which case they will set to the default value.

If you need to add additional tags that are specific to an individual resource, say to provide a `Name` field, you can do the following:
``` terraform
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = merge(map("Name", "name_of_my_vpc"), module.tags.values)
}
```

### Required Module Variables
See `01-inputs-required.tf`

### Optional Module Variables
See `02-inputs-optional.tf`

### Module Output Variables
See `99-outputs.tf`
