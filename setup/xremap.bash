#!/usr/bin/env bash

print-header 'Install build dependencies'
if command -v apt-get &>/dev/null; then
	print-run sudo apt-get update || exit $?
	print-run sudo apt-get install -y curl build-essential libx11-dev libxtst-dev pkg-config || exit $?
elif command -v dnf &>/dev/null; then
	print-run sudo dnf install -y curl gcc make libX11-devel libXtst-devel pkgconf-pkg-config || exit $?
elif command -v pacman &>/dev/null; then
	print-run sudo pacman -Sy --needed --noconfirm curl base-devel libx11 libxtst pkgconf || exit $?
else
	print-error "Unsupported package manager. Install libx11-dev (or equivalent) manually."
	exit 1
fi

print-header 'Install Rust'
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
if ! command -v cargo &>/dev/null; then
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | print-run sh -s -- -y || exit $?
	source "$HOME/.cargo/env"
fi
type cargo || exit $?

print-header 'Build xremap'
print-run cargo install xremap --features x11 || exit $?
type xremap || exit $?

print-header 'Update PATH'
path_line='export PATH="$HOME/.cargo/bin:$PATH"'
for rc_file in "$HOME/.bashrc" "$HOME/.profile"; do
	[[ -f "$rc_file" ]] || continue
	grep -qF "$path_line" "$rc_file" && continue
	echo "$path_line" >> "$rc_file"
done

print-header 'Configure input/uinput groups'
print-run sudo groupadd -f uinput || exit $?
print-run sudo usermod -aG input "$USER" || exit $?
print-run sudo usermod -aG uinput "$USER" || exit $?

print-header 'Write udev rule'
rules_file=/etc/udev/rules.d/99-input.rules
echo 'KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"' \
	| print-run sudo tee "$rules_file" > /dev/null || exit $?

print-header 'Reload udev rules'
print-run sudo udevadm control --reload-rules || exit $?
print-run sudo udevadm trigger || exit $?

print-header 'Write xremap config'
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/xremap"
config_yml="$config_dir/config.yml"
mkdir -p "$config_dir" || exit $?
cat > "$config_yml" <<'EOF' || exit $?
keymap:
  - name: Slack Custom Shortcuts
    application:
      only: Slack
    remap:
      alt-l: F6
      alt-h: shift-F6
EOF

print-header 'Write systemd user service'
service_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
service_file="$service_dir/xremap.service"
mkdir -p "$service_dir" || exit $?
cat > "$service_file" <<EOF || exit $?
[Unit]
Description=xremap key remapper
After=graphical-session.target

[Service]
ExecStart=%h/.cargo/bin/xremap $config_yml
Restart=on-failure
RestartSec=2

[Install]
WantedBy=default.target
EOF

print-header 'Enable xremap service'
print-run systemctl --user daemon-reload || exit $?
print-run systemctl --user enable --now xremap.service || exit $?

echo
print-header 'Next steps'
echo 'Group membership changes (input/uinput) only apply after you log out and'
echo 'back in, or reboot. If xremap.service fails on permission errors, log'
echo 'out/in and run:'
print-cmd systemctl --user restart xremap.service
