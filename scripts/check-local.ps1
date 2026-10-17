$ErrorActionPreference = "Stop"
Write-Host "Checking required commands..."
foreach ($command in @("git", "docker", "terraform", "aws")) {
  if (-not (Get-Command $command -ErrorAction SilentlyContinue)) { throw "Missing command: $command" }
}
Write-Host "Checking Docker daemon..."
docker info | Out-Null
Write-Host "Checking AWS identity..."
aws sts get-caller-identity
Write-Host "Building image..."
docker build -t focusflow-app ./app
Write-Host "Starting container on http://localhost:8080 ..."
$existing = docker ps -aq --filter "name=focusflow-local"
if ($existing) { docker rm -f focusflow-local | Out-Null }
docker run -d --name focusflow-local -p 8080:8080 focusflow-app
Start-Sleep -Seconds 2
curl.exe -i http://localhost:8080/health
Write-Host "Open http://localhost:8080 in your browser. Stop container with: docker rm -f focusflow-local"
