function Docker-Start {
    param(
        [string]$context = "",
        [string]$path,
        [int] $maxAttempts = 30
    )

    Write-Host "Starting Docker Desktop..." -ForegroundColor Green
    Start-Process $path
    $dockerRunning = $null
    $attempts = 0
    do {
        $dockerRunning = Invoke-Expression -Command "docker ps" -ErrorAction SilentlyContinue
        if($dockerRunning -eq $null) { 
            $attempts++ 
            Write-Host "Waiting for Docker to start...$attempts"  -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
        if($attempts > $maxAttempts)
        {
            Write-Error "Docker could not be started within $maxAttempts seconds" -ErrorAction Stop
        }
    } while ($dockerRunning -eq $null)

    if($context -ne "")
    {
        Write-Host "Switching to the docker context: $context" -ForegroundColor Cyan
        docker context use $context
    }
}