Param(
  [string] [Parameter(Mandatory = $true)] $resourceGroupName,
  [string] [Parameter(Mandatory = $true)] $frontDoorName,
  [string] [Parameter(Mandatory = $true)] $customDomainName,
  [string] [Parameter(Mandatory = $true)] $hostName
)

$domains =  Get-AzFrontDoorCdnCustomDomain -ResourceGroupName $resourceGroupName -ProfileName $frontDoorName
$matchingDomain = $domains | Where-Object { $_.Name -eq $customDomainName }

if ($null -eq $matchingDomain)
{
   $tlsSetting = New-AzFrontDoorCdnCustomDomainTlsSettingParametersObject -CertificateType 'ManagedCertificate' -MinimumTlsVersion 'TLS12'
   New-AzFrontDoorCdnCustomDomain -ResourceGroupName $resourceGroupName -ProfileName $frontDoorName -CustomDomainName $customDomainName -HostName $hostName -TlsSetting $tlsSetting
}
