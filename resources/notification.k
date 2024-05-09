import base64
import models
import ..utils
import .vault_references

_resource = lambda name: str -> any {
    option("params").ocds[name]?.Resource or None
}
_resourceSynced = lambda resource: any -> bool {
    True if resource?.status?.atProvider?.id != None else False
}

_notificationHubNamespaceName = utils._internalResourceName("notificationhubnamespace", utils._config)
notificationHubNamespace = models.NotificationHubNamespace {
    metadata: {
        name: _notificationHubNamespaceName
        annotations: {
            "crossplane.io/external-name": utils._externalResourceName("nhns", utils._config)
        }
    }
    spec: {
        providerConfigRef: {
            name: utils._config.azureProviderConfigRef
        }
        forProvider: {
            resourceGroupNameSelector.matchControllerRef = True
            location: utils._config.location
            enabled: utils._config.enabled
            namespaceType: "NotificationHub"
            skuName: utils._config.sku
        }
    }        
}

_hubInternalName = lambda hubName: str -> str {
    utils._internalResourceName("notificationhub-{}".format(hubName), utils._config)    
}
_hubExternalName = lambda hubName: str -> str {
    utils._externalResourceName("nh-{}".format(hubName), utils._config)
}

_hubAuthRuleInternalName = lambda hubName: str -> str {
    utils._internalResourceName("notificationhubauthorizationrule-{}".format(hubName), utils._config)    
}
_hubAuthRuleExternalName = lambda hubName: str -> str {
    utils._externalResourceName("nhar-{}".format(hubName), utils._config)
}
_hubAuthRuleSecretInternalName = lambda hubName: str -> str {
    utils._internalResourceName("notificationhubauthorizationrulesecret-{}".format(hubName), utils._config)    
}
_hubAuthRulePushSecretInternalName = lambda hubName: str -> str {
    utils._internalResourceName("notificationhubauthorizationrulepushsecret-{}".format(hubName), utils._config)    
}
_resource = lambda name: str -> any {
    option("params").ocds[name]?.Resource or None
}

_notificationHub = lambda hub: utils.NotificationHubConfig -> models.NotificationHub {
    models.NotificationHub {
        metadata: {
            name: _hubInternalName(hub.name)
            annotations: {
                "crossplane.io/external-name": _hubExternalName(hub.name)
            }
        }
        spec: {
            providerConfigRef: {
                name: utils._config.azureProviderConfigRef
            }
            forProvider: {
                resourceGroupNameSelector.matchControllerRef = True
                namespaceNameSelector.matchControllerRef = True
                location: utils._config.location
                if hub.gcmCredentialSecretKeyRef != None:
                    gcmCredential: [{
                        apiKeySecretRef: {
                            key: hub.gcmCredentialSecretKeyRef.key
                            name: hub.gcmCredentialSecretKeyRef.name
                            namespace: utils._config.claimNamespace
                        }
                    }]
            }
        }        
    }

}
notificationHubs = [_notificationHub(hub) for hub in utils._config.notificationHubs]

_authRule = lambda hub: utils.NotificationHubConfig -> models.AuthorizationRule {
    models.AuthorizationRule {
        metadata: {
            name: _hubAuthRuleInternalName(hub.name)
            annotations: {
                "crossplane.io/external-name": _hubAuthRuleExternalName(hub.name)
            }
        }
        spec: {
            deletionPolicy: "Orphan"
            providerConfigRef: {
                name: utils._config.azureProviderConfigRef
            }
            forProvider: {
                resourceGroupNameSelector.matchControllerRef = True
                namespaceNameSelector.matchControllerRef = True
                notificationHubNameRef.name = _hubInternalName(hub.name)
                listen: True
                send: True
                manage: True
            }
        }        
    }
}

notificationHubAuthorizationRules = [
    _authRule(hub) for hub in utils._config.notificationHubs \
    if _resourceSynced(_resource(_hubInternalName(hub.name)))
]

_hubConnectionString = lambda hubName: str -> str {
    servicebusEndpoint = _resource(_notificationHubNamespaceName)?.status?.atProvider?.servicebusEndpoint
    primaryAccessKey = _resource(_hubAuthRuleInternalName(hubName))?.status?.atProvider?.primaryAccessKey or None
    if servicebusEndpoint == None or primaryAccessKey == None:
        connectionString = None
    else:
        connectionString = "Endpoint=${servicebusEndpoint};SharedAccessKeyName=${_hubAuthRuleExternalName(hubName)};SharedAccessKey=${primaryAccessKey}"

    connectionString
}

