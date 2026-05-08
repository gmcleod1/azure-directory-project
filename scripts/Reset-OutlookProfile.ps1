<#
.SYNOPSIS
    Removes the current Outlook profile for a user and recreates a clean one.

.DESCRIPTION
    Closes Outlook, removes the named profile from the registry, and stages a
    fresh autodiscover-based profile. Designed to be run on the user's machine
    (locally or via remote session). Supports -WhatIf for dry runs.

    Mapped ticket category: Outlook / Profile Corruption (~30% of email tickets)

.PARAMETER ProfileName
    The Outlook profile name to remove and recreate. Default: 'Outlook'.

.PARAMETER UserUpn
    The user's UserPrincipalName, used to seed the new profile. Optional —
    if omitted, autodiscover prompts the user on next launch.

.EXAMPLE
    .\Reset-OutlookProfile.ps1 -UserUpn 'jane.doe@smallco.example' -WhatIf

.EXAMPLE
    .\Reset-OutlookProfile.ps1
    # Removes default profile; user signs in manually next launch.

.NOTES
    Author : Garfield McLeod
    Repo   : github.com/gmcleod1/smallco-it-ops
    Tested : Windows 11 23H2, Outlook 365 (16.0)
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$ProfileName = 'Outlook',
    [string]$UserUpn
)

begin {
    $ErrorActionPreference = 'Stop'
    $profilesKey = 'HKCU:\Software\Microsoft\Office\16.0\Outlook\Profiles'
    $defaultsKey = 'HKCU:\Software\Microsoft\Office\16.0\Outlook'
}

process {
    # 1. Stop Outlook if running
    $outlook = Get-Process -Name 'OUTLOOK' -ErrorAction SilentlyContinue
    if ($outlook) {
        if ($PSCmdlet.ShouldProcess('OUTLOOK.EXE', 'Stop process')) {
            $outlook | Stop-Process -Force
            Start-Sleep -Seconds 2
        }
    }

    # 2. Remove the named profile
    $target = Join-Path $profilesKey $ProfileName
    if (Test-Path $target) {
        if ($PSCmdlet.ShouldProcess($target, 'Remove registry key')) {
            Remove-Item -Path $target -Recurse -Force
        }
    } else {
        Write-Verbose "Profile '$ProfileName' not present — nothing to remove."
    }

    # 3. Clear the default profile pointer so Outlook prompts on next launch
    if ($PSCmdlet.ShouldProcess($defaultsKey, "Clear DefaultProfile value")) {
        Set-ItemProperty -Path $defaultsKey -Name 'DefaultProfile' -Value '' -ErrorAction SilentlyContinue
    }

    # 4. Optional: pre-seed the new profile name so autodiscover lands on a clean shell
    if ($UserUpn) {
        $newProfilePath = Join-Path $profilesKey $ProfileName
        if ($PSCmdlet.ShouldProcess($newProfilePath, "Seed new profile for $UserUpn")) {
            New-Item -Path $newProfilePath -Force | Out-Null
            Write-Verbose "Seeded profile '$ProfileName' for $UserUpn. User signs in on next Outlook launch."
        }
    }

    [pscustomobject]@{
        ProfileName = $ProfileName
        UserUpn     = $UserUpn
        Removed     = (-not (Test-Path $target))
        Timestamp   = (Get-Date).ToString('s')
    }
}
