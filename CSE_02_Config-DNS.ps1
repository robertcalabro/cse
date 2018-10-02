<#
this custom script extension configer DNS.

#>

#this will be our temp folder - need it for download / logging

$tmpDir = "c:\temp\" 

#create folder if it doesn't exist
if (!(Test-Path $tmpDir)) { mkdir $tmpDir -force}

Start-Transcript "$tmpDir\ScriptExtension_DNS.log" -Append

#DNS Configure
#Reverse-Lookup-Zone erstellen
Add-DnsServerPrimaryZone -NetworkID 10.0.1.0/24 -ReplicationScope Domain -DynamicUpdate Secure -PassThru
Add-DnsServerPrimaryZone -NetworkID 10.0.2.0/24 -ReplicationScope Domain -DynamicUpdate Secure -PassThru

#DNS Regesrieren
ipconfig /registerdns

#DNS Eintrag auf die Server IP änderen
Set-DnsClientServerAddress -InterfaceAlias "Ethernet 2" -ResetServerAddresses


Stop-Transcript
