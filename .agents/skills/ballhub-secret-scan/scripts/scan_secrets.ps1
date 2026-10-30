# ==============================================================================
# Ballhub Secret Scanner Script (PowerShell)
# Scans repository for sensitive files and secret credentials before commit/push
# ==============================================================================

$ErrorActionPreference = "Stop"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " [BALLHUB] Starting Pre-Push Secret & Credential Scan...         " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")
Set-Location $RepoRoot

$FoundIssues = 0

# 1. Forbidden file patterns
$ForbiddenPatterns = @(
    "*.env",
    "*.env.local",
    "*.env.production",
    "*service-account*.json",
    "*service_account*.json",
    "*.runtimeconfig.json",
    "*key.properties",
    "*.keystore",
    "*.jks",
    "*.p12",
    "*.mobileprovision",
    "*id_rsa",
    "*id_ed25519"
)

Write-Host "`n[1/3] Checking for sensitive files in repository tree..." -ForegroundColor Yellow

foreach ($pattern in $ForbiddenPatterns) {
    $matches = Get-ChildItem -Path $RepoRoot -Filter $pattern -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { 
            $_.FullName -notmatch "node_modules|\.dart_tool|build|\.git|\.history" 
        }
    
    foreach ($file in $matches) {
        $relPath = $file.FullName.Replace($RepoRoot.Path, "")
        Write-Host " [DANGER] Detected sensitive credential file: $relPath" -ForegroundColor Red
        $FoundIssues++
    }
}

# 2. Check Git Staged and Tracked files
Write-Host "`n[2/3] Checking Git tracked and staged files..." -ForegroundColor Yellow
try {
    $trackedFiles = & git ls-files
    foreach ($file in $trackedFiles) {
        if ($file -match "\.env$|\.env\.|\.keystore$|\.jks$|key\.properties$|service-account.*\.json$") {
            Write-Host " [GIT TRACKED LEAK] Sensitive file is currently tracked by Git: $file" -ForegroundColor Red
            $FoundIssues++
        }
    }
} catch {
    Write-Host " (Git command not available, skipping tracked file check)" -ForegroundColor Gray
}

# 3. Source code scanning for private keys and tokens
Write-Host "`n[3/3] Scanning source code contents for hardcoded credentials..." -ForegroundColor Yellow

$SecretRegexList = @(
    @{ Name = "RSA or Private Key Header"; Regex = "-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----" },
    @{ Name = "Google Service Account Type"; Regex = '"type"\s*:\s*"service_account"' },
    @{ Name = "Stripe Live Secret Key"; Regex = 'sk_live_[0-9a-zA-Z]{24}' },
    @{ Name = "Hardcoded Private Key or Secret Token"; Regex = '(?i)(client_secret|jwt_secret|private_key)\s*[:=]\s*["''][^"''\s]{12,}["'']' }
)

$sourceFiles = Get-ChildItem -Path $RepoRoot -Recurse -File -Include "*.dart", "*.ts", "*.js", "*.json", "*.yaml", "*.yml" |
    Where-Object { 
        $_.FullName -notmatch "node_modules|\.dart_tool|build|\.git|dist|\.history|package-lock\.json|pubspec\.lock|firebase_options\.dart|\.agents" 
    }

foreach ($file in $sourceFiles) {
    try {
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }

        foreach ($rule in $SecretRegexList) {
            if ($content -match $rule.Regex) {
                $relPath = $file.FullName.Replace($RepoRoot.Path, "")
                Write-Host " [SECURITY WARNING] Found pattern '$($rule.Name)' in: $relPath" -ForegroundColor Red
                $FoundIssues++
            }
        }
    } catch {}
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
if ($FoundIssues -eq 0) {
    Write-Host " [PASSED] Clean! No sensitive files or private credentials found." -ForegroundColor Green
    Write-Host " Safe to commit and push to GitHub." -ForegroundColor Green
    Write-Host "=================================================================`n" -ForegroundColor Cyan
    exit 0
} else {
    Write-Host " [ALERT] Found $FoundIssues security issue(s) that may leak secrets!" -ForegroundColor Red
    Write-Host " Please review .gitignore and remove sensitive credentials before pushing." -ForegroundColor Yellow
    Write-Host "=================================================================`n" -ForegroundColor Cyan
    exit 1
}
