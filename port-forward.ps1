# Open cloudflared in a new Windows Terminal tab and write logs to a file
$logDir  = Join-Path $env:USERPROFILE ".cloudflared"
$logFile = Join-Path $logDir "cloudflared.log"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
if (Test-Path $logFile) { Clear-Content -Path $logFile }

wt -w 0 new-tab -p "Windows PowerShell" powershell -NoExit -Command "cloudflared tunnel --url http://localhost:30000 --logfile `"$logFile`""

echo "Started - waiting 10s..."
Start-Sleep -Seconds 10

# Read the logfile and extract the first trycloudflare URL
# (allow hyphens in subdomain just in case)
$lines = Get-Content $logFile -ErrorAction SilentlyContinue
$match = ($lines | Select-String -Pattern "https://[a-z0-9-]+\.trycloudflare\.com" | Select-Object -First 1)

if (-not $match) {
  echo "Could not capture URL - check cloudflared log at $logFile"
  exit 1
}

$url = $match.Matches[0].Value.Trim()
echo "URL: $url"

# Build cache-busted final URL (append to the tunnel URL, not GitHub)
$cachebuster = Get-Date -UFormat %s
$finalUrl = "{0}?v={1}" -f $url, $cachebuster
echo "Final URL: $finalUrl"

# Write redirect page using JavaScript (no meta refresh)
@"
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Redirecting…</title>
    <meta http-equiv="refresh" content="0; url=$finalUrl">
    <script>
      (function() {
        var target = "$finalUrl";
        // Prefer replace (no back button to GitHub page), fallback assign
        try { window.location.replace(target); }
        catch (e) { window.location.href = target; }
      })();
    </script>
  </head>
  <body>
    <p>Redirecting to Foundry VTT at <a href="$finalUrl">$finalUrl</a>…</p>
  </body>
</html>
"@ | Set-Content -Path index.html -Encoding UTF8

git add index.html
git commit -m "Update redirect to $finalUrl"
git push

echo "Pushed to GitHub - wait ~60s for Pages to deploy"
