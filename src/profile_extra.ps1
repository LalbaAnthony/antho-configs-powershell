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
function pseu() { Invoke-RestMethod https://raw.githubusercontent.com/LalbaAnthony/antho-configs-powershell/main/install.ps1 | Invoke-Expression }
function profile_extra_update() { Invoke-RestMethod https://raw.githubusercontent.com/LalbaAnthony/antho-configs-powershell/main/install.ps1 | Invoke-Expression }
function profile_extra_uninstall() { Invoke-RestMethod https://raw.githubusercontent.com/LalbaAnthony/antho-configs-powershell/main/uninstall.ps1 | Invoke-Expression }

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
function gp { git push }
function gpo { git push origin @args }
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
# Claude
# =================================================================================

function claudesync {
    <#
    .SYNOPSIS
        Sync ~/.claude with its git remote, self-healing.
        Order matters: heal stale state -> commit local -> fetch -> integrate
        (rebase, then merge, then conflict-proof overlay) -> push with retries.
        Conflict policy: on a same-line conflict, THIS machine wins.
    .PARAMETER Message
        Optional commit message (default: "sync(HOST): timestamp").
    #>
    [CmdletBinding()]
    param (
        [string] $Message
    )

    $claudePath = Join-Path $env:USERPROFILE '.claude'
    $gitDir = Join-Path $claudePath '.git'

    function step($msg) { Write-Host "claudesync: $msg" }

    if (-not (Test-Path $gitDir)) {
        step "no git repository at '$claudePath'"
        return
    }

    # -- 0. Heal state left behind by a previously interrupted sync ----------
    # A half-finished rebase/merge makes every later git command fail, which
    # is what made conflicts look "systematic".
    if ((Test-Path (Join-Path $gitDir 'rebase-merge')) -or (Test-Path (Join-Path $gitDir 'rebase-apply'))) {
        step "aborting stale rebase from a previous run"
        git -C $claudePath rebase --abort 2>$null
    }
    if (Test-Path (Join-Path $gitDir 'MERGE_HEAD')) {
        step "aborting stale merge from a previous run"
        git -C $claudePath merge --abort 2>$null
    }

    $branch = git -C $claudePath rev-parse --abbrev-ref HEAD
    if ($LASTEXITCODE -ne 0 -or -not $branch) {
        Write-Error "claudesync: cannot resolve current branch"
        return
    }

    # -- 1. Commit local work BEFORE touching the remote ---------------------
    # Rebasing a dirty tree was the root cause of the old failures.
    git -C $claudePath add -A
    if (git -C $claudePath status --porcelain) {
        if (-not $Message) {
            $Message = "sync($env:COMPUTERNAME): $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        }
        git -C $claudePath commit -m $Message --quiet
        step "committed local changes"
    }

    # -- 2. Fetch. Offline is fine: the commit stays local until next run ----
    git -C $claudePath fetch origin --quiet 2>$null
    if ($LASTEXITCODE -ne 0) {
        step "fetch failed (offline?) - changes are committed locally, will sync next run"
        return
    }

    git -C $claudePath rev-parse --verify --quiet "origin/$branch" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        step "no upstream yet, publishing '$branch'"
        git -C $claudePath push -u origin $branch
        return
    }

    # -- 3. Integrate the remote, escalating through 3 strategies ------------
    $behind = [int](git -C $claudePath rev-list --count "HEAD..origin/$branch")
    if ($behind -gt 0) {
        # 3a. Rebase; "-X theirs" during a rebase = replayed LOCAL commits win
        git -C $claudePath rebase "origin/$branch" -X theirs --quiet 2>$null
        if ($LASTEXITCODE -ne 0) {
            git -C $claudePath rebase --abort 2>$null

            # 3b. Merge; "-X ours" during a merge = LOCAL branch wins
            step "rebase failed, falling back to merge"
            git -C $claudePath merge "origin/$branch" -X ours --no-edit --quiet 2>$null
            if ($LASTEXITCODE -ne 0) {
                git -C $claudePath merge --abort 2>$null

                # 3c. Conflict-proof overlay: snapshot local state on a backup
                # branch, adopt the remote history, then re-apply local files
                # on top. Cannot conflict by construction; nothing is lost.
                $backup = "backup/$($env:COMPUTERNAME.ToLower())-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                step "merge failed, using overlay fallback (local snapshot on '$backup')"
                git -C $claudePath branch $backup
                git -C $claudePath reset --hard "origin/$branch" --quiet
                git -C $claudePath checkout $backup -- .
                git -C $claudePath add -A
                git -C $claudePath commit -m "sync($env:COMPUTERNAME): overlay of local state" --quiet
            }
        }
        step "integrated $behind remote commit(s)"
    }

    # -- 4. Push, retrying if another machine pushed in the meantime ---------
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        git -C $claudePath push origin $branch --quiet 2>$null
        if ($LASTEXITCODE -eq 0) {
            step "synced ('$branch' up to date with origin)"
            return
        }
        step "push rejected (concurrent push from another machine?), retry $attempt/3"
        Start-Sleep -Seconds $attempt
        git -C $claudePath fetch origin --quiet 2>$null
        git -C $claudePath rebase "origin/$branch" -X theirs --quiet 2>$null
        if ($LASTEXITCODE -ne 0) { git -C $claudePath rebase --abort 2>$null }
    }

    # Last attempt without silencing, so the real error is visible
    git -C $claudePath push origin $branch
    if ($LASTEXITCODE -ne 0) { Write-Error "claudesync: push failed after retries (see output above)" }
}

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
    $confirm = Read-Host "Type 'NUKE' to confirm"

    if ($confirm -ne 'NUKE') {
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
# AI
# =================================================================================

function mdclean {
    <#
    .SYNOPSIS
        Clean a Markdown file in place: strip emojis, normalize AI-style typography, remove bold markers and extra blank lines.
    .PARAMETER Path
        Path to the input .md / .markdown file.
    .EXAMPLE
        mdclean .\README.md
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string] $Path
    )

    $resolvedPath = Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue
    if (-not $resolvedPath) {
        Write-Error "File not found: $Path"
        return
    }

    $file = Get-Item -LiteralPath $resolvedPath.Path
    if ($file.Extension -notin @('.md', '.markdown')) {
        Write-Warning "File extension is '$($file.Extension)' - expected .md or .markdown. Proceeding anyway."
    }

    $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)

    # Normalize newlines up front; processing is line-based so fenced code
    # blocks can be passed through untouched
    $content = $content -replace "`r`n", "`n" -replace "`r", "`n"

    $out = [System.Collections.Generic.List[string]]::new()
    $inFence = $false

    foreach ($rawLine in ($content -split "`n")) {
        # Fenced code blocks (``` / ~~~): keep content byte-for-byte
        if ($inFence) {
            $out.Add($rawLine)
            if ($rawLine -match '^\s*(```|~~~)\s*$') { $inFence = $false }
            continue
        }
        if ($rawLine -match '^\s*(```|~~~)') {
            $inFence = $true
            $out.Add($rawLine.TrimEnd())
            continue
        }

        $line = $rawLine

        # Typography replacements (before emoji strip: arrows/math symbols sit
        # near the symbol blocks the emoji pattern removes).
        # \uXXXX regex escapes keep this file ASCII-safe regardless of profile encoding.
        $line = $line -replace ' \u2014 ', ', '                   # " em-dash " -> ", "
        $line = $line -replace '\u2026', '...'                    # ellipsis
        $line = $line -replace '\u0153', 'oe'                     # oe ligature
        $line = $line -replace '\u0152', 'Oe'                     # OE ligature
        $line = $line -replace '\u2248', '~='                     # almost equal
        $line = $line -replace '\u2192', '->'                     # right arrow
        $line = $line -replace '[\u2018\u2019]', "'"              # curly single quotes
        # $line = $line -replace '[\u201C\u201D\u00AB\u00BB]', '"'  # curly double quotes + guillemets # TODO replace with space
        $line = $line -replace '\u2265', '>='                     # greater-or-equal
        $line = $line -replace '\u2264', '<='                     # less-or-equal
        $line = $line -replace '\u21D2', '=>'                     # double right arrow
        $line = $line -replace '[\u21D4\u2194]', '<=>'            # double / double-headed arrow

        # Emojis: astral-plane chars (surrogate pairs) + BMP symbol/dingbat blocks,
        # variation selector, ZWJ, keycap combiner - plus one space on the right
        $line = $line -replace '(?:[\uD800-\uDBFF][\uDC00-\uDFFF]|[\u2300-\u23FF\u2600-\u27BF\u2B00-\u2BFF\uFE0F\u200D\u20E3])+ ?', ''

        # Trailing whitespace only: leading indent is significant in Markdown
        # (nested lists, indented code blocks)
        $line = $line.TrimEnd()

        # Remove only actual horizontal rules: a '---' preceded by a blank line.
        # A '---' directly under text is a setext heading or a table separator,
        # and one on the very first line opens YAML frontmatter - keep those.
        if ($line -eq '---' -and $out.Count -gt 0 -and $out[$out.Count - 1] -eq '') {
            continue
        }

        # Collapse runs of blank lines into a single blank line
        if ($line -eq '' -and $out.Count -gt 0 -and $out[$out.Count - 1] -eq '') {
            continue
        }

        $out.Add($line)
    }

    $content = ($out -join "`n" -replace '^\n+', '').TrimEnd() + "`n"

    [System.IO.File]::WriteAllText($file.FullName, $content, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Cleaned: $($file.FullName)"
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
        2. Go to Dashboard -> API Keys -> copy your key

    -- Create a compatible template ----------------------------------

        1. Dashboard -> Manage Templates -> New PDF Template
        2. Select "Markdown String to PDF" -> Create
        3. Copy the template_id shown in the template list

    -- Set the variables permanently (PowerShell profile) ------------

        Add these lines to your `$PROFILE  ($($PROFILE)):

        `$env:APITEMPLATE_API_KEY     = "your_api_key_here"
        `$env:APITEMPLATE_TEMPLATE_ID = "your_template_id_here"
        `$env:APITEMPLATE_REGION      = "us"   # or de / au / sg

        Then reload: . `$PROFILE
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

    # -- Output path  ->  <stem>_<YYYY-MM-DD>.pdf -----------------------------

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
    # Normalise CRLF -> LF so the remote markdown parser handles line breaks correctly.

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

    python $scriptPath
}