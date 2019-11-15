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