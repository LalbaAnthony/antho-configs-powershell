# =================================================================================
# RANDOM
# =================================================================================

# Folders
function ll { Get-ChildItem -Force @args }
function la { Get-ChildItem -Force -Name @args }
function l  { Get-ChildItem @args }
function f  { Get-ChildItem -Recurse -Filter $args[0] }

# Navigation
function ..    { Set-Location .. }
function ...   { Set-Location ../.. }
function ....  { Set-Location ../../.. }
function ..... { Set-Location ../../../.. }

# Random
function again { Invoke-History }
function h     { Get-History -Count 30 }

# PowerShell
function pseu() { Invoke-RestMethod https://raw.githubusercontent.com/LalbaAnthony/antho-configs-powershell/main/install.ps1 | iex }
function profile_extra_update() { Invoke-RestMethod https://raw.githubusercontent.com/LalbaAnthony/antho-configs-powershell/main/install.ps1 | iex }
function profile_extra_uninstall() { Invoke-RestMethod https://raw.githubusercontent.com/LalbaAnthony/antho-configs-powershell/main/uninstall.ps1 | iex }

function mkcd {
    param($path)
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    Set-Location $path
}

# =================================================================================
# Node
# =================================================================================

function nr     { npm run @args }
function nrb    { npm run build }
function nrd    { npm run dev }
function nrt    { npm run test }
function nstart { npm start }
function nsetup {
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue node_modules, .vite, .cache, package-lock.json
    npm i
}

function yr     { yarn run @args }
function yrb    { yarn run build }
function yrd    { yarn run dev }
function yrt    { yarn run test }
function ystart { yarn start }
function ysetup {
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue node_modules, .vite, .cache, yarn.lock
    yarn install
}

# =================================================================================
# Git
# =================================================================================

function gs    { git status -sb }
function ga    { git add . }
function gc    { git commit -m @args }
function gp    { git push }
function gpo   { git push origin @args }
function gpl   { git pull }
function gf    { git fetch }
function gplo  { git pull origin @args }
function gl    { git log --oneline --graph --decorate --all }
function gd    { git diff "origin/$(git rev-parse --abbrev-ref HEAD)" }
function gds   { git diff --shortstat "origin/$(git rev-parse --abbrev-ref HEAD)" }
function gco   { git checkout @args }
function gcb   { git checkout -b @args }
function gbd   { git branch -d @args }
function gundo { git reset --soft HEAD~1 }
function gclean { git reset --hard; git clean -fd }
function gtags { git tag -l --sort=-creatordate | Select-Object -First 10 }
function gpf   { git push --force-with-lease }

function gacp {
    param($message)
    git add .
    git commit -m $message
    git push
}

function gbranch {
    $branches = git branch | ForEach-Object { $_.TrimStart('* ').Trim() }
    $i = 1
    foreach ($b in $branches) { Write-Host "$i) $b"; $i++ }
    $choice = Read-Host "Select branch"
    $branch = $branches[$choice - 1]
    if ($branch) {
        git checkout $branch
    } else {
        Write-Host "Invalid choice"
    }
}

# Drag changes from current branch into another branch
function gdrag {
    param($target)
    $origin = git rev-parse --abbrev-ref HEAD
    git checkout $target
    git pull origin $origin
    git push
    git checkout $origin
}

# =================================================================================
# Docker
# =================================================================================

function dcb      { docker compose up --build -d }
function dps      { docker ps }
function dpa      { docker ps -a }
function drm      { docker rm -f @args }
function dim      { docker images }
function dlog     { docker logs -f @args }
function dclean   { docker system prune -af --volumes }
function drestart { docker restart $(docker ps -q) }

function dexec {
    param($container)
    if (-not $container) {
        Write-Host "Usage: dexec <container_name_or_id>"
        return
    }

    docker exec -it $container /bin/bash
    if ($LASTEXITCODE -ne 0) { docker exec -it $container /bin/sh }
}

function denv {
    param($container)
    if (-not $container) {
        Write-Host "Usage: denv <container_name_or_id>"
        return
    }

    docker exec -it $container env
}

function dnuke {
    Write-Host "WARNING: This will destroy ALL Docker containers, images, volumes, networks, and build cache."
    Write-Host "Current state:"
    Write-Host "  Containers: $(@(docker ps -aq 2>$null).Count)"
    Write-Host "  Images:     $(@(docker images -q 2>$null).Count)"
    Write-Host "  Volumes:    $(@(docker volume ls -q 2>$null).Count)"
    Write-Host ""
    $confirm = Read-Host "Type 'NUKE' to confirm"

    if ($confirm -ne 'NUKE') {
        Write-Host "Aborted."
        return
    }

    docker stop $(docker ps -aq) 2>$null
    docker volume rm $(docker volume ls -q) 2>$null
    docker system prune -a --volumes -f
    docker builder prune -a -f

    Write-Host "Docker environment wiped."
}

# =================================================================================
# apitemplate.io
# =================================================================================

function mdtopdf {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $File
    )

    # -- Config -----------------------------------------------------------------

    $API_KEY = $env:APITEMPLATE_API_KEY
    $TEMPLATE_ID = $env:APITEMPLATE_TEMPLATE_ID
    $REGION = if ($env:APITEMPLATE_REGION) { $env:APITEMPLATE_REGION } else { 'us' }

    $REGION_HOSTS = @{
        us = 'rest.apitemplate.io'
        de = 'rest-de.apitemplate.io'
        au = 'rest-au.apitemplate.io'
        sg = 'rest-sg.apitemplate.io'
    }

    # -- Guard: missing credentials ---------------------------------------------

    if ([string]::IsNullOrWhiteSpace($API_KEY) -or [string]::IsNullOrWhiteSpace($TEMPLATE_ID)) {
        Write-Host @"

        mdtopdf — missing configuration
        ----------------------------------------------------------------

        Two environment variables are required:

            APITEMPLATE_API_KEY     Your APITemplate.io API key
            APITEMPLATE_TEMPLATE_ID A "Markdown String to PDF" template ID
            APITEMPLATE_REGION      (optional) us | de | au | sg  [default: us]

        -- Get your API key ----------------------------------------------

            1. Sign up at https://app.apitemplate.io/accounts/signup/
            2. Go to Dashboard → API Keys → copy your key

        -- Create a compatible template ----------------------------------

            1. Dashboard → Manage Templates → New PDF Template
            2. Select "Markdown String to PDF" → Create
            3. Copy the template_id shown in the template list

        -- Set the variables permanently (PowerShell profile) ------------

            Add these lines to your `$PROFILE  ($($PROFILE)):

            `$env:APITEMPLATE_API_KEY     = "your_api_key_here"
            `$env:APITEMPLATE_TEMPLATE_ID = "your_template_id_here"
            `$env:APITEMPLATE_REGION      = "us"   # or de / au / sg

            Then reload: . `$PROFILE

        -- Or set them for the current session only ----------------------

            `$env:APITEMPLATE_API_KEY     = "your_api_key_here"
            `$env:APITEMPLATE_TEMPLATE_ID = "your_template_id_here"
"@ -ForegroundColor Yellow

        return
    }

    # -- Guard: invalid region --------------------------------------------------

    if ($REGION -notin $REGION_HOSTS.Keys) {
        Write-Error "Invalid APITEMPLATE_REGION '$REGION'. Must be: $($REGION_HOSTS.Keys -join ' | ')"
        return
    }

    # -- Guard: file exists -----------------------------------------------------

    if (-not (Test-Path $File -PathType Leaf)) {
        Write-Error "File not found: $File"
        return
    }

    # -- Paths ------------------------------------------------------------------

    $resolved = (Resolve-Path $File).Path
    $directory = Split-Path $resolved -Parent
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($resolved)
    $outputPath = Join-Path $directory "${baseName}_$(Get-Date -Format 'yyyy-MM-dd').pdf"
    $createUrl = "https://$($REGION_HOSTS[$REGION])/v2/create-pdf?template_id=$TEMPLATE_ID"

    # -- Convert ----------------------------------------------------------------

    Write-Host "[1/3] Reading '$resolved'..."
    $markdown = Get-Content -Path $resolved -Raw -Encoding UTF8

    Write-Host "[2/3] Sending to APITemplate.io ($REGION)..."

    try {
        $response = Invoke-RestMethod `
            -Method Post `
            -Uri $createUrl `
            -Headers @{ 'X-API-KEY' = $API_KEY; 'Content-Type' = 'application/json' } `
            -Body (@{ markdown = $markdown } | ConvertTo-Json -Depth 5) `
            -TimeoutSec 60
    }
    catch {
        Write-Error "API request failed (HTTP $($_.Exception.Response?.StatusCode.value__)).`n$($_.ErrorDetails?.Message)"
        return
    }

    if (-not $response.download_url) {
        Write-Error "Unexpected API response (no download_url).`n$($response | ConvertTo-Json)"
        return
    }

    Write-Host "[3/3] Saving '$outputPath'..."

    try {
        Invoke-WebRequest -Uri $response.download_url -OutFile $outputPath -TimeoutSec 60
    }
    catch {
        Write-Error "Download failed: $_"
        return
    }

    Write-Host "Done -> $outputPath ($([math]::Round((Get-Item $outputPath).Length / 1KB, 1)) KB)" -ForegroundColor Green
}
