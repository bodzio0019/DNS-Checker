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

# Wykonanie zapytania DNS dla domeny, aby uzyskać adres IP
ip_addresses=$(host "$domain" | awk '/has address/ { print $4 }')

# Sprawdzenie, czy zapytanie zwróciło adres IP
if [ -z "$ip_addresses" ]; then
  echo -e "${RED}Nie udało się uzyskać adresów IP dla domeny: $domain${NC}"
  exit 1
fi

# Wyświetlenie adresów IP i wykonanie zapytań wstecznych
for ip_address in $ip_addresses; do
  echo -e "${BLUE}Rekordy A. Drugi dla www:${NC}"
  host "$domain" | awk '/has address/ { print $4 }'
  host www."$domain" | awk '/has address/ { print $4 }'
  echo ""
  
  # Wykonanie zapytania wstecznego DNS na uzyskany adres IP
  echo -e "${BLUE}Host IP:${NC}"
  host "$ip_address" | awk '/domain name pointer/ { ptr = $NF } END { print ptr }'
  echo ""

  # Zapytanie o rekordy NS
  echo -e "${BLUE}Rekordy NS:${NC}"
  ns_records=$(host -t ns "$domain" | awk '/name server/ { print $NF }')
  
  # Wyświetlenie wyników NS bez dodatkowych informacji
  for ns in $ns_records; do
    echo "${ns%.}"
  done
  echo ""

  # Zapytanie o rekordy MX
  echo -e "${BLUE}Rekordy MX:${NC}"
  host -t mx "$domain"
  echo ""

  # Zapytanie o rekordy TXT
  echo -e "${BLUE}Rekordy TXT:${NC}"
  host -t txt "$domain"
  echo ""

  # Zapytanie o rekord DKIM dla wspoldzielonego
  echo -e "${BLUE}Rekord DKIM default:${NC}"
  host -t txt default._domainkey."$domain"
  echo ""
 
  # Zapytanie o rekord DKIM dla clouda
  echo -e "${BLUE}Rekord DKIM x:${NC}"
  host -t txt x._domainkey."$domain"
  echo ""

  # Zapytanie o rekordy DMARC
  echo -e "${BLUE}Rekordy DMARC:${NC}"
  host -t txt _dmarc."$domain"
  echo ""

  # Zapytanie o rekord SOA
  echo -e "${BLUE}Rekord SOA:${NC}"
  host -t soa "$domain" ns.lh.pl
  echo ""

done

