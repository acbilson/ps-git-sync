function Print-Header {
param(
[string]$Header
)

	# Sets the spacing width for console output
	$consoleWidth = [math]::Floor($Host.UI.RawUI.WindowSize.Width / 3)
	
	# Sets the width of the header buffer
	$leftBufferWidth = [math]::Floor(($consoleWidth - $Header.Length) / 2)
	$rightBufferWidth = $leftBufferWidth
	
	# adjusts buffer width for odd header names to keep them the same length as even
	if ($consoleWidth % 2 -eq 1 -and $Header.Length % 2 -eq 0) 
	{
		$leftBufferWidth = $leftBufferWidth + 1
	} elseif ($consoleWidth % 2 -eq 0 -and $Header.Length % 2 -eq 0)
	{
		$leftBufferWidth = $leftBufferWidth - 1
	}
	
	# Write left buffer
	Write-Host -ForegroundColor DarkGray -NoNewLine $('#' * $leftBufferWidth)
	
	# Write header
	Write-Host -ForegroundColor DarkGreen -NoNewLine ([string]::Format(" {0} ", $Header.ToUpper()))
	
	# Write right buffer
	Write-Host -ForegroundColor DarkGray $('#' * $rightBufferWidth)
}

function Print-SubHeader {
param(
[string]$Header
)

	$underline = @('-' * $Header.Length)
	
	Write-Host
	Write-Host -ForegroundColor DarkGreen " "$Header
	Write-Host -ForegroundColor DarkGray " "$underline
}

function Print-Branch {

param(
[string]$BranchName
)

	$dayWidth = 12

	$lastCommit = git log -n 1 --no-merges --format="%cr|%h" $BranchName
	$day = $lastCommit.Split('|')[0]
	$commit = $lastCommit.Split('|')[1]
	
	Write-Host -ForegroundColor Yellow -NoNewLine ([string]::Format(" {0}{1}", $day, $(' ' * [math]::abs($dayWidth - $day.Length))))
	
	Write-Host -ForegroundColor DarkGray -NoNewLine " "$commit" "
	Write-Host -ForegroundColor Cyan $BranchName
}