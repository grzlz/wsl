# Ariadna Installation Script for Windows (PowerShell)
# Run with: powershell -ExecutionPolicy Bypass -File install.ps1

$ErrorActionPreference = "Stop"

Write-Host "🏛️  Ariadna - Instalador para Windows" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator (not needed, but warn if true)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    Write-Host "⚠️  Advertencia: Estás ejecutando como Administrador" -ForegroundColor Yellow
    Write-Host "   Esto puede causar problemas de permisos." -ForegroundColor Yellow
    Write-Host "   Recomendación: Ejecuta sin privilegios de administrador" -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "¿Continuar de todas formas? (s/N)"
    if ($continue -ne "s" -and $continue -ne "S") {
        exit 1
    }
}

# Function to check if command exists
function Test-Command {
    param($Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# Check Neovim
if (-not (Test-Command nvim)) {
    Write-Host "❌ Neovim no está instalado" -ForegroundColor Red
    Write-Host ""
    Write-Host "   Opciones de instalación:" -ForegroundColor Yellow
    Write-Host "   1. Usando winget (recomendado):" -ForegroundColor White
    Write-Host "      winget install Neovim.Neovim" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   2. Usando Chocolatey:" -ForegroundColor White
    Write-Host "      choco install neovim" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   3. Descarga manual:" -ForegroundColor White
    Write-Host "      https://github.com/neovim/neovim/releases" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

$nvimVersion = (nvim --version | Select-Object -First 1) -replace 'NVIM v', ''
Write-Host "✓ Neovim $nvimVersion encontrado" -ForegroundColor Green

# Check Node.js
if (-not (Test-Command node)) {
    Write-Host "⚠️  Node.js no está instalado (necesario para LSP servers)" -ForegroundColor Yellow
    Write-Host "   Instala desde: https://nodejs.org" -ForegroundColor White
} else {
    $nodeVersion = node --version
    Write-Host "✓ Node.js $nodeVersion encontrado" -ForegroundColor Green
}

# Check Git
if (-not (Test-Command git)) {
    Write-Host "❌ Git no está instalado" -ForegroundColor Red
    Write-Host "   Instala desde: https://git-scm.com/download/win" -ForegroundColor White
    exit 1
}
Write-Host "✓ Git encontrado" -ForegroundColor Green

Write-Host ""
Write-Host "📂 Preparando instalación..." -ForegroundColor Cyan

# Windows-specific paths
$nvimConfigPath = "$env:LOCALAPPDATA\nvim"
$nvimDataPath = "$env:LOCALAPPDATA\nvim-data"
$nvimCachePath = "$env:LOCALAPPDATA\nvim"

# Backup existing config
if (Test-Path $nvimConfigPath) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = "$nvimConfigPath.backup.$timestamp"
    Write-Host "⚠️  Configuración existente encontrada" -ForegroundColor Yellow
    Write-Host "   Creando respaldo en: $backupPath" -ForegroundColor White
    Move-Item -Path $nvimConfigPath -Destination $backupPath -Force
    Write-Host "✓ Respaldo creado" -ForegroundColor Green
}

# Backup existing data
if (Test-Path $nvimDataPath) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupDataPath = "$nvimDataPath.backup.$timestamp"
    Write-Host "   Respaldando datos en: $backupDataPath" -ForegroundColor White
    Move-Item -Path $nvimDataPath -Destination $backupDataPath -Force
    Write-Host "✓ Datos respaldados" -ForegroundColor Green
}

Write-Host ""
Write-Host "🏛️  Siguiendo el hilo de Ariadna..." -ForegroundColor Cyan
Write-Host ""

# Base URL for downloads
$baseUrl = "https://icarus.mx/ariadna"

# Create directory structure
Write-Host "📂 Creando estructura de directorios..." -ForegroundColor Cyan

$directories = @(
    "$nvimConfigPath",
    "$nvimConfigPath\lua\config",
    "$nvimConfigPath\lua\plugins"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

Write-Host "✓ Directorios creados" -ForegroundColor Green

# Files to download
$files = @(
    "init.lua",
    "lua/config/autocmds.lua",
    "lua/config/keymaps.lua",
    "lua/config/lazy.lua",
    "lua/config/options.lua",
    "lua/plugins/ariadna.lua",
    "lua/plugins/colorscheme.lua",
    "lua/plugins/example.lua",
    "lua/plugins/markdown.lua",
    "lua/plugins/svelte.lua",
    "lua/plugins/tailwind.lua"
)

# Fun loading messages
$messages = @(
    "Desenredando el laberinto...",
    "Esquivando al Minotauro...",
    "Siguiendo el hilo dorado...",
    "Encontrando la salida...",
    "Trazando el camino...",
    "Navegando los pasillos...",
    "Descubriendo secretos...",
    "Iluminando el camino..."
)

$totalFiles = $files.Count
$current = 0

# Download each file with progress
foreach ($file in $files) {
    $current++

    # Pick a random message
    $message = $messages | Get-Random

    # Progress calculation
    $percent = [math]::Floor(($current / $totalFiles) * 100)
    $filled = [math]::Floor($percent / 10)
    $empty = 10 - $filled
    $bar = "█" * $filled + "░" * $empty

    # Display progress
    Write-Host "`r$message [$bar] $percent% - $(Split-Path $file -Leaf)" -NoNewline

    # Download URL (convert forward slashes for URL)
    $fileUrl = "$baseUrl/$($file -replace '\\', '/')"

    # Destination path (Windows paths)
    $destPath = Join-Path $nvimConfigPath $file

    # Ensure parent directory exists
    $parentDir = Split-Path $destPath -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    # Download file
    try {
        Invoke-WebRequest -Uri $fileUrl -OutFile $destPath -UseBasicParsing -ErrorAction Stop
    } catch {
        Write-Host ""
        Write-Host "❌ Error descargando $file" -ForegroundColor Red
        Write-Host "   URL: $fileUrl" -ForegroundColor Gray
        Write-Host "   Error: $_" -ForegroundColor Gray
        exit 1
    }

    Start-Sleep -Milliseconds 100
}

Write-Host ""
Write-Host ""
Write-Host "✓ Hilo seguido - ¡Has escapado del laberinto!" -ForegroundColor Green

Write-Host ""
Write-Host "🎨 Instalando plugins y LSP servers..." -ForegroundColor Cyan
Write-Host "   (Esto puede tomar 2-3 minutos)" -ForegroundColor White
Write-Host ""

# Open nvim and install plugins (suppress output)
& nvim --headless "+Lazy! sync" "+qa" 2>&1 | Out-Null

Write-Host ""
Write-Host "✓ Plugins instalados" -ForegroundColor Green

Write-Host ""
Write-Host "🎉 ¡Instalación completada!" -ForegroundColor Green
Write-Host ""
Write-Host "📚 Próximos pasos:" -ForegroundColor Cyan
Write-Host "   1. Abre Neovim: nvim" -ForegroundColor White
Write-Host "   2. Espera a que Mason instale LSP servers (~1 min)" -ForegroundColor White
Write-Host "   3. Reinicia Neovim" -ForegroundColor White
Write-Host "   4. Lee la ayuda: :help ariadna" -ForegroundColor White
Write-Host ""
Write-Host "⌨️  Keybindings esenciales:" -ForegroundColor Cyan
Write-Host "   Space Space  - Buscar archivos" -ForegroundColor White
Write-Host "   Space e      - Explorador de archivos" -ForegroundColor White
Write-Host "   Space h      - Ayuda" -ForegroundColor White
Write-Host ""
Write-Host "📁 Configuración instalada en:" -ForegroundColor Cyan
Write-Host "   $nvimConfigPath" -ForegroundColor Gray
Write-Host ""
Write-Host "🏛️  Hecho con <3 por icarus.mx" -ForegroundColor Cyan
Write-Host ""
