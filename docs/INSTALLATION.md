# Installation and upgrades

Run the compatibility check first:

```sh
./install.sh --check
```

Install Ayame Shell V2 as the default Hyprland shell:

```sh
./install.sh
```

The installer detects Ayame V1, offers to migrate compatible settings and
history, disables its services, and keeps its files available for rollback.
Existing V2 settings are preferred when installing a checkout that has already
been used for daily-driver testing.

After installation:

```sh
ayame-shell-v2 update
ayame-shell-v2 doctor
ayame-shell-v2 rollback
```

The same updater is available in **Ayame Settings → System → Ayame Updater**.
Updates are downloaded from the V2 GitHub repository, validated, installed over
the program files, and restarted without replacing user data.

Uninstall V2 while preserving its data:

```sh
~/.local/share/ayame-shell-v2/uninstall.sh
```

Pass `--restore-v1` to return to an existing V1 installation, or
`--purge-data` to remove V2 settings and history as well.