_connectionSecretObject = lambda hub: utils.NotificationHubConfig -> models.Object {
    models.Object {
        metadata: {
            name: _hubAuthRuleSecretInternalName(hub.name)
        }
        spec: {
            providerConfigRef: {
                name: utils._config.clusterProviderConfigRef
            }
            forProvider: {
                manifest: {
                    apiVersion: "v1"
                    kind: "Secret"
                    metadata: {
                        name:  "{}-secret".format(utils._externalResourceName("nh-{}".format(hub.name), utils._config))
                        namespace: "crossplane-system"
                    }
                    if _hubConnectionString(hub.name) != None:
                        data: {
                            name: base64.encode(hub.name)
                            hubName: base64.encode(_hubExternalName(hub.name))
                            hubConnectionString: base64.encode(_hubConnectionString(hub.name))
                        }
                    else:
                        data: {}
                }
            }
        }        
    }
}

connectionSecrets = [
    _connectionSecretObject(hub) for hub in utils._config.notificationHubs \
    if _resourceSynced(_resource(_hubInternalName(hub.name)))
]

secretStoreNames = vault_references.vaultSecretStoreNames

_pushSecretObject = lambda pushSecret: utils.PushSecretConfig -> models.Object {
    models.Object {
        metadata: {
            name: _hubAuthRulePushSecretInternalName(pushSecret.name)
            annotations: {
                "secretStoreName": "{}".format(",".join(map s in secretStoreNames { s.name }))
            }
        }
        spec: {
            providerConfigRef: {
                name: utils._config.clusterProviderConfigRef
            }
            forProvider: {
                manifest: {
                    apiVersion: "external-secrets.io/v1alpha1"
                    kind: "PushSecret"
                    metadata: {
                        name:  "{}-pushsecret".format(utils._externalResourceName("nh-{}".format(pushSecret.name), utils._config))
                        namespace: "crossplane-system"
                    }
                    spec: {
                        if (len(secretStoreNames) > 0 and len(filter s in secretStoreNames { s.name == pushSecret.vaultSecretRefName }) == 1):
                            secretStoreRefs: [{
                                kind: "ClusterSecretStore"
                                name: filter s in secretStoreNames { s.name == pushSecret.vaultSecretRefName }[0].secretStoreName
                            }]
                        selector: {
                            secret: {
                                name: "{}-secret".format(utils._externalResourceName("nh-{}".format(pushSecret.name), utils._config))
                            }
                        }
                        data: [
                            if pushSecret.nameToKey != None:
                                {
                                    conversionStrategy: "None"
                                    match: {
                                        secretKey: "name"
                                        remoteRef: {
                                            remoteKey: pushSecret.nameToKey
                                        }
                                    }
                                }
                            {
                                conversionStrategy: "None"
                                match: {
                                    secretKey: "hubName"
                                    remoteRef: {
                                        remoteKey: pushSecret.hubNameToKey
                                    }
                                }
                            },
                            {
                                conversionStrategy: "None"
                                match: {
                                    secretKey: "hubConnectionString"
                                    remoteRef: {
                                        remoteKey: pushSecret.hubConnectionStringToKey
                                    }
                                }
                            }
                        ]
                    }
                }
            }
        }        
    }
}

pushSecrets = [
    _pushSecretObject(pushSecret) for pushSecret in utils._config.pushSecrets \
    if _resourceSynced(_resource(_hubInternalName(pushSecret.name)))
]



# oxr = option("params").oxr
# dxr = {
#     **oxr
#     status.identityPrincipalId = _principalId or ""
# }

# identity = {
#     id          = mapsAccountIdentityId
#     clientId    = mapsAccountClientId
# }

details = {
    apiVersion: "meta.krm.kcl.dev/v1alpha1"
    kind: "CompositeConnectionDetails"
    # if mapsAccountClientId != None:
    #     data: {
    #         identity = base64.encode(json.encode(identity))
    #     }
    # else:
        data: {}
}

notificationResources = [
    notificationHubNamespace,
    *notificationHubs,
    *notificationHubAuthorizationRules,
    *connectionSecrets,
    *pushSecrets,
    *vault_references.vaultSecrets
    details
]