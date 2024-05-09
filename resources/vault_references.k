import ..utils


# Secret references
vaultSecretRefNames = map c in utils._config.pushSecrets { c.vaultSecretRefName }
vaultSecretRefNamesUnique = utils._removeDuplicates(vaultSecretRefNames)

vaultSecretRefInternalName = lambda name: str -> str {
    utils._internalResourceName("vault-secretref-{}-{}".format(name, utils._config.claimNamespace), utils._config)
}

vaultSecrets = map name in vaultSecretRefNamesUnique {
    utils._observableSecret( \
        vaultSecretRefInternalName(name), \
        name, \
        utils._config.claimNamespace, \
        utils._config)
}

_vaultSecretStoreNameMapToObject = lambda name: str -> any {
    _secretStoreName = utils._observableSecretPropertyValue(vaultSecretRefInternalName(name), "secretStoreName")
    _result = None
    if _secretStoreName != None:
        _result = {
            name: name
            secretStoreName: _secretStoreName
        }
    _result
}

vaultSecretStoreNames = [v for _, v in map name in vaultSecretRefNamesUnique { _vaultSecretStoreNameMapToObject(name) } if v != None]
