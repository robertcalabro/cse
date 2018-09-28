<#
this custom script extension installs file services
#>


#this will be our temp folder - need it for download / logging

$tmpDir = "c:\temp\" 

#create folder if it doesn't exist
if (!(Test-Path $tmpDir)) { mkdir $tmpDir -force}

Start-Transcript "$tmpDir\ScriptExtension.log" -Append

#install Fileservice and Domain features 
$features = @("FileAndStorage-Services","File-Services", "FS-FileServer", "FS-Data-Deduplication", "Storage-Services", "AD-Domain-Services")
Install-WindowsFeature -Name $features -IncludeManagementTools -IncludeAllSubFeature -Verbose

#Create a storage Pool with a VDisk and Volume
$StaPool01 = New-StoragePool -FriendlyName "DataStaPool01" -StorageSubSystemUniqueId (Get-StorageSubSystem -FriendlyName "*storage*").uniqueID -PhysicalDisks (Get-PhysicalDisk -CanPool $true)
$VDisk01 = New-VirtualDisk -FriendlyName "VData01" -StoragePoolFriendlyName $StaPool01.FriendlyName -UseMaximumSize -ProvisioningType Fixed -ResiliencySettingName simple
$Disknumber = Get-VirtualDisk -FriendlyName $VDisk01.FriendlyName | Get-Disk | Select-Object Number
Initialize-Disk -Number $Disknumber.Number
$NewPartition = New-Partition -DiskNumber $Disknumber.Number -UseMaximumSize -AssignDriveLetter
Format-Volume -DriveLetter $NewPartition.DriveLetter -FileSystem NTFS -NewFileSystemLabel "DataStore01"

Stop-Transcript
