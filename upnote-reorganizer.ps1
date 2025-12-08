<#
.SYNOPSIS
Reorganizes markdown files into subdirectories based on their YAML front matter 'categories' field.

.DESCRIPTION
This script iterates through all .md files in the specified folder, reads the YAML front matter
to find the 'categories' entry, which must be in the format:
categories:
- FolderA / FolderB / FolderC / ...

It now handles any level of nesting. The script creates the necessary directory structure and
moves the file into the deepest folder found.

.PARAMETER TargetPath
The path to the folder containing the markdown files to be organized.
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$TargetPath
)

# --- Configuration ---
$CategoryDelimiter = ' / '

# Define a function to sanitize folder names, removing illegal characters and non-printable characters
function Sanitize-FolderName {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
    # 1. Strip common non-printable/control characters (like null bytes) that can cause unexpected truncation.
    $CleanName = $Name -replace '[\p{C}]', ''
    
    # 2. Characters illegal in Windows file paths: \ / : * ? " < > |
    # We replace them with a hyphen or simply remove them.
    $SanitizedName = $CleanName -replace '[\\/:\*\?"<>\|]', '-'
    
    # 3. Final trim to remove any residual leading/trailing spaces
    return $SanitizedName.Trim()
}

# --- Main Script Logic ---
Write-Host "Starting markdown file organization in: $TargetPath"
Write-Host "Looking for the categories pattern: 'Folder A', 'Folder A$CategoryDelimiter Folder B', etc."
Write-Host "------------------------------------------------------------------"

# Get all markdown files in the target path
$FilesToProcess = Get-ChildItem -Path $TargetPath -Filter "*.md" -File

if (-not $FilesToProcess) {
    Write-Warning "No markdown files found in '$TargetPath'. Exiting."
    exit
}

foreach ($File in $FilesToProcess) {
    Write-Host "`nProcessing file: $($File.Name)"
    # Read file content line by line for efficiency, especially with large files
    $Content = Get-Content $File.FullName

    $InFrontMatter = $false
    $FoundCategoriesHeader = $false
    $CategoryPath = $null

    # 1. Extract the categories path from the YAML front matter
    foreach ($Line in $Content) {
        $TrimmedLine = $Line.Trim()

        if ($TrimmedLine -eq '---') {
            # Found the start or end of the YAML block
            if ($InFrontMatter) {
                # End of block reached
                break
            }
            $InFrontMatter = $true
            continue
        }

        if ($InFrontMatter) {
            # Check for the 'categories' header
            if ($TrimmedLine -eq 'categories:') {
                $FoundCategoriesHeader = $true
                continue
            }

            # Check for the first list item under 'categories'
            if ($FoundCategoriesHeader -and $TrimmedLine -like '- *') {
                # Extract the value after '- '
                $RawPath = $TrimmedLine -replace '^- ', ''
                $CategoryPath = $RawPath.Trim('"').Trim("'").Trim(' ') # Remove potential quotes
                Write-Host "want to move $File.Name to $CategoryPath"
                break # Found the path, exit line loop
            }

            # Stop looking for list items if another major field starts (e.g., date: or tags:)
            if ($FoundCategoriesHeader -and $TrimmedLine -match '^\w+:') {
                $FoundCategoriesHeader = $false
            }
        }
    }
    
    # 2. Process and move the file if a path was found
    if ($CategoryPath) {
        # Split the path by the defined delimiter, explicitly trim each result, and filter out any empties.
        $FolderNames = ($CategoryPath -split $CategoryDelimiter) | ForEach-Object {
            $_.Trim()
        } | Where-Object { $_ -ne '' } # Filter out empty strings after trimming

        if ($FolderNames.Count -ge 1) {
            
            $DestinationDir = $TargetPath
            $StructureDescriptionComponents = @()

            # Iterate through all folder names provided in the category path to build the full path
            foreach ($FolderName in $FolderNames) {
                $CleanedName = Sanitize-FolderName -Name $FolderName

                if ([string]::IsNullOrWhiteSpace($CleanedName)) {
                    Write-Warning "Skipping segment: Sanitized folder name was empty for original segment: '$FolderName'."
                    # Continue the foreach loop, skipping this segment but allowing subsequent segments
                    continue
                }

                # Successively join the cleaned folder name to the destination path
                $DestinationDir = Join-Path -Path $DestinationDir -ChildPath $CleanedName
                $StructureDescriptionComponents += $CleanedName
            }
            
            # Check if a valid folder structure was successfully built after processing all segments
            if ($StructureDescriptionComponents.Count -eq 0) {
                Write-Warning "Skipping: No valid folder structure could be built from category path: '$CategoryPath'."
                continue
            }

            $StructureDescription = $StructureDescriptionComponents -join '\'

            # Create the destination directory if it doesn't exist
            if (-not (Test-Path -Path $DestinationDir)) {
                Write-Host "--> Creating directory structure: $StructureDescription" -ForegroundColor Cyan
                New-Item -Path $DestinationDir -ItemType Directory | Out-Null
            }

            # Move the file
            Write-Host "--> Moving to: $StructureDescription" -ForegroundColor Green
            Move-Item -Path $File.FullName -Destination $DestinationDir -Force
        } else {
            Write-Warning "Skipping: Could not find any valid folder names in the category path: '$CategoryPath'."
        }
    } else {
        Write-Warning "Skipping: Could not find the expected 'categories' entry in the file's front matter."
    }
    
}

Write-Host "`n------------------------------------------------------------------"
Write-Host "Organization complete."
