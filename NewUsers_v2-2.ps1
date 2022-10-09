# Import Active D irectory module
Import-Module ActiveDirectory
Import-Module 'Posh-SSH'
$creds=Get-Credential
 
# Open file dialog
# Load Windows Forms
[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
 
# Create and show open file dialog
$dialog = New-Object System.Windows.Forms.OpenFileDialog
$dialog.InitialDirectory = $StartDir
$dialog.Filter = "CSV (*.csv)| *.csv" 
$dialog.ShowDialog() | Out-Null
 
# Get file path
$CSVFile = $dialog.FileName
 
# Import file into variable
# Lets make sure the file path was valid
# If the file path is not valid, then exit the script
if ([System.IO.File]::Exists($CSVFile)) {
    Write-Host "Importing CSV..."
    $CSV = Import-Csv -LiteralPath "$CSVFile"
} else {
    Write-Host "File path specified was not valid"
    Exit
}
 
# Lets iterate over each line in the CSV file
foreach($user in $CSV) {
 
    # Password
    $SecurePassword = ConvertTo-SecureString "$($user.FirstName[0])$($user.LastName)$($user.EmployeeID)!@#" -AsPlainText -Force
 
    # Format their username
    $Username = "$($user.FirstName).$($user.LastName)"
    $Username = $Username.Replace(" ", "")
 
    # Create new user
    New-ADUser -Name "$($user.FirstName) $($user.LastName)" `
                -GivenName $user.FirstName `
                -Surname $user.LastName `
                -UserPrincipalName $Username `
                -SamAccountName $Username `
                -EmailAddress $user.Email `
                -Description $user.Description `
                -OfficePhone $user.OfficePhone `
                -Path "$($user.OU)" `
                -ChangePasswordAtLogon $true `
                -AccountPassword $SecurePassword `
                -Enabled $([System.Convert]::ToBoolean($user.Enabled))
 
    # Write to host that we created a new user
    Write-Host "Created $Username / $($user.Email)"
 
    # If groups is not null... then iterate over groups (if any were specified) and add user to groups
    if ($user.Groups -ne "") {
        $user.Groups.Split(",") | ForEach {
            Add-ADGroupMember -Identity $_ -Members "$($user.FirstName).$($user.LastName)"
            Write-Host "Added $Username to $_ group" # Log to console
        }

    }
 
    # Write to host that we created the user
    Write-Host "Created user $Username with groups $($user.Groups)"


}




$creds=Get-Credential
$session=New-SSHSession -Computername 192.168.101.100 -Credential $creds -AcceptKey
Invoke-SSHCOMMAND -SSHSession $session -command "pwd"
Invoke-SshCommand -Command "ansible-playbook vmware.yml" -SessionId 0




 
Read-Host -Prompt "Script complete... Press enter to exit."