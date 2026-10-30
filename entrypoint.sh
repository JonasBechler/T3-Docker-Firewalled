#!/bin/sh
# Starts sshd (as "node", port 2222) next to T3 Code.
# Host key and authorized_keys live in home/.ssh, so they survive rebuilds.
set -eu

# Docker creates missing bind-mount directories as root
for d in "$HOME" /workspace; do
  [ -w "$d" ] || sudo chown node:node "$d"
done

mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
[ -f ~/.ssh/ssh_host_ed25519_key ] \
  || ssh-keygen -q -t ed25519 -N '' -C t3code -f ~/.ssh/ssh_host_ed25519_key

umask 077
EXTRA=/tmp/sshd_extra.conf
: > "$EXTRA"

# Optional password login, from SSH_PASSWORD in .env. Problems here only
# disable password login; they never stop T3 Code from starting.
nl='
'
case "${SSH_PASSWORD:-}" in
  "") sudo usermod -p '!' node ;;   # no password left over from an earlier start
  *"$nl"*) echo "SSH_PASSWORD contains a newline; password login disabled" >&2
           sudo usermod -p '!' node ;;
  *) if printf 'node:%s\n' "$SSH_PASSWORD" | sudo chpasswd; then
       echo "PasswordAuthentication yes" >> "$EXTRA"
     else
       echo "Could not set SSH_PASSWORD; password login disabled" >&2
     fi ;;
esac
# Keeps it out of T3 Code and SSH sessions. Agents can still read it from
# /proc/1/environ, so it must be a password used nowhere else.
unset SSH_PASSWORD

# SSH sessions start with a clean environment; hand them the container's.
# Skips values sshd_config can't quote: containing " or ending in \.
/usr/bin/env | grep -E '^[A-Za-z_][A-Za-z0-9_]*=' \
  | grep -vE '^(HOME|HOSTNAME|PWD|OLDPWD|SHLVL|TERM|USER|LOGNAME|SHELL|_)=' \
  | grep -v '"' | grep -v '\\$' \
  | awk '{v = v " \"" $0 "\""} END{if (v != "") print "SetEnv" v}' \
  >> "$EXTRA"

# Keep sshd running; if it fails, T3 Code stays up and the log says why.
(
  while :; do
    /usr/sbin/sshd -D -e -f /etc/ssh/t3_sshd_config || true
    echo "sshd exited; restarting in 10s" >&2
    sleep 10
  done
) &
exec "$@"
