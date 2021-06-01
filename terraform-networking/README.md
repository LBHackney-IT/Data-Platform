## Networking
This project deploys networking for the Data Platform accounts. Unless you intend to modify the network configuration
you should not need to make changes to these files or run them. For a complete description of this process please
see the main README.md file.

## State Management
The state for the network infrastructure is stored alongside the main module state but is not directly related. For
development the state is stored in the default workspace rather than individual engineer workspaces.

## Terraform commands

After running, you can run `make plan`, `make apply` and `make destroy` to run the Terraform deploy/destroy commands with the development `env.tfvars` set for you.
