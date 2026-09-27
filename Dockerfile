# SnappyMail on Railway — thin wrapper image.
# Base: the official SnappyMail image built by the app author (djmaze),
# pinned to upstream release v2.38.2 (image build date 2024-10-09).
# Stack inside: nginx (hardcoded listen 8888) + php-fpm (9000) under
# supervisord, data volume /var/lib/snappymail, container user root.
FROM djmaze/snappymail:v2.38.2

# Railway build quirk (same as the Roundcube fix): files that an image layer
# only DELETED get re-materialized at container start on Railway, while
# CREATE operations stick. The base image renamed the stock php-fpm pools
# (docker.conf/www.conf/zz-docker.conf -> *.disabled) so only its own
# [default] pool loads; Railway resurrected the stock [www] pool, which then
# collided with [default] on port 9000 ("unable to set listen address as
# it's already used in another pool 'www'" -> FPM init failed -> crash loop).
# Fix: OVERWRITE all three with comment-only files (a create op always sticks;
# a comment-only pool config defines no pool and is harmless).
RUN ls -la /usr/local/etc/php-fpm.d/ > /tmp/fpmdump.txt; \
    for f in docker.conf www.conf zz-docker.conf; do \
        printf '; disabled for Railway: only the custom [default] pool may load\n' > "/usr/local/etc/php-fpm.d/$f"; \
    done; \
    ls -la /usr/local/etc/php-fpm.d/

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
