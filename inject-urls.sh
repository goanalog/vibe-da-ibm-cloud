#!/usr/bin/env bash
# inject-urls.sh — Auto-update Vibe IDE with live Function URLs
# Usage: ./inject-urls.sh <push_cos_url> <push_project_url>

PUSH_COS_URL="$1"
PUSH_PROJECT_URL="$2"

if [ -z "$PUSH_COS_URL" ] || [ -z "$PUSH_PROJECT_URL" ]; then
  echo "Usage: ./inject-urls.sh <push_cos_url> <push_project_url>"
  exit 1
fi

cat <<EOF > injected-vars.txt
PUSH_COS_URL=$PUSH_COS_URL
PUSH_PROJECT_URL=$PUSH_PROJECT_URL
EOF

# Also perform inline replace if you want static embedding:
sed -i.bak \
  -e "s|__PUSH_COS_URL__|$PUSH_COS_URL|g" \
  -e "s|__PUSH_PROJECT_URL__|$PUSH_PROJECT_URL|g" \
  index.html

echo "Injected URLs into index.html and created injected-vars.txt ✨"
