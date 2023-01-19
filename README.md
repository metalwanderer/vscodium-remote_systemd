# vscodium-remote_systemd
Script and systemd unit files to launch Remote Execution Host for VSCodium on demand

Features:
* Launch Remote Execution Host on-demand
* Shut down server after idle timeout
* Cleanup cached versions
* Runs as user unit

## Requirements
* `bash`
* `systemd`
* `wget` (can be adjusted to use `curl`)
* `jq`

## Usage
### Configure settings in `vscodium-server.sh`
In particular, you may want to adjust the following:
```
VSCODIUM_DIR="${HOME}/lib/vscodium-server"      # adjust to your preferred location
VSCODIUM_VERSION=""                             # matches your VSCodium version (a.bb.c.ddddd)
KEEP_PKGS=3                                     # keep this many versions cached (including current version)
CONNECTION_TOKEN=""                             # matches your connection token for remote-oss extension
SOCKET_PATH="${VSCODIUM_DIR}/socket"            # socket passed to systemd-socket-proxyd
```

### Configure settings in unit files
`vscodium-proxy.socket`:
```
[Socket]
ListenStream=0.0.0.0:8000                       # adjust to your desired port
```

`vscodium-proxy.service`:
```
[Service]
# adjust path to wait-socket.sh and socket as needed
ExecStart=/usr/bin/timeout 90 %h/lib/vscodium-server/bin/wait-socket.sh %h/lib/vscodium-server/socket
# set --exit-idle-time as desired
ExecStart=/lib/systemd/systemd-socket-proxyd --exit-idle-time 900 %h/lib/vscodium-server/socket
```

`vscodium-server.service`:
```
[Service]
# adjust path to vscodium-server.sh and socket as needed
ExecStart=%h/bin/vscodium-server.sh
ExecStopPost=rm -f %h/lib/vscodium-server/socket
```

### Install scripts
Copy scripts to paths configured above:
* `vscodium-server.sh`
* `wait-socket.sh`

Copy unit files to systemd user path (`~/.config/systemd/user/`):
* `vscodium-proxy.socket`
* `vscodium-proxy.service`
* `vscodium-server.service`

Load unit files:
```
systemctl --user daemon-reload
```

Activate socket unit:
```
systemctl --user enable --now vscodium-proxy.socket
```

## Debugging / Troubleshooting
Check that all required variables are set to correct values

Check output from units:
```
journalctl --user -u vscodium-proxy.service
```
```
journalctl --user -u vscodium-server.service
```
