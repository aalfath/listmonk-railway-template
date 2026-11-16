# listmonk for Railway: the official image, pinned by version and digest.
# Bump the tag and digest together, and add a CHANGELOG.md entry.
FROM listmonk/listmonk:v6.2.0@sha256:f535d59e14991337a9f2d570273685378ae86b0d7698c3e00da444e3bc205286

# psql: sets listmonk's root URL to the Railway domain on first boot.
RUN apk add --no-cache postgresql-client

COPY start.sh /usr/local/bin/railway-start.sh
RUN chmod +x /usr/local/bin/railway-start.sh

EXPOSE 9000

# The upstream ENTRYPOINT (docker-entrypoint.sh) stays and runs this command.
CMD ["railway-start.sh"]
