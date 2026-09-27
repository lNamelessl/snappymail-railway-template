#!/bin/sh
# SnappyMail on Railway — entrypoint wrapper.
#
# Runs instead of the stock /entrypoint.sh (CMD override; the stock image has
# ENTRYPOINT=[]), fixes what breaks on Railway, then execs the stock script.
#
# Verified against the djmaze/snappymail:v2.38.2 image and SnappyMail v2.38.2
# source:
#   * The container starts as root but all app data is written by www-data
#     (Alpine uid/gid 82:82; the nginx user 101 is also in that group).
#     Railway volumes mount root:root, so the volume must be chowned BEFORE
#     anything writes to it — otherwise the first mkdir() dies with
#     "Permission denied".
#   * Admin auth checks ONLY the bcrypt hash in
#     /var/lib/snappymail/_data_/_default_/configs/application.ini
#     (security.admin_password). The freshly generated skeleton ships it empty
#     (admin_password = "").
#   * The stock entrypoint, when the ini hash is empty, generates a RANDOM
#     password on the first HTTP request and writes it to
#     _data_/_default_/admin_password.txt — we pre-seed hash + passfile from
#     the SNAPPYMAIL_ADMIN_PASSWORD variable instead, so the deployer always
#     knows the password (Variables tab) and no random file password is used.
#   * Seeding only happens while the ini hash is empty, so a password later
#     changed in the admin panel survives reboots and redeploys.
set -eu

DATA=/var/lib/snappymail
INI="$DATA/_data_/_default_/configs/application.ini"
PASSFILE="$DATA/_data_/_default_/admin_password.txt"
PW="${SNAPPYMAIL_ADMIN_PASSWORD:-}"

# 1. Fix volume ownership BEFORE anything else (Railway mounts it root:root;
#    mkdir()/file writes from www-data would fail with Permission denied).
echo "[railway] Fixing ownership of $DATA (www-data)"
chown -R www-data:www-data "$DATA" 2>/dev/null || true

# 2. Build the data skeleton if missing (same command the stock entrypoint
#    uses; doing it here lets us seed the password into the fresh ini before
#    the servers start). NOTE: the data dir must end up mode 750 (owner
#    www-data needs WRITE on it to create _data_) — the stock script's
#    550 + find-750 dance has exactly this net effect.
if [ ! -f "$INI" ]; then
    echo "[railway] First boot: creating SnappyMail data skeleton in $DATA"
    mkdir -p "$DATA"
    chown -R www-data:www-data "$DATA"
    chmod 750 "$DATA"
    find "$DATA" -type d -exec chmod 750 {} \;
    su - www-data -s /bin/sh -c 'php /snappymail/index.php'
fi

# 3. Seed the admin password from the Railway variable — only while the ini
#    hash is still empty (never clobbers a password changed in the panel).
if [ -n "$PW" ] && [ -f "$INI" ] && grep -qE '^admin_password[[:space:]]*=[[:space:]]*["'"'"']{0,2}[[:space:]]*$' "$INI"; then
    echo "[railway] Seeding admin password hash into application.ini (+ passfile)"
    export PW INI PASSFILE
    php -r '
$h = password_hash(getenv("PW"), PASSWORD_DEFAULT);
$c = file_get_contents(getenv("INI"));
$c2 = preg_replace_callback(
    "/^admin_password[[:space:]]*=.*$/m",
    function () use ($h) { return "admin_password = \"" . $h . "\""; },
    $c, 1, $n
);
if ($n < 1) { fwrite(STDERR, "[railway] admin_password line not found in ini\n"); exit(1); }
file_put_contents(getenv("INI"), $c2);
file_put_contents(getenv("PASSFILE"), getenv("PW") . "\n");
'
    unset PW
    chown www-data:www-data "$INI" "$PASSFILE"
    chmod 600 "$PASSFILE"
    echo "[railway] Admin panel ready at /?admin — user 'admin', password = the SNAPPYMAIL_ADMIN_PASSWORD variable (Railway Variables tab)"
fi

# 4. Hand off to the stock entrypoint (config seds + supervisord + nginx:8888).
exec /entrypoint.sh
