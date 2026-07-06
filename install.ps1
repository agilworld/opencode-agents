#Requires -Version 5.1
$ErrorActionPreference = "Stop"

# OpenCode Agents Installer (PowerShell)
# Copies agent .md files and generates opencode.json from agents.json
# Native Windows equivalent of install.sh

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SourceDir = Join-Path $ScriptDir ".opencode\agent"
$TargetDir = "$env:USERPROFILE\.config\opencode\agent"

Write-Host "OpenCode Agents Installer" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host ""

# --- Source Check ----------------------------------------------
if (-not (Test-Path $SourceDir)) {
    Write-Host "Error: Source directory not found: $SourceDir" -ForegroundColor Red
    exit 1
}

# --- Tech Stack Selection --------------------------------------
$Stack = ""
$StackName = ""

if ($env:STACK) {
    switch ($env:STACK.ToLower()) {
        "python" {
            $Stack = "python"
            $StackName = "Python"
            Write-Host "-> Stack pre-selected via STACK env var: $Stack" -ForegroundColor Yellow
        }
        "typescript" {
            $Stack = "typescript"
            $StackName = "TypeScript"
            Write-Host "-> Stack pre-selected via STACK env var: $Stack" -ForegroundColor Yellow
        }
        default {
            Write-Host "Error: Invalid STACK value '$env:STACK'. Must be 'python' or 'typescript'." -ForegroundColor Red
            exit 1
        }
    }
}

if (-not $Stack) {
    Write-Host "Select tech stack:"
    Write-Host "  1) Python"
    Write-Host "  2) TypeScript"
    $choice = Read-Host "Enter choice (1 or 2)"

    switch -Regex ($choice) {
        "^1$|^python$|^Python$" {
            $Stack = "python"
            $StackName = "Python"
        }
        "^2$|^typescript$|^TypeScript$|^ts$|^TS$" {
            $Stack = "typescript"
            $StackName = "TypeScript"
        }
        default {
            Write-Host "Invalid choice. Please select 1 or 2." -ForegroundColor Red
            exit 1
        }
    }
}

# --- QA Engineer Agent -----------------------------------------
$WithQA = $false

if ($env:WITH_QA) {
    switch ($env:WITH_QA.ToLower()) {
        "true" { $WithQA = $true; Write-Host "-> QA agent pre-selected via WITH_QA env var: yes" -ForegroundColor Yellow }
        "false" { $WithQA = $false; Write-Host "-> QA agent pre-selected via WITH_QA env var: no" -ForegroundColor Yellow }
        "yes"  { $WithQA = $true; Write-Host "-> QA agent pre-selected via WITH_QA env var: yes" -ForegroundColor Yellow }
        "no"   { $WithQA = $false; Write-Host "-> QA agent pre-selected via WITH_QA env var: no" -ForegroundColor Yellow }
        "1"    { $WithQA = $true; Write-Host "-> QA agent pre-selected via WITH_QA env var: yes" -ForegroundColor Yellow }
        "0"    { $WithQA = $false; Write-Host "-> QA agent pre-selected via WITH_QA env var: no" -ForegroundColor Yellow }
        default {
            Write-Host "Error: Invalid WITH_QA value '$env:WITH_QA'. Use true/false, yes/no, 1/0." -ForegroundColor Red
            exit 1
        }
    }
} else {
    $qaInput = Read-Host "Include QA Engineer/Documenter in the team? (y/N)"
    if ($qaInput -match "^[Yy]$") {
        $WithQA = $true
    }
}

$StackSrc = Join-Path $SourceDir $Stack

if (-not (Test-Path $StackSrc)) {
    Write-Host "Error: Stack source directory not found: $StackSrc" -ForegroundColor Red
    exit 1
}

Write-Host "Installing $StackName agents..." -ForegroundColor Green
Write-Host ""

# Create target directory
if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
}

# ----------------------------------------------
# 1. Copy agent .md files
# ----------------------------------------------

# Copy base agent files (top-level .md only, skip with-qa/)
$agentFiles = Get-ChildItem -Path $StackSrc -Filter "*.md" -File
foreach ($agent in $agentFiles) {
    $dest = Join-Path $TargetDir $agent.Name
    Copy-Item $agent.FullName $dest -Force
    Write-Host "  [OK] $($agent.Name)" -ForegroundColor Green
}

# If QA selected, overwrite with with-qa variants
if ($WithQA) {
    $withQaDir = Join-Path $StackSrc "with-qa"
    if (Test-Path $withQaDir) {
        Write-Host ""
        Write-Host "  Applying with-qa variants:" -ForegroundColor Yellow
        $variantFiles = Get-ChildItem -Path $withQaDir -Filter "*.md" -File
        foreach ($variant in $variantFiles) {
            $dest = Join-Path $TargetDir $variant.Name
            Copy-Item $variant.FullName $dest -Force
            Write-Host "    [OK] $($variant.Name) (with-qa)" -ForegroundColor Green
        }
    } else {
        Write-Host "  [WARN] Warning: with-qa directory not found: $withQaDir" -ForegroundColor Yellow
    }
}

