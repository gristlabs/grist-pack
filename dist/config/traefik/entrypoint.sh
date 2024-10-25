#!/bin/sh

# Workaround to allow env vars in traefik's static config
while IFS= read -r line || [ -n "$line" ]; do
  eval "printf '%s\n' \"$line\""
done < /settings/config.yaml.template > /settings/config.yaml

# Run Traefik with the generated configuration
exec traefik --configFile=/settings/config.yaml
