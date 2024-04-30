function Setup-Kubernetes 
{
    param(
        [string]$kubeConfigPath="\\wsl.localhost\Ubuntu\root",
        [string]$manifestPath="\home\k8s-training",
        [string]$textFilePath="\\wsl.localhost\Ubuntu\home"
    )

    Write-Host "`nSetting up kubernetes environment..." -ForegroundColor Green

    # Copy kube config to WSL2
    $kubeConfigFile = "$kubeConfigPath\.kube\config"
    Write-Host "Copying the kube config file to WSL2 ($kubeConfigFile)..." -ForegroundColor Cyan
    $kubeConfig = Get-Content "$env:USERPROFILE\.kube\config"
    $kubeConfig = $kubeConfig -replace 'C:', '/mnt/c'
    $kubeConfig = $kubeConfig -replace '\\', '/'
    $kubeConfig | Set-Content -Path $kubeConfigFile

    # create any necessary kubernetes secrets
    $secretsText = "$textFilePath\k8s-training\setup-scripts\secrets.txt"
    Write-Host "`nCreating kubernetes secrets from $secretsText..." -ForegroundColor Cyan
    # create any necessary secrets
    foreach($line in Get-Content -Path $secretsText -ErrorAction SilentlyContinue)
    {
        if(-not $line.Contains("#"))
        {
            $values = $line.Split(":")
            $name = $values[0]
            $file = $values[1]
            Write-Host "Creating the kubernetes secret $name from file: $file" -ForegroundColor Magenta
            # wsl -e bash -c "cd $manifestPath; kubectl create secret generic $name --from-env-file=$file"
            $wslCommand = "bash -c 'cd $manifestPath; kubectl create secret generic $name --from-env-file=$file'"
            Invoke-WslCommand -wslCommand $wslCommand
        }
    }

    # create any necessary kubernetes manifests
    $scriptsText = "$textFilePath\k8s-training\setup-scripts\setup-scripts.txt"
    Write-Host "`nCreating kubernetes manifest files from $scriptsText..." -ForegroundColor Cyan
    foreach($line in Get-Content -Path $scriptsText -ErrorAction SilentlyContinue)
    {
        if(-not $line.Contains("#") -and -not $line -eq "")
        {
            $values = $line.Split(":")
            $name = $values[0]
            $type = $values[1]
            $delete = $values[2].ToLower()
            $file = $values[3]
            $namespace = $values[4]
            Write-Host "Creating the kubernetes manifest file: $file"-ForegroundColor Magenta
            Write-Host "name: $name, type: $type, delete: $delete, namespace: $namespace" -ForegroundColor White

            $wslCommand = "bash -c 'cd $manifestPath; kubectl create -f $file -n $namespace'"
            if($delete -eq "true"){
                $wslCommand = "bash -c 'cd $manifestPath; kubectl delete -f $file -n $namespace; kubectl create -f $file -n $namespace'"
            }
            Invoke-WslCommand -wslCommand $wslCommand
        }
        elseif ($line.Contains("#*")) {
            $values = $line.Split("*")
            $type = $values[1].trim()
            Write-Host "Creating kubernetes $type..." -ForegroundColor Blue
        }
    }

}