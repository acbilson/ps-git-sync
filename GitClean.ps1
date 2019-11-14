param (
	[Parameter(Mandatory=$false)]
	[string]$BaseDirectory=""
)

# Sets a spacing width for console output
$consoleWidth = $Host.UI.RawUI.WindowSize.Width / 3

$executionDirectory = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
$dataPath = [System.IO.Path]::Combine($executionDirectory, "clean.csv")

if ([System.IO.File]::Exists($dataPath) -eq $false) 
{
    Write-Host -ForegroundColor Red "Add a CSV file called clean.csv to the same directory as this script with two columns, BaseFolder and RelativePath, to use this script."
	return
}

# Reads cleaning data from CSV
$data = Import-CSV $dataPath | group -Property BaseFolder

# Moves to the base directory for all Git repos	
Push-Location $BaseDirectory

foreach ($folder in $data) {

    # Moves to the subfolder to do work in
    Push-Location $folder.Name

    Write-Host -ForegroundColor DarkGray $('#' * $consoleWidth)
	Write-Host -ForegroundColor Cyan "Cleaning Repository:" $folder.Name

    foreach($row in $folder.Group) {

        $path = [System.IO.Path]::Combine($BaseDirectory, $row.BaseFolder, $row.RelativePath)
		$pathIsNotNull = $row.RelativePath -ne "NULL"
		$itemExists = Test-Path $path

		if($pathIsNotNull) {
			if ($itemExists) {
				
				$item = Get-Item $path

				# Runs if the path is a directory
				if($item -is [System.IO.DirectoryInfo])
				{
					Write-Host -ForegroundColor DarkCyan "Deleting folder:" $row.RelativePath
					Remove-item -Recurse $path
				} 
				# Runs if the path is a file
				elseif($item -is [System.IO.FileInfo])
				{
					Write-Host -ForegroundColor DarkCyan "Deleting file:  " $row.RelativePath
					Remove-Item $path
				}
			} else {
			
				Write-Host -ForegroundColor DarkGray "Skipping: path did not exist:" $row.RelativePath
			}
		}
    }

    # restores auto-updated version files to avoid accidental commit of new versions
	# which would cause merge conflicts
	Write-Host -ForegroundColor Cyan "Restoring assembly version files..."
	git restore *version.txt
	git restore *Assembly*.cs

    Write-Host ""

    Pop-Location
}