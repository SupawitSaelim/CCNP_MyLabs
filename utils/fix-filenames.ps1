$ErrorActionPreference = "Stop"

function Remove-InvalidFileNameChars {
    param(
        [Parameter(Mandatory=$true,
        Position=0,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)]
        [String]$Name
    )

    $invalidChars = [IO.Path]::GetInvalidFileNameChars() -join ''
    $invalidChars += ' '  # Add space to invalid characters
    $re = "[{0}]" -f [RegEx]::Escape($invalidChars)
    
    # Replace invalid characters with underscore
    $newName = $Name -replace $re, '_'
    
    # Replace multiple underscores with single underscore
    $newName = $newName -replace '_{2,}', '_'
    
    # Remove leading/trailing underscores
    $newName = $newName.Trim('_')
    
    return $newName
}

function Rename-FilesAndFolders {
    param (
        [string]$path
    )

    Write-Host "Starting rename process in: $path" -ForegroundColor Green

    # Process all folders first (bottom-up to avoid path issues)
    Get-ChildItem -Path $path -Directory -Recurse | Sort-Object -Property FullName -Descending | ForEach-Object {
        $folder = $_
        $newName = Remove-InvalidFileNameChars -Name $folder.Name
        
        if ($newName -ne $folder.Name) {
            $newPath = Join-Path -Path $folder.Parent.FullName -ChildPath $newName
            Write-Host "Renaming folder: $($folder.FullName) -> $newPath" -ForegroundColor Yellow
            try {
                Rename-Item -Path $folder.FullName -NewName $newName -Force
                Write-Host "Successfully renamed folder" -ForegroundColor Green
            }
            catch {
                Write-Host "Error renaming folder: $_" -ForegroundColor Red
            }
        }
    }

    # Then process all files
    Get-ChildItem -Path $path -File -Recurse | ForEach-Object {
        $file = $_
        $newName = Remove-InvalidFileNameChars -Name $file.Name
        
        if ($newName -ne $file.Name) {
            $newPath = Join-Path -Path $file.DirectoryName -ChildPath $newName
            Write-Host "Renaming file: $($file.FullName) -> $newPath" -ForegroundColor Yellow
            try {
                Rename-Item -Path $file.FullName -NewName $newName -Force
                Write-Host "Successfully renamed file" -ForegroundColor Green
            }
            catch {
                Write-Host "Error renaming file: $_" -ForegroundColor Red
            }
        }
    }

    Write-Host "Rename process completed" -ForegroundColor Green
}

# Get the current script's directory
$scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# Use the script directory as the starting point
Rename-FilesAndFolders -path $scriptPath

Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")