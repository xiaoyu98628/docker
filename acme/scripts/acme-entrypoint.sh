#!/usr/bin/env sh
set -eu

LOG_FILE="${ACME_LOG_FILE:-/var/log/acme/acme.log}"
EMAIL="${ACME_EMAIL:-}"
SERVER="${ACME_SERVER:-letsencrypt}"
DEFAULT_MODE="${ACME_DEFAULT_MODE:-webroot}"
WEBROOT="${ACME_WEBROOT:-/usr/share/nginx/html}"
CERT_HOME="${ACME_CERT_HOME:-/usr/config/acme}"
CONFIG_DIR="${ACME_DOMAIN_CONFIG_DIR:-/usr/config/acme/domains}"
KEYLENGTH="${ACME_KEYLENGTH:-ec-256}"
SYNC_INTERVAL_SECONDS="${ACME_SYNC_INTERVAL_SECONDS:-3600}"
RENEW_INTERVAL_SECONDS="${ACME_RENEW_INTERVAL_SECONDS:-86400}"
RELOAD_MARKER="$CERT_HOME/nginx.reload"

mkdir -p \
  "$(dirname "$LOG_FILE")" \
  "$CERT_HOME/account" \
  "$CERT_HOME/certs" \
  "$CONFIG_DIR" \
  "$WEBROOT/.well-known/acme-challenge"

log() {
  printf '[%s] %s\n' "$(date)" "$*" | tee -a "$LOG_FILE"
}

find_acme() {
  if command -v acme.sh >/dev/null 2>&1; then
    command -v acme.sh
    return
  fi

  if [ -x /root/.acme.sh/acme.sh ]; then
    printf '%s\n' /root/.acme.sh/acme.sh
    return
  fi

  if [ -x /acme.sh/acme.sh ]; then
    printf '%s\n' /acme.sh/acme.sh
    return
  fi

  log "ERROR: acme.sh command not found"
  exit 1
}

trim() {
  printf '%s' "$1" |
    sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

validate_positive_integer() {
  case "$1" in
    ""|*[!0-9]*)
      return 1
      ;;
  esac

  [ "$1" -gt 0 ]
}

validate_primary_domain() {
  DOMAIN_VALUE="$1"

  [ "${#DOMAIN_VALUE}" -le 253 ] || return 1

  printf '%s\n' "$DOMAIN_VALUE" |
    grep -Eq '^([A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)+[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$'
}

validate_certificate_domain() {
  DOMAIN_VALUE="$1"

  case "$DOMAIN_VALUE" in
    \*.*)
      validate_primary_domain "${DOMAIN_VALUE#*.}"
      ;;
    *)
      validate_primary_domain "$DOMAIN_VALUE"
      ;;
  esac
}

load_config() {
  CONFIG_FILE="$1"
  CFG_ENABLED="true"
  CFG_DOMAIN=""
  CFG_ALT_NAMES=""
  CFG_MODE="$DEFAULT_MODE"
  CFG_DNS_PROVIDER=""
  CONFIG_LINE_NUMBER=0

  while IFS= read -r CONFIG_LINE || [ -n "$CONFIG_LINE" ]; do
    CONFIG_LINE_NUMBER=$((CONFIG_LINE_NUMBER + 1))
    CONFIG_LINE="$(trim "$CONFIG_LINE")"

    case "$CONFIG_LINE" in
      ""|\#*)
        continue
        ;;
      *=*)
        ;;
      *)
        log "ERROR: Invalid line $CONFIG_LINE_NUMBER in $CONFIG_FILE"
        return 1
        ;;
    esac

    CONFIG_KEY="$(trim "${CONFIG_LINE%%=*}")"
    CONFIG_VALUE="$(trim "${CONFIG_LINE#*=}")"

    case "$CONFIG_KEY" in
      enabled)
        CFG_ENABLED="$CONFIG_VALUE"
        ;;
      domain)
        CFG_DOMAIN="$CONFIG_VALUE"
        ;;
      alt_names)
        CFG_ALT_NAMES="$CONFIG_VALUE"
        ;;
      mode)
        CFG_MODE="${CONFIG_VALUE:-$DEFAULT_MODE}"
        ;;
      dns_provider)
        CFG_DNS_PROVIDER="$CONFIG_VALUE"
        ;;
      *)
        log "ERROR: Unsupported key '$CONFIG_KEY' in $CONFIG_FILE"
        return 1
        ;;
    esac
  done <"$CONFIG_FILE"

  case "$CFG_ENABLED" in
    true|false)
      ;;
    *)
      log "ERROR: enabled must be true or false in $CONFIG_FILE"
      return 1
      ;;
  esac
}

