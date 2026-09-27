# SnappyMail on Railway

Fast, modern webmail for your existing mail server — deployed in one click.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/snappymail-template)

SnappyMail is a **webmail client**, not a mail server: it connects to the IMAP/SMTP mail you already have (Gmail, Outlook, your own mail host) and gives it a fast, modern web interface. No other services are required beyond your mail provider.

## What you get

- One service: the official [`djmaze/snappymail`](https://hub.docker.com/r/djmaze/snappymail) image (built by the app author) pinned to `v2.38.2` — nginx on port 8888 behind Railway's TLS edge
- One volume on `/var/lib/snappymail` — all app data, domain settings and users persist across restarts and redeploys
- **Zero-credential admin bootstrap**: Railway generates the admin password per deployment into the `SNAPPYMAIL_ADMIN_PASSWORD` variable and the entrypoint pre-seeds it into the app before first boot — no file-digging, no random passwords lost in logs
- Zero deploy-form prompts: everything is provisioned and generated automatically

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

# Deploy and Host

Deploy SnappyMail to Railway with one click. The template provisions a single webmail service built from the pinned official SnappyMail image, attaches a persistent volume at `/var/lib/snappymail`, and generates a public domain on port 8888. The admin password is generated per deployment (variable `SNAPPYMAIL_ADMIN_PASSWORD`) and seeded into the app on first boot, so the admin panel at `/?admin` is usable immediately with the password from the Variables tab.

## About Hosting

Hosting SnappyMail yourself means your mail credentials and messages pass through your own infrastructure instead of a third-party webmail host. The template runs one service (nginx + PHP-FPM under supervisord, ~512 MB RAM is plenty) with one volume for config, contacts, filters and cache. SnappyMail is a client: it stores settings and session data locally but fetches mail live over IMAP and sends over SMTP, so storage needs stay small (1 GB volume is comfortable).

## Why Deploy

- The official image's worst quirk — the admin password being generated into a file inside the data volume — is solved: the password is a Railway variable you can read and rotate, seeded before first boot.
- Volume ownership and the stock PHP-FPM pool configuration are fixed for Railway's runtime, so first boot succeeds without manual `chown` or config surgery.
- One pinned image version, one volume, one generated variable — no database service, no deploy-form prompts, nothing else to wire up.

## Common Use Cases

- Self-hosted webmail front-end for a personal or family mail server (Mailcow, Mail-in-a-Box, Dovecot/Postfix, Zimbra).
- A fast web UI for provider mailboxes that support IMAP/SMTP (Gmail app passwords, Outlook, Fastmail, Migadu, Purelymail).
- A lightweight replacement for Roundcube with modern UI, Sieve filter editing and GPG support.

## Dependencies for

SnappyMail has no runtime dependencies inside Railway — no database, no cache, no workers. The only external dependency is the mail server you point it at.

### Deployment Dependencies

- An IMAP/SMTP mail server reachable from the internet (your own, or a provider's). Configure it in the admin panel → Domains (IMAP `imap.example.com:993` SSL, SMTP `smtp.example.com:465` SSL or `587` STARTTLS with auth).
- Outbound internet access from the service for IMAP/SMTP/Sieve connections (Railway allows this by default).
