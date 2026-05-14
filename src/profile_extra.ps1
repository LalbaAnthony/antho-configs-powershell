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
function profile_extra_update() { irm https://raw.githubusercontent.com/LalbaAnthony/antho-configs-powershell/main/install.ps1 | iex }
function profile_extra_uninstall() { irm https://raw.githubusercontent.com/LalbaAnthony/antho-configs-powershell/main/uninstall.ps1 | iex }

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
