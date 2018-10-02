<#
this custom script extension installs File, AD Feature.
Add Storage Pool, VDisk and Volume
Add Domain Forest
#>
############################
#   Function
############################
function generate-password {

   $passwordlength = 8   # length of dynamic generates password
   $passwortchars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890" # characters for password generation

   -join ($passwortchars.tochararray() | get-random -count $passwordlength | foreach {$_}) 
}

###################################################################


#this will be our temp folder - need it for download / logging

$tmpDir = "c:\temp\" 

#create folder if it doesn't exist
if (!(Test-Path $tmpDir)) { mkdir $tmpDir -force}

Start-Transcript "$tmpDir\ScriptExtension_DC_FS.log" -Append

#install Fileservice and Domain features 
$features = @("FileAndStorage-Services","File-Services", "FS-FileServer", "FS-Data-Deduplication", "Storage-Services", "AD-Domain-Services")
Install-WindowsFeature -Name $features -Verbose -IncludeManagementTools -IncludeAllSubFeature

#Create a storage Pool with a VDisk and Volume
$StaPool01 = New-StoragePool -FriendlyName "DataStaPool01" -StorageSubSystemUniqueId (Get-StorageSubSystem -FriendlyName "*storage*").uniqueID -PhysicalDisks (Get-PhysicalDisk -CanPool $true)
$VDisk01 = New-VirtualDisk -FriendlyName "VData01" -StoragePoolFriendlyName $StaPool01.FriendlyName -UseMaximumSize -ProvisioningType Fixed -ResiliencySettingName simple
$Disknumber = Get-VirtualDisk -FriendlyName $VDisk01.FriendlyName | Get-Disk | Select-Object Number
Initialize-Disk -Number $Disknumber.Number
$NewPartition = New-Partition -DiskNumber $Disknumber.Number -UseMaximumSize -AssignDriveLetter
Format-Volume -DriveLetter $NewPartition.DriveLetter -FileSystem NTFS -NewFileSystemLabel "DataStore01"

#Check Path
$ADPathDir = "f:\ADDB"
if (!(Test-Path $ADPathDir)) {mkdir $ADPathDir -force}

#Password Gernerator
$pwd = generate-password
$SecurePassword = ConvertTo-SecureString $pwd -AsPlainText -Force

#Install AD Forest
Install-ADDSForest -DomainName mc-demo.de -DomainNetBiosName mc-demo -DomainMode WinThreshold -ForestMode WinThreshold -SkipPreChecks -DatabasePath $ADPathDir -InstallDns:$true -SafeModeAdministratorPassword $SecurePassword -Force

Stop-Transcript
