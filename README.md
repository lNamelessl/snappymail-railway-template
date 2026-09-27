# SnappyMail on Railway

Fast, modern webmail in one click.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.app/new?template=snappymail-template)

SnappyMail is a **webmail client**, not a mail server: it connects to your **existing IMAP/SMTP mail** (Gmail, Outlook, your own mail host) and gives you a fast web interface for it. Nothing else is required beyond your mail provider.

## What you get

- One service: the official [`djmaze/snappymail`](https://hub.docker.com/r/djmaze/snappymail) image (built by the app author) pinned to `v2.38.2` — nginx on port 8888 behind Railway's TLS edge
- One volume on `/var/lib/snappymail` — all app data, domain settings and users persist across restarts and redeploys
- **Zero-credential admin bootstrap**: Railway generates the admin password per deployment into the `SNAPPYMAIL_ADMIN_PASSWORD` variable and the entrypoint pre-seeds it into the app before first boot — no file-digging, no random passwords lost in logs

## After deploying

1. Open your Railway project → **Variables** → copy the value of `SNAPPYMAIL_ADMIN_PASSWORD`.
2. Open your Railway domain at **`/?admin`** — log in as user **`admin`** with that password.
3. (Recommended) Change the admin password in the admin panel. The seed only applies while the password is unset, so your change survives reboots.
4. **Configure your mail domain** (required before anyone can log in):
   - In the admin panel open the **Domains** tab.
   - Edit the `default` domain or click **Add domain** for your mail host.
   - **IMAP**: host (e.g. `imap.gmail.com`), port **993**, security **SSL**; users log in with their full email address.
   - **SMTP**: host (e.g. `smtp.gmail.com`), port **465** security **SSL** (or port **587** security **STARTTLS**), enable **use auth**.
   - **Sieve** (optional, supported): host + port **4190**.
   - Save, then log in at `/` with a real mailbox account.
5. Optional: further domain/provider options (filters, attachment limits, branding) are all in the admin panel.

## Admin password details

- The password lives in the `SNAPPYMAIL_ADMIN_PASSWORD` variable; a bcrypt hash is written to `/var/lib/snappymail/_data_/_default_/configs/application.ini` on first boot.
- To reset later: change it in the admin panel (Settings → Security), or delete the volume to start over.
- The file `admin_password.txt` (same folder) only exists while the initial password is unchanged; the app removes it once you set your own.

## Scope & notes

- **Client, not server**: bring your own IMAP/SMTP. No POP3 support (removed upstream); Sieve is supported.
- Timezone inside the container is UTC.
- Image pinned to `v2.38.2` for reproducible deploys (the official image build dates to 2024-10; check upstream for newer releases).
- Cost: roughly **$3–5/month** (512 MB service + 1 GB volume).

## Troubleshooting

- **Login fails for a mailbox**: the domain is not configured or IMAP/SMTP host/port/security is wrong — check the Domains tab in `/?admin` and SnappyMail's logs (enabled to stderr, visible under the service's Deployments → Logs).
- **Admin password unknown**: copy it from the `SNAPPYMAIL_ADMIN_PASSWORD` variable. If you changed it in the panel and forgot it: set a new password by updating the variable, then delete `application.ini`'s `admin_password` line… simpler — delete the volume and redeploy to re-seed.
- **Attachments rejected**: raise `UPLOAD_MAX_SIZE` (default `25M`) in the service variables — the entrypoint template applies it to nginx and php-fpm.
