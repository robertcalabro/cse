﻿<#
this custom script extension configer DNS.

#>

#this will be our temp folder - need it for download / logging

$tmpDir = "c:\temp\" 

#create folder if it doesn't exist
if (!(Test-Path $tmpDir)) { mkdir $tmpDir -force}

Start-Transcript "$tmpDir\ScriptExtension_DNS.log" -Append

$RDSLS= '1azsrvdc01.mc-demo.de'  # Lizenz-Server
$RDSCB= '1azsrvrdsgw01.mc-demo.de'  # Verbindungsbroker
$RDSWA= '1azsrvrdsgw01.mc-demo.de'  # Web Access
$RDSSH= '1azsrvrds01.mc-demo.de' # RDShosts
$RDSGW= '1azsrvrdsgw01' # Gateway - Server

#RDS Rollen installieren
New-RDSessionDeployment -ConnectionBroker $RDSCB -SessionHost $RDSSH -WebAccessServer $RDSWA -Verbos

#Verbindung zum Broker
#Get-RDServer -ConnectionBroker $RDSCB

#Lizenz Server hinzufügen
Add-RDServer -Role RDS-LICENSING -Server $RDSLS -ConnectionBroker $RDSCB -Verbose
#Lizenze Sever Einstelungen festlegen
Set-RDLicenseConfiguration -Mode PerUser -LicenseServer $RDSLS -ConnectionBroker $RDSCB -Force

#Neue Collection anlegen
New-RDSessionCollection -CollectionName 'RDS SessionCollection' -SessionHost $RDSSH -ConnectionBroker $RDSCB -CollectionDescription 'This Collection is for Desktop Sessions'

#Neustart der Server
Restart-Computer -ComputerName $RDSCB,$RDSWA,$RDSSH -Force

Stop-Transcript