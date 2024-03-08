function Minikube-Start {
    param(
        [switch]$startDocker=$false,
        [switch]$startMinikube=$false,
        [switch]$deleteMinikube=$false,
        [switch]$startKubernetes=$false,
        [switch]$startDockerRegistry=$false,
        [switch]$startDbForwarding=$false,
        [switch]$setAllFlagsTrue=$false,
        [int]$minikubeNodes=2,
        [int]$cpus=2,
        [string]$memory="2g",
        [int]$dbWslPort=5433,
        [int]$dbServicePort=5432
    )

    function Get-ExecutionTime {
        param (
            [datetime]$startTime,
            [datetime]$endTime
        )
        $executionTime = $endTime - $startTime
        return "$($executionTime.Minutes) minutes $($executionTime.Seconds) seconds $($executionTime.Milliseconds) milliseconds"
    }


    if($setAllFlagsTrue)
    {
        $startDocker=$true
        $startMinikube=$true
        $deleteMinikube=$true
        $startKubernetes=$true
        $startDockerRegistry=$true
        $startDbForwarding=$true
    }

    $startTime = Get-Date
    if($startDocker)
    {
        # docker
        $time = Get-Date
        Docker-Start -path "C:\Program Files\Docker\Docker\Docker Desktop.exe" -context "minikube"
        $docker_time = Get-ExecutionTime -startTime $time -endTime $(Get-Date)
    }

    if($startMinikube)
    {
        # minikube
        $time = Get-Date
        Init-Minikube -nodes $minikubeNodes -addons @("registry") -wslpath "\\wsl.localhost\Ubuntu\root\" -deleteMinikube $deleteMinikube -cpus $cpus -memory $memory
        $minikube_time = Get-ExecutionTime -startTime $time -endTime $(Get-Date)
    }

    if($startKubernetes)
    {
        $time = Get-Date
        Setup-Kubernetes -kubeConfigPath "\\wsl.localhost\Ubuntu\root" -manifestPath "/home/k8s-training" -textFilePath "\\wsl.localhost\Ubuntu\home"
        $kubernetes_time = Get-ExecutionTime -startTime $time -endTime $(Get-Date)
    }

    if($startDockerRegistry)
    {
        $time = Get-Date
        Docker-Registry-Setup -dockerFilePath "\\wsl.localhost\Ubuntu\home\k8s-training\flask-docker-app"
        $registry_time = Get-ExecutionTime -startTime $time -endTime $(Get-Date)
    }

    if($startDbForwarding)
    {
        $time = Get-Date
        Db-Port-Forwarding-Setup -dbWslPort $dbWslPort -dbServicePort $dbServicePort
        $db_port_forwarding_time = Get-ExecutionTime -startTime $time -endTime $(Get-Date)
    }    

    $path = "/home/k8s-training"
    Write-Host "`nOpening Ubuntu terminal at path $path" -ForegroundColor Green
    Invoke-Expression -Command "wt -w 0 new-tab -d $path -p Ubuntu"

    Write-Host "`nExecution times:" -ForegroundColor Green
    if($startDocker)
    {
        Write-Host "Docker startup time: $docker_time" -ForegroundColor Cyan
    }
    if($startMinikube)
    {
        Write-Host "Minikube startup time: $minikube_time" -ForegroundColor Cyan
    }
    if($startKubernetes)
    {
        Write-Host "Kubernetes startup time: $kubernetes_time" -ForegroundColor Cyan
    }
    if($startDockerRegistry)
    {
        Write-Host "Docker registry startup time: $registry_time" -ForegroundColor Cyan
    }
    if($startDbForwarding)
    {
        Write-Host "Database port forwarding startup time: $db_port_forwarding_time" -ForegroundColor Cyan
    }

    $totalTime = Get-ExecutionTime -startTime $startTime -endTime $(Get-Date)
    Write-Host "Total execution time: $totalTime" -ForegroundColor DarkCyan
}