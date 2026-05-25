# init.ps1 — personalize the template for a new domain.
#
# Run once after creating a repo from the template (Windows PowerShell).
# Substitutes <DOMAIN_NAME>, <PRIMARY_DB>, and <PRIMARY_SCHEMA> across the repo.

$ErrorActionPreference = 'Stop'

# Resolve repo root (parent of this script's directory)
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

Write-Host "=== snowflake-domain-template — personalization ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "This will substitute <DOMAIN_NAME>, <PRIMARY_DB>, and <PRIMARY_SCHEMA>"
Write-Host "across the template files. Run once after cloning."
Write-Host ""

# --- Prompt for values ---
$DomainName    = Read-Host "Domain name        (e.g. il-customers)"
$PrimaryDb     = Read-Host "Primary database   (e.g. IL_Customers)"
$PrimarySchema = Read-Host "Primary schema     (e.g. PUBLIC) [PUBLIC]"

if ([string]::IsNullOrWhiteSpace($PrimarySchema)) { $PrimarySchema = "PUBLIC" }

Write-Host ""
Write-Host "Will substitute:"
Write-Host "  <DOMAIN_NAME>     -> $DomainName"
Write-Host "  <PRIMARY_DB>      -> $PrimaryDb"
Write-Host "  <PRIMARY_SCHEMA>  -> $PrimarySchema"
Write-Host ""
$Confirm = Read-Host "Proceed? [y/N]"
if ($Confirm -notmatch '^(y|Y|yes|YES)$') {
    Write-Host "Aborted."
    exit 1
}

# Rename sql/public if a non-default schema was chosen
if ($PrimarySchema -ne "PUBLIC" -and $PrimarySchema -ne "public") {
    $SchemaLower = $PrimarySchema.ToLower()
    if (Test-Path "sql\public") {
        Rename-Item -Path "sql\public" -NewName $SchemaLower
        Write-Host "Renamed sql\public\ -> sql\$SchemaLower\"
    }
}

# Find files to patch (md, yml, yaml, sql) excluding .git and bin
$Files = Get-ChildItem -Path . -Recurse -File -Include *.md, *.yml, *.yaml, *.sql `
    | Where-Object {
        $_.FullName -notlike "*\.git\*" -and
        $_.FullName -notlike "*\bin\*"
    }

foreach ($file in $Files) {
    $content = (Get-Content -Path $file.FullName -Raw -Encoding UTF8) `
        -replace '<DOMAIN_NAME>',    $DomainName `
        -replace '<PRIMARY_DB>',     $PrimaryDb `
        -replace '<PRIMARY_SCHEMA>', $PrimarySchema
    Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
}

Write-Host ""
Write-Host "Personalization complete." -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Review the changes:    git diff"
Write-Host "  2. Read CLAUDE.md's 'First Steps' checklist."
Write-Host "  3. Commit:                git add -A; git commit -m 'chore: personalize template'"
