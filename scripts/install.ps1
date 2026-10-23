<#
.SYNOPSIS
  Installs the Motion Design Director plugin for Claude Code (Windows PowerShell 5.1+ / PowerShell 7).

.DESCRIPTION
  1. Checks that the Claude Code CLI is installed.
  2. Adds the "motion-design-director" marketplace if it is not already added.
  3. Installs ONLY the "motion-director" plugin.
  4. Verifies the result. The official Remotion plugin is NOT installed by this script: Claude Code
     installs it by itself because motion-director declares it as a dependency.

  What this script does not do: it never edits git config, SSH config or known_hosts, and it never
  removes or overwrites anything. It sets CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1 for its own process only,
  so that the public GitHub repositories involved are cloned over HTTPS instead of SSH.

  These scripts are a convenience. The canonical install is:
    claude plugin marketplace add eshaan-eshaan/motion-design-director
    claude plugin install motion-director@motion-design-director

.PARAMETER Source
  Where to fetch the marketplace from: a GitHub "owner/repo" or a local folder path.

.PARAMETER Scope
  Claude Code install scope: user (default), project or local.

.PARAMETER BareCommand
  Optional. Also copies the skill into your personal skills folder so that the un-namespaced
  /motion-design command exists. Skipped if that folder already exists. The copy is not updated
  automatically when the plugin updates.
#>
[CmdletBinding()]
param(
  [string]$Source = 'eshaan-eshaan/motion-design-director',
  [ValidateSet('user', 'project', 'local')][string]$Scope = 'user',
  [switch]$BareCommand
)

$Marketplace = 'motion-design-director'
$Plugin      = 'motion-director'
$PluginId    = "$Plugin@$Marketplace"

function Write-Step($t) { Write-Host "==> $t" -ForegroundColor Cyan }
function Write-Ok($t)   { Write-Host "    OK   $t" -ForegroundColor Green }
function Write-Warn2($t){ Write-Host "    WARN $t" -ForegroundColor Yellow }
function Stop-Install($t, $hint) {
  Write-Host "    FAIL $t" -ForegroundColor Red
  if ($hint) { Write-Host "         $hint" -ForegroundColor Red }
  exit 1
}

# Runs `claude <args>` and returns @{ ExitCode; Output } without letting stderr abort the script.
function Invoke-Claude([string[]]$ClaudeArgs) {
  $prev = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    $text = (& claude @ClaudeArgs 2>&1 | ForEach-Object { "$_" } | Out-String).TrimEnd()
    return @{ ExitCode = $LASTEXITCODE; Output = $text }
  } finally { $ErrorActionPreference = $prev }
}

# 1. Claude Code installed?
Write-Step 'Checking for Claude Code'
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
  Stop-Install 'The "claude" command was not found on PATH.' 'Install Claude Code first: https://code.claude.com/docs/en/quickstart , then open a new terminal and run this script again.'
}
$ver = Invoke-Claude @('--version')
if ($ver.ExitCode -ne 0) { Stop-Install 'Could not run "claude --version".' $ver.Output }
Write-Ok "Claude Code $($ver.Output)"
$help = Invoke-Claude @('plugin', '--help')
if ($help.ExitCode -ne 0) { Stop-Install 'This Claude Code version has no "claude plugin" commands.' 'Update Claude Code, then run this script again.' }

# Clone public GitHub repos over HTTPS (this process only). Older Claude Code versions (seen on 2.1.212) fail with
# "SSH host key is not in your known_hosts" on machines that never connected to github.com over SSH; newer ones
# (2.1.309) fall back to HTTPS themselves. Respect an explicit user setting.
if (-not $env:CLAUDE_CODE_PLUGIN_PREFER_HTTPS) { $env:CLAUDE_CODE_PLUGIN_PREFER_HTTPS = '1' }

# 2. Marketplace
Write-Step "Adding the $Marketplace marketplace ($Scope scope)"
$mk = Invoke-Claude @('plugin', 'marketplace', 'list')
if ($mk.ExitCode -eq 0 -and $mk.Output -match [regex]::Escape($Marketplace)) {
  Write-Ok 'Marketplace already added; refreshing it'
  $up = Invoke-Claude @('plugin', 'marketplace', 'update', $Marketplace)
  if ($up.ExitCode -ne 0) { Write-Warn2 "Could not refresh the marketplace (continuing with the cached copy): $($up.Output)" }
} else {
  $add = Invoke-Claude @('plugin', 'marketplace', 'add', $Source, '--scope', $Scope)
  if ($add.ExitCode -ne 0) {
    Stop-Install "Could not add the marketplace from '$Source'." "$($add.Output)`n         Check the source value, your network connection, and that git is installed (git --version)."
  }
  Write-Ok "Marketplace added from $Source"
}

# 3. Install only the primary plugin; Claude Code resolves the Remotion dependency.
Write-Step "Installing $PluginId (Claude Code adds the official Remotion plugin as its dependency)"
$inst = Invoke-Claude @('plugin', 'install', $PluginId, '--scope', $Scope)
Write-Host "    $($inst.Output)"
if ($inst.ExitCode -ne 0) {
  Stop-Install "claude plugin install failed (exit code $($inst.ExitCode))." 'If the message mentions a git clone, check your network and that git is installed, then run this script again.'
}

# 4. Verify
Write-Step 'Verifying'
$lst = Invoke-Claude @('plugin', 'list', '--json')
$items = $null
try { $items = $lst.Output | ConvertFrom-Json } catch { }
if (-not $items) {
  Write-Warn2 'Could not read "claude plugin list --json"; run "claude plugin list" yourself and check both plugins show enabled.'
} else {
  $primary = @($items | Where-Object { $_.id -eq $PluginId }) | Select-Object -First 1
  if (-not $primary) { Stop-Install "$PluginId is not in the installed plugin list." 'Run "claude plugin list" to see what was installed.' }
  if ($primary.errors) {
    Stop-Install "$PluginId is installed but failed to load:" ("$($primary.errors -join '; ')`n         Fix the cause above (usually a failed git clone of the Remotion dependency), then run:  claude plugin install remotion@$Marketplace")
  }
  if (-not $primary.enabled) { Stop-Install "$PluginId is installed but disabled." "Run: claude plugin enable $PluginId" }
  Write-Ok "$PluginId $($primary.version) is enabled"

  $remotion = @($items | Where-Object { $_.id -like 'remotion@*' -and $_.enabled -and -not $_.errors })
  if ($remotion.Count -eq 0) {
    Stop-Install 'The official Remotion plugin is not enabled, so the dependency did not resolve.' "Run: claude plugin install remotion@$Marketplace"
  }
  foreach ($r in $remotion) { Write-Ok "Official Remotion plugin: $($r.id) $($r.version) is enabled" }
  if ($remotion.Count -gt 1) {
    Write-Warn2 'More than one copy of the Remotion plugin is enabled. This is harmless (newer Claude Code versions de-duplicate the skills, older ones list each twice).'
    foreach ($r in ($remotion | Where-Object { $_.id -ne "remotion@$Marketplace" })) {
      Write-Warn2 "To keep a single copy, you can run:  claude plugin uninstall $($r.id)"
    }
  }
}

# 5. Optional bare /motion-design command (personal skill copy)
if ($BareCommand) {
  Write-Step 'Adding the optional bare /motion-design command'
  $cfg = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME '.claude' }
  $dest = Join-Path (Join-Path $cfg 'skills') 'motion-design'
  $srcDir = if ($primary -and $primary.installPath) { Join-Path (Join-Path $primary.installPath 'skills') 'motion-design' } else { $null }
  if (Test-Path -LiteralPath $dest) {
    Write-Warn2 "$dest already exists; leaving it untouched."
  } elseif (-not $srcDir -or -not (Test-Path -LiteralPath $srcDir)) {
    Write-Warn2 'Could not locate the installed skill files; skipping the bare command.'
  } else {
    New-Item -ItemType Directory -Path (Split-Path $dest) -Force | Out-Null
    Copy-Item -LiteralPath $srcDir -Destination $dest -Recurse
    Write-Ok "Copied the skill to $dest (this copy does not auto-update; delete it to remove /motion-design)"
  }
}

Write-Host ''
Write-Host 'Done.' -ForegroundColor Green
Write-Host '  Restart Claude Code, or run /reload-plugins in a session that is already open.'
Write-Host '  Then, inside a Remotion project:  /motion-director:motion-design <your brief>'
Write-Host '  You also need Node.js and Git, and a Remotion project (the skill can create one for you).'
