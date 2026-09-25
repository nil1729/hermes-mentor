FROM nousresearch/hermes-agent:latest

# Baked config, staged outside /opt/data (the persistent volume mount point).
# The cont-init.d hook below copies these onto the volume on every boot.
COPY config.yaml /opt/hermes-mentor/config.yaml
COPY SOUL.md /opt/hermes-mentor/SOUL.md
COPY MEMORY.md /opt/hermes-mentor/MEMORY.md
COPY scripts/storage-cleanup.sh /opt/hermes-mentor/scripts/storage-cleanup.sh

# Runs after the official 01-hermes-setup/02-reconcile-profiles hooks, inside
# the same s6-overlay cont-init.d chain: config/identity seeding + cron jobs.
COPY --chmod=0755 cont-init.d/03-hermes-mentor-setup /etc/cont-init.d/03-hermes-mentor-setup

# Matches the official docker-compose.yml's "gateway" service command; the
# s6-overlay main-wrapper.sh routes this to `hermes gateway run` as the
# supervised foreground process.
CMD ["gateway", "run"]
