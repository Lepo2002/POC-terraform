#!/bin/bash

set -e

if [ "$#" -lt 3 ]; then
    echo "Utilizzo: $0 <modulo> <versione_attuale> <tipo_incremento>"
    echo "Esempio: $0 gcp_networking v1 minor"
    echo "Tipi di incremento: patch, minor, major"
    exit 1
fi

MODULE="$1"
CURRENT_VERSION="$2"
BUMP_TYPE="$3"

MODULE_PATH="modules/$MODULE/$CURRENT_VERSION"
if [ ! -d "$MODULE_PATH" ]; then
    echo "Errore: Il modulo $MODULE alla versione $CURRENT_VERSION non esiste ($MODULE_PATH)!"
    exit 1
fi

VERSION_NUM=${CURRENT_VERSION#v}

if [[ "$VERSION_NUM" =~ ^([0-9]+)\.([0-9]+)$ ]]; then
    MAJOR="${BASH_REMATCH[1]}"
    MINOR="${BASH_REMATCH[2]}"
else
    echo "Errore: Formato versione non valido. Deve essere in formato 'vX.Y'"
    exit 1
fi

case "$BUMP_TYPE" in
    "patch")

        NEW_VERSION="v$MAJOR.$((MINOR + 1))"
        ;;
    "minor")
        NEW_VERSION="v$MAJOR.$((MINOR + 1))"
        ;;
    "major")
        NEW_VERSION="v$((MAJOR + 1)).0"
        ;;
    *)
        echo "Errore: Tipo di incremento non valido. Usa 'patch', 'minor' o 'major'."
        exit 1
        ;;
esac

NEW_MODULE_PATH="modules/$MODULE/$NEW_VERSION"

if [ -d "$NEW_MODULE_PATH" ]; then
    echo "Errore: La versione $NEW_VERSION del modulo $MODULE esiste già!"
    exit 1
fi

echo "Creazione della nuova versione $NEW_VERSION per il modulo $MODULE..."

mkdir -p "$NEW_MODULE_PATH"

cp -r "$MODULE_PATH"/* "$NEW_MODULE_PATH"/

README_PATH="$NEW_MODULE_PATH/README.md"
if [ -f "$README_PATH" ]; then

    sed -i "s/Versione: $CURRENT_VERSION/Versione: $NEW_VERSION/" "$README_PATH"
    sed -i "s/Version: $CURRENT_VERSION/Version: $NEW_VERSION/" "$README_PATH"
    
    if ! grep -q "## Changelog" "$README_PATH"; then
        echo -e "\n## Changelog\n\n- $NEW_VERSION: Aggiornamento dalla versione $CURRENT_VERSION" >> "$README_PATH"
    else

        sed -i "/## Changelog/a - $NEW_VERSION: Aggiornamento dalla versione $CURRENT_VERSION" "$README_PATH"
    fi
    
    echo "README aggiornato con la nuova versione."
fi

echo "$NEW_VERSION"

echo "Modulo $MODULE aggiornato con successo alla versione $NEW_VERSION."
echo "La nuova versione si trova in: $NEW_MODULE_PATH"
echo "Ricorda di aggiornare le referenze al modulo negli ambienti di sviluppo."
exit 0