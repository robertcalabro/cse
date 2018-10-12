<#
this custom script extension configer DNS.

#>

#this will be our temp folder - need it for download / logging

$tmpDir = "c:\temp\" 

#create folder if it doesn't exist
if (!(Test-Path $tmpDir)) { mkdir $tmpDir -force}

Start-Transcript "$tmpDir\ScriptExtension_DNS.log" -Append

#Domain Joind
$domain = "mc-demo.de"
$password = "Welcome2018!" | ConvertTo-SecureString -asPlainText -Force
$username = "$domain\Deployment" 
$credential = New-Object System.Management.Automation.PSCredential($username,$password)
Add-Computer -DomainName $domain -Credential $credential


Stop-Transcript