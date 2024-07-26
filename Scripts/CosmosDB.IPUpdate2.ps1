param(
    [Parameter(Mandatory = $true)]
    [string] $ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string] $AccountName,

    [Parameter(Mandatory = $true)]
    [string] $NewIpRanges
)


$NewIpRangesArray = $NewIpRanges -split ","

# Retrieve all Cosmos DB accounts in the specified resource group
$cosmosObjs = Get-AzCosmosDBAccount -ResourceGroupName $resourceGroupName

# Check if the specific Cosmos DB account is present
$accountExists = $cosmosObjs | Where-Object { $_.Name -eq $AccountName }


# Output based on the existence of the account
if ($accountExists) {
    $cosmosObj = $accountExists;
    # Check if IpRules is null or empty and initialize an empty array if true
    if ($null -eq $cosmosObj.IpRules -or $cosmosObj.IpRules.Count -eq 0) {
        $currentIpRangesArray = @()
        Write-Output "No existing IP rules found. Initializing with an empty array."
    }
    else {
        # Retrieve the current IP rules and convert to an array of IP strings
        $currentIpRangesArray = $cosmosObj.IpRules | Select-Object -ExpandProperty IPAddressOrRangeProperty
    }

    # Initialize a list to store all updated IP ranges
    $updatedIpRangesArray = $currentIpRangesArray.Clone()
    $changesMade = $false  # Flag to track if new IPs are added

    # Loop through each new IP range and add it to the list if it is not already included
    foreach ($newIpRange in $NewIpRangesArray) {
        if (-not $updatedIpRangesArray.Contains($newIpRange)) {
            $updatedIpRangesArray += $newIpRange
            Write-Output "Added IP range $newIpRange to update list"
            $changesMade = $true  # Set flag to true indicating a change was made
        }
        else {
            Write-Output "IP range $newIpRange already exists in Cosmos DB account $AccountName"
        }
    }

    # Check if changes were made and update the Cosmos DB account
    if ($changesMade) {
        # Update the Cosmos DB account with the new IP rules
        $cosmosObj = Get-AzCosmosDBAccount -Name $AccountName -ResourceGroupName $ResourceGroupName
        if ($cosmosObj.ProvisioningState -ne "Updating") {
            ##Update-AzCosmosDBAccount -Name $AccountName -ResourceGroupName $ResourceGroupName -IpRule $updatedIpRangesArray
            Write-Output "Updated IP ranges for Cosmos DB account $AccountName"
        }
        else {
            Write-Output "There is already an operation in progress which requires exclusive lock on this Cosmos: $AccountName . Please retry the operation after sometime"
        }
    }
    else {
        Write-Output "No new IP ranges added; no update necessary."
    }
}
else {

    $updatedIpRangesArray = $NewIpRangesArray.Clone()
}
$ipObjectsArray = $updatedIpRangesArray | ForEach-Object {
    # Create a custom object for each IP address
    [PSCustomObject]@{
        ipAddressOrRange = $_
    }
}


$DeploymentScriptOutputs = @{}
$DeploymentScriptOutputs['ipAddress'] = $ipObjectsArray
