#!/usr/bin/env sh
set -Eeo pipefail

if [ "${1:0:1}" = '-' ]; then
	set -- zerotier-one "$@"
fi

DEFAULT_PRIMARY_PORT=9993
DEFAULT_PORT_MAPPING_ENABLED=true
DEFAULT_ALLOW_TCP_FALLBACK_RELAY=true

MANAGEMENT_NETWORKS=""
if [ -n "$ZT_ALLOW_MANAGEMENT_FROM" ]; then # Using -n for clarity, same as ! -z
  # Loop to process comma-separated networks.
  # Assumes network definitions themselves don't contain IFS characters (spaces, tabs, newlines by default).
  # The ${VAR//find/replace} syntax requires a shell like bash/ksh/zsh.
  for NETWORK in ${ZT_ALLOW_MANAGEMENT_FROM//,/$IFS}; do
    if [ -n "$MANAGEMENT_NETWORKS" ]; then
      MANAGEMENT_NETWORKS="${MANAGEMENT_NETWORKS},"
    fi
    # Append the network, quoted, to the MANAGEMENT_NETWORKS string.
    # The backslash escapes the quote for the shell, so the quote becomes part of the string.
    MANAGEMENT_NETWORKS="${MANAGEMENT_NETWORKS}\"${NETWORK}\""
  done
fi

if [ "$ZT_OVERRIDE_LOCAL_CONF" = 'true' ] || [ ! -f "/var/lib/zerotier-one/local.conf" ]; then
  # Use a subshell to group echo commands for redirection to the config file.
  (
    echo "{"
    echo "  \"settings\": {"
    echo "    \"primaryPort\": ${ZT_PRIMARY_PORT:-$DEFAULT_PRIMARY_PORT},"
    # Add secondaryPort if ZT_SECONDARY_PORT is set
    if [ -n "$ZT_SECONDARY_PORT" ]; then
      echo "    \"secondaryPort\": ${ZT_SECONDARY_PORT},"
      # Add tertiaryPort if ZT_TERTIARY_PORT is set (and secondaryPort was also set for correct placement)
      if [ -n "$ZT_TERTIARY_PORT" ]; then
        echo "    \"tertiaryPort\": ${ZT_TERTIARY_PORT},"
      fi
    fi
    echo "    \"portMappingEnabled\": ${ZT_PORT_MAPPING_ENABLED:-$DEFAULT_PORT_MAPPING_ENABLED},"
    echo "    \"softwareUpdate\": \"disable\","
    # MANAGEMENT_NETWORKS will be empty if ZT_ALLOW_MANAGEMENT_FROM is not set, resulting in "[]"
    echo "    \"allowManagementFrom\": [${MANAGEMENT_NETWORKS}],"
    # The last item in the settings object does not have a trailing comma.
    echo "    \"allowTcpFallbackRelay\": ${ZT_ALLOW_TCP_FALLBACK_RELAY:-$DEFAULT_ALLOW_TCP_FALLBACK_RELAY}"
    echo "  }"
    echo "}"
  ) > "/var/lib/zerotier-one/local.conf" # Quoted file path for safety
fi

exec "$@"
