#!/usr/bin/env bash
set -eu
##
# Usage: ./easyDNS.sh [<username>:<token>[:<domain> ...] ...]
##

################
# DEPENDENCIES #
################
hash dig 1>/dev/null 2>&1 || { echo >&2 "Please install dig"; exit 79; }

############
# DEFAULTS #
############
:

##########
# INPUTS #
##########
configurations=("${@}")

#############
# FUNCTIONS #
#############
ipv4() {
    host_ip="$(dig -4 +short +time=1 +tries=1 myip.opendns.com. A @resolver2.opendns.com.)" || { echo >&2 "Could not find IPv4 address for host, skipping..."; return; }

    update_easydns_if_changed A "${host_ip}"
}

ipv6() {
    host_ip="$(dig -6 +short +time=1 +tries=1 myip.opendns.com. AAAA @resolver2.opendns.com.)" || { echo >&2 "Could not find IPv6 address for host, skipping..."; return; }

    update_easydns_if_changed AAAA "${host_ip}"
}

update_easydns() {
    local username="${1:?must be provided}"
    local password="${2:?must be provided}"
    local domain="${3:?must be provided}"
    local host_ip="${4:?must be provided}"

    update_result="$(tr -d '\n' < <(curl --silent "http://${username}:${password}@api.cp.easydns.com/dyn/generic.php?hostname=${domain%.}&myip=${host_ip}"))" || :
    case "${update_result}" in
        *NO_AUTH*)
            echo >&2 "Invalid permissions to update '${domain}': ${update_result}"
            ;;
        *NO_SERVICE*)
            echo >&2 "Dynamic DNS is not enabled for '${domain}': ${update_result}"
            ;;
        *TOO_FREQ*)
            echo >&2 "Attempted to update '${domain}' too quickly: ${update_result}"
            ;;
        *NO_ERROR*|*OK*)
            echo "Updated '${domain}' to '${host_ip}': ${update_result}"
            ;;
        *)
            echo >&2 "Unknown result when updating '${domain}': ${update_result}"
            ;;
    esac

    # sleep to avoid hitting too frequently
    sleep 60
}

update_easydns_if_changed() {
    local qtype="${1:?must be provided}"
    local host_ip="${2:?must be provided}"

    for configuration in "${configurations[@]:+${configurations[@]}}"
    do
        while read -r username password domains
        do
            while read -r domain
            do
                echo "Looking up ${qtype} records for ${domain}..."
                domain_ips=()
                case "${qtype}" in
                    A)
                        resolver=
                        apex_domain="${domain}"
                        until [ -n "${resolver}" ]
                        do
                            resolver="$(head -n 1 <(dig -4 +short "${apex_domain}" NS))"
                            apex_domain="${apex_domain#*.}"
                        done

                        while read -r ip
                        do
                            domain_ips+=("${ip}")
                        done < <(dig -4 +short "${domain}" "${qtype}" "@${resolver}")
                        ;;
                    AAAA)
                        resolver=
                        apex_domain="${domain}"
                        until [ -n "${resolver}" ]
                        do
                            resolver="$(head -n 1 <(dig -6 +short "${apex_domain}" NS))"
                            apex_domain="${apex_domain#*.}"
                        done

                        while read -r ip
                        do
                            domain_ips+=("${ip}")
                        done < <(dig -6 +short "${domain}" "${qtype}" "@${resolver}")
                        ;;
                    *)
                        echo >&2 "Unknown query type '${qtype}' specified"
                        continue
                        ;;
                esac
                echo "Found ${#domain_ips[@]} ${qtype} record(s) for ${domain}: ${domain_ips[*]}"

                for ip in "${domain_ips[@]:+${domain_ips[@]}}"
                do
                    if [ "${ip}" = "${host_ip}" ]
                    then
                        continue 2
                    fi
                done

                update_easydns "${username}" "${password}" "${domain}" "${host_ip}"
            done < <(tr '\t' '\n' < <(echo "${domains}"))
        done < <(tr ':' '\t' < <(echo "${configuration}"))
      done
}

main() {
    ipv4
    ipv6
    sleep "${interval}"
}

#################
# CONFIGURATION #
#################
interval="${interval:-600}"

########
# MAIN #
########
main
