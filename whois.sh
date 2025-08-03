#!/bin/bash

# Definicje kolorów
RED='\033[0;31m'
BLUE='\033[1;36m'
NC='\033[0m' # Resetowanie koloru

# Sprawdzenie, czy użytkownik podał nazwę domeny jako argument
if [ -z "$1" ]; then
    read -p "Domena: " domain
    echo ""
else
    domain=$1
fi

echo -e "${BLUE}Rekordy A i AAAA. Też dla www:${NC}"

# Rekordy A i AAAA dla domeny głównej
host "$domain" | awk '/has address/ || /IPv6 address/ { print $1, $NF }' | while read label ip; do
    reverse=$(host "$ip" | awk '/domain name pointer/ { print $NF }')
    echo "$ip    -> ${reverse:-brak hosta IP}"
done

# Jeśli brak
if ! host "$domain" | grep -qE "has address|IPv6 address"; then
    echo "Brak A/AAAA dla $domain"
fi

# Rekordy A i AAAA dla www.domena
host www."$domain" | awk '/has address/ || /IPv6 address/ { print $1, $NF }' | while read label ip; do
    reverse=$(host "$ip" | awk '/domain name pointer/ { print $NF }')
    echo "$ip (www)    -> ${reverse:-brak hosta IP}"
done

# Jeśli brak
if ! host www."$domain" | grep -qE "has address|IPv6 address"; then
    echo "Brak A/AAAA dla www.$domain"
fi
echo ""

echo -e "${BLUE}Rekordy NS:${NC}"
ns_records=$(host -t ns "$domain")
if echo "$ns_records" | grep -qiE "has no NS record|not found"; then
    echo "Brak NS"
else
    echo "$ns_records" | awk '/name server/ { print $NF }' | sed 's/\.$//'
fi
echo ""

echo -e "${BLUE}Rekordy MX:${NC}"
mx_records=$(host -t mx "$domain")
if echo "$mx_records" | grep -qiE "has no MX record|not found"; then
    echo "Brak MX"
else
    echo "$mx_records"
fi
echo ""

echo -e "${BLUE}Rekordy TXT:${NC}"
txt_records=$(host -t txt "$domain")
if echo "$txt_records" | grep -qiE "has no TXT record|not found"; then
    echo "Brak TXT"
else
    echo "$txt_records"
fi
echo ""

echo -e "${BLUE}Rekord DKIM default:${NC}"
dkim_default=$(host -t txt default._domainkey."$domain")
if echo "$dkim_default" | grep -qiE "has no TXT record|not found"; then
    echo "Brak DKIM dla default"
else
    echo "$dkim_default"
fi
echo ""

echo -e "${BLUE}Rekord DKIM x:${NC}"
dkim_x=$(host -t txt x._domainkey."$domain")
if echo "$dkim_x" | grep -qiE "has no TXT record|not found"; then
    echo "Brak DKIM dla x"
else
    echo "$dkim_x"
fi
echo ""

echo -e "${BLUE}Rekordy DMARC:${NC}"
dmarc=$(host -t txt _dmarc."$domain")
if echo "$dmarc" | grep -qiE "has no TXT record|not found"; then
    echo "Brak DMARC"
else
    echo "$dmarc"
fi
echo ""

echo -e "${BLUE}Rekord SOA:${NC}"
soa_output=$(host -t soa "$domain" ns.lh.pl 2>&1)
if echo "$soa_output" | grep -qiE "not found|REFUSED|NXDOMAIN|SERVFAIL"; then
    echo "Brak SOA w strefie ns.lh.pl. Domena nie jest dodana do serwera w LH"
else
    echo "$soa_output" | awk '/has SOA record/'
fi
