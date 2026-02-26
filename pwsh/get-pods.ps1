#This script confirms access to AWS via CLI and then grabs all pods from EKS in all regions
$k8sinfo = @()
# Check if AWS CLI is installed
if (-not (Get-Command "aws" -ErrorAction SilentlyContinue)) {
    Write-Host "AWS CLI is not installed. Please install it to proceed." -ForegroundColor Red
    exit 1
}

# Get all AWS regions
$regions = aws ec2 describe-regions --query "Regions[].RegionName" --output text

foreach ($region in $regions) {
    Write-Host "Fetching pods from region: $region" -ForegroundColor Cyan
    # Get EKS clusters in the region
    $clusters = aws eks list-clusters --region $region --query "clusters[]" --output text

    foreach ($cluster in $clusters) {
        Write-Host "Fetching pods from cluster: $cluster in region: $region" -ForegroundColor Green
        # Update kubeconfig for the cluster
        aws eks update-kubeconfig --name $cluster --region $region

        # Get all pods in the cluster
        $pods = kubectl get pods --all-namespaces
        $info = @{
            Region = $region
            Cluster = $cluster
            Pods = $pods
        }
        $k8sinfo += $info
    }
}
# Output the collected information to csv
$k8sinfo | Export-Csv -Path "k8s_info.csv" -NoTypeInformation