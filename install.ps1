$CacheDir = "C:\ProgramData\Jagex\RuneScape-BETA"

function Install-Plugin {
    param (
        [string]$PluginName
    )

    $TargetDir = Join-Path $CacheDir (Split-Path $PluginName -Leaf)

    # Remove existing plugin folder if it exists
    if (Test-Path $TargetDir -PathType Container) {
        Remove-Item $TargetDir -Recurse -Force
    }

    # Copy plugin folder to target directory
    Copy-Item $PluginName $TargetDir -Recurse
}

Install-Plugin "cluetrainer"

Get-ChildItem "dependencies\plugins" -Directory | ForEach-Object {
    Install-Plugin $_.FullName
}

if (Test-Path "mre" -PathType Container) {
    Get-ChildItem "mre" -Directory | ForEach-Object {
        Install-Plugin $_.FullName
    }
}
