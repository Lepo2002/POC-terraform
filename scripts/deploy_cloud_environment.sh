
#!/bin/bash

set -e

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <cloud_provider> <environment> [target]"
    echo "Example: $0 aws production"
    echo "Example with target: $0 gcp development module.networking"
    exit 1
fi

CLOUD_PROVIDER="$1"
ENVIRONMENT="$2"
TARGET="$3"
LOCK_ID="terraform-${CLOUD_PROVIDER}-${ENVIRONMENT}-lock"
TIMEOUT=1800

ENV_DIR="${CLOUD_PROVIDER}/environments/${ENVIRONMENT}"
if [ ! -d "$ENV_DIR" ]; then
    echo "Error: Environment $ENVIRONMENT does not exist in $CLOUD_PROVIDER ($ENV_DIR)!"
    exit 1
fi

get_lock_project_id() {
    echo "terraform-state-project"
}

check_lock() {
    local project_id=$(get_lock_project_id)
    
    echo "Checking if lock exists for $CLOUD_PROVIDER environment $ENVIRONMENT..."
    
    existing_lock=$(gcloud firestore documents get "projects/$project_id/databases/(default)/documents/terraform-locks/$LOCK_ID" 2>/dev/null || echo "")
    
    if [ -n "$existing_lock" ]; then
        lock_timestamp=$(echo "$existing_lock" | grep -o '"timestamp": "[^"]*"' | cut -d'"' -f4)
        lock_user=$(echo "$existing_lock" | grep -o '"user": "[^"]*"' | cut -d'"' -f4)
        
        lock_time=$(date -d "@$lock_timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "unknown time")
        
        echo "⚠️ Lock already exists for $CLOUD_PROVIDER environment $ENVIRONMENT!"
        echo "Lock created by: $lock_user"
        echo "Lock created at: $lock_time"

        current_time=$(date +%s)
        if [ $((current_time - lock_timestamp)) -gt $TIMEOUT ]; then
            echo "Lock has expired (older than 30 minutes). Forcing release..."
            release_lock
            return 0
        else
            echo "❌ Cannot proceed. Wait for the lock to be released or expire."
            return 1
        fi
    fi
    
    return 0
}

acquire_lock() {
    local project_id=$(get_lock_project_id)
    local timestamp=$(date +%s)
    local user=$(whoami)
    
    echo "Acquiring lock for $CLOUD_PROVIDER environment $ENVIRONMENT..."

    gcloud firestore documents create "projects/$project_id/databases/(default)/documents/terraform-locks" \
        --document-id="$LOCK_ID" \
        --field="timestamp=$timestamp" \
        --field="user=$user" \
        --field="environment=$ENVIRONMENT" \
        --field="cloud_provider=$CLOUD_PROVIDER"
    
    echo "✅ Lock acquired successfully."
}

release_lock() {
    local project_id=$(get_lock_project_id)
    
    echo "Releasing lock for $CLOUD_PROVIDER environment $ENVIRONMENT..."
    
    gcloud firestore documents delete "projects/$project_id/databases/(default)/documents/terraform-locks/$LOCK_ID" --quiet
    
    echo "✅ Lock released successfully."
}

if ! check_lock; then
    exit 1
fi

acquire_lock

trap "echo 'Releasing lock before exit...'; release_lock" EXIT INT TERM

cd "$ENV_DIR"

echo "Initializing Terraform..."
terraform init

if [ -n "$TARGET" ]; then
    echo "Planning Terraform with target $TARGET..."
    terraform plan -target="$TARGET"
    
    echo "Applying Terraform with target $TARGET..."
    terraform apply -target="$TARGET"
else
    echo "Planning Terraform..."
    terraform plan
    
    echo "Applying Terraform..."
    terraform apply
fi

echo "Operation completed successfully!"