Write-Host ""

# ----------------------------------------------
# 2. Copy skills
# ----------------------------------------------

$SkillsSrc = Join-Path $ScriptDir ".opencode\skills"
$SkillsTarget = "$env:USERPROFILE\.config\opencode\skills"

if (Test-Path $SkillsSrc) {
    Write-Host "Copying skills..." -ForegroundColor Green
    if (-not (Test-Path $SkillsTarget)) {
        New-Item -ItemType Directory -Path $SkillsTarget -Force | Out-Null
    }
    Copy-Item "$SkillsSrc\*" $SkillsTarget -Recurse -Force
    $skillCount = (Get-ChildItem -Path $SkillsSrc -Directory).Count
    Write-Host "  [OK] Skills installed ($skillCount skill directories)" -ForegroundColor Green
    Write-Host ""
}

# ----------------------------------------------
# 3. Generate opencode.json from template + agents.json
# ----------------------------------------------

$AgentsJson = Join-Path $StackSrc "agents.json"
$TemplateJson = Join-Path $ScriptDir "opencode.json.example"

if (-not (Test-Path $AgentsJson)) {
    Write-Host "[WARN] Warning: agents.json not found at $AgentsJson" -ForegroundColor Yellow
    Write-Host "  Skipping opencode.json generation." -ForegroundColor Yellow
} else {
    $genChoice = Read-Host "Generate opencode.json from template? (Y/n)"
    if ($genChoice -notmatch "^[Nn]$") {
        if (Test-Path $TemplateJson) {
            Write-Host "Generating opencode.json..." -ForegroundColor Green

            try {
                # Read template
                $config = Get-Content $TemplateJson -Raw | ConvertFrom-Json

                # Read agents
                $agents = Get-Content $AgentsJson -Raw | ConvertFrom-Json

                # Filter out QA agents if not selected
                if (-not $WithQA) {
                    if ($Stack -eq "python") {
                        # In Python stack, 'marco' is the QA engineer -- remove it
                        $agents.PSObject.Properties.Remove("marco")
                    } else {
                        # In TypeScript stack, 'quill' is the QA engineer -- remove it
                        $agents.PSObject.Properties.Remove("quill")
                    }
                }

                # Merge agents into template
                $config | Add-Member -MemberType NoteProperty -Name "agent" -Value $agents -Force

                # Set default_agent based on stack
                if ($Stack -eq "python") {
                    $config.default_agent = "oscar"
                } else {
                    $config.default_agent = "ostype"
                }

                # Write to target
                $configTarget = "$env:USERPROFILE\.config\opencode\opencode.json"
                $config | ConvertTo-Json -Depth 10 | Set-Content $configTarget

                Write-Host "  [OK] opencode.json generated at $configTarget" -ForegroundColor Green

                # List installed agents
                $agentNames = $agents.PSObject.Properties.Name -join ", "
                Write-Host "  [OK] Agents registered: $agentNames" -ForegroundColor Green
            }
            catch {
                Write-Host "Error generating opencode.json: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "[WARN] Warning: template not found at $TemplateJson" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Skipping opencode.json generation." -ForegroundColor Yellow
    }
}

# --- AGENTS.md Configuration ----------------------------------
Write-Host ""
Write-Host "Configuring AGENTS.md for $StackName stack..." -ForegroundColor Green

$AgentsSource = Join-Path $ScriptDir "AGENTS.$Stack.md"
$AgentsTarget = Join-Path $ScriptDir "AGENTS.md"

if (Test-Path $AgentsSource) {
    Copy-Item $AgentsSource $AgentsTarget -Force
    Write-Host "  [OK] AGENTS.md generated from AGENTS.$Stack.md" -ForegroundColor Green
} else {
    Write-Host "  [WARN] Warning: AGENTS.$Stack.md not found -- skipping AGENTS.md generation" -ForegroundColor Yellow
}

# ----------------------------------------------
# 4. Summary
# ----------------------------------------------

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  Installation Complete" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Stack:        $StackName" -ForegroundColor White
Write-Host "QA Engineer:  $(if ($WithQA) { 'Yes' } else { 'No' })" -ForegroundColor White
Write-Host "Target:       $TargetDir" -ForegroundColor White
Write-Host ""

Write-Host "Installed agents:" -ForegroundColor Green
$installedAgents = Get-ChildItem -Path $TargetDir -Filter "*.md" -File
foreach ($agent in $installedAgents) {
    Write-Host "  - $([System.IO.Path]::GetFileNameWithoutExtension($agent.Name))" -ForegroundColor White
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Verify $env:USERPROFILE\.config\opencode\opencode.json has the correct agents" -ForegroundColor White
Write-Host "  2. Set your ZEN_API_KEY or provider API key variable in opencode.json" -ForegroundColor White
Write-Host "  3. Run 'opencode' to start!" -ForegroundColor White
Write-Host "  4. Select primary agent ostype/oscar and run prompt" -ForegroundColor White
