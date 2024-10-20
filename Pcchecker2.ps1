# Clear the PowerShell window and set the custom window title
Clear-Host
$host.UI.RawUI.WindowTitle = "Created By: Zeyfr on Discord"
$titleText = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encodedTitle))

$darkRed = [System.ConsoleColor]::DarkRed
$magenta = [System.ConsoleColor]::Magenta
$white = [System.ConsoleColor]::White

$art = @"
                  

|       /  |   ____\   \  /   /
`---/  /   |  |__   \   \/   / 
   /  /    |   __|   \_    _/  
  /  /----.|  |____    |  |    
 /________||_______|   |__|                         
"@

foreach ($char in $art.ToCharArray()) {
    if ($char -match '[▒░▓]') {
        Write-Host $char -ForegroundColor $darkRed -NoNewline
    } else {
        Write-Host $char -ForegroundColor $magenta -NoNewline  # Use magenta for ASCII art
    }
}

function Get-OneDrivePath {
    try {
        if (-not $oneDrivePath) {
            Write-Warning "OneDrive path not found in registry. Attempting alternative detection..."
            $envOneDrive = [System.IO.Path]::Combine($env:UserProfile, "OneDrive")
            if (Test-Path $envOneDrive) {
                $oneDrivePath = $envOneDrive
                Write-Host "OneDrive path detected using environment variable: $oneDrivePath" -ForegroundColor Green
            } else {
                Write-Error "Unable to find OneDrive path automatically."
            }
        }
        return $oneDrivePath
    } catch {
        Write-Error "Unable to find OneDrive path: $_"
        return $null
    }
}

function Format-Output {
    param($name, $value)
    "{0} : {1}" -f $name, $value -replace 'System.Byte\[\]', ''
}

function Log-FolderNames {
    $userName = $env:UserName
    $oneDrivePath = Get-OneDrivePath
    $potentialPaths = @("C:\Users\$userName\Documents\My Games\Rainbow Six - Siege", "$oneDrivePath\Documents\My Games\Rainbow Six - Siege")
    $allUserNames = @()

    foreach ($path in $potentialPaths) {
        if (Test-Path -Path $path) {
            $dirNames = Get-ChildItem -Path $path -Directory | ForEach-Object { $_.Name }
            $allUserNames += $dirNames
        }
    }

    $uniqueUserNames = $allUserNames | Select-Object -Unique

    if ($uniqueUserNames.Count -eq 0) {
        Write-Output "R6 directory not found."
    } else {
        return $uniqueUserNames
    }
}

function Find-RarAndExeFiles {
    Write-Output "Finding .rar and .exe files..."
    $desktopPath = [System.Environment]::GetFolderPath('Desktop')
    $outputFile = Join-Path -Path $desktopPath -ChildPath "PcCheckLogs.txt"
    $oneDriveFileHeader = "`n-----------------`nOneDrive Files:`n"
    $oneDriveFiles = @()

    $rarSearchPaths = @()
    Get-PSDrive -PSProvider 'FileSystem' | ForEach-Object { $rarSearchPaths += $_.Root }
    $oneDrivePath = Get-OneDrivePath
    if ($oneDrivePath) { $rarSearchPaths += $oneDrivePath }

    $jobs = @()

    $rarJob = {
        param ($searchPaths, $oneDriveFiles)
        $allFiles = @()
        foreach ($path in $searchPaths) {
            Get-ChildItem -Path $path -Recurse -Filter "*.rar" -ErrorAction SilentlyContinue | ForEach-Object {
                $allFiles += $_.FullName
                if ($_.FullName -like "*OneDrive*") { $oneDriveFiles += $_.FullName }
            }
        }
        return $allFiles
    }

    $exeJob = {
        param ($oneDrivePath, $oneDriveFiles)
        $exeFiles = @()
        if ($oneDrivePath) {
            Get-ChildItem -Path $oneDrivePath -Recurse -Filter "*.exe" -ErrorAction SilentlyContinue | ForEach-Object {
                $exeFiles += $_.FullName
                if ($_.FullName -like "*OneDrive*") { $oneDriveFiles += $_.FullName }
            }
        }
        return $exeFiles
    }

    $jobs += Start-Job -ScriptBlock $rarJob -ArgumentList $rarSearchPaths, $oneDriveFiles
    $jobs += Start-Job -ScriptBlock $exeJob -ArgumentList $oneDrivePath, $oneDriveFiles

    $jobs | ForEach-Object {
        Wait-Job $_ | Out-Null
        $allFiles += Receive-Job $_
        Remove-Job $_
    }

    $groupedFiles = $allFiles | Sort-Object

    if ($oneDriveFiles.Count -gt 0) {
        Add-Content -Path $outputFile -Value $oneDriveFileHeader
        $oneDriveFiles | Sort-Object | ForEach-Object { Add-Content -Path $outputFile -Value $_ }
    }

    if ($groupedFiles.Count -gt 0) {
        $groupedFiles | ForEach-Object { Add-Content -Path $outputFile -Value $_ }
    }
}

function Find-SusFiles {
    Write-Output "Finding suspicious file names..."
    $desktopPath = [System.Environment]::GetFolderPath('Desktop')
    $outputFile = Join-Path -Path $desktopPath -ChildPath "PcCheckLogs.txt"
    $susFilesHeader = "`n-----------------`nSus Files:`n"
    $susFiles = @()

    if (Test-Path $outputFile) {
        $loggedFiles = Get-Content -Path $outputFile
        foreach ($file in $loggedFiles) {
            if ($file -match "loader.*\.exe") { $susFiles += $file }
        }

        if ($susFiles.Count -gt 0) {
            Add-Content -Path $outputFile -Value $susFilesHeader
            $susFiles | Sort-Object | ForEach-Object { Add-Content -Path $outputFile -Value $_ }
        }
    } else {
        Write-Output "Log file not found. Unable to search for suspicious files."
    }
}

function Log-PrefetchFiles {
    Write-Output "Logging prefetch files..."
    $desktopPath = [System.Environment]::GetFolderPath('Desktop')
    $outputFile = Join-Path -Path $desktopPath -ChildPath "PcCheckLogs.txt"
    $prefetchPath = "C:\Windows\Prefetch"
    $prefetchFilesHeader = "`n-----------------`nPrefetch Files:`n"

    if (Test-Path $prefetchPath) {
        $prefetchFiles = Get-ChildItem -Path $prefetchPath -Filter "*.pf"
        if ($prefetchFiles.Count -gt 0) {
            Add-Content -Path $outputFile -Value $prefetchFilesHeader
            foreach ($file in $prefetchFiles) {
                $fileInfo = Get-Item -Path $file.FullName
                $timestamp = $fileInfo.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")  # Get last write time
                Add-Content -Path $outputFile -Value "$($file.FullName) - Last Modified: $timestamp"
            }
        } else {
            Add-Content -Path $outputFile -Value "`nNo prefetch files found."
        }
    } else {
        Add-Content -Path $outputFile -Value "`nPrefetch directory not found."
    }
}

function List-BAMStateUserSettings {
    Write-Host "Logging reg entries inside PowerShell..." -ForegroundColor DarkMagenta
    $desktopPath = [System.Environment]::GetFolderPath('Desktop')
    $outputFile = Join-Path -Path $desktopPath -ChildPath "PcCheckLogs.txt"
    if (Test-Path $outputFile) { Clear-Content $outputFile }
    $loggedPaths = @{ }
    Write-Host " Fetching UserSettings Entries " -ForegroundColor DarkMagenta
    $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings"
    $userSettings = Get-ChildItem -Path $registryPath | Where-Object { $_.Name -like "*1001" }

    if ($userSettings) {
        foreach ($setting in $userSettings) {
            Add-Content -Path $outputFile -Value "`n$($setting.PSPath)"
            $items = Get-ItemProperty -Path $setting.PSPath | Select-Object -Property *
            foreach ($item in $items.PSObject.Properties) {
                if (($item.Name -match "exe" -or $item.Name -match ".rar") -and -not $loggedPaths.ContainsKey($item.Name)) {
                    Add-Content -Path $outputFile -Value (Format-Output $item.Name $item.Value)
                    $loggedPaths[$item.Name] = $true
                }
            }
        }
    } else {
        Write-Output "No UserSettings found."
    }
}

function Log-BrowserFolders {
    Write-Host "Logging Browser Folders..." -ForegroundColor DarkMagenta
    $desktopPath = [System.Environment]::GetFolderPath('Desktop')
    $outputFile = Join-Path -Path $desktopPath -ChildPath "PcCheckLogs.txt"

    $browsers = @("Chrome", "Firefox", "Edge")
    foreach ($browser in $browsers) {
        $browserPath = "C:\Users\$env:UserName\AppData\Local\$browser\User Data\Default"
        if (Test-Path $browserPath) {
            Add-Content -Path $outputFile -Value "`n`n-----------------`n$browser Data Folders:`n"
            $folders = Get-ChildItem -Path $browserPath -Directory | Select-Object -ExpandProperty Name
            foreach ($folder in $folders) {
                Add-Content -Path $outputFile -Value $folder
            }
        } else {
            Write-Output "$browser path not found."
        }
    }
}

