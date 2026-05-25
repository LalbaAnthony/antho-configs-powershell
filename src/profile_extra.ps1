# =================================================================================
# RANDOM
# =================================================================================

# Folders
function ll { Get-ChildItem -Force @args }
function la { Get-ChildItem -Force -Name @args }
function l { Get-ChildItem @args }
function f { Get-ChildItem -Recurse -Filter $args[0] }

# Navigation
function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }
function ..... { Set-Location ../../../.. }

# Random
function again { Invoke-History }
function h { Get-History -Count 30 }

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

function nr { npm run @args }
function nrb { npm run build }
function nrd { npm run dev }
function nrt { npm run test }
function nstart { npm start }
function nsetup {
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue node_modules, .vite, .cache, package-lock.json
    npm i
}

function yr { yarn run @args }
function yrb { yarn run build }
function yrd { yarn run dev }
function yrt { yarn run test }
function ystart { yarn start }
function ysetup {
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue node_modules, .vite, .cache, yarn.lock
    yarn install
}

# =================================================================================
# Git
# =================================================================================

function gs { git status -sb }
function ga { git add . }
function gc { git commit -m @args }
function gp { git push }
function gpo { git push origin @args }
function gpl { git pull }
function gf { git fetch }
function gplo { git pull origin @args }
function gl { git log --oneline --graph --decorate --all }
function gd { git diff "origin/$(git rev-parse --abbrev-ref HEAD)" }
function gds { git diff --shortstat "origin/$(git rev-parse --abbrev-ref HEAD)" }
function gco { git checkout @args }
function gcb { git checkout -b @args }
function gbd { git branch -d @args }
function gundo { git reset --soft HEAD~1 }
function gclean { git reset --hard; git clean -fd }
function gtags { git tag -l --sort=-creatordate | Select-Object -First 10 }
function gpf { git push --force-with-lease }

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
    }
    else {
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

function dcb { docker compose up --build -d }
function dps { docker ps }
function dpa { docker ps -a }
function drm { docker rm -f @args }
function dim { docker images }
function dlog { docker logs -f @args }
function dclean { docker system prune -af --volumes }
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

# ? Made using: https://apitemplate.io/blog/how-to-turn-markdown-into-pdfs/

function mdtopdf {
    <#
    .SYNOPSIS
        Convert a Markdown file to PDF via the APITemplate.io API.
    .PARAMETER Path
        Path to the input .md / .markdown file.
    .EXAMPLE
        mdtopdf .\README.md
        mdtopdf C:\docs\spec.md
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string] $Path
    )

    # -- Config guard --------------------------------------------------------

    $apiKey     = $env:APITEMPLATE_API_KEY
    $templateId = $env:APITEMPLATE_TEMPLATE_ID
    $region     = if ($env:APITEMPLATE_REGION) { $env:APITEMPLATE_REGION } else { 'us' }

    if (-not $apiKey -or -not $templateId) {
        Write-Host @"
    mdtopdf - missing configuration
    ----------------------------------------------------------------

    Two environment variables are required:

        APITEMPLATE_API_KEY     Your APITemplate.io API key
        APITEMPLATE_TEMPLATE_ID a "Markdown String to PDF" template ID
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
"@
        return
    }

    # -- Input validation ----------------------------------------------------

    $resolvedPath = Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue
    if (-not $resolvedPath) {
        Write-Error "File not found: $Path"
        return
    }

    $file = Get-Item -LiteralPath $resolvedPath.Path
    if ($file.Extension -notin @('.md', '.markdown')) {
        Write-Warning "File extension is '$($file.Extension)' - expected .md or .markdown. Proceeding anyway."
    }

    # -- Output path  →  <stem>_<YYYY-MM-DD>.pdf -----------------------------

    $outputPath = Join-Path $file.DirectoryName (
        '{0}_{1}.pdf' -f [System.IO.Path]::GetFileNameWithoutExtension($file.Name),
                         (Get-Date -Format 'yyyy-MM-dd')
    )

    # -- Regional endpoint ---------------------------------------------------

    $baseUrl = @{
        us = 'https://rest.apitemplate.io'
        de = 'https://rest-de.apitemplate.io'
        au = 'https://rest-au.apitemplate.io'
        sg = 'https://rest-sg.apitemplate.io'
    }[$region.ToLower()]

    if (-not $baseUrl) {
        Write-Error "Unknown region '$region'. Valid values: us | de | au | sg"
        return
    }

    # -- Read + normalise content --------------------------------------------
    # Read as bytes then decode as UTF-8 to avoid BOM / Windows encoding issues.
    # Normalise CRLF → LF so the remote markdown parser handles line breaks correctly.

    $rawBytes       = [System.IO.File]::ReadAllBytes($file.FullName)
    $markdownContent = [System.Text.Encoding]::UTF8.GetString($rawBytes) -replace "`r`n", "`n" -replace "`r", "`n"

    # -- Build and encode body as UTF-8 bytes --------------------------------
    # ConvertTo-Json escapes the string correctly; explicit UTF-8 byte array
    # prevents Invoke-RestMethod from silently re-encoding on non-UTF8 systems.

    $bodyJson  = @{ markdown = $markdownContent } | ConvertTo-Json -Depth 2 -Compress
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($bodyJson)

    # -- API call ------------------------------------------------------------

    Write-Host "Sending '$($file.Name)' to APITemplate.io ($region)..."

    try {
        $response = Invoke-RestMethod `
            -Method      Post `
            -Uri         "${baseUrl}/v2/create-pdf?template_id=${templateId}" `
            -Headers     @{ 'X-API-KEY' = $apiKey } `
            -Body        $bodyBytes `
            -ContentType 'application/json; charset=utf-8' `
            -ErrorAction Stop
    } catch {
        $code = $_.Exception.Response.StatusCode.value__
        switch ($code) {
            401     { Write-Error "Authentication failed (401). Verify APITEMPLATE_API_KEY." }
            404     { Write-Error "Template not found (404). Verify APITEMPLATE_TEMPLATE_ID." }
            429     { Write-Error "Rate limit exceeded (429). Wait before retrying." }
            default { Write-Error "API call failed (HTTP $code).`n$($_.ErrorDetails.Message)" }
        }
        return
    }

    # -- Validate response ---------------------------------------------------

    if (-not $response.download_url) {
        Write-Error "Unexpected API response - 'download_url' missing.`n$($response | ConvertTo-Json)"
        return
    }

    if ($response.status -and $response.status -ne 'success') {
        Write-Error "API returned non-success status: '$($response.status)'`n$($response | ConvertTo-Json)"
        return
    }

    # -- Download ------------------------------------------------------------

    try {
        Invoke-WebRequest -Uri $response.download_url -OutFile $outputPath -ErrorAction Stop
    } catch {
        Write-Error "Failed to download PDF from '$($response.download_url)'.`n$_"
        return
    }

    Write-Host "PDF saved: $outputPath"
}