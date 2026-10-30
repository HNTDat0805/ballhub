# ==============================================================================
# Installs Git Pre-Commit Hook to auto-scan secrets before each commit
# ==============================================================================

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")
$GitHooksDir = Join-Path $RepoRoot ".git\hooks"

if (-not (Test-Path $GitHooksDir)) {
    Write-Host "[ERROR] Could not find .git/hooks directory at: $GitHooksDir" -ForegroundColor Red
    exit 1
}

$PreCommitPath = Join-Path $GitHooksDir "pre-commit"

$HookContent = @'
#!/bin/sh
# Ballhub Automatic Pre-Commit Secret Scanner
echo "[Git Hook] Checking for secrets & credentials before commit..."

powershell.exe -ExecutionPolicy Bypass -File .agents/skills/ballhub-secret-scan/scripts/scan_secrets.ps1
STATUS=$?

if [ $STATUS -ne 0 ]; then
    echo ""
    echo "[COMMIT BLOCKED] Detected sensitive credentials or secret files!"
    echo "git commit has been aborted to protect your repository."
    exit 1
fi

exit 0
'@

Set-Content -Path $PreCommitPath -Value $HookContent
Write-Host "[SUCCESS] Installed Git Pre-Commit Hook at: $PreCommitPath" -ForegroundColor Green
Write-Host "From now on, all 'git commit' commands will be scanned automatically." -ForegroundColor Cyan
