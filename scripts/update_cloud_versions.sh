
#!/bin/bash

set -e

if [ "$#" -lt 4 ]; then
    echo "Usage: $0 <cloud_provider> <environment> <module> <version>"
    echo "Example: $0 aws development networking v2"
    exit 1
fi

CLOUD_PROVIDER="$1"
ENVIRONMENT="$2"
MODULE="$3"
VERSION="$4"

VERSION_FILE="${CLOUD_PROVIDER}/environments/versions.json"

if [ ! -f "$VERSION_FILE" ]; then
    echo "Error: Version file $VERSION_FILE not found!"
    exit 1
fi

if ! jq -e ".environments.\"$ENVIRONMENT\"" "$VERSION_FILE" > /dev/null 2>&1; then
    echo "Error: Environment '$ENVIRONMENT' not found in version file!"
    exit 1
fi

MODULE_PATH="${CLOUD_PROVIDER}/modules/${MODULE}/${VERSION}"
if [ ! -d "$MODULE_PATH" ]; then
    echo "Error: Module $MODULE at version $VERSION does not exist ($MODULE_PATH)!"
    exit 1
fi

CURRENT_VERSION=$(jq -r ".environments.\"$ENVIRONMENT\".\"$MODULE\"" "$VERSION_FILE")
if [ "$CURRENT_VERSION" == "null" ]; then
    echo "Warning: Module $MODULE was not previously defined in environment $ENVIRONMENT."
elif [ "$CURRENT_VERSION" == "$VERSION" ]; then
    echo "Module $MODULE is already at version $VERSION in environment $ENVIRONMENT. No changes needed."
    exit 0
else
    echo "Updating module $MODULE from $CURRENT_VERSION to $VERSION in environment $ENVIRONMENT."
fi

jq --arg module "$MODULE" --arg version "$VERSION" --arg env "$ENVIRONMENT" \
    '.environments[$env][$module] = $version' "$VERSION_FILE" > "${VERSION_FILE}.tmp"
mv "${VERSION_FILE}.tmp" "$VERSION_FILE"

jq --arg date "$(date +'%Y-%m-%d')" --arg user "$(whoami)" \
    --arg changes "Updated $MODULE from $CURRENT_VERSION to $VERSION in environment $ENVIRONMENT" \
    '.update_history = [{"date": $date, "user": $user, "changes": $changes}] + .update_history' \
    "$VERSION_FILE" > "${VERSION_FILE}.tmp"
mv "${VERSION_FILE}.tmp" "$VERSION_FILE"

VERSIONS_TF="${CLOUD_PROVIDER}/environments/${ENVIRONMENT}/versions.tf"

if [ ! -f "$VERSIONS_TF" ]; then
    echo "Warning: File $VERSIONS_TF not found. Creating new file..."
    
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

echo "Update completed successfully!"
echo "Module $MODULE is now at version $VERSION in environment $ENVIRONMENT."
