function Docker-Registry-Setup
{
    param(
        [string]$dockerFilePath
    )

    Write-Host "`nSetting up local docker registry..." -ForegroundColor Green
    # setup local docker registry
    Write-Host "Building python-image image..." -ForegroundColor Cyan
    cd $dockerFilePath
    docker buildx build -t python-image:latest .

    Write-Host "`nMapping local computer to minikube vm..." -ForegroundColor Cyan
    wt -w 0 new-tab --title kube-port-forward PowerShell -NoExit -c {wsl -e bash -c "kubectl port-forward --namespace kube-system service/registry 5000:80"}
    sleep 5

    Write-Host "`nTesting local docker registry connection" -ForegroundColor Cyan
    wsl -e bash -c "curl http://localhost:5000/v2/_catalog"

    Write-Host "`nStopping the container k8s-docker-registry if it exists" -ForegroundColor Cyan
    docker stop k8s-docker-registry
    Write-Host "`nRedirecting traffic going to the docker port to your own port..." -ForegroundColor Cyan
    wt -w 0 new-tab --title docker-redirect PowerShell -NoExit -c {
        docker run --name=k8s-docker-registry --rm -it --network=host alpine ash -c "apk add socat && socat TCP-LISTEN:5000,reuseaddr,fork TCP:host.docker.internal:5000"
    }
    sleep 10

    Write-Host "`nTagging image..." -ForegroundColor Cyan
    docker tag python-image localhost:5000/python-image
    Write-Host "Pushing image..." -ForegroundColor Cyan
    docker push localhost:5000/python-image
}