import models
import ..utils

resourceGroup = models.ResourceGroup {
    metadata: {
        name: utils._internalResourceName("resourcegroup", utils._config)
        annotations: {
            "crossplane.io/external-name": utils._externalResourceName("rg", utils._config)
        }
    }
    spec: {
        providerConfigRef: {
            name: utils._config.azureProviderConfigRef
        }
        forProvider: {
            location: utils._config.location
        }
    }
} if utils._config.resourceGroupName == None else None
