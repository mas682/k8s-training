function Init-Minikube {
    param(
        [string]$profile = "minikube",
        [int]$nodes = 1,
        [array]$addons = @(),
        [string]$wslpath="\\wsl.localhost\Ubuntu\root\",
        [bool]$skipDeletion=$false
    )

    # get minikube running
    Write-Host "`nStarting minikube..." -ForegroundColor Green
    $minkubeProfile = "minikube"
    Write-Host "Checking minikube status..." -ForegroundColor Cyan
    $minikubeStatusOutput = minikube status -p $profile

    if($minikubeStatusOutput[0].contains("Profile `"$profile`" not found"))
    {
        Write-Host "Profile $profile not found" -ForegroundColor Cyan
    }
    else
    {
        Write-Host "Minikube profile $profile found"  -ForegroundColor Cyan
        if(-not $skipDeletion)
        {
            Write-Host "Deleting profile..." -ForegroundColor Cyan
            minikube delete -p $profile
        }
    }

    Write-Host "`nInitializing minikube..." -ForegroundColor Cyan
    minikube start -p $profile --nodes=$nodes
    # addons
    # only needed if using local docker registry
    if($addons.Count -ge 1)
    {
        Write-Host "`nEnabling addons..." -ForegroundColor Cyan
    }
    foreach($addon in $addons)
    {
        Write-Host "Enabling addon $addon" -ForegroundColor Cyan
        minikube addons enable $addon
    }
}