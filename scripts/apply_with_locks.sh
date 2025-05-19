#!/bin/bash

set -e

if [ "$#" -lt 1 ]; then
    echo "Utilizzo: $0 <environment> [target]"
    echo "Esempio: $0 development"
    echo "Esempio con target: $0 development module.gcp_networking"
    exit 1
fi

ENVIRONMENT="$1"
TARGET="$2"
LOCK_ID="terraform-$ENVIRONMENT-lock"
TIMEOUT=1800

ENV_DIR="environments/$ENVIRONMENT"
if [ ! -d "$ENV_DIR" ]; then
    echo "Errore: L'ambiente $ENVIRONMENT non esiste ($ENV_DIR)!"
    exit 1
fi

get_lock_project_id() {

    echo "terraform-state-project"
}

check_lock() {
    local project_id=$(get_lock_project_id)
    
    echo "Verifica se esiste già un lock per l'ambiente $ENVIRONMENT..."
    
    existing_lock=$(gcloud firestore documents get "projects/$project_id/databases/(default)/documents/terraform-locks/$LOCK_ID" 2>/dev/null || echo "")
    
    if [ -n "$existing_lock" ]; then

        lock_timestamp=$(echo "$existing_lock" | grep -o '"timestamp": "[^"]*"' | cut -d'"' -f4)
        lock_user=$(echo "$existing_lock" | grep -o '"user": "[^"]*"' | cut -d'"' -f4)
        
        lock_time=$(date -d "@$lock_timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "tempo sconosciuto")
        
        echo "⚠️ Lock già esistente per l'ambiente $ENVIRONMENT!"
        echo "Lock creato da: $lock_user"
        echo "Lock creato il: $lock_time"

        current_time=$(date +%s)
        if [ $((current_time - lock_timestamp)) -gt $TIMEOUT ]; then
            echo "Il lock è scaduto (più vecchio di 30 minuti). Forzatura del rilascio..."
            release_lock
            return 0
        else
            echo "❌ Non è possibile procedere. Attendi che il lock venga rilasciato o scada."
            return 1
        fi
    fi
    
    return 0
}

acquire_lock() {
    local project_id=$(get_lock_project_id)
    local timestamp=$(date +%s)
    local user=$(whoami)
    
    echo "Acquisizione lock per l'ambiente $ENVIRONMENT..."

    gcloud firestore documents create "projects/$project_id/databases/(default)/documents/terraform-locks" \
        --document-id="$LOCK_ID" \
        --field="timestamp=$timestamp" \
        --field="user=$user" \
        --field="environment=$ENVIRONMENT"
    
    echo "✅ Lock acquisito con successo."
}

release_lock() {
    local project_id=$(get_lock_project_id)
    
    echo "Rilascio lock per l'ambiente $ENVIRONMENT..."
    
    gcloud firestore documents delete "projects/$project_id/databases/(default)/documents/terraform-locks/$LOCK_ID" --quiet
    
    echo "✅ Lock rilasciato con successo."
}

if ! check_lock; then
    exit 1
fi

acquire_lock

trap "echo 'Rilascio lock prima di uscire...'; release_lock" EXIT INT TERM

cd "$ENV_DIR"

echo "Inizializzazione Terraform..."
terraform init

if [ -n "$TARGET" ]; then
    echo "Pianificazione Terraform con target $TARGET..."
    terraform plan -target="$TARGET"
    
    echo "Applicazione Terraform con target $TARGET..."
    terraform apply -target="$TARGET"
else
    echo "Pianificazione Terraform..."
    terraform plan
    
    echo "Applicazione Terraform..."
    terraform apply
fi

echo "Operazione completata con successo!"
exit 0