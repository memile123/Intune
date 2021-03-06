[CmdletBinding()]
Param (
    [Parameter()]
    [string] $Path = $pwd
)

# Get the latest Intune PowerShell SDK
$latestRelease = (Invoke-Webrequest -uri https://api.github.com/repos/Microsoft/Intune-PowerShell-SDK/releases | ConvertFrom-Json)[0]

# Return the latest version tag
$latestVersion = $latestRelease.tag_name
Write-Verbose -Message "Latest release is $latestVersion."

# Array of releases and downloaded
$releases = $latestRelease.assets | Select-Object name, browser_download_url
Write-Output $releases

# Output paths
$intuneSdk = "Intune-SDK"
$releaseZip = Join-Path $Path (Join-Path $intuneSdk $(Split-Path $releases.browser_download_url -Leaf))
$extractFolder = Join-Path $Path $intuneSdk
Write-Verbose "New directory $extractFolder."
New-Item -Path $extractFolder -ItemType Directory

# Download and extract the latest release
try {
    If (!(Test-Path -path $releaseZip)) {
        Write-Verbose -Message "Downloading $($releases.browser_download_url) to $releaseZip."
        Invoke-WebRequest -Uri $releases.browser_download_url -OutFile $releaseZip
    }
}
catch {
    $_
    Break
}
finally {
    If (!(Test-Path -Path (Join-Path $extractFolder "Release"))) {
        Write-Verbose -Message "Extracting $releaseZip."
        Expand-Archive -LiteralPath $releaseZip -DestinationPath $extractFolder
    }
}

# Find the module path and get the SDK releases from the extracted archive
$releases = Get-ChildItem -Path (Join-Path $extractFolder "Release") -Directory | Select-Object FullName
If ($PSVersionTable.PSVersion -lt [Version]"6.0") {
    $moduleFolder = ($releases | Where-Object { $_.FullName -like "*net471" }).FullName
}
Else {
    $moduleFolder = ($releases | Where-Object { $_.FullName -like "*netstandard2.0" }).FullName
}

# Import the Intune PowerShell module and connect to Intune Graph API
try {
    Write-Verbose "Target module folder is $moduleFolder."
    Import-Module (Join-Path $moduleFolder "Microsoft.Graph.Intune.psd1")
}
catch {
    $_
    Break
}
finally {
    Connect-MSGraph
}
