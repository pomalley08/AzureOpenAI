<#
.SYNOPSIS
    Retrieves all Azure OpenAI deployments and their deprecation dates.
#>

# Get all OpenAI resources in the subscription
$aoaiResources = Get-AzCognitiveServicesAccount | Where-Object { $_.AccountType -eq "OpenAI" }

# Create an ArrayList to store the model and deployment details
$allDeployments = New-Object System.Collections.ArrayList
$allModels = New-Object System.Collections.ArrayList

# Loop through each OpenAI resource
foreach ($resource in $aoaiResources) {
    # Get deployment details for the current resource
    $deployments = Get-AzCognitiveServicesAccountDeployment -ResourceGroupName $resource.ResourceGroupName -AccountName $resource.AccountName

    # Loop through each deployment
    foreach ($deployment in $deployments) {
        $deploymentDetails = $deployment.Properties

        # Create a custom object with relevant information
        $deploymentObject = [PSCustomObject]@{
            "Resource Group" = $resource.ResourceGroupName
            "AOAI Resource Name" = $resource.AccountName
            "Region" = $resource.Location
            "Model Name" = $deploymentDetails.Model.Name
            "Deployment Name" = $deployment.Name
            "Model Version" = $deploymentDetails.Model.Version
            "Upgrade Option" = $deploymentDetails.VersionUpgradeOption
        }

        # Add the current deployment details to the array
        $allDeployments.Add($deploymentObject) > $null
    }

    # Get model details for the current resource
    $models = Get-AzCognitiveServicesAccountModel -ResourceGroupName $resource.ResourceGroupName -AccountName $resource.AccountName
    
    # Loop through each model
    foreach ($model in $models) {
        $deprecationDetails = $model.Deprecation

        # Create a custom object with relevant information
        $modelObject = [PSCustomObject]@{
            "Resource Group" = $resource.ResourceGroupName
            "AOAI Resource Name" = $resource.AccountName
            "Region" = $resource.Location
            "Model Name" = $model.Name
            "Model Version" = $model.Version
            "Inference Deprecation Date" = $deprecationDetails.Inference
        }

        # Add the current deployment details to the array
        $allModels.Add($modelObject) > $null
    }
}

# Join deployments with the model deprecation dates
$deploymentDeprecations = $allDeployments | LeftJoin $allModels -On @(
    "Resource Group",
    "Region",
    "AOAI Resource Name",
    "Model Name",
    "Model Version"
)

# Define the properties to select
$properties = @(
    "Resource Group",
    "AOAI Resource Name",
    "Region",
    "Deployment Name",
    "Upgrade Option",
    "Model Name",
    "Model Version",
    "Inference Deprecation Date"
)

# Select and sort the deployments
$sorted = $deploymentDeprecations |
    Select-Object -Property $properties |
    Sort-Object -Property "Inference Deprecation Date"

$sorted | Format-Table
