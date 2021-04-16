
Example Init
`terraform init -backend-config="profile=hackney-dataplatform-staging"`

Example Plan
`terraform plan -var-file="../config/terraform/Stg.tfvars"`

Example Apply
`terraform apply -var-file="../config/terraform/Stg.tfvars"`

Example Destory
`terraform destroy -var-file="../config/terraform/Stg.tfvars"`