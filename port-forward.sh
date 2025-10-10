#!/bin/bash

# Start Cloudflare tunnel and capture URL
URL=$(cloudflared tunnel --url http://localhost:30000 2>&1 | grep -o "https://[a-z0-9]*\.trycloudflare.com" | head -n 1)

if [ -z "$URL" ]; then
  echo "Could not capture URL - is Foundry running?"
  exit 1
fi

CACHEBUSTER=$(date +%s)
FINAL_URL="${URL}?v=${CACHEBUSTER}"

echo "New tunnel URL: $FINAL_URL"

# Write index.html with JavaScript redirect
cat > index.html <<EOF
<!DOCTYPE html>
<html>
  <head>
    <script>
      window.location.replace("$FINAL_URL");
    </script>
  </head>
  <body>
    <p>Redirecting to Foundry VTT at <a href="$FINAL_URL">$FINAL_URL</a>…</p>
  </body>
</html>
EOF

# Commit and push to GitHub
git add index.html
git commit -m "Update redirect to $FINAL_URL"
git push

echo "Redirect updated!"
