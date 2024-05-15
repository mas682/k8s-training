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

    $windowsPortClear = $false
    $linuxPortClear = $false
    $unknownError = $false
    $loop = $true
    $counter = 1
    $processKilled = $false
    while($loop -and $counter -lt 5)
    {
        Write-Host "`nChecking to see if the port $dbWslPort is in use on the wsl machine..." -ForegroundColor Cyan
        $result = wsl -e bash -c "sudo lsof -ti :$env:dbWslPort"
        if($result -ne $null)
        {
            Write-Host "Process found using the port:" -ForegroundColor Yellow
            Write-Host $result -ForegroundColor Yellow
            Write-Host "Attempting to kill process on wsl2 side..." -ForegroundColor Yellow
            Write-Host "wsl -e bach -c `"kill $result`"" -ForegroundColor Yellow
            wsl -e bash -c "kill $result"
            $processKilled = $true
        }
        else
        {
            Write-Host "No processes found using the port $dbWslPort on the wsl machine`n" -ForegroundColor Magenta
            $loop = $false
            $linuxPortClear = $true
        }
        $counter = $counter + 1
    }

    if($linuxPortClear)
    {   
        $loop = $true
        $counter = 1
        while($loop -and $counter -lt 5)
        {
            Write-Host "Checking to see if the port $dbWslPort is in use on the windows machine..." -ForegroundColor Cyan
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
                Write-Host "To find the process, run:" -ForegroundColor Yellow
                Write-Host "`$process = Get-Process -Id (Get-NetTCPConnection -LocalPort $dbWslPort -ErrorAction stop).OwningProcess"
                Write-Host "To kill the process, run (Be careful as this can cause routing issues so that windows doesn't see a newly mapped port from WSL):" -ForegroundColor Yellow
                Write-Host "Stop-Process -ID `$process.id -Force"
                $counter = $counter + 1
                if($processKilled)
                {
                    $sleepSeconds = 3
                    Write-Host "Sleeping $sleepSeconds seconds to give the windows machine time to see the process was killed on the wsl machine...`n" -ForegroundColor Magenta
                    Start-Sleep -Seconds $sleepSeconds
                }
            }
        }
    }

    if($windowsPortClear -and $linuxPortClear)
    {
        Write-Host "`nMapping WSL2 port $dbWslPort to the database service port $dbServicePort exposed on the cluster" -ForegroundColor Cyan
        Write-Host "kubectl port-forward service/db-external ${dbWslPort}:${dbServicePort}" -ForegroundColor Yellow
        # set environment variables so bash can see the values
        $env:dbWslPort = $dbWslPort
        $env:dbServicePort = $dbServicePort
        wt -w 0 new-tab --title db-port-forward PowerShell -NoExit -c "wsl -e bash -c 'kubectl port-forward service/db-external $env:dbWslPort\:$env:dbServicePort'"
        wt -w 0 focus-tab --previous
        $sleepSeconds = 3
        Write-Host "Sleeping $sleepSeconds seconds to give windows time to see the new process..." -ForegroundColor Cyan
        Start-Sleep $sleepSeconds
        Write-Host "The process should be running on the windows side:" -ForegroundColor Cyan
        Write-Host "Get-Process -Id (Get-NetTCPConnection -LocalPort $dbWslPort -ErrorAction stop).OwningProcess" -ForegroundColor Yellow
        try 
        {
            $process = Get-Process -Id (Get-NetTCPConnection -LocalPort $dbWslPort -ErrorAction stop).OwningProcess
            $process
        } catch {
            if ($_.Exception.Message -match "No MSFT_NetTCPConnection objects found with property 'LocalPort' equal to '$dbWslPort'") {
                Write-Host "No TCP connections found for port $dbWslPort" -ForegroundColor Red
            } else {
                Write-Host "An error occurred: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}