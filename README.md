# Hackney AWS Infrastructure

This repository contains all of the infrastructure-as-code for building the Hackney AWS environment. The structure is as follows:

- `/modules` contains re-usable Terraform modules for building AWS infrastructure in a Hackney way.
- `/platform` contains implementations of the Terraform modules that build shared/common AWS infrastructure such as VPCs.
- `/projects` contains implementations of the Terraform modules that build AWS infrastructure that is project specific.
- `/workflow-templates` contains GitHub Action templates that can be reused across other GitHub projects if required.
- `./github` contains the GitHub workflows used to deploy the Hackney AWS environments.


## Installation & Developer Setup

```bash
git clone git@github.com:LBHackney-IT/infrastructure.git
```

We recommend installing https://pre-commit.com/#install to allow you to do some additional validation before pushing. This will handle linting and validation of things like YAML, JSON, XML.

## Usage

TODO: Setting up TF with correct versions, running TF, testing TF etc

## Contributing
All changes must be made against a branch and merged via a pull request. Please see `./github` for information on creating a GitHub action to deploy your project to AWS.

Please make sure to update tests as appropriate.

## License
[MIT](https://choosealicense.com/licenses/mit/)
