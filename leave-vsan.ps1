$vmhosts = @("node1","node2","node3","node4")
$user = "root"
$password = "notMyP@ssw0rd!"
$password = ConvertTo-SecureString -String $password -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential($user,$password)

foreach ($i in $vmhosts){

    write-host -fore green `n`t "Connecting to $i"
    connect-viserver $i -credential $creds

    write-host -fore green `n`t "Stopping all VMs"
    get-vm | stop-vm -kill -confirm:$false -ErrorAction SilentlyContinue  | remove-vm -confirm:$false -ErrorAction SilentlyContinue

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
