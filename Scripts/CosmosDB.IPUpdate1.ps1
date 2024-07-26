param(
    [Parameter(Mandatory = $true)]
    [string] $ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string] $AccountName,

    [Parameter(Mandatory = $true)]
    [string] $NewIpRanges  # Comma-separated string of new IP ranges
)

# Split the comma-separated string of new IP ranges into an array
$NewIpRangesArray = $NewIpRanges -split ","

# Retrieve all Cosmos DB accounts in the specified resource group
$cosmosObjs = Get-AzCosmosDBAccount -ResourceGroupName $ResourceGroupName

# Check if the specific Cosmos DB account is present
$accountExists = $cosmosObjs | Where-Object { $_.Name -eq $AccountName }

# Proceed if the account exists
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
}
else {
    # If the account doesn't exist, initialize the updated IP array with the input IP ranges
    $updatedIpRangesArray = $NewIpRangesArray.Clone()
    Write-Output "Account $AccountName does not exist in the resource group $ResourceGroupName."
}

# Convert the final list of IP ranges into a comma-separated string
$updatedIpRangesString = $updatedIpRangesArray -join ","
$DeploymentScriptOutputs = @{}
$DeploymentScriptOutputs['ipAddress'] = $updatedIpRangesString

# Output final IP ranges for use in subsequent steps or deployments
Write-Output "Final IP Ranges: $updatedIpRangesString"
