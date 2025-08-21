$vmhosts = @("node1","node2","node3","node4")
$user = "root"
$password = "notMyP@ssw0rd!"
$password = ConvertTo-SecureString -String $password -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential($user,$password)

Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Confirm:$false

foreach ($i in $vmhosts){
    write-host -fore green `n`t "Connecting to $i"
    connect-viserver $i -credential $creds
}

write-host -fore green `n`t "Killing all VMs"
get-vm | select Name
get-vm | stop-vm -confirm:$false -ErrorAction SilentlyContinue -RunAsync
get-vm remove-vm -DeletePermanently -confirm:$false -ErrorAction SilentlyContinue -RunAsync
disconnect-viserver * -confirm:$false

foreach ($i in $vmhosts){
    write-host -fore green `n`t "Connecting to $i"
    connect-viserver $i -credential $creds
    write-host -fore green `n`t "Leaving vSAN cluster and deleting vSAN disk groups"
    $esxcli = get-esxcli -v2
    $esxcli.vsan.cluster.leave.Invoke()
    $vsanDG = $esxcli.vsan.storage.list.Invoke()
    $vsanDGArgs = $esxcli.vsan.storage.remove.CreateArgs()
    foreach ($UUID in $vsanDG.VSANDiskGroupUUID){
        $vsanDGArgs.uuid = $UUID
        $esxcli.vsan.storage.remove.Invoke($vsanDGArgs)
    }

  write-host -fore green `n`t "Done, moving on"
  disconnect-viserver $i -confirm:$false
}
