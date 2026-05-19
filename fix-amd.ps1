#requires -Modules posh-ssh 
$vmhosts = @("node1","node2","node3","node4")
$creds = Get-Credential
$cmd = "echo 'cpuid.brandstring = `"AMD EPYC Ryzen 9 7945HX`"' >> /etc/vmware/config"
foreach ($i in $vmhosts){
    write-host -fore green `n`t "Connecting to $i"   
    connect-viserver $i -credential $creds

    write-host -fore green `n`t "Setting AMD Ryzen Entropy on $i"   
    $esxcli = get-esxcli -v2
    $entropyArgs = $esxcli.system.settings.kernel.set.CreateArgs()
    $entropyArgs.setting = "entropySources"
    $entropyArgs.value = 1
    $esxcli.system.settings.kernel.set.Invoke($entropyArgs)

    write-host -fore green `n`t "Enabling & starting SSH"
    Get-VmHostService | Where-Object {$_.key -match "TSM-SSH"} | Set-VMHostService -Policy "on" -confirm:$false | Start-VMHostService -confirm:$false

    write-host -fore green `n`t "SSHing into the host to set cpuid.brandstring"
    $ssh = New-SSHSession -computername $i -credential $creds -Force -KeepAliveInterval 5 -Verbose -WarningAction SilentlyContinue
    Invoke-SSHCommand -SessionId $ssh.SessionId -Command $cmd -TimeOut 30
    Remove-SSHSession -SessionId $ssh.SessionId

    write-host -fore green `n`t "Rebooting $i"
    Restart-VMHost $i -Force -Confirm:$false -RunAsync

    write-host -fore green `n`t "Done, moving on"
    disconnect-viserver $i -confirm:$false
}
