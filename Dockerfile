# SnappyMail on Railway — thin wrapper image.
# Base: the official SnappyMail image built by the app author (djmaze),
# pinned to upstream release v2.38.2 (image build date 2024-10-09).
# Stack inside: nginx (hardcoded listen 8888) + php-fpm (9000) under
# supervisord, data volume /var/lib/snappymail, container user root.
FROM djmaze/snappymail:v2.38.2

# Railway probes/routes by the PORT variable. The image's nginx listens on a
# hardcoded 8888, so align PORT with it (kept as image ENV, not a service
# variable, so published templates stay zero-prompt). EXPOSE is re-declared
# so Railway unambiguously picks 8888 (the base image also exposes 9000 for
# php-fpm, which must never win).
ENV PORT=8888
EXPOSE 8888

# Railway entrypoint wrapper: fixes volume ownership (Railway volumes mount
# root:root while the app data is written by www-data), builds the data
# skeleton on first boot, seeds the admin password from the
# SNAPPYMAIL_ADMIN_PASSWORD variable, then hands off to the stock entrypoint.
COPY --chmod=755 railway-entrypoint.sh /railway-entrypoint.sh

# Stock image has ENTRYPOINT=[] and CMD ["/entrypoint.sh"] — override CMD only.
CMD ["/railway-entrypoint.sh"]
