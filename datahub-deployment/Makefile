.PHONY: $(MAKECMDGOALS)

generate-kubeconfig-file:
	aws-vault exec hackney-dataplatform-staging -- aws eks --region eu-west-2 update-kubeconfig --name stg-datahub

get-all:
	aws-vault exec hackney-dataplatform-staging -- kubectl get all --kubeconfig ./kubeconfig

upgrade-datahub-release:
	aws-vault exec hackney-dataplatform-staging -- helm upgrade --install datahub datahub/datahub --values ./values.yaml --kubeconfig ./kubeconfig