param(
    [Parameter(Mandatory=$true,Position=0)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet(
		"branch",
		"branches",
		"branches-detailed",
		"checkout",
		"clean",
		"fetch",
		"pull",
		"script",
		"status",
		"update-remote"
		)]
    [String]$Action,
	
	[Alias('b')]
	[Parameter(Mandatory=$false)]
	[ValidateSet("master", "feature/coc_psr_13645", "feature/spr_coc", "feature/coc_psr_13645_R20191214")]
	[String]$Branch = "",
	
	[Alias('s')]
	[Parameter(Mandatory=$false)]
	[scriptblock]$Script = {},
	
	[Alias('h')]
	[Parameter(Mandatory=$false)]
	[string]$BaseDirectory="C:\AIM\Trunk\Products\RAD",
	
	[Parameter(Mandatory=$false)]
	[switch]$hard,
	
	[Parameter(Mandatory=$false)]
	[ValidateSet("today", "two-weeks", "all")]
	[string]$BranchHistory = "all"
)

$executionDirectory = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)

# Loads functions from utility script
. "$executionDirectory\GitUtil.ps1"

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

# Adds root to the path stack so we can get back to the directory from which the command ran
Push-Location $BaseDirectory

# Filters only directories that are Git repos
$directories = Get-ChildItem -Directory | Where-Object { [System.IO.Directory]::Exists($_.FullName + '\.git\') -eq $true }

foreach ($directory in $directories) {

    Set-Location $directory.FullName
	
	Print-Header -Header $directory.Name

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
		
		"update-remote" {
		
			git remote update origin --prune
		}

		"pull" {
		
			$currentBranch = git branch --show-current
			if ($Branch -ne $currentBranch) { git checkout $Branch }
			git pull origin $Branch
			if ($Branch -ne $currentBranch) { git checkout $currentBranch }
		}
		
		"checkout" {
		
			if ((git branch --show-current) -match $Branch) {
				Write-Host -ForegroundColor DarkCyan "already on ${Branch} branch"
			} else {
				
				$hasBranch = $false
				git branch | % { if (($_ -like "*${Branch}")) { $hasBranch = $true } }
				
				if ($hasBranch) {
					git checkout $Branch
				}
			}
		}
		
		"branch" {
		
			Write-Host -ForegroundColor Cyan ' '(git branch --show-current)
		}
		
		"branches" {
		
			$allBranches = git branch -r | sort
			$myBranches =      $allBranches | sls '[Ff]eature\/abilson'
			$koskyBranches =   $allBranches | sls '[Ff]eature\/kosky'
			$ahmedBranches =   $allBranches | sls '[Ff]eature\/KA\/'
			$kasardaBranches = $allBranches | sls '[Ff]eature\/kasarda'
			$cocBranches =     $allBranches | sls 'coc' | sls -NotMatch 'abilson|kosky|kasarda|\/KA\/' 

			$myBranches      | % { Write-Host -ForegroundColor Yellow $_ }
			$koskyBranches   | % { Write-Host -ForegroundColor Cyan $_ }
			$ahmedBranches   | % { Write-Host -ForegroundColor Blue $_ }
			$kasardaBranches | % { Write-Host -ForegroundColor Magenta $_ }
			$cocBranches     | % { Write-Host -ForegroundColor White $_ }
		}
		
		"branches-detailed" {
		
			$allBranches = git branch -r --sort=committerdate
			$myBranches =      $allBranches | sls '[Ff]eature\/abilson'
			$koskyBranches =   $allBranches | sls '[Ff]eature\/kosky'
			$ahmedBranches =   $allBranches | sls '[Ff]eature\/KA\/'
			$kasardaBranches = $allBranches | sls '[Ff]eature\/kasarda'
			$cocBranches =     $allBranches | sls 'coc' | sls -NotMatch 'abilson|kosky|kasarda|\/KA\/' 
			
			if ($myBranches.Length -gt 0) { Print-SubHeader -Header "My Branches" }
			$myBranches | % { Print-Branch -BranchName $_.Line.Trim() -BranchHistory $BranchHistory }
			
			if ($koskyBranches.Length -gt 0) { Print-SubHeader -Header "Kosky Branches" }
			$koskyBranches | % { Print-Branch -BranchName $_.Line.Trim() -BranchHistory $BranchHistory }
			
			if ($ahmedBranches.Length -gt 0) { Print-SubHeader -Header "Ahmed Branches" }
			$ahmedBranches | % { Print-Branch -BranchName $_.Line.Trim() -BranchHistory $BranchHistory }
			
			if ($kasardaBranches.Length -gt 0) { Print-SubHeader -Header "Kasarda Branches" }
			$kasardaBranches | % { Print-Branch -BranchName $_.Line.Trim() -BranchHistory $BranchHistory }
			
			if ($cocBranches.Length -gt 0) { Print-SubHeader -Header "CoC Branches" }
			$cocBranches | % { Print-Branch -BranchName $_.Line.Trim() -BranchHistory $BranchHistory }
		}
		
		"clean" {
		
			# removes all untracked files and directories (not counting ignored files and directories)
			Write-Host -ForegroundColor Cyan "Removing untracked files and directories (not counting ignored files and directories)"
			$cleaned = git clean -df
			$cleaned | % { Write-Host -ForegroundColor DarkCyan $_ }
			
			# resets assembly version updates from build
			# 2>&1 - sends stderr to stdout so it can be captured in the terminal
			# > $null - sends error to empty buffer so it doesn't appear.
			Write-Host -ForegroundColor Cyan "Restoring assembly version files..."
			git restore *version.txt 2>&1 > $null
			git restore *Assembly*.cs 2>&1 > $null
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