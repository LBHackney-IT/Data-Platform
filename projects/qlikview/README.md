# GitHub Repository Template

## About

This is a source code regarding the build of a QlikView Service, which is a Windows based service.

https://help.qlik.com/en-US/qlikview/April2020/Content/QV_HelpSites/System-requirements.htm

https://biconsult.ru/files/QlikView-in-the-Cloud.pdf


## Build/Setup

The environment is built using Infrastructure as Code utilising Terraform.  

Environment definitions : https://github.com/LBHackney-IT/infrastructure/tree/master/projects/qlikview/config/terraform

The CI/CD process is run via GitHub actions pipeline :  https://github.com/LBHackney-IT/infrastructure/blob/360516d17c67a288c12d31da2952cba61f8fe5e4/.github/workflows/project_qlikview_prod.yml

## Setting Up Git

To clone repo Localy : git@github.com:LBHackney-IT/infrastructure.git

To make changes to the QLik project :
    > cd projects/qlikview
 
To Check branch :
    > git branch

To View changes :
    > git status 
    
To commit a change :

    > git commit -a -m "CHANGE DETAIL"

To Push a change to the Repo :

    > git push 

## Branching

Protected branch is : Master

PR review process is implemented on branch : Master

## Git Secrets

Secrets used in Pipeline : https://github.com/LBHackney-IT/infrastructure/settings/secrets/actions

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
[MIT](https://choosealicense.com/licenses/mit/)
