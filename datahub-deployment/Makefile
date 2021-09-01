.PHONY: $(MAKECMDGOALS)

generate-kubeconfig-file:
	aws-vault exec hackney-dataplatform-staging -- aws eks --region eu-west-2 update-kubeconfig --name stg-datahub

get-all:
	aws-vault exec hackney-dataplatform-staging -- kubectl get all --kubeconfig ./kubeconfig

upgrade-datahub-release:
	aws-vault exec hackney-dataplatform-staging -- helm upgrade --install datahub datahub/datahub --values ./values.yaml --kubeconfig ./kubeconfig

datahub-release-history:
	aws-vault exec hackney-dataplatform-staging -- helm history datahub --kubeconfig ./kubeconfig

pull-datahub-repository:
	aws-vault exec hackney-dataplatform-staging -- helm repo add datahub https://helm.datahubproject.io/

datahub-source:
	git clone git@github.com:linkedin/datahub.git datahub-source
