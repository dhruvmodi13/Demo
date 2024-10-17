Param(
  [string] [Parameter(Mandatory = $true)] $storageAccount_name,
  [string] [Parameter(Mandatory = $true)] $resourceGroupName,
  [string] [Parameter(Mandatory = $true)] $subId,
  [string] [Parameter(Mandatory = $true)] $vaults_salesproductivity_name,
  [string] [Parameter(Mandatory = $true)] $profiles_cdn_salesproductivity_name,
  [string] [Parameter(Mandatory = $true)] $endpoint_cdn_salesproductivity_name,
  [string] [Parameter(Mandatory = $true)] $vivaSalesSSLCertName,
  [string] [Parameter(Mandatory = $false)] $shouldDeployCDN
)

## Enable Static Website
$indexDocument = "somehtml.html"

Write-Output "Enabling Static website for $storageAccount_name"
$context = New-AzStorageContext -StorageAccountName -Name $storageAccount_name -UseConnectedAccount
Enable-AzStorageStaticWebsite -Context $context -IndexDocument $indexDocument
Write-Output "Enabled Static website for $storageAccount_name"

## Enable HTTPS on Custom Domain CDN endpoint
if ($shouldDeployCDN -eq "true") {
  $customDomain = (Get-AzCdnCustomDomain -EndpointName $endpoint_cdn_salesproductivity_name -ProfileName $profiles_cdn_salesproductivity_name -ResourceGroupName $resourceGroupName)[0]
    if ($null -ne $customDomain) {
      $customDomainName = $customDomain.Name
      if ($customDomain.CustomHttpsProvisioningState -eq "Enabled") {
        Write-Output "$customDomainName is already HTTPS Enabled"
      }
      else {
        ## Enable HTTPS on the customDomain
        Write-Output "Enabling AzCdnCustomDomainCustomHttps"
        $customDomainHttpsParameter = New-AzCdnUserManagedHttpsParametersObject -CertificateSource AzureKeyVault -CertificateSourceParameterResourceGroupName $resourceGroupName -CertificateSourceParameterSecretName $vivaSalesSSLCertName -CertificateSourceParameterSubscriptionId $subId -CertificateSourceParameterVaultName $vaults_salesproductivity_name -ProtocolType ServerNameIndication
        Enable-AzCdnCustomDomainCustomHttps -ResourceGroupName $resourceGroupName -ProfileName $profiles_cdn_salesproductivity_name -EndpointName $endpoint_cdn_salesproductivity_name -CustomDomainName $customDomainName -CustomDomainHttpsParameter $customDomainHttpsParameter
        Write-Output "Enabled AzCdnCustomDomainCustomHttps"
      }
    }
}
