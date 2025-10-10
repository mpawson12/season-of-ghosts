# start-foundry.ps1

# Start Cloudflare tunnel and capture URL
$tunnelOutput = & cloudflared tunnel --url http://localhost:30000 2>&1
$url = ($tunnelOutput | Select-String -Pattern "https://[a-z0-9]*\.trycloudflare.com").Matches.Value

if (-not $url) {
    Write-Host "Could not capture URL - is Foundry running?"
    exit 1
}

$cachebuster = Get-Date -UFormat %s
$finalUrl = "$url?v=$cachebuster"

Write-Host "New tunnel URL: $finalUrl"

# Write index.html
@"
<!DOCTYPE html>
<html>
  <head>
    <script>
      window.location.replace("$finalUrl");
    </script>
  </head>
  <body>
    <p>Redirecting to Foundry VTT at <a href="$finalUrl">$finalUrl</a>…</p>
  </body>
</html>
"@ | Set-Content -Path index.html -Encoding UTF8

# Commit and push
git add index.html
git commit -m "Update redirect to $finalUrl"
git push

Write-Host "Redirect updated!
