# Terraform Backend Setup

This project is used to deploy state storage buckets to AWS ensuring that they share the same tags and settings as the
project who's state they manage.

Since this project deploys the backend s3 buckets, it cannot itself use a backend s3 bucket but since should only be
needed to deploy new environments or to rarely make changes to the bucket setup we have chosen to use local state
management which we will commit to the GitRepo.

Therefore, in order to differentiate environment states we have additionally choosen to use terraform workspaces.

Before applying changes, please ensure that you have switched to the correct workspace using:
`terraform workspace list`

If you are not using the correct workspace, switch to the correct one using:
`terraform workspace select <environment>`

If you need to create a new workspace use:
`terraform workspace new <environment>`