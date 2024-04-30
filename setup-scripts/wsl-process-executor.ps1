function Invoke-WslCommand {
    param(
        # ex. "bash -c 'cd $manifestPath; kubectl create -f $file -n $namespace'"
        [string]$wslCommand
    )

    # Create a ProcessStartInfo object
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = "wsl"
    $processInfo.Arguments = $wslCommand
    $processInfo.RedirectStandardOutput = $true
    $processInfo.RedirectStandardError = $true
    $processInfo.UseShellExecute = $false

    # Create a Process object
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $processInfo

    try {
        # Start the process
        $process.Start() | Out-Null

        # Capture the output and error
        $output = $process.StandardOutput.ReadToEnd()
        $errorOutput = $process.StandardError.ReadToEnd()

        # Wait for the process to exit
        $process.WaitForExit()

        # Check the exit code
        if ($process.ExitCode -eq 0) {
            Write-Host $output -ForegroundColor Green
        } else {
            Write-Host $errorOutput -ForegroundColor Red
        }
    }
    finally {
        # Dispose the process object to release resources
        $process.Dispose()
    }
}