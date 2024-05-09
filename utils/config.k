schema Config:
    id: str
    claimName: str
    claimNamespace: str
    azureProviderConfigRef: str
    clusterProviderConfigRef: str
    resourceGroupName?: str
    location?: str
    enabled: bool
    sku: str
    notificationHubs: [NotificationHubConfig]
    pushSecrets: [PushSecretConfig]

schema NotificationHubConfig:
    name: str
    gcmCredentialSecretKeyRef?: SecretKeyRef = None

schema PushSecretConfig:
    name: str
    vaultSecretRefName: str
    nameToKey?: str = None
    hubNameToKey: str
    hubConnectionStringToKey: str

schema SecretKeyRef:
    key?: str = None
    name: str
    namespace?: str = None

_config: Config {
    id: option("params")?.oxr?.spec?.id or "test"
    claimName: option("params")?.oxr?.metadata?.labels?["crossplane.io/claim-name"] or ""
    claimNamespace: option("params")?.oxr?.metadata?.labels?["crossplane.io/claim-namespace"] or "default"
    azureProviderConfigRef: option("params")?.oxr?.spec?.parameters?.azureProviderConfigRef or "workload-identity-provider-config"
    clusterProviderConfigRef: option("params")?.oxr?.spec?.parameters?.clusterProviderConfigRef or "local-cluster-provider-config"
    resourceGroupName: option("params")?.oxr?.spec?.parameters?.resourceGroupName or None
    location: option("params")?.oxr?.spec?.parameters?.location or "australiaeast"
    enabled: option("params")?.oxr?.spec?.parameters?.enabled
    sku: option("params")?.oxr?.spec?.parameters?.sku or "Free"
    notificationHubs: option("params")?.oxr?.spec?.parameters?.notificationHubs or []
    pushSecrets: option("params")?.oxr?.spec?.parameters?.pushSecrets or []
}