validate_config() {
  CONFIG_FILE="$1"

  if ! validate_primary_domain "$CFG_DOMAIN"; then
    log "ERROR: Invalid primary domain '$CFG_DOMAIN' in $CONFIG_FILE"
    return 1
  fi

  case "$CFG_MODE" in
    webroot|dns)
      ;;
    *)
      log "ERROR: mode must be webroot or dns in $CONFIG_FILE"
      return 1
      ;;
  esac

  if [ "$CFG_MODE" = "dns" ]; then
    if ! printf '%s\n' "$CFG_DNS_PROVIDER" |
      grep -Eq '^dns_[A-Za-z0-9_]+$'; then
      log "ERROR: Invalid dns_provider '$CFG_DNS_PROVIDER' in $CONFIG_FILE"
      return 1
    fi
  elif [ -n "$CFG_DNS_PROVIDER" ]; then
    log "ERROR: dns_provider is only valid when mode=dns: $CONFIG_FILE"
    return 1
  fi

  if [ -n "$CFG_ALT_NAMES" ] &&
    printf '%s\n' "$CFG_ALT_NAMES" | grep -Eq '(^;|;$|;;)'; then
    log "ERROR: alt_names contains an empty domain in $CONFIG_FILE"
    return 1
  fi

  CFG_ALL_DOMAINS="$CFG_DOMAIN"
  CFG_DOMAIN_LINES="$CFG_DOMAIN"
  VALIDATION_ERROR=""

  if [ -n "$CFG_ALT_NAMES" ]; then
    OLD_IFS="$IFS"
    IFS=";"
    set -f

    for ALT_DOMAIN in $CFG_ALT_NAMES; do
      ALT_DOMAIN="$(trim "$ALT_DOMAIN")"

      if ! validate_certificate_domain "$ALT_DOMAIN"; then
        VALIDATION_ERROR="Invalid alternative domain '$ALT_DOMAIN'"
        break
      fi

      case "$ALT_DOMAIN" in
        \*.*)
          if [ "$CFG_MODE" != "dns" ]; then
            VALIDATION_ERROR="Wildcard domain '$ALT_DOMAIN' requires dns mode"
            break
          fi
          ;;
      esac

      if printf '%s\n' "$CFG_DOMAIN_LINES" | grep -Fqx "$ALT_DOMAIN"; then
        VALIDATION_ERROR="Duplicate domain '$ALT_DOMAIN'"
        break
      fi

      CFG_ALL_DOMAINS="$CFG_ALL_DOMAINS;$ALT_DOMAIN"
      CFG_DOMAIN_LINES="$CFG_DOMAIN_LINES
$ALT_DOMAIN"
    done

    set +f
    IFS="$OLD_IFS"
  fi

  if [ -n "$VALIDATION_ERROR" ]; then
    log "ERROR: $VALIDATION_ERROR in $CONFIG_FILE"
    return 1
  fi
}

certificate_checksum() {
  printf '%s\n' \
    "domains=$CFG_ALL_DOMAINS" \
    "mode=$CFG_MODE" \
    "dns_provider=$CFG_DNS_PROVIDER" \
    "server=$SERVER" \
    "webroot=$WEBROOT" \
    "keylength=$KEYLENGTH" |
    cksum |
    awk '{print $1 ":" $2}'
}

issue_certificate() {
  set -- \
    --issue \
    --config-home "$CERT_HOME/account" \
    --keylength "$KEYLENGTH" \
    --force

  if [ -n "$SERVER" ]; then
    set -- "$@" --server "$SERVER"
  fi

  if [ -n "$EMAIL" ]; then
    set -- "$@" --accountemail "$EMAIL"
  fi

  OLD_IFS="$IFS"
  IFS=";"
  set -f

  for CERT_DOMAIN in $CFG_ALL_DOMAINS; do
    set -- "$@" -d "$CERT_DOMAIN"
  done

  set +f
  IFS="$OLD_IFS"

  case "$CFG_MODE" in
    webroot)
      log "INFO: Issuing webroot certificate: $CFG_ALL_DOMAINS"

      if ! "$ACME_SH" "$@" \
        -w "$WEBROOT" >>"$LOG_FILE" 2>&1; then
        log "ERROR: Certificate issue failed: $CFG_DOMAIN"
        return 1
      fi
      ;;
    dns)
      log "INFO: Issuing DNS certificate with $CFG_DNS_PROVIDER: $CFG_ALL_DOMAINS"

      if ! "$ACME_SH" "$@" \
        --dns "$CFG_DNS_PROVIDER" >>"$LOG_FILE" 2>&1; then
        log "ERROR: Certificate issue failed: $CFG_DOMAIN"
        return 1
      fi
      ;;
  esac
}

