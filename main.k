import resources

# Compose all resource collections
_items = [
    *resources.mapsResources
]

# An empty resource variable means the object was not assigned due to not being ready yet.
# We must ensure the items only contains non-None resource variables.
items = [v for _, v in _items if v != None]