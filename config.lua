-- Auto-detect hostname so the same repo can serve multiple machines.
-- Falls back to "default" if no host/<hostname>.lua exists.
---@diagnostic disable: undefined-global -- dcli globals are provided by dcli runtime

local hostname = dcli.system.hostname()
dcli.log.info("Auto-detected host: " .. hostname)

local host_path = dcli.env.config_dir() .. "/arch-config/hosts/" .. hostname .. ".lua"
local effective = dcli.file.is_file(host_path) and hostname or "default"

if effective == "default" then
    dcli.log.warn("No host config for '" .. hostname .. "', using default configuration")
    dcli.log.warn("Create hosts/" .. hostname .. ".lua to customize for this system")
end

return {
    host = effective,
}