function Log-WindowsInstallDate {
    Write-Output "Logging Windows Install Date..."
    $desktopPath = [System.Environment]::GetFolderPath('Desktop')
    $outputFile = Join-Path -Path $desktopPath -ChildPath "PcCheckLogs.txt"
    $installDateHeader = "`n-----------------`nWindows Install Date:`n"

    try {
        $windowsInstallDate = (Get-WmiObject Win32_OperatingSystem).InstallDate
        $formattedDate = [Management.ManagementDateTimeConverter]::ToDateTime($windowsInstallDate).ToString("yyyy-MM-dd HH:mm:ss")
        Add-Content -Path $outputFile -Value $installDateHeader
        Add-Content -Path $outputFile -Value $formattedDate
    } catch {
        Write-Error "Unable to retrieve Windows install date: $_"
    }
}

function Check-KMBoxesAndDMA {
    Write-Output "Checking for Kernel-mode boxes and DMA devices..."
    $desktopPath = [System.Environment]::GetFolderPath('Desktop')
    $outputFile = Join-Path -Path $desktopPath -ChildPath "PcCheckLogs.txt"
    $kmHeader = "`n-----------------`nKernel-mode Boxes and DMA Devices:`n"
    
    Add-Content -Path $outputFile -Value $kmHeader
    
    # Example of checking for known KM boxes or DMA devices
    $knownKMs = @("KMBox1", "KMBox2") # Add known KM box names here
    $knownDMAs = @("DMABox1", "DMABox2") # Add known DMA device names here
    
    foreach ($km in $knownKMs) {
        if (Test-Path "C:\Path\To\$km") { # Adjust path accordingly
            Add-Content -Path $outputFile -Value "$km found."
        }
    }
    
    foreach ($dma in $knownDMAs) {
        if (Test-Path "C:\Path\To\$dma") { # Adjust path accordingly
            Add-Content -Path $outputFile -Value "$dma found."
        }
    }
    
    # Optionally, log if none found
    if (-not (Get-Content -Path $outputFile | Select-String -Pattern "found")) {
        Add-Content -Path $outputFile -Value "No known Kernel-mode boxes or DMA devices found."
    }
}

# Main execution block
List-BAMStateUserSettings
Log-WindowsInstallDate
Find-RarAndExeFiles
Find-SusFiles
Log-PrefetchFiles
Log-BrowserFolders
Check-KMBoxesAndDMA  # Call the function to check for KM boxes and DMA

$desktopPath = [System.Environment]::GetFolderPath('Desktop')
# Copy the log file to clipboard
$logFilePath = Join-Path -Path $desktopPath -ChildPath "PcCheckLogs.txt"

if (Test-Path $logFilePath) {
    Set-Clipboard -Path $logFilePath
    Write-Host "Log file copied to clipboard." -ForegroundColor Cyan
} else {
    Write-Host "Log file not found on the desktop." -ForegroundColor Cyan
}

# Clean up old PcCheck.txt if exists
# Function and code to delete existing files unchanged...

# Print completion message
$folderNames = Log-FolderNames | Sort-Object | Get-Unique

foreach ($name in $folderNames) {
    $url = "https://stats.cc/siege/$name"
    Write-Host "Opening stats for $name on Stats.cc ..." -ForegroundColor Cyan
    Start-Process $url
    Start-Sleep -Seconds 0.5
}

# Define colors
$yellow = "Yellow"
$space = " " * 12  # Increased the number of spaces for more right alignment

# Print the red "SCAN COMPLETE" line with more white space to the right
Write-Host "`n$space╭─────────────────────────────────────╮" -ForegroundColor $yellow
Write-Host "$space│            SCAN COMPLETE            │" -ForegroundColor $yellow
Write-Host "$space╰─────────────────────────────────────╯" -ForegroundColor $yellow

# Print the magenta border and text
Write-Host "$space╭─────────────────────────────────────╮" -ForegroundColor $yellow
Write-Host "$space│          Discord @zeyski            │" -ForegroundColor $yellow
Write-Host "$space╰─────────────────────────────────────╯" -ForegroundColor $yellow
