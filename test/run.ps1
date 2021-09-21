$ErrorActionPreference = "Stop"
$here = Split-Path $MyInvocation.MyCommand.Definition
$json = Get-Content "$here/variablesubstitution-variables.explicitenvironments.json" | out-string | ConvertFrom-Json

$TargetEnvironment = 'DevTest'

# Find scoped environment if present
$scopedEnvironment = $json.ScopeValues.Environments | Where-Object {$_.Name -eq $targetEnvironment}

# Find scoped variables based on target environment
$targetVariables = $json.Variables | Where-Object {
       $_.Scope.Environment -contains $scopedEnvironment.Id `
       -OR $_.Scope.Environment -contains $targetEnvironment `
       -OR [bool]($_.Scope.PSobject.Properties.name -match 'Environment') -eq $false 
    }

# Find variables needing substitution    
$needsSubstituting = $targetVariables | Where-Object {
    $_.Value -match '#{?(.*)}'
}

# Substitute
$needsSubstituting | ForEach-Object {
    $m = $_.Value | Select-String -pattern '#{?(.*)}'
    $value = $m.Matches.Groups[1].Value
    $substition = $targetVariables | Where-Object {$_.Name -eq $value}
    $_.Value = $_.Value -replace '#{?(.*)}', $substition.Value
}

# Write alle variables to env
$targetVariables | ForEach-Object {
    Write-Output "$($_.Name)=$($_.Value)"
}

$Env:GITHUB_ENV | format-table
