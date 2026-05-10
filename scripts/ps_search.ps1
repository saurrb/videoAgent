param(
  [Parameter(Mandatory = $true)][string]$Pattern,
  [string]$Root = (Split-Path $PSScriptRoot -Parent),
  [string[]]$Include = @("*.ps1", "*.py", "*.md", "*.txt", "*.json", "*.toml", "*.yaml", "*.yml"),
  [string[]]$ExcludeDir = @(".git", "node_modules", "tools", "assets")
)

$ErrorActionPreference = "Stop"

function Get-SearchFiles {
  param([string]$Base)
  $dirs = Get-ChildItem -LiteralPath $Base -Directory -Force -ErrorAction SilentlyContinue |
    Where-Object { $ExcludeDir -notcontains $_.Name }

  $files = Get-ChildItem -LiteralPath $Base -File -Recurse -Force -Include $Include -ErrorAction SilentlyContinue |
    Where-Object {
      foreach ($d in $ExcludeDir) {
        if ($_.FullName -match ([regex]::Escape([IO.Path]::DirectorySeparatorChar + $d + [IO.Path]::DirectorySeparatorChar))) { return $false }
      }
      return $true
    }

  return $files
}

$searchFiles = Get-SearchFiles -Base $Root
if (-not $searchFiles) { exit 0 }

$searchFiles | Select-String -Pattern $Pattern | ForEach-Object {
  "{0}:{1}:{2}" -f $_.Path, $_.LineNumber, $_.Line.TrimEnd()
}
