#!/bin/bash

set -e

if [ "$#" -lt 3 ]; then
    echo "Utilizzo: $0 <ambiente> <modulo> <versione>"
    echo "Esempio: $0 development gcp_networking v2"
    exit 1
fi

ENVIRONMENT="$1"
MODULE="$2"
VERSION="$3"

VERSION_FILE="environments/versions.json"

if [ ! -f "$VERSION_FILE" ]; then
    echo "Errore: File $VERSION_FILE non trovato!"
    exit 1
fi

if ! jq -e ".environments.\"$ENVIRONMENT\"" "$VERSION_FILE" > /dev/null 2>&1; then
    echo "Errore: Ambiente '$ENVIRONMENT' non trovato nel file delle versioni!"
    exit 1
fi

MODULE_PATH="modules/$MODULE/$VERSION"
if [ ! -d "$MODULE_PATH" ]; then
    echo "Errore: Il modulo $MODULE alla versione $VERSION non esiste ($MODULE_PATH)!"
    exit 1
fi

CURRENT_VERSION=$(jq -r ".environments.\"$ENVIRONMENT\".\"$MODULE\"" "$VERSION_FILE")
if [ "$CURRENT_VERSION" == "null" ]; then
    echo "Attenzione: Il modulo $MODULE non era precedentemente definito nell'ambiente $ENVIRONMENT."
elif [ "$CURRENT_VERSION" == "$VERSION" ]; then
    echo "Il modulo $MODULE è già alla versione $VERSION nell'ambiente $ENVIRONMENT. Nessuna modifica necessaria."
    exit 0
else
    echo "Aggiornamento del modulo $MODULE da $CURRENT_VERSION a $VERSION nell'ambiente $ENVIRONMENT."
fi

jq --arg module "$MODULE" --arg version "$VERSION" --arg env "$ENVIRONMENT" \
    '.environments[$env][$module] = $version' "$VERSION_FILE" > "${VERSION_FILE}.tmp"
mv "${VERSION_FILE}.tmp" "$VERSION_FILE"

LATEST_VERSION=$(jq -r ".latest.\"$MODULE\"" "$VERSION_FILE")
if [ "$LATEST_VERSION" == "null" ] || [[ "${VERSION:1}" > "${LATEST_VERSION:1}" ]]; then
    jq --arg module "$MODULE" --arg version "$VERSION" \
        '.latest[$module] = $version' "$VERSION_FILE" > "${VERSION_FILE}.tmp"
    mv "${VERSION_FILE}.tmp" "$VERSION_FILE"
    echo "Aggiornata anche latest per $MODULE a $VERSION"
fi

jq --arg date "$(date +'%Y-%m-%d')" --arg user "$(whoami)" \
    --arg changes "Aggiornato $MODULE da $CURRENT_VERSION a $VERSION nell'ambiente $ENVIRONMENT" \
    '.update_history = [{"date": $date, "user": $user, "changes": $changes}] + .update_history' \
    "$VERSION_FILE" > "${VERSION_FILE}.tmp"
mv "${VERSION_FILE}.tmp" "$VERSION_FILE"

VERSIONS_TF="environments/$ENVIRONMENT/versions.tf"

if [ ! -f "$VERSIONS_TF" ]; then
    echo "Avviso: File $VERSIONS_TF non trovato. Creazione di un nuovo file..."
    
    cat > "$VERSIONS_TF" << EOF

terraform {
  required_version = ">= 1.0.0"
}

locals {
  module_versions = {
    "$MODULE" = "$VERSION"
  }
}
EOF
else

    if grep -q "\"$MODULE\"" "$VERSIONS_TF"; then

        sed -i "s/\"$MODULE\" *= *\"v[0-9.]*\"/\"$MODULE\" = \"$VERSION\"/" "$VERSIONS_TF"
    else

        awk -v module="$MODULE" -v version="$VERSION" '
        /module_versions = {/ {
            print $0
            print "    \"" module "\" = \"" version "\","
            next
        }
        {print}
        ' "$VERSIONS_TF" > "${VERSIONS_TF}.tmp"
        mv "${VERSIONS_TF}.tmp" "$VERSIONS_TF"
    fi
fi

echo "Aggiornamento completato con successo!"
echo "Il modulo $MODULE è ora alla versione $VERSION nell'ambiente $ENVIRONMENT."
exit 0