To setup the scripts locally:

Get the full path to the minikube_start.ps1 script relative to your windows machine
It should be something like:
\\wsl.localhost\Ubuntu\home\k8s-training\setup-scripts\minikube_start.ps1

In powershell, do notepad $PROFILE

Take the path to the script and add it to the file with a preceding . such as:

. \\wsl.localhost\Ubuntu\home\k8s-training\setup-scripts\init_minikube.ps1

You will have to add any scripts that minikube_start depends on such as docker_start

. \\wsl.localhost\Ubuntu\home\k8s-training\setup-scripts\minikube_start.ps1
. \\wsl.localhost\Ubuntu\home\k8s-training\setup-scripts\docker_start.ps1
. \\wsl.localhost\Ubuntu\home\k8s-training\setup-scripts\docker_registry_setup.ps1
. \\wsl.localhost\Ubuntu\home\k8s-training\setup-scripts\kubernetes_setup.ps1
. \\wsl.localhost\Ubuntu\home\k8s-training\setup-scripts\init_minikube.ps1

Restart PowerShell when you are done

You should be able to now run Minikube-Start
You should also be able to run Docker-Start, Docker-Registry-Setup, etc.
(the names of the functions in the files) 
Ideally you want to just run Minikube-Start but this gives you the option to run 
the others independently but be aware some are dependent on others running first