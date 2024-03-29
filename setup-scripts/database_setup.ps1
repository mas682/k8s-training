function Db-Port-Forwarding-Setup
{
    param(
        # port wsl2 will use to connect to database
        [int]$dbWslPort=5433,
        # port exposed by service in k8s
        [int]$dbServicePort=5432
    )

    # set environment variables
    $env:dbWslPort = $dbWslPort
    $env:dbServicePort = $dbServicePort

    Write-Host "`nSetting up port forwarding for the database" -ForegroundColor Green
    Write-Host "Checking to see if the port $dbWslPort is in use on the windows machine..." -ForegroundColor Cyan



    $windowsPortClear = $false
    $linuxPortClear = $false
    $unknownError = $false
    $loop = $true
    $counter = 1
    while($loop -and $counter -lt 5)
    {
        try 
        {
            $process = Get-Process -Id (Get-NetTCPConnection -LocalPort $dbWslPort -ErrorAction stop).OwningProcess
        } catch {
            if ($_.Exception.Message -match "No MSFT_NetTCPConnection objects found with property 'LocalPort' equal to '$dbWslPort'") {
                Write-Host "No TCP connections found for port $dbWslPort" -ForegroundColor Magenta
                $windowsPortClear = $true
                $loop = $false
            } else {
                $unknownError = $true
                Write-Host "An error occurred: $($_.Exception.Message)" -ForegroundColor Red
                $loop = $false
            }
        }
        
        if(-not $windowsPortClear -and -not $unknownError)
        {
            Write-Host "A process is already using the specified port $dbWslPort so port forwarding could not be set up for the database" -ForegroundColor Red
            Write-Host "Use a different port number or kill the process" -ForegroundColor Red
            Write-Host "Process:" -ForegroundColor Red
            $process

            if($process.ProcessName -eq "wslrelay")
            {
                Write-Host "Attempting to kill process with id of:" + $process.Id 
                Stop-Process -ID $process.id -Force
            }
            $counter = $counter + 1
        }
    }

    if($windowsPortClear)
    {   
        $loop = $true
        $counter = 1
        Write-Host "`nChecking to see if the port $dbWslPort is in use on the wsl machine..." -ForegroundColor Cyan
        while($loop -and $counter -lt 5)
        {
            $result = wsl -e bash -c "sudo lsof -ti :$env:dbWslPort"
            if($result -ne $null)
            {
                Write-Host "Process(es) found using the port:" -ForegroundColor Yellow
                Write-Host $result -ForegroundColor Yellow
                Write-Host "Attempting to kill any processes on wsl2 side..." -ForegroundColor Yellow
                wsl -e bash -c "kill -9 $result"
            }
            else
            {
                Write-Host "No processes found using the port $dbWslPort on the wsl machine" -ForegroundColor Magenta
                $loop = $false
                $linuxPortClear = $true
            }
            $counter = $counter + 1
        }
    }

    if($windowsPortClear -and $linuxPortClear)
    {
        Write-Host "`nMapping WSL2 port $dbWslPort to the database service port $dbServicePort exposed on the cluster" -ForegroundColor Cyan
        Write-Host "kubectl port-forward service/db-service ${dbWslPort}:${dbServicePort}" -ForegroundColor Cyan
        # set environment variables so bash can see the values
        $env:dbWslPort = $dbWslPort
        $env:dbServicePort = $dbServicePort
        wt -w 0 new-tab --title db-port-forward PowerShell -NoExit -c "wsl -e bash -c 'kubectl port-forward service/db-service $env:dbWslPort\:$env:dbServicePort'"
        wt -w 0 focus-tab --previous
    }
}