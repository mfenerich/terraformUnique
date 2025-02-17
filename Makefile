# Include variables from .env if available
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

# Construct the full ACR image reference (strip any extra spaces)
ACR_IMAGE := $(strip $(ACR_REGISTRY))/$(strip $(IMAGE_NAME)):$(strip $(IMAGE_TAG))

.PHONY: build tag login push deploy destroy all

build:
	@echo "Building Docker image '$(strip $(IMAGE_NAME))' from Dockerfile at '$(strip $(APP_PATH))/Dockerfile'..."
	docker buildx build --platform linux/amd64 --load -t $(strip $(IMAGE_NAME)) -f $(strip $(APP_PATH))/Dockerfile $(strip $(APP_PATH))

tag:
	@echo "Tagging image '$(strip $(IMAGE_NAME))' as '$(ACR_IMAGE)'..."
	docker tag $(strip $(IMAGE_NAME)) $(ACR_IMAGE)

login:
	@echo "Logging in to ACR '$(strip $(ACR_NAME))'..."
	az acr login --name $(strip $(ACR_NAME))

push: login
	@echo "Pushing image '$(ACR_IMAGE)' to ACR..."
	docker push $(ACR_IMAGE)

aks-login:
	@echo "Logging in to AKS cluster '$(strip $(AKS_CLUSTER_NAME))'..."
	az aks get-credentials --resource-group $(strip $(AKS_RESOURCE_GROUP)) --name $(strip $(AKS_CLUSTER_NAME)) --overwrite-existing

deploy:
	@echo "Deploying Helm chart '$(strip $(HELM_RELEASE))' with storage account details..."
	helm upgrade --install $(strip $(HELM_RELEASE)) $(strip $(HELM_CHART_PATH)) \
	  --namespace default \
	  --set storageAccountName="$(strip $(STORAGE_ACCOUNT_NAME))" \
	  --set storageAccountKey="$(strip $(STORAGE_ACCOUNT_KEY))"

destroy:
	@echo "Destroying Helm release '$(strip $(HELM_RELEASE))'..."
	helm uninstall $(strip $(HELM_RELEASE))

all: build tag push deploy
