-- ComfyUI installed via the AUR package. On NVIDIA hosts we also pull
-- python-pytorch-cuda so torch runs on the GPU instead of CPU.
---@diagnostic disable: undefined-global -- dcli globals are provided by dcli runtime

local packages = { "comfyui" }

if dcli.hardware.has_nvidia() then
    table.insert(packages, "python-pytorch-cuda")
end

return {
    description = "ComfyUI (Stable Diffusion) via AUR; pulls CUDA torch on NVIDIA hosts",
    packages = packages,
}
