import configschemas

_externalResourceName = lambda prefix: str, cfg: configschemas.ConfigSchema -> str {
    name = "{}-{}".format(prefix, cfg.id)
    name
}
