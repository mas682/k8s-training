Write-Host "Starting Docker Desktop"

Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
$dockerRunning = $null
$attempts = 0
$maxAttempts = 5
do {
    $dockerRunning = Invoke-Expression -Command "docker ps" -ErrorAction SilentlyContinue
    if($dockerRunning -eq $null) { 
        $attempts++ 
        Write-Host "Waiting for Docker to start...$attempts"
        Start-Sleep -Seconds 1
    }
    if($attempts > $maxAttempts)
    {
        Write-Error "Docker could not be started within $maxAttempts seconds" -ErrorAction Stop
    }
} while ($dockerRunning -eq $null)

$dockerContext = "minikube"
Write-Host "Switching to the docker context: $dockerContext"
docker context use $dockerContext

# get minikube status
$minikubeStatusOutput = minikube status
# Create a custom object
$minikubeStatus = [PSCustomObject]@{}
# Split the output into lines and process each line
foreach ($line in $minikubeStatusOutput -split "`n") {
    # Split each line into key and value pairs using the colon as a delimiter
    $key, $value = $line -split ':'
    if($key -eq $null -or $value -eq $null)
    {
        continue;
    }

    # Trim leading and trailing spaces from the key and value
    $key = $key.Trim()
    $value = $value.Trim()

    # Add the key-value pair to the custom object
    $minikubeStatus | Add-Member -MemberType NoteProperty -Name $key -Value $value
}


if( -not ($minikubeStatus.host -eq "Running" -and $minikubeStatus.kubelet -eq "Running" -and $minikubeStatus.apiserver -eq "Running" -and $minikubeStatus.kubeconfig -eq "Configured"))
{
    Write-Host "Minikube not running"
    minikube start
}
else
{
    Write-Host "Minikube already running"
}

Write-Host "Copying the kube config file to WSL2"
$kubeConfig = Get-Content "$env:USERPROFILE\.kube\config"
$kubeConfig = $kubeConfig -replace 'C:', '/mnt/c'
$kubeConfig = $kubeConfig -replace '\\', '/'

$kubeConfig | Set-Content -Path "\\wsl.localhost\Ubuntu\root\.kube\config"

$path = "/home/k8s-training"
Write-Host "Opening Ubuntu terminal at path $path"
Invoke-Expression -Command "wt -d $path -p Ubuntu"