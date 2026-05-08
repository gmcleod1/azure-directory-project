# Pester smoke tests for Reset-OutlookProfile.ps1
# Run: Invoke-Pester -Path .\scripts\tests\Reset-OutlookProfile.Tests.ps1

Describe 'Reset-OutlookProfile.ps1' {
    BeforeAll {
        $script:ScriptPath = Join-Path $PSScriptRoot '..\Reset-OutlookProfile.ps1'
    }

    It 'exists at the expected path' {
        Test-Path $script:ScriptPath | Should -BeTrue
    }

    It 'parses without syntax errors' {
        { [scriptblock]::Create((Get-Content $script:ScriptPath -Raw)) } | Should -Not -Throw
    }

    It 'declares CmdletBinding with SupportsShouldProcess' {
        (Get-Content $script:ScriptPath -Raw) | Should -Match 'SupportsShouldProcess\s*=\s*\$true'
    }

    It 'supports -WhatIf without changing state' {
        { & $script:ScriptPath -ProfileName 'NonExistentProfile' -WhatIf } | Should -Not -Throw
    }
}
