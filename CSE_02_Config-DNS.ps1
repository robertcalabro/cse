<#
this custom script extension configer DC DNS.

#>
########################################################################################
# Function
########################################################################################
# Funciton AD User Informationen
function New-ADUserDetails
{
    [CmdletBinding()]
       param ($Name,$UserPrincipalName,$DisplayName,$GivenName,$SurName)

       $ADUser = New-Object PSObject
       $ADUser | Add-Member -NotePropertyName Name -NotePropertyValue $Name
       $ADUser | Add-Member -NotePropertyName UserPrincipalName -NotePropertyValue $UserPrincipalName
       $ADUser | Add-Member -NotePropertyName DisplayName -NotePropertyValue $DisplayName
       $ADUser | Add-Member -NotePropertyName GivenName -NotePropertyValue $GivenName
       $ADUser | Add-Member -NotePropertyName SurName -NotePropertyValue $SurName


       return $ADUser
} 


$ADUserList = @()
$ADUserList += New-ADUserDetails -Name "RDS01" -UserPrincipalName "rds01@mc-demo.de" -DisplayName "RDS01" -GivenName "RDS01" -SurName "RDS01"
$ADUserList += New-ADUserDetails -Name "RDS02" -UserPrincipalName "rds02@mc-demo.de" -DisplayName "RDS02" -GivenName "RDS02" -SurName "RDS02"
$ADUserList += New-ADUserDetails -Name "RDS03" -UserPrincipalName "rds03@mc-demo.de" -DisplayName "RDS03" -GivenName "RDS03" -SurName "RDS03"

########################################################################################
#   Function
########################################################################################
# Passwort Generator
function New-SWRandomPassword {
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

Start-Transcript "$tmpDir\ScriptExtension_DNS.log" -Append

#DNS Configure
#Reverse-Lookup-Zone erstellen
Add-DnsServerPrimaryZone -NetworkID 10.1.0.0/24 -ReplicationScope Domain -DynamicUpdate Secure -PassThru
Add-DnsServerPrimaryZone -NetworkID 10.2.0.0/24 -ReplicationScope Domain -DynamicUpdate Secure -PassThru

#DNS Regesrieren
ipconfig /registerdns

#DNS Eintrag auf die Server IP änderen
Set-DnsClientServerAddress -InterfaceAlias "Ethernet 2" -ResetServerAddresses

#Deaktivierung Windwos Firewall
Set-NetFirewallProfile -Enabled True

#Erstellen eines AD Admin
$password = "Welcome2018!" | ConvertTo-SecureString -AsPlainText -Force
$DNSroot = (Get-ADDomain).dnsroot
New-ADUser -Name Deployment -UserPrincipalName deployment@$dnsroot -AccountPassword $Password -PasswordNeverExpires $True -Enabled $True
Add-ADGroupMember -Identity "Domain Admins" -Members deployment


#Password Gernerator
$pwd = New-SWRandomPassword -MinPasswordLength 8 -MaxPasswordLength 12
$SecurePassword = ConvertTo-SecureString $pwd -AsPlainText -Force
#AD User erstellen
$ADUserList | ForEach-Object { 
    New-ADUser -Name $_.Name -UserPrincipalName $_.UserPrincipalName -DisplayName $_.DisplayName -GivenName $_.GivenName -Surname $_.SurName -AccountPassword $SecurePassword -PasswordNeverExpires $True -Enabled $True
    }


Stop-Transcript
