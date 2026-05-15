---@diagnostic disable: undefined-global -- dcli globals are provided by dcli runtime

local packages = {
    "docker",
    "docker-compose",
    "containerd",
}

-- NVIDIA container passthrough is only meaningful with an NVIDIA GPU.
if dcli.hardware.has_nvidia() then
    table.insert(packages, "nvidia-container-toolkit")
    table.insert(packages, "nvidia-docker-compose")
end

return {
    description = "Container runtimes and tooling (Docker + containerd, NVIDIA passthrough when applicable)",
    packages = packages,
}
