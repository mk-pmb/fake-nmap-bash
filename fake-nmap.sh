#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function fake_nmap () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  # local SELFPATH="$(readlink -m -- "$BASH_SOURCE"/..)"
  # cd -- "$SELFPATH" || return $?

  local PROGNAME='fake-nmap'
  local KNOWN_SERVICES=()
  local N_SVC_KNOWN=0
  local BASH_MAX_RANDOM=32767

  # Config:
  local SCANNED_PORTS_PER_HOST=1000
  local OPEN_PORTS_MIN=1
  local OPEN_PORTS_DICE='4 4 6'
  local LATENCY_MSEC_MIN=20
  local LATENCY_MSEC_RNG=2000
  local COLWIDTH_PORT=12

  local RUNMODE="${1:-scam}"; shift
  fnmap_"$RUNMODE" "$@"; return $?
}


function fnmap_services () {
  local FILES=(
    /usr/{,local/}share/nmap/nmap-services
    /etc/services
    )
  sed -nre 's~^([a-z]\S+)\s+([0-9]+)/([a-z]+)\s.*$~\3 \2 \1~p' \
    -- "${FILES[@]}" 2>/dev/null | sort -Vu | grep -vPe '\s(unknown$)'
}


function fnmap_scan () {
  echo E: "$PROGNAME cannot actually 'scan'. Did you mean 'scam'?" >&2
  return 2
}


function fnmap_ensure_service_list () {
  [ "$N_SVC_KNOWN" == 0 ] || return 0
  readarray -t KNOWN_SERVICES < <(fnmap_services)
  N_SVC_KNOWN="${#KNOWN_SERVICES[@]}"
  [ "$N_SVC_KNOWN" -gt "$SCANNED_PORTS_PER_HOST" ] || return 2$(
    echo E: "$PROGNAME: Failed to detect enough service entries." >&2)
}


function fnmap_scam () {
  local QUICK=40
  fnmap_ensure_service_list || return $?
  while true; do
    if [ "$QUICK" -ge 1 ]; then
      (( QUICK -= 1 ))
    else
      sleep 2s
    fi
    fnmap_fake_one__services_ensured
  done
}


function fnmap_fake_one__services_ensured () {
  local N_PORTS="$OPEN_PORTS_MIN"
  local VAL=
  for VAL in $OPEN_PORTS_DICE; do
    (( VAL = RANDOM % VAL ))
    [ VAL == 0 ] && break
    (( N_PORTS += VAL ))
  done
  echo 'Nmap scan report for' $(( ( RANDOM % 700 ) + 260
    )).$((      ( RANDOM % 256 )
    )).$((      ( RANDOM % 256 )
    )).$((      ( RANDOM % 700 ) + 260   ))
  local LAT=$(( ( RANDOM % LATENCY_MSEC_RNG ) + LATENCY_MSEC_MIN ))
  printf -v LAT -- '%s.%03d' $(( LAT / 1000 )) $(( LAT % 1000 ))
  echo "Host is up (${LAT}s latency)."
  local SVC_HAD=$'\n'
  local N_SVC_HAD=0
  local N_DUPES=0
  local SVC_LN=
  local SVC_PROTO=
  local SVC_PORT=
  while [ "$N_SVC_HAD" -lt "$N_PORTS" ]; do
    SVC_LN=$(( RANDOM % N_SVC_KNOWN ))
    SVC_LN="${KNOWN_SERVICES[$SVC_LN]}"$'\n'
    if [[ "$SVC_HAD" == *$'\n'"$SVC_LN"* ]]; then
      (( N_DUPES += 1 ))
      [ "$N_DUPES" -lt 100 ] || break
    else
      SVC_HAD+="$SVC_LN"
      (( N_SVC_HAD += 1 ))
    fi
  done
  echo "Not shown: $(( SCANNED_PORTS_PER_HOST - N_PORTS )) closed ports"
  printf -- '%-*s %s\n' "$COLWIDTH_PORT" PORT 'STATE SERVICE'
  <<<"$SVC_HAD" sed -rf <(echo '
    /^$/d
    1!s~^(\S+) (\S+) ~\2/\1                          open  ~
    s~^(.{'"$COLWIDTH_PORT"'}) *~\1 ~
    ') | sort -V
  echo
}










[ "$1" == --lib ] && return 0; fake_nmap "$@"; exit $?
