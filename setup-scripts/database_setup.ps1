function Db-Port-Forwarding-Setup
{
    param(
        # port wsl2 will use to connect to database
        [int]$dbWslPort=5433,
        # port exposed by service in k8s
        [int]$dbServicePort=5432
    )

    Write-Host "`nSetting up port forwarding for the database" -ForegroundColor Green

    Write-Host "Checking to see if the port $dbWslPort is in use on the windows machine..." -ForegroundColor Cyan

    $continue = $false
    $unknownError = $false
    try 
    {
        $process = Get-Process -Id (Get-NetTCPConnection -LocalPort $dbWslPort -ErrorAction stop).OwningProcess
    } catch {
        if ($_.Exception.Message -match "No MSFT_NetTCPConnection objects found with property 'LocalPort' equal to '$dbWslPort'") {
            Write-Host "No TCP connections found for port $dbWslPort" -ForegroundColor Cyan
            $continue = $true
        } else {
            $unknownError = $true
            Write-Host "An error occurred: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    if(-not $continue -and -not $unknownError)
    {
        Write-Host "A process is already using the specified port $dbWslPort so port forwarding could not be set up for the database" -ForegroundColor Red
        Write-Host "Use a different port number" -ForegroundColor Red
        Write-Host "Process:" -ForegroundColor Red
        $process
    }

    if($continue)
    {
        Write-Host "Mapping WSL2 port $dbWslPort to the database service port $dbServicePort exposed on the cluster"
        Write-Host "kubectl port-forward service/db-service ${dbWslPort}:${dbServicePort}"
        # set environment variables so bash can see the values
        $env:dbWslPort = $dbWslPort
        $env:dbServicePort = $dbServicePort
        wt -w 0 new-tab --title db-port-forward PowerShell -NoExit -c "wsl -e bash -c 'kubectl port-forward service/db-service $env:dbWslPort\:$env:dbServicePort'"
        #wt -w 0 new-tab --title db-port-forward Powershell -NoExit -c "wsl -e bash -c 'kubectl port-forward service/db-service $env:abc\:$env:abc'"
    }
}