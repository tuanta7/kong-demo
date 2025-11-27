local plugin = {
    PRIORITY = 1000,
    VERSION = "1.0.0"
}

function plugin:init_worker()
    kong.log.debug("saying hi from the 'init_worker' handler")
end

function plugin:access(conf)
    kong.log.debug("saying hi from the 'access' handler")
    kong.log.info(conf.key)
end

return plugin
