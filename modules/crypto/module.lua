return {
    description = "Crypto wallets — Ledger hardware wallet and Monero",
    packages = {
        "ledger-live-bin",  -- AUR: official Ledger Live desktop app
        "ledger-udev",      -- AUR: udev rules; without them Ledger Live can't see the device over USB
        "monero-gui",       -- pulls in monero (monerod, monero-wallet-cli)
    },
}
