#!/usr/bin/env sh
set -eu

LOG_FILE="/var/log/acme/acme.log"
MODE="${ACME_MODE:-webroot}"
DOMAINS="${ACME_DOMAINS:-}"
EMAIL="${ACME_EMAIL:-}"
SERVER="${ACME_SERVER:-}"
DNS_HOOK="${ACME_DNS:-}"
WEBROOT="${ACME_WEBROOT:-/usr/share/nginx/html}"
CERT_HOME="${ACME_CERT_HOME:-/usr/config/acme}"
KEYLENGTH="${ACME_KEYLENGTH:-ec-256}"
RENEW_INTERVAL_SECONDS="${ACME_RENEW_INTERVAL_SECONDS:-86400}"

mkdir -p "$(dirname "$LOG_FILE")" "$CERT_HOME/account" "$CERT_HOME/certs" "$WEBROOT/.well-known/acme-challenge"

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

ACME_SH="$(find_acme)"

main_domain() {
  printf '%s' "$DOMAINS" | cut -d ';' -f 1
}

issue_cert() {
  if [ -z "$DOMAINS" ]; then
    log "INFO: ACME_DOMAINS is empty, skip issuing certificate"
    return
  fi

  MAIN_DOMAIN="$(main_domain)"
  CERT_DIR="$CERT_HOME/certs/$MAIN_DOMAIN"
  mkdir -p "$CERT_DIR"

  if [ -n "$SERVER" ]; then
    log "INFO: Setting default CA server: $SERVER"
    "$ACME_SH" --home "$CERT_HOME/account" --set-default-ca --server "$SERVER" >>"$LOG_FILE" 2>&1
  fi

  set -- --issue --home "$CERT_HOME/account" --keylength "$KEYLENGTH"

  if [ -n "$EMAIL" ]; then
    set -- "$@" --accountemail "$EMAIL"
  fi

  OLD_IFS="$IFS"
  IFS=";"
  for domain in $DOMAINS; do
    [ -n "$domain" ] && set -- "$@" -d "$domain"
  done
  IFS="$OLD_IFS"

  case "$MODE" in
    webroot)
      log "INFO: Issuing certificate in webroot mode for: $DOMAINS"
      "$ACME_SH" "$@" -w "$WEBROOT" >>"$LOG_FILE" 2>&1
      ;;
    dns)
      if [ -z "$DNS_HOOK" ]; then
        log "ERROR: ACME_DNS is required when ACME_MODE=dns"
        return 1
      fi
      log "INFO: Issuing certificate in dns mode for: $DOMAINS"
      "$ACME_SH" "$@" --dns "$DNS_HOOK" >>"$LOG_FILE" 2>&1
      ;;
    *)
      log "ERROR: Unsupported ACME_MODE=$MODE, expected webroot or dns"
      return 1
      ;;
  esac

  log "INFO: Installing certificate to $CERT_DIR"
  set -- --install-cert --home "$CERT_HOME/account"

  OLD_IFS="$IFS"
  IFS=";"
  for domain in $DOMAINS; do
    [ -n "$domain" ] && set -- "$@" -d "$domain"
  done
  IFS="$OLD_IFS"

  "$ACME_SH" "$@" \
    --cert-file "$CERT_DIR/cert.pem" \
    --key-file "$CERT_DIR/key.pem" \
    --ca-file "$CERT_DIR/ca.pem" \
    --fullchain-file "$CERT_DIR/fullchain.pem" >>"$LOG_FILE" 2>&1
}

renew_certs() {
  log "INFO: Running certificate renewal"
  "$ACME_SH" --cron --home "$CERT_HOME/account" >>"$LOG_FILE" 2>&1
}

issue_cert

while true; do
  sleep "$RENEW_INTERVAL_SECONDS"
  renew_certs
done
