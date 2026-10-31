# Script kiểm tra tự động trước khi Review / Merge cho Ballhub
# Chạy từ thư mục gốc do_an_mobile: powershell -File .agents/skills/ballhub-code-review/scripts/review-check.ps1

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "⚽ BẮT ĐẦU KIỂM TRA CHẤT LƯỢNG CODE BALLHUB" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)))
$ballhubDir = Join-Path $root "ballhub"
if (-not (Test-Path $ballhubDir)) {
    # If already running inside ballhub directory
    $ballhubDir = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
}
$functionsDir = Join-Path $ballhubDir "functions"

# 1. FRONTEND FLUTTER CHECKS
Write-Host "`n[1/4] 🚀 Đang kiểm tra Dart Analyzer (lib/ & test/)..." -ForegroundColor Yellow
Push-Location $ballhubDir
try {
    $dartAnalyze = dart analyze lib test
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Dart Analyzer phát hiện lỗi!" -ForegroundColor Red
        Write-Host $dartAnalyze
    } else {
        Write-Host "✅ Dart Analyzer: 0 lỗi / cảnh báo." -ForegroundColor Green
    }

    Write-Host "`n[2/4] 🧪 Đang chạy Flutter Unit & Widget Tests..." -ForegroundColor Yellow
    $flutterTest = flutter test
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Flutter Tests thất bại!" -ForegroundColor Red
        Write-Host $flutterTest
    } else {
        Write-Host "✅ Flutter Tests: Toàn bộ kiểm thử thành công!" -ForegroundColor Green
    }
} finally {
    Pop-Location
}

# 2. BACKEND CLOUD FUNCTIONS CHECKS
Write-Host "`n[3/4] 🔨 Đang biên dịch Backend TypeScript..." -ForegroundColor Yellow
Push-Location $functionsDir
try {
    npm run build
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Backend TypeScript Build thất bại!" -ForegroundColor Red
    } else {
        Write-Host "✅ Backend TypeScript Build thành công!" -ForegroundColor Green
    }

    Write-Host "`n[4/4] 🧪 Đang chạy Backend Integration Tests..." -ForegroundColor Yellow
    npm test
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Backend Tests thất bại!" -ForegroundColor Red
    } else {
        Write-Host "✅ Backend Tests: Toàn bộ bài test thành công!" -ForegroundColor Green
    }
} finally {
    Pop-Location
}

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "🏁 HOÀN TẤT KIỂM TRA TỰ ĐỘNG" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
