param (
	[Parameter(Mandatory=$true,Position=0)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("release", "merge")]
    [String]$Action,
	
	[Parameter(Mandatory=$false)]
	[string]$NUnitConsoleExe = "C:\AIM\Trunk\Products\RAD\NUnit.Console-3.10.0\bin\net35\nunit3-console.exe",
	
	[Alias('h')]
	[Parameter(Mandatory=$false)]
	[string]$BaseDirectory="C:\AIM\Trunk\Products\RAD"
)

# MSBuild Key
#
# /m                     - runs build in parallel
# /t:Build               - sets build action (Build, Rebuild, Clean)
# /p:Configuration:Debug - sets build config (Debug, Release)
# -verbosity:minimal     - sets console verbosity to the same as Visual Studio
# -clp:ErrorsOnly        - Sends only errors to console output. Remove for all content

$executionDirectory = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)

# Loads functions from utility script
. "$executionDirectory\GitUtil.ps1"

switch ($Action) {

	"release" {

        if ((Test-Path $executionDirectory/banner-imasis.txt) -eq $true)
        { 
            Get-Content -Path $executionDirectory/banner-imasis.txt | Write-Host -ForegroundColor DarkGreen
        } else 
        {
            Print-Header "Starting RadImasis Release Build..." 
        }
		Write-Host -ForegroundColor Yellow "Caution: don't modify class files or run builds in visual studio until the release build is complete or it may fail because of interference."
		msbuild C:\AIM\Trunk\Products\RAD\RadImasis\RadImasis.sln /m /t:Build /p:Configuration=Release -verbosity:minimal

        Write-Host -ForegroundColor Cyan "RadImasis Build Complete. Moving to RadPortal. CTRL-C to stop."
        Start-Sleep -Seconds 2

        if ((Test-Path $executionDirectory/banner-portal.txt) -eq $true)
        { 
            Get-Content -Path $executionDirectory/banner-portal.txt | Write-Host -ForegroundColor DarkGreen
        } else 
        {
            Print-Header "Starting RadPortal Release Build..." 
        }
		msbuild C:\AIM\Trunk\Products\RAD\RadPortal\RadPortal.sln /m /t:Build /p:Configuration=Release -verbosity:minimal
	}
	
	"merge" {

		if ((Test-Path $NUnitConsoleExe) -eq $false) {
            Write-Host -ForegroundColor Red "Was unable to find nunit3-console.exe. Please copy entire folder to AIM root directory or update NUnitConsoleExe parameter"
            return
         }
		
		do {
			$retry = $false

			$testFiles = @(
			"C:\AIM\Trunk\Products\RAD\Domain\UnitTest\bin\Debug\AIM.Rad.Domain.UnitTest.dll",
			"C:\AIM\Trunk\Products\RAD\RadImasis\Tests\bin\Debug\AIM.Rad.Imasis.UnitTest.dll",
			"C:\AIM\Trunk\Products\RAD\RadPortal\Portal.Tests\bin\Debug\AIM.Rad.Portal.UnitTest.dll"
			)

			foreach ($filePath in $testFiles) {
				
				if (Test-Path $filePath) {
					
					$testFile = Get-Item $filePath
						
					Print-Header ([string]::Format("Testing: {0}", $testFile.BaseName))
						
					& $NUnitConsoleExe --noresult --noh --where:cat==coc $testFile.FullName
				} else {
					
					Write-Host -ForegroundColor Red "Did not find a unit test assembly. Check that you've build the project, and that the path to the assembly hasn't changed. Missing path was: ${filePath}"
						
					$runBuild = Read-Host -Prompt "Would you like to run a debug build and retry? You may also rebuild in Visual Studio. The build process takes a long time. (y/n)"
					if (@('y','yes').Contains($runBuild))
					{
						$retry = $true

                        if ($filePath.Contains("Portal")) {

                            Print-Header "Starting RadPortal Debug Build..."
                            msbuild C:\AIM\Trunk\Products\RAD\RadPortal\RadPortal.sln /m /t:Build /p:Configuration=Debug -verbosity:minimal -clp:ErrorsOnly

                        } else {
                            Print-Header "Starting RadImasis Debug Build..."
                            msbuild C:\AIM\Trunk\Products\RAD\RadImasis\RadImasis.sln /m /t:Build /p:Configuration=Debug -verbosity:minimal -clp:ErrorsOnly 
                        }


					}
				}
			}
		} while ($retry)
	}
}