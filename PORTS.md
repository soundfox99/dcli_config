# Local ports

Ports bound by services this repo declares, so a new one can be picked without
collision. Everything here is **loopback-only** except SSH — check before
changing a bind address.

Regenerate the live picture with:

```bash
ss -tulpn
```

## In use

| Port | Bound to | Service | Declared in |
| --- | --- | --- | --- |
| 22 | `0.0.0.0`, `[::]` | `sshd` | `hosts/*.lua` → `services.enabled` |
| 631 | `127.0.0.1`, `[::1]` | CUPS print spooler | `hosts/*.lua` → `services.enabled` (`cups`) |
| 8081 | `127.0.0.1` | LanguageTool HTTP server | `modules/supernote` → `languagetool.service` |
| 8188 | `127.0.0.1` | ComfyUI web UI | `hosts/arch-desktop.lua` → `services.enabled` (`comfyui`) |

**22 is the only port reachable off-box.** `sshd` is declared on both hosts. The
rest are bound to loopback and cannot be reached from the network even with the
firewall open.

## Ephemeral

High-numbered loopback ports (roughly 32768–60999) are handed out by the kernel
and change every restart — VSCodium language servers, Electron helpers, browser
IPC. They are not allocations and must not be reserved. Currently visible:
`40239` (codium), `43107`.

## Picking a new port

1. Prefer the **8000–8999** range for local HTTP services; it is where the two
   existing web services already sit and it stays clear of the ephemeral range.
2. Check it is free: `ss -tulpn | grep :<port>`
3. Bind to `127.0.0.1` explicitly. A service that binds `0.0.0.0` is reachable
   from the LAN the moment the firewall allows it — LanguageTool in particular
   sees note text, so its `--port 8081` is deliberately loopback-only.
4. Record it in the table above in the same commit that adds the service.

## Related

- `modules/supernote/README.md` — LanguageTool server rationale and JVM cap
