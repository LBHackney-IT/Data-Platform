# Data Platform
Hackney Data Platform Infrastructure and Code

## Data Dictionary & Playbook

The Data Dictionary & Playbook can be found on the [Document Site](https://lbhackney-it.github.io/lbh-hackney-data-platform-docs/) and it's related [git repository](https://github.com/LBHackney-IT/lbh-hackney-data-platform-docs)

## Architecture Decision Records
We use Architecture Decision Records (ADRs) to document architecture decisions that we make. They can be found in
`documentation/architecture-decisions` and contributed to with [adr-tools](https://github.com/npryce/adr-tools).

### Hackney Infrastructure (Copy)
While in the initial phase of development, we have decided to manage our terraform in our own repository with the
future intention of potentially merging it into the infrastructure project in the future if there is relevant value add.

However, to ensure that we are using the shared modules contained in infrastructure we have used `git subtree` to include
the project code into this repository for reference.

To use the below commands, you will need to add the infrastructure repository as a remote:
`git remote add -f infrastructure git@github.com:LBHackney-IT/infrastructure.git`

Adding the repository for the first time:
`git subtree add --prefix infrastructure infrastructure master --squash`

To update the sub-project:
`git fetch infrastructure master; git subtree pull --prefix infrastructure infrastructure master --squash`
