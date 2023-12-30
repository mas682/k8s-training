function Minikube-Start {
    param(
        [switch]$skipMinikube=$false,
        [switch]$skipMinikubeDeletion=$false,
        [int]$minikubeNodes=2,
        [switch]$skipKubernetes=$false,
        [switch]$skipDockerRegistry=$false
    )

    function Get-ExecutionTime {
        param (
            [datetime]$startTime,
            [datetime]$endTime
        )
        $executionTime = $endTime - $startTime
        return "$($executionTime.Minutes) minutes $($executionTime.Seconds) seconds $($executionTime.Milliseconds) milliseconds"
    }

    $startTime = Get-Date
    # docker
    $time = Get-Date
    Docker-Start -path "C:\Program Files\Docker\Docker\Docker Desktop.exe" -context "minikube"
    $docker_time = Get-ExecutionTime -startTime $time -endTime $(Get-Date)

    if(-not $skipMinikube)
    {
        # minikube
        $time = Get-Date
        Init-Minikube -nodes $minikubeNodes -addons @("registry") -wslpath "\\wsl.localhost\Ubuntu\root\" -skipDeletion $skipMinikubeDeletion
        $minikube_time = Get-ExecutionTime -startTime $time -endTime $(Get-Date)
    }

    if(-not $skipKubernetes)
    {
        $time = Get-Date
        Setup-Kubernetes -kubeConfigPath "\\wsl.localhost\Ubuntu\root" -manifestPath "/home/k8s-training" -textFilePath "\\wsl.localhost\Ubuntu\home"
        $kubernetes_time = Get-ExecutionTime -startTime $time -endTime $(Get-Date)
    }

    if(-not $skipDockerRegistry)
    {
        $time = Get-Date
        Docker-Registry-Setup -dockerFilePath "\\wsl.localhost\Ubuntu\home\k8s-training\flask-docker-app"
        $registry_time = Get-ExecutionTime -startTime $time -endTime $(Get-Date)
    }

    $path = "/home/k8s-training"
    Write-Host "`nOpening Ubuntu terminal at path $path" -ForegroundColor Green
    Invoke-Expression -Command "wt -w 0 new-tab -d $path -p Ubuntu"

    Write-Host "`nExecution times:" -ForegroundColor Green
    Write-Host "Docker startup time: $docker_time" -ForegroundColor Cyan
    if(-not $skipMinikube)
    {
        Write-Host "Minikube startup time: $minikube_time" -ForegroundColor Cyan
    }
    if(-not $skipKubernetes)
    {
        Write-Host "Kubernetes startup time: $kubernetes_time" -ForegroundColor Cyan
    }
    if(-not $skipDockerRegistry)
    {
        Write-Host "Docker registry startup time: $registry_time" -ForegroundColor Cyan
    }

    $totalTime = Get-ExecutionTime -startTime $startTime -endTime $(Get-Date)
    Write-Host "Total execution time: $totalTime" -ForegroundColor DarkCyan
}