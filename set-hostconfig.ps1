#requires -Modules posh-ssh 
$vmhosts = @("node1","node2","node3","node4")
$ntp = "pool.ntp.org"
$dns1 = "8.8.8.8"
$dns2 = "8.8.4.4"
$dnsSearch = "home.lab"
$cmd = "/sbin/generate-certificates && reboot"
$user = "root"
$password = "notMyP@ssw0rd!"
$password = ConvertTo-SecureString -String $password -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential($user,$password)

foreach ($i in $vmhosts){
    write-host -fore green `n`t "Connecting to $i"   
    connect-viserver $i -credential $creds

    write-host -fore green `n`t "Setting hostname $i"   
    $esxcli = get-esxcli -v2
    $hostnameArgs = $esxcli.system.hostname.set.CreateArgs()
    $hostnameArgs.fqdn = $i
    $esxcli.system.hostname.set.Invoke($hostnameArgs)

    write-host -fore green `n`t "Setting network config"
    $vmhostnetwork = get-vmhostnetwork
    set-vmhostnetwork -network $vmhostnetwork -dnsaddress $dns1,$dns2 -DomainName $dnsSearch -searchdomain $dnsSearch -dnsfromdhcp $false

    write-host -fore green `n`t "Setting NTP"
    add-vmhostntpserver -ntpserver $ntp

    write-host -fore green `n`t "Enabling & starting SSH"
    Get-VmHostService | Where-Object {$_.key -match "TSM-SSH"} | Set-VMHostService -Policy "on" -confirm:$false | Start-VMHostService -confirm:$false

    write-host -fore green `n`t "Enabling & starting NTP"
    Get-VmHostService | Where-Object {$_.key -match "ntpd"} | Set-VMHostService -Policy "on" -confirm:$false | Start-VMHostService -confirm:$false

    write-host -fore green `n`t "SSHing into the host to regenerate certificates & reboot"
    Get-SSHTrustedHost | ? {$_.HostName -match $vmhosts[0]} | Remove-SSHTrustedHost
    $ssh = New-SSHSession -computername $i -credential $creds -AcceptKey -KeepAliveInterval 5 -Verbose
    Invoke-SSHCommand -SessionId $ssh.SessionId -Command $cmd -TimeOut 30
    Remove-SSHSession -SessionId $ssh.SessionId

    write-host -fore green `n`t "Done, moving on"
    disconnect-viserver $i -confirm:$false
}
