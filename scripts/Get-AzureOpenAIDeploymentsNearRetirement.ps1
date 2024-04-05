# Get all OpenAI resources in the subscription
$aoaiResources = Get-AzCognitiveServicesAccount | Where-Object { $_.AccountType -eq "OpenAI" }

# Initialize an empty array to store deployment details
$allDeployments = @()

# Loop through each OpenAI resource
foreach ($resource in $aoaiResources) {
    # Get deployment details for the current resource
    $deployments = Get-AzCognitiveServicesAccountDeployment -ResourceGroupName $resource.ResourceGroupName -AccountName $resource.AccountName

    # Loop through each deployment
    foreach ($deployment in $deployments) {
        $deploymentDetails = $deployment.Properties

        # Create a custom object with relevant information
        $outputObject = [PSCustomObject]@{
            "Resource Group" = $resource.ResourceGroupName
            "AOAI Resource Name" = $resource.AccountName
            "Region" = $resource.Location
            "Model Name" = $deploymentDetails.Model.Name
            "Deployment Name" = $deployment.Name
            "Model Version" = $deploymentDetails.Model.Version
            "Upgrade Option" = $deploymentDetails.VersionUpgradeOption
        }

        # Add the current deployment details to the array
        $allDeployments += $outputObject
    }
}

# Filter deployments for versions with upcoming retirement dates
$filteredDeployments = $allDeployments | Where-Object {
    $_."Model Name" -like "*gpt-35*" -and ($_."Model Version" -in ("0613", "0301"))
}

$filteredDeployments | Format-Table -AutoSize
