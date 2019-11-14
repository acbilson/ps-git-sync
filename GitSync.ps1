param(
    [Parameter(Mandatory=$true,Position=0)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("status", "pull", "branch", "fetch", "branches", "checkout", "clean", "script")]
    [String]$Action,
	
	[Parameter(Mandatory=$false)]
	[ValidateSet("master", "feature/coc_psr_13645", "feature/spr_coc")]
	[String]$Branch = "",
	
	[Parameter(Mandatory=$false)]
	[scriptblock]$Script = {},
	
	[Parameter(Mandatory=$false)]
	[string]$BaseDirectory="C:\AIM\Trunk\Products\RAD"
)

$executionDirectory = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)

# Commands run at the root level
$globalActions = @("clean")
if ($globalActions.Contains($Action)) {

	& "$executionDirectory\GitClean.ps1" -BaseDirectory $BaseDirectory
	return
}

# Error checks to ensure branch is selected when certain actions are requested
if ($Action -eq "pull" -and $Branch -eq "") { 
	Write-Host -ForegroundColor Red "Must select a branch to pull across repositories."
	return
	}

if ($Action -eq "checkout" -and $Branch -eq "") { 
	Write-Host -ForegroundColor Red "Must select a branch to checkout across repositories."
	return
	}

if ($Action -eq "script" -and $Script.ToString() -eq "") {
	Write-Host -ForegroundColor Red "Must supply a script block to run a script across repositories."
	return
	}

# Navigates to the base path if not already there
Set-Location $BaseDirectory

# Adds root to location stack to return here when complete
Push-Location

# Sets a spacing width for console output
$consoleWidth = $Host.UI.RawUI.WindowSize.Width / 3

# Filters only directories that are Git repos
$directories = Get-ChildItem -Directory | Where-Object { [System.IO.Directory]::Exists($_.FullName + '\.git\') -eq $true }

foreach ($directory in $directories) {

    # Header to print per directory
    Set-Location $directory.FullName
    Write-Host -ForegroundColor DarkGray $('#' * $consoleWidth)
    Write-Host -ForegroundColor DarkGreen ' ' $directory.Name.ToUpper()

    # Git actions to take per directory
    # Note: Add new actions to ValidateSet in param
    switch ($Action) {

        "status" {

            $status = git status --porcelain
			$status | % {
				if ($_ -like '`?*') {Write-Host -ForegroundColor Red $_}
				else {Write-Host -ForegroundColor Yellow $_}
				}
        }
		
		"fetch" {
		
			$fetch = git fetch 2>&1
			[regex]$regex = '\[.*>\s[^\s]+'
			if ($fetch -and $fetch[1]) {
				$regex.Matches($fetch[1]) | % { Write-Host -ForegroundColor Cyan $_.Value }
			}
		
		}
		
		"pull" {
		
			$currentBranch = git branch --show-current
			if ($Branch -ne $currentBranch) { git checkout $Branch }
			git pull origin $Branch
			if ($Branch -ne $currentBranch) { git checkout $currentBranch }
		}
		
		"checkout" {
		
			if ((git branch --show-current) -match $Branch) {
				git checkout $Branch
			} else
			{ Write-Host -ForegroundColor Red "skipped repo because ${Branch} does not exist" }
		}
		
		"branch" {
		
			$temp = git branch | sls \*
			Write-Host -ForegroundColor Cyan $temp
		}
		
		"branches" {
		
			$branches = git branch -r
			$branches |	sls '[Ff]eature\/abilson' | % { Write-Host -ForegroundColor Cyan $_ }
			$branches |	sls '[Ff]eature\/kosky' | % { Write-Host -ForegroundColor Yellow $_ }
			$branches |	sls '[Ff]eature\/KA\/' | % { Write-Host -ForegroundColor Gray $_ }
			$branches |	sls '[Ff]eature\/kasarda' | % { Write-Host -ForegroundColor Magenta $_ }
			$branches |	sls 'coc' | % { Write-Host -ForegroundColor White $_ }
		}
		
		"script" {
		
			$Script.Invoke()
		}
    }

    # Footer to print per directory
    ""
}

# Returns to the root directory
Pop-Location