<#
this custom script extension installs File, AD Feature.
Add Storage Pool, VDisk and Volume
Add Domain Forest
#>
############################
#   Function
############################
    .FUNCTIONALITY
       Generates random passwords
  
    #>
    [CmdletBinding(DefaultParameterSetName='FixedLength',ConfirmImpact='None')]
    [OutputType([String])]
    Param
    (
        # Specifies minimum password length
        [Parameter(Mandatory=$false,
                   ParameterSetName='RandomLength')]
        [ValidateScript({$_ -gt 0})]
        [Alias('Min')] 
        [int]$MinPasswordLength = 8,
        
        # Specifies maximum password length
        [Parameter(Mandatory=$false,
                   ParameterSetName='RandomLength')]
        [ValidateScript({
                if($_ -ge $MinPasswordLength){$true}
                else{Throw 'Max value cannot be lesser than min value.'}})]
        [Alias('Max')]
        [int]$MaxPasswordLength = 12,

        # Specifies a fixed password length
        [Parameter(Mandatory=$false,
                   ParameterSetName='FixedLength')]
        [ValidateRange(1,2147483647)]
        [int]$PasswordLength = 8,
        
        # Specifies an array of strings containing charactergroups from which the password will be generated.
        # At least one char from each group (string) will be used.
        [String[]]$InputStrings = @('abcdefghijkmnpqrstuvwxyz', 'ABCEFGHJKLMNPQRSTUVWXYZ', '23456789', '!"#%&'),

        # Specifies a string containing a character group from which the first character in the password will be generated.
        # Useful for systems which requires first char in password to be alphabetic.
        [String] $FirstChar,
        
        # Specifies number of passwords to generate.
        [ValidateRange(1,2147483647)]
        [int]$Count = 1
    )
    Begin {
        Function Get-Seed{
            # Generate a seed for randomization
            $RandomBytes = New-Object -TypeName 'System.Byte[]' 4
            $Random = New-Object -TypeName 'System.Security.Cryptography.RNGCryptoServiceProvider'
            $Random.GetBytes($RandomBytes)
            [BitConverter]::ToUInt32($RandomBytes, 0)
        }
    }
    Process {
        For($iteration = 1;$iteration -le $Count; $iteration++){
            $Password = @{}
            # Create char arrays containing groups of possible chars
            [char[][]]$CharGroups = $InputStrings

            # Create char array containing all chars
            $AllChars = $CharGroups | ForEach-Object {[Char[]]$_}

            # Set password length
            if($PSCmdlet.ParameterSetName -eq 'RandomLength')
            {
                if($MinPasswordLength -eq $MaxPasswordLength) {
                    # If password length is set, use set length
                    $PasswordLength = $MinPasswordLength
                }
                else {
                    # Otherwise randomize password length
                    $PasswordLength = ((Get-Seed) % ($MaxPasswordLength + 1 - $MinPasswordLength)) + $MinPasswordLength
                }
            }

            # If FirstChar is defined, randomize first char in password from that string.
            if($PSBoundParameters.ContainsKey('FirstChar')){
                $Password.Add(0,$FirstChar[((Get-Seed) % $FirstChar.Length)])
            }
            # Randomize one char from each group
            Foreach($Group in $CharGroups) {
                if($Password.Count -lt $PasswordLength) {
                    $Index = Get-Seed
                    While ($Password.ContainsKey($Index)){
                        $Index = Get-Seed                        
                    }
                    $Password.Add($Index,$Group[((Get-Seed) % $Group.Count)])
                }
            }

            # Fill out with chars from $AllChars
            for($i=$Password.Count;$i -lt $PasswordLength;$i++) {
                $Index = Get-Seed
                While ($Password.ContainsKey($Index)){
                    $Index = Get-Seed                        
                }
                $Password.Add($Index,$AllChars[((Get-Seed) % $AllChars.Count)])
            }
            Write-Output -InputObject $(-join ($Password.GetEnumerator() | Sort-Object -Property Name | Select-Object -ExpandProperty Value))
        }
    }
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
$pwd = New-SWRandomPassword -MinPasswordLength 8 -MaxPasswordLength 12
$SecurePassword = ConvertTo-SecureString $pwd -AsPlainText -Force

#Install AD Forest
Install-ADDSForest -DomainName mc-demo.de -DomainNetBiosName mc-demo -DomainMode WinThreshold -ForestMode WinThreshold -SkipPreChecks -DatabasePath $ADPathDir -InstallDns:$true -SafeModeAdministratorPassword $SecurePassword -Force

Stop-Transcript
