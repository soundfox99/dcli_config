-- Hardware Detection Module
-- Emits CPU microcode, GPU drivers/userland, laptop power tooling, and
-- vendor-specific packages based on what dcli detects at evaluation time.
-- Lets the same repo bootstrap any AMD/Intel/NVIDIA desktop or laptop.
---@diagnostic disable: undefined-global -- dcli globals are provided by dcli runtime

local hardware = {}

-- Probe whether the [multilib] repository is visible to pacman by checking a
-- canonical lib32 package. dcli's Lua sandbox blocks reading /etc/pacman.conf
-- directly, so this is the next-best signal. The pre_install_hook below
-- enables multilib if missing so this returns true after the first sync.
local function multilib_enabled()
    return dcli.package.is_available("lib32-mesa")
end

local function detect_chassis_vendor()
    local candidates = {
        "/sys/class/dmi/id/chassis_vendor",
        "/sys/class/dmi/id/board_vendor",
        "/sys/class/dmi/id/sys_vendor",
    }
    for _, path in ipairs(candidates) do
        if dcli.file.exists(path) then
            local value = dcli.file.read(path)
            if value and value ~= "" then
                return value:gsub("%s+$", "")
            end
        end
    end
    return "unknown"
end

function hardware.get_cpu_packages()
    local packages = {}
    local cpu = dcli.hardware.cpu_vendor()
    if cpu == "intel" then
        table.insert(packages, "intel-ucode")
    elseif cpu == "amd" then
        table.insert(packages, "amd-ucode")
    end
    return packages
end

function hardware.get_gpu_packages()
    local packages = {
        "mesa",
        "vulkan-icd-loader",
    }
    local has_multilib = multilib_enabled()
    local is_laptop = dcli.hardware.is_laptop()
    local is_desktop = dcli.hardware.chassis_type() == "desktop"

    if has_multilib then
        table.insert(packages, "lib32-vulkan-icd-loader")
    end

    if dcli.hardware.has_nvidia() then
        if is_desktop then
            table.insert(packages, "nvidia-open-dkms")
        elseif is_laptop then
            table.insert(packages, "nvidia-dkms")
            table.insert(packages, "nvidia-prime")
        end
        table.insert(packages, "nvidia-utils")
        table.insert(packages, "nvidia-settings")
        table.insert(packages, "opencl-nvidia")
        table.insert(packages, "libva-nvidia-driver")
        if has_multilib then
            table.insert(packages, "lib32-nvidia-utils")
            table.insert(packages, "lib32-opencl-nvidia")
        end
        -- CUDA stack is nvidia-only.
        table.insert(packages, "cuda")
        table.insert(packages, "cudnn")
    end

    if dcli.hardware.has_amd_gpu() then
        table.insert(packages, "vulkan-radeon")
        table.insert(packages, "libva-mesa-driver")
        table.insert(packages, "xf86-video-amdgpu")
        if has_multilib then
            table.insert(packages, "lib32-vulkan-radeon")
            table.insert(packages, "lib32-mesa")
        end
    end

    if dcli.hardware.has_intel_gpu() then
        table.insert(packages, "vulkan-intel")
        table.insert(packages, "intel-media-driver")
        table.insert(packages, "libva-intel-driver")
        if has_multilib then
            table.insert(packages, "lib32-vulkan-intel")
            table.insert(packages, "lib32-mesa")
        end
    end

    return packages
end

function hardware.get_laptop_packages()
    local packages = {}
    if dcli.hardware.is_laptop() or dcli.hardware.has_battery() then
        table.insert(packages, "tlp")
        table.insert(packages, "tlp-rdw")
        table.insert(packages, "powertop")
        table.insert(packages, "brightnessctl")
    end
    return packages
end

function hardware.get_services()
    local services = { enabled = {}, disabled = {} }
    if dcli.hardware.is_laptop() or dcli.hardware.has_battery() then
        table.insert(services.enabled, "tlp")
    end
    return services
end

function hardware.get_vendor_packages()
    local packages = {}
    local vendor = detect_chassis_vendor():lower()
    if vendor:find("asus") then
        table.insert(packages, "asusctl")
        table.insert(packages, "supergfxctl")
        table.insert(packages, "rog-control-center")
    end
    return packages
end

function hardware.get_all_packages()
    local packages = {}
    for _, pkg in ipairs(hardware.get_cpu_packages()) do
        table.insert(packages, pkg)
    end
    for _, pkg in ipairs(hardware.get_gpu_packages()) do
        table.insert(packages, pkg)
    end
    for _, pkg in ipairs(hardware.get_laptop_packages()) do
        table.insert(packages, pkg)
    end
    for _, pkg in ipairs(hardware.get_vendor_packages()) do
        table.insert(packages, pkg)
    end
    -- Firmware: always installed
    table.insert(packages, "linux-firmware")
    table.insert(packages, "sof-firmware")
    return packages
end

function hardware.get_metadata()
    return {
        cpu = dcli.hardware.cpu_vendor(),
        gpus = dcli.hardware.gpu_vendors(),
        is_laptop = dcli.hardware.is_laptop(),
        has_battery = dcli.hardware.has_battery(),
        chassis = dcli.hardware.chassis_type(),
        chassis_vendor = detect_chassis_vendor(),
        multilib_enabled = multilib_enabled(),
        hostname = dcli.system.hostname(),
    }
end

return {
    description = "Auto-detected hardware configuration for " .. dcli.system.hostname(),
    packages = hardware.get_all_packages(),
    services = hardware.get_services(),
    metadata = hardware.get_metadata(),

    -- Enable [multilib] in /etc/pacman.conf if missing, so subsequent module
    -- installs can pull lib32-* GPU/userland packages on the same sync.
    pre_install_hook = "scripts/enable-multilib.sh",
    -- Chromium skips VA-API on nvidia-drm render nodes; this overrides its
    -- desktop entry to lift that. No-op (and cleans up) on non-NVIDIA hosts.
    -- Previously rode along with the browser extension policies, which are gone.
    post_install_hook = "scripts/chromium-nvidia-vaapi.sh",
    hook_behavior = "always",
    run_hooks_as_user = false,
}
