import ..models
import base64
import json

# AzureCAF naming: // https://github.com/aztfmod/terraform-provider-azurecaf/blob/main/resourceDefinition.json

_externalResourceName = lambda prefix: str, cfg: Config, trimChars: bool = False -> str {
    name = "{}-{}-{}".format(prefix, cfg.claimNamespace, cfg.id).lower()
    result = name if trimChars == False else name.replace("-", "")
    result
}

_internalResourceName = lambda resourceType: str, cfg: Config -> str {
    name = "{}-{}-{}".format(cfg.id, cfg.claimNamespace, resourceType).lower().replace("_", "")
    name
}

_removeDuplicates = lambda items: [str] -> [str] {
    [item for item in {item = None for item in items}]
}

_observableSecret = lambda name: str, secretName: str, secretNamespace: str, cfg: Config -> models.Object {
    models.Object {
        metadata: {
            name: name
        }
        spec: {
            managementPolicies: ["Observe"]
            providerConfigRef: {
                name: cfg.clusterProviderConfigRef
            }
            forProvider: {
                manifest: {
                    apiVersion: "v1"
                    kind: "Secret"
                    metadata: {
                        name:  secretName
                        namespace: secretNamespace
                    }
                }
            }
        }        
    }
}

_observableSecretPropertyValue = lambda name: str, propertyName: str -> str {
    resource = option("params")?.ocds[name]?.Resource
    data = resource?.status?.atProvider?.manifest?.data
    propertyValue = data?[propertyName] or None
    decoded = base64.decode(propertyValue) if propertyValue != None else None
    decoded
}

_jsonDecode = lambda data: str -> any {
    if data != None and data != "":
        result = json.decode(data)
    else:
        result = None

    result
}

