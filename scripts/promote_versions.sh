#!/bin/bash


set -e

if [ "$#" -lt 2 ]; then
    echo "Utilizzo: $0 <ambiente_sorgente> <ambiente_destinazione> [modulo_specifico]"
    echo "Esempio: $0 development testing gcp_networking"
    exit 1
fi

SOURCE_ENV="$1"
TARGET_ENV="$2"
SPECIFIC_MODULE="$3"

VERSION_FILE="environments/versions.json"

if [ ! -f "$VERSION_FILE" ]; then
    echo "Errore: File $VERSION_FILE non trovato!"
    exit 1
fi

if ! jq -e ".environments.\"$SOURCE_ENV\"" "$VERSION_FILE" > /dev/null 2>&1; then
    echo "Errore: Ambiente sorgente '$SOURCE_ENV' non trovato nel file delle versioni!"
    exit 1
fi

if ! jq -e ".environments.\"$TARGET_ENV\"" "$VERSION_FILE" > /dev/null 2>&1; then
    echo "Errore: Ambiente destinazione '$TARGET_ENV' non trovato nel file delle versioni!"
    exit 1
fi

promote_module() {
    local module="$1"
    
    local source_version=$(jq -r ".environments.\"$SOURCE_ENV\".\"$module\"" "$VERSION_FILE")
    
    if [ "$source_version" == "null" ]; then
        echo "Avviso: Modulo '$module' non trovato nell'ambiente sorgente. Nessuna promozione necessaria."
        return
    fi

    local target_version=$(jq -r ".environments.\"$TARGET_ENV\".\"$module\"" "$VERSION_FILE")
    
    if [ "$source_version" == "$target_version" ]; then
        echo "Modulo '$module': Già alla versione $source_version in entrambi gli ambienti. Nessuna promozione necessaria."
        return
    fi
    
    echo "Promozione del modulo '$module' da $source_version a $target_version"
    
    jq --arg module "$module" --arg version "$source_version" --arg env "$TARGET_ENV" \
        '.environments[$env][$module] = $version' "$VERSION_FILE" > "${VERSION_FILE}.tmp"
    mv "${VERSION_FILE}.tmp" "$VERSION_FILE"

    update_environment_config "$module" "$source_version"
    
    echo "Modulo '$module' promosso con successo alla versione $source_version nell'ambiente $TARGET_ENV"
}

update_environment_config() {
    local module="$1"
    local version="$2"

    local versions_tf="environments/$TARGET_ENV/versions.tf"
    
    if [ ! -f "$versions_tf" ]; then
        echo "Avviso: File $versions_tf non trovato. Creazione di un nuovo file..."
        
        cat > "$versions_tf" << EOF

terraform {
  required_version = ">= 1.0.0"
}

locals {
  module_versions = {
  }
}
EOF
    fi
    
    if grep -q "\"$module\"" "$versions_tf"; then

        sed -i "s/\"$module\" *= *\"v[0-9.]*\"/\"$module\" = \"$version\"/" "$versions_tf"
    else

        awk -v module="$module" -v version="$version" '
        /module_versions = {/ {
            print $0
            print "    \"" module "\" = \"" version "\","
            next
        }
        {print}
        ' "$versions_tf" > "${versions_tf}.tmp"
        mv "${versions_tf}.tmp" "$versions_tf"
    fi
    
    echo "File $versions_tf aggiornato per il modulo $module"
}

if [ -n "$SPECIFIC_MODULE" ]; then

    promote_module "$SPECIFIC_MODULE"
else

    echo "Promozione di tutti i moduli da $SOURCE_ENV a $TARGET_ENV..."
    
    modules=$(jq -r ".environments.\"$SOURCE_ENV\" | keys[]" "$VERSION_FILE")
    
    for module in $modules; do
        promote_module "$module"
    done
fi

echo "Promozione completata con successo!"
exit 0