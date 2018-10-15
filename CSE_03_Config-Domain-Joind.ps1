<#
this custom script extension configer DNS.

#>

#this will be our temp folder - need it for download / logging

$tmpDir = "c:\temp\" 

#create folder if it doesn't exist
if (!(Test-Path $tmpDir)) { mkdir $tmpDir -force}

Start-Transcript "$tmpDir\ScriptExtension_DomainJoind.log" -Append

#Domain Joind
$domain = "mc-demo.de"
$password = "Welcome2018!" | ConvertTo-SecureString -asPlainText -Force
$username = "mc-demo\Deployment" 
$credential = New-Object System.Management.Automation.PSCredential($username,$password)
Add-Computer -DomainName $domain -Credential $credential -Restart


Stop-Transcript