save_checksum() {
  CHECKSUM_FILE="$1"
  REQUEST_CHECKSUM="$2"
  CHECKSUM_TEMP_FILE="${CHECKSUM_FILE}.tmp.$$"

  if ! printf '%s\n' "$REQUEST_CHECKSUM" >"$CHECKSUM_TEMP_FILE"; then
    log "ERROR: Unable to prepare certificate checksum: $CFG_DOMAIN"
    return 1
  fi

  if ! mv "$CHECKSUM_TEMP_FILE" "$CHECKSUM_FILE"; then
    rm -f "$CHECKSUM_TEMP_FILE" || true
    log "ERROR: Unable to save certificate checksum: $CFG_DOMAIN"
    return 1
  fi
}

install_certificate() {
  CERT_DIR="$1"

  log "INFO: Installing certificate to $CERT_DIR"

  set -- \
    --install-cert \
    --config-home "$CERT_HOME/account" \
    -d "$CFG_DOMAIN"

  case "$KEYLENGTH" in
    ec-*)
      set -- "$@" --ecc
      ;;
  esac

  if ! "$ACME_SH" "$@" \
    --cert-file "$CERT_DIR/cert.pem" \
    --key-file "$CERT_DIR/key.pem" \
    --ca-file "$CERT_DIR/ca.pem" \
    --fullchain-file "$CERT_DIR/fullchain.pem" \
    --reloadcmd "touch $RELOAD_MARKER" >>"$LOG_FILE" 2>&1; then
    log "ERROR: Certificate installation failed: $CFG_DOMAIN"
    return 1
  fi

  if ! chmod 600 "$CERT_DIR/key.pem"; then
    log "ERROR: Unable to update private key permissions: $CFG_DOMAIN"
    return 1
  fi

  log "INFO: Certificate installed: $CFG_DOMAIN"
}

issue_or_update_cert() {
  CERT_DIR="$CERT_HOME/certs/$CFG_DOMAIN"
  REQUEST_CHECKSUM_FILE="$CERT_DIR/.request.checksum"
  INSTALL_CHECKSUM_FILE="$CERT_DIR/.install.checksum"
  REQUEST_CHECKSUM="$(certificate_checksum)"
  STORED_REQUEST_CHECKSUM=""
  STORED_INSTALL_CHECKSUM=""

  if ! mkdir -p "$CERT_DIR"; then
    log "ERROR: Unable to create certificate directory: $CERT_DIR"
    return 1
  fi

  if [ -f "$REQUEST_CHECKSUM_FILE" ]; then
    STORED_REQUEST_CHECKSUM="$(sed -n '1p' "$REQUEST_CHECKSUM_FILE")"
  fi

  if [ -f "$INSTALL_CHECKSUM_FILE" ]; then
    STORED_INSTALL_CHECKSUM="$(sed -n '1p' "$INSTALL_CHECKSUM_FILE")"
  fi

  if [ "$STORED_REQUEST_CHECKSUM" != "$REQUEST_CHECKSUM" ]; then
    log "INFO: Certificate request changed, issuing certificate: $CFG_DOMAIN"

    if ! issue_certificate; then
      return 1
    fi

    # Save successful issuance before installation so a local copy failure
    # retries only --install-cert instead of creating another CA order.
    if ! save_checksum "$REQUEST_CHECKSUM_FILE" "$REQUEST_CHECKSUM"; then
      return 1
    fi
  fi

  if [ "$STORED_INSTALL_CHECKSUM" != "$REQUEST_CHECKSUM" ] ||
    [ ! -s "$CERT_DIR/fullchain.pem" ] || [ ! -s "$CERT_DIR/key.pem" ]; then
    log "INFO: Certificate installation is missing or outdated, reinstalling: $CFG_DOMAIN"

    if ! install_certificate "$CERT_DIR"; then
      return 1
    fi

    save_checksum "$INSTALL_CHECKSUM_FILE" "$REQUEST_CHECKSUM"
    return
  fi

  if ! chmod 600 "$CERT_DIR/key.pem"; then
    log "ERROR: Unable to update private key permissions: $CFG_DOMAIN"
    return 1
  fi

  log "INFO: Certificate configuration unchanged: $CFG_DOMAIN"
}

sync_certs() {
  FOUND_CONFIG=false
  FAILED_COUNT=0
  SEEN_DOMAINS="|"

  for CONFIG_FILE in "$CONFIG_DIR"/*.conf; do
    [ -f "$CONFIG_FILE" ] || continue
    FOUND_CONFIG=true

    if ! load_config "$CONFIG_FILE"; then
      FAILED_COUNT=$((FAILED_COUNT + 1))
      continue
    fi

    if [ "$CFG_ENABLED" = "false" ]; then
      log "INFO: Certificate configuration disabled: $CONFIG_FILE"
      continue
    fi

    if ! validate_config "$CONFIG_FILE"; then
      FAILED_COUNT=$((FAILED_COUNT + 1))
      continue
    fi

    case "$SEEN_DOMAINS" in
      *"|$CFG_DOMAIN|"*)
        log "ERROR: Duplicate primary domain '$CFG_DOMAIN': $CONFIG_FILE"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        continue
        ;;
    esac

    SEEN_DOMAINS="$SEEN_DOMAINS$CFG_DOMAIN|"

    if ! issue_or_update_cert; then
      FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
  done

  if [ "$FOUND_CONFIG" = "false" ]; then
    log "INFO: No certificate config found in $CONFIG_DIR"
  fi

  [ "$FAILED_COUNT" -eq 0 ]
}

renew_certs() {
  FOUND_CONFIG=false
  FAILED_COUNT=0
  SEEN_DOMAINS="|"

  for CONFIG_FILE in "$CONFIG_DIR"/*.conf; do
    [ -f "$CONFIG_FILE" ] || continue
    FOUND_CONFIG=true

    if ! load_config "$CONFIG_FILE"; then
      FAILED_COUNT=$((FAILED_COUNT + 1))
      continue
    fi

    [ "$CFG_ENABLED" = "true" ] || continue

    if ! validate_config "$CONFIG_FILE"; then
      FAILED_COUNT=$((FAILED_COUNT + 1))
      continue
    fi

    case "$SEEN_DOMAINS" in
      *"|$CFG_DOMAIN|"*)
        log "ERROR: Duplicate primary domain '$CFG_DOMAIN': $CONFIG_FILE"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        continue
        ;;
    esac

    SEEN_DOMAINS="$SEEN_DOMAINS$CFG_DOMAIN|"

    set -- \
      --renew \
      --config-home "$CERT_HOME/account" \
      -d "$CFG_DOMAIN"

    case "$KEYLENGTH" in
      ec-*)
        set -- "$@" --ecc
        ;;
    esac

    RENEW_STATUS=0

    if "$ACME_SH" "$@" >>"$LOG_FILE" 2>&1; then
      RENEW_STATUS=0
    else
      RENEW_STATUS=$?
    fi

    case "$RENEW_STATUS" in
      0)
        log "INFO: Certificate renewal completed: $CFG_DOMAIN"
        ;;
      2)
        log "INFO: Certificate is not due for renewal: $CFG_DOMAIN"
        ;;
      *)
        log "ERROR: Certificate renewal failed with status $RENEW_STATUS: $CFG_DOMAIN"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        ;;
    esac
  done

  if [ "$FOUND_CONFIG" = "false" ]; then
    log "INFO: No certificate config found for renewal in $CONFIG_DIR"
  fi

  [ "$FAILED_COUNT" -eq 0 ]
}

if ! validate_positive_integer "$SYNC_INTERVAL_SECONDS"; then
  log "ERROR: ACME_SYNC_INTERVAL_SECONDS must be a positive integer"
  exit 1
fi

if ! validate_positive_integer "$RENEW_INTERVAL_SECONDS"; then
  log "ERROR: ACME_RENEW_INTERVAL_SECONDS must be a positive integer"
  exit 1
fi

ACME_SH="$(find_acme)"

if [ -n "$SERVER" ]; then
  log "INFO: Setting default CA server: $SERVER"

  if ! "$ACME_SH" \
    --config-home "$CERT_HOME/account" \
    --set-default-ca \
    --server "$SERVER" >>"$LOG_FILE" 2>&1; then
    log "ERROR: Unable to set default CA server: $SERVER"
    exit 1
  fi
fi

if ! sync_certs; then
  log "ERROR: One or more certificates failed to synchronize"
fi

LAST_RENEW_TIMESTAMP=0

if renew_certs; then
  LAST_RENEW_TIMESTAMP="$(date +%s)"
else
  log "ERROR: One or more certificates failed the renewal check"
fi

while true; do
  sleep "$SYNC_INTERVAL_SECONDS"

  if ! sync_certs; then
    log "ERROR: One or more certificates failed to synchronize"
  fi

  CURRENT_TIMESTAMP="$(date +%s)"

  if [ "$CURRENT_TIMESTAMP" -lt "$LAST_RENEW_TIMESTAMP" ] ||
    [ $((CURRENT_TIMESTAMP - LAST_RENEW_TIMESTAMP)) -ge "$RENEW_INTERVAL_SECONDS" ]; then
    if renew_certs; then
      LAST_RENEW_TIMESTAMP="$CURRENT_TIMESTAMP"
    else
      log "ERROR: One or more certificates failed the renewal check"
    fi
  fi
done
