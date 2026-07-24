# =================================================================================
# WINDOWS CONFIG
# =================================================================================

function prompt {
    $isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    $userColor = if ($isAdmin) { "Red" } else { "Cyan" }

    # user@host
    Write-Host "$env:USERNAME" -NoNewline -ForegroundColor $userColor
    Write-Host "@" -NoNewline -ForegroundColor White
    Write-Host "$env:COMPUTERNAME" -NoNewline -ForegroundColor Green
    Write-Host ":" -NoNewline

    # working directory
    Write-Host "$($executionContext.SessionState.Path.CurrentLocation)" `
        -NoNewline -ForegroundColor Gray

    # git branch
    $branch = git branch --show-current 2>$null
    if ($branch) {
        Write-Host " ($branch)" -NoNewline -ForegroundColor DarkGray
    }

    return " $ "
}

# =================================================================================
# RANDOM
# =================================================================================

# Folders
function ll { Get-ChildItem -Force @args }
function la { Get-ChildItem -Force -Name @args }
function l { Get-ChildItem @args }
function f { Get-ChildItem -Recurse -Filter $args[0] }
function list_files {
    param([string]$Path = '.')
    $base = (Resolve-Path $Path).Path
    Get-ChildItem -Path $base -Recurse -File | ForEach-Object {
        $_.FullName.Substring($base.Length).TrimStart('\', '/')
    }
}

# Navigation
function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }
function ..... { Set-Location ../../../.. }
function prjt { 
    $projectPath = Join-Path $env:USERPROFILE 'projects'
    if (Test-Path $projectPath) {
        Set-Location $projectPath
    }
    else {
        Write-Host "Folder not found at '$projectPath'"
    }
}

# Random
function again { Invoke-History }

# PowerShell
function profile_extra_update() { Invoke-RestMethod https://raw.githubusercontent.com/LalbaAnthony/antho-configs-powershell/main/install.ps1 | Invoke-Expression }
function profile_extra_uninstall() { Invoke-RestMethod https://raw.githubusercontent.com/LalbaAnthony/antho-configs-powershell/main/uninstall.ps1 | Invoke-Expression }
function pseu() { Invoke-RestMethod https://raw.githubusercontent.com/LalbaAnthony/antho-configs-powershell/main/install.ps1 | Invoke-Expression }
function psf() { Write-Host "Profile file: $PROFILE" }

function mkcd {
    param($path)
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    Set-Location $path
}

# =================================================================================
# Python
# =================================================================================

function pysetup {
    python -m venv .venv
    .\.venv\Scripts\activate
    pip install -r requirements.txt
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
function gpo { git push origin @args }
function gck { git checkout @args }
function gpl { git pull }
function gplr { git pull --rebase }
function gf { git fetch }
function gplo { git pull origin @args }
function gph { git log --oneline --graph --decorate --all }
function gd { git diff "origin/$(git rev-parse --abbrev-ref HEAD)" }
function gds { git diff --shortstat "origin/$(git rev-parse --abbrev-ref HEAD)" }
function gco { git checkout @args }
function gcb { git checkout -b @args }
function gbd { git branch -d @args }
function gundo { git reset --soft HEAD~1 }
function gclean { git reset --hard; git clean -fd }
function gtags { git tag -l --sort=-creatordate | Select-Object -First 10 }
function gpf { git push --force-with-lease }

function grestore {
    param($file, $commit)

    if (-not $file) {
        Write-Host "Usage: grestore <file_path> [commit_hash]"
        return
    }

    if (-not $commit) {
        git restore -- $file
    }
    else {
        git restore --source $commit -- $file
    }
}

function gbdel {
    param($branchName)

    if (-not $branchName) {
        Write-Host "Usage: gbdel <branch_name>"
        return
    }

    git branch -D $branchName
    git push origin --delete $branchName
}

function gclone {
    param($repoUrl)

    $repoName = [System.IO.Path]::GetFileNameWithoutExtension($repoUrl)
    git clone $repoUrl

    if ($LASTEXITCODE -eq 0) {
        Set-Location $repoName
        code .
    }
    else {
        Write-Host "Failed to clone repository: $repoUrl"
    }
}

function gacp {
    param($message)
    if (-not $message) {
        Write-Host "Usage: gacp <commit_message>"
        return
    }

    $root = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Not a git repository."
        return
    }
    if ((Get-Location).Path -ne (Resolve-Path $root).Path) {
        Write-Host "Not at repo root ($root). Aborting."
        return
    }

    git add .
    git commit -m $message
    git push
}

function groot {
    $root = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -eq 0) {
        Set-Location $root
    }
    else {
        Write-Host "Not a git repository."
    }
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
# Claude
# =================================================================================

function claude-usage { npx ccusage@latest }

# =================================================================================
# Docker
# =================================================================================

function dcb { docker compose up --build -d }
function dps { docker ps }
function dpa { docker ps -a }
function drm { docker rm -f @args }
function dst { docker stats }
function dim { docker images }
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

function dlogs {
    param($container)
    if (-not $container) {
        Write-Host "Usage: dlogs <container_name_or_id>"
        return
    }

    docker logs -f $container
}

function denv {
    param($container)
    if (-not $container) {
        Write-Host "Usage: denv <container_name_or_id>"
        return
    }

    docker exec -it $container env
}

function derase {
    Write-Host "WARNING: This will destroy ALL Docker volumes."
    Write-Host "Current state:"
    Write-Host "  Volumes:    $(@(docker volume ls -q 2>$null).Count)"
    Write-Host ""
    $confirm = Read-Host "Type 'ERASE' to confirm"

    if ($confirm -ne 'ERASE') {
        Write-Host "Aborted."
        return
    }

    docker volume rm $(docker volume ls -q) 2>$null

    Write-Host "All Docker volumes removed."
}

function dnuke {
    Write-Host "WARNING: This will destroy ALL Docker containers, images, volumes, networks, and build cache."
    Write-Host "Current state:"
    Write-Host "  Containers: $(@(docker ps -aq 2>$null).Count)"
    Write-Host "  Images:     $(@(docker images -q 2>$null).Count)"
    Write-Host "  Volumes:    $(@(docker volume ls -q 2>$null).Count)"
    Write-Host ""

    $token = -join ((1..6) | ForEach-Object { [char][int]((65..90) + (48..57) | Get-Random) })
    $confirm = Read-Host "Type '$token' to confirm"

    if ($confirm -cne $token) {
        Write-Host "Aborted."
        return
    }

    docker rm -f $(docker ps -aq) 2>$null
    docker volume rm $(docker volume ls -q) 2>$null
    docker system prune -a --volumes -f
    docker builder prune -a -f

    Write-Host "Docker environment wiped."
}

function ddown {
    $ids = @(docker ps -aq 2>$null)

    if ($ids.Count -eq 0) {
        Write-Host "No containers running."
        return
    }

    Write-Host "Stopping $($ids.Count) container(s)..."
    docker stop $ids
    Write-Host "All containers stopped."
}

# =================================================================================
# Scripts shortcuts
# =================================================================================

function gyc {
    $scriptPaths = @(
        (Join-Path $env:USERPROFILE 'projects\antho-scripts\git\git_sync_projects.py')
    )

    $scriptPath = $scriptPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $scriptPath) {
        Write-Host "git_sync_projects.py script not found."
        return
    }

    python $scriptPath
}

function fzc {
    $scriptPaths = @(
        (Join-Path $env:USERPROFILE 'projects\filezilla-companion\src\main.py')
    )

    $scriptPath = $scriptPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $scriptPath) {
        Write-Host "FileZilla Companion script not found."
        return
    }

    Start-Process powershell -ArgumentList "python `"$scriptPath`"" # Open in a new PowerShell window
}

function claudesync {
    $scriptPaths = @(
        (Join-Path $env:USERPROFILE 'projects\antho-scripts\ai\claude_sync.ps1')
    )

    $scriptPath = $scriptPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $scriptPath) {
        Write-Host "claude_sync.ps1 script not found."
        return
    }

    & $scriptPath @args
}

function mdclean {
    $scriptPaths = @(
        (Join-Path $env:USERPROFILE 'projects\antho-scripts\ai\markdown_cleaner.ps1')
    )

    $scriptPath = $scriptPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $scriptPath) {
        Write-Host "markdown_cleaner.ps1 script not found."
        return
    }

    & $scriptPath @args
}

function mdtopdf {
    $scriptPaths = @(
        (Join-Path $env:USERPROFILE 'projects\antho-scripts\apitemplate\markdown_to_pdf.ps1')
    )

    $scriptPath = $scriptPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $scriptPath) {
        Write-Host "markdown_to_pdf.ps1 script not found."
        return
    }

    & $scriptPath @args
}