#requires -Modules posh-ssh 
$vmhosts = @("node1","node2","node3","node4")

# This looks for all NVMe disks and wipes all partitions
$cmdNVMe = "for disk in `$(ls /vmfs/devices/disks | grep NVMe | grep -v :); do partedUtil setptbl /vmfs/devices/disks/`$disk msdos; done"

# This looks for all "mpx" disks and wipes all partitions, these would be SAS/SATA disks
$cmdmpx = "for disk in `$(ls /vmfs/devices/disks | grep mpx | grep -E '^([^:]*:){3}[^:]*$'); do partedUtil setptbl /vmfs/devices/disks/`$disk msdos; done"

$user = "root"
$password = "notMyP@ssw0rd!"
$password = ConvertTo-SecureString -String $password -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential($user,$password)

foreach ($i in $vmhosts){
    write-host -fore green `n`t "Connecting to $i"   
    connect-viserver $i -credential $creds

    # SSH is disabled by default
    write-host -fore green `n`t "Enabling SSH"
    Get-VmHostService | Where-Object {$_.key -match "TSM-SSH"} | Set-VMHostService -Policy "on" -confirm:$false | Start-VMHostService -confirm:$false

    # removes a stored key for the host if the OS has been reinstalled after first SSH session
    Get-SSHTrustedHost | ? {$_.HostName -match $i} | Remove-SSHTrustedHost -ErrorAction SilentlyContinue
    
    write-host -fore green `n`t "SSHing into $i"
    # Create a new SSH session
    $ssh = New-SSHSession -computername $i -credential $creds -AcceptKey -KeepAliveInterval 5 -Verbose

    # run the ssh command for NVMe
    write-host -fore green `n`t "Clearing NVMe"
    Invoke-SSHCommand -SessionId $ssh.SessionId -Command $cmdNVMe -TimeOut 30

    # run the ssh command for mpx
    write-host -fore green `n`t "Clearing SAS/SATA"
    Invoke-SSHCommand -SessionId $ssh.SessionId -Command $cmdmpx -TimeOut 30
    Remove-SSHSession -SessionId $ssh.SessionId

    Write-Host -fore green `n`t "thank you, next"
}
