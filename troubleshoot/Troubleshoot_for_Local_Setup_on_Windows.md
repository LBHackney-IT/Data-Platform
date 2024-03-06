**Pre-Install:**
The ReadMe commands are mostly based on the Linux system (Ubuntu or Mac). If you are using Windows, please install the following apps in advance:
- First, go to this website to install choco: [https://chocolatey.org/install](https://chocolatey.org/install)
- `choco install terraform --version=1.2.9` (not the latest 1.7.4 as it causes conflict with aws-tags-lbh.git)
- `choco install python --version=3.9.0`  # for creating a Python virtual environment
- `choco install make` # for executing the "make" command in Windows, ok to use the latest 4.4.1 version
- `choco install gcloudsdk` # for Google Cloud SDK (ok to use the latest 463.0.0 version)
- `choco install maven --version=3.6.3` # release 2019-11-25
- For Maven, if it is not recognised by the terminal, please add the path to the system environment variable: "C:\\ProgramData\\chocolatey\\lib\\maven\\apache-maven-3.9.6\\bin"

**Note:** For installation, you need to open PowerShell (or another terminal) as an administrator.

**Pre-replace:**
1. Replace the Makefile in the root directory with the Makefile in the "troubleshoot" folder.
2. Replace the "package-helpers.sh" file in the scripts folder with the "package-helpers.bat" file in the "troubleshoot" folder.
3. `env.tfvars` file:
    - Instead of creating an `env.tfvars` file following the doc, you need to talk to "Wayne" to get the `env.tfvars` file.
    - After you have the file from Wayne, you need to change:
        a) `email_to_notify` to your own address
        b) `rentsense_target_path` to your own path

**Pre-check:**
1. Make sure you have the "google_service_account_creds.json" file in the root directory.
- Option (1)  `gcloud auth application-default login && copy C:\Users\{PC_username}\AppData\Roaming\gcloud\application_default_credentials.json D:\test\Data-Platform\google_service_account_creds.json /y` Replace the destination {D:\test\} with your root directory of the Data-Platform folder.
- Option (2) `gcloud auth application-default login; if ($?) { Copy-Item -Path 'C:\Users\{PC_username}\AppData\Roaming\gcloud\application_default_credentials.json' -Destination 'C:\Users\{PC_username}\Data-Platform\google_service_account_creds.json' -Force }` the desination is your root directory of the Data-Platform folder.

2. Make sure Pre-replace has been done.

Then, it's all good, you can `make init` and `make plan` in the root folder.

**Error:**
1. Provider configuration not present: If you encounter VPC issues, make sure to initialise your workspace and select your workspace.
- `aws-vault exec hackney-dataplatform-development -- terraform workspace new "{your_first_name}"`
- `aws-vault exec hackney-dataplatform-development -- terraform workspace select "{your_first_name}"`
