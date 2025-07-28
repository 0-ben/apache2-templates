#!/bin/bash

# script to download cloudflare ipv4 & ipv6 list and output it to a .conf (/etc/apache2/conf-available/ip_whitelist.conf)

IPV4_URL="https://www.cloudflare.com/ips-v4"
IPV6_URL="https://www.cloudflare.com/ips-v6"

APACHE_CONF="/etc/apache2/conf-available/ip_whitelist.conf"

# temp randomly named files
TEMP_IPV4=$(mktemp)
TEMP_IPV6=$(mktemp)

echo "Downloading IPv4"
curl -s -f -o "$TEMP_IPV4" "$IPV4_URL"
if [ $? -ne 0 ]; then
    echo "ipv4 download failed"
    rm -f "$TEMP_IPV4" "$TEMP_IPV6"
    exit 1
fi

echo "Downloading IPv6"
curl -s -f -o "$TEMP_IPV6" "$IPV6_URL"
if [ $? -ne 0 ]; then
    echo "ipv6 download failed"
    rm -f "$TEMP_IPV4" "$TEMP_IPV6"
    exit 1
fi

{
    echo "# Generated on $(date)"
    echo "<Location />"
    echo "<RequireAll>"
    echo "    Require all granted"
    echo "    <RequireAny>"

    while IFS= read -r ip; do
        [[ -z "$ip" ]] && continue
        echo "        Require ip $ip"
    done < "$TEMP_IPV4"

    while IFS= read -r ip; do
        [[ -z "$ip" ]] && continue
        echo "        Require ip $ip"
    done < "$TEMP_IPV6"

    echo "    </RequireAny>"
    echo "</Location>"
} > "$APACHE_CONF"

rm -f "$TEMP_IPV4" "$TEMP_IPV6"

a2enconf ip_whitelist > /dev/null 2>&1

echo "Reloading Apache"
systemctl reload apache2
if [ $? -ne 0 ]; then
    echo "Failed to reload Apache. Check configuration."
    exit 1
fi

echo "Success."