<#
this custom script extension configer RDS Host.

#>

#this will be our temp folder - need it for download / logging

$tmpDir = "c:\temp\" 

#create folder if it doesn't exist
if (!(Test-Path $tmpDir)) { mkdir $tmpDir -force}

Start-Transcript "$tmpDir\ScriptExtension_RDSConfig.log" -Append

$RDSLS = 'azsrvdc01.mc-demo.de'  # Lizenz-Server
$RDSCB = 'azsrvrdsgw01.mc-demo.de'  # Verbindungsbroker
$RDSWA = 'azsrvrdsgw01.mc-demo.de'  # Web Access
$RDSSH = 'azsrvrds01.mc-demo.de' # RDShosts
$RDSGW = 'azsrvrdsgw01' # Gateway - Server

#Import RDS Modul
Import-Module RemoteDesktop

#RDS Rollen installieren
New-RDSessionDeployment -ConnectionBroker $RDSCB -SessionHost $RDSSH -WebAccessServer $RDSWA -Verbos

#Verbindung zum Broker
Get-RDServer -ConnectionBroker $RDSCB

#Lizenz Server hinzufügen
Add-RDServer -Role RDS-LICENSING -Server $RDSLS -ConnectionBroker $RDSCB -Verbose
#Lizenze Sever Einstelungen festlegen
Set-RDLicenseConfiguration -Mode PerUser -LicenseServer $RDSLS -ConnectionBroker $RDSCB -Force

#Neue Collection anlegen
New-RDSessionCollection -CollectionName 'RDS SessionCollection' -SessionHost $RDSSH -ConnectionBroker $RDSCB -CollectionDescription 'This Collection is for Desktop Sessions'

#Installaiton RDS Gateway
#Install-WindowsFeature -Name RDS-Gateway -Verbose -IncludeManagementTools -IncludeAllSubFeature

#Neustart der Server
Restart-Computer -ComputerName $RDSCB,$RDSWA,$RDSSH -Force

Stop-Transcript
