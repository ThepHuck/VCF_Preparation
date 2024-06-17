#requires -Modules posh-ssh 
$cloudBuilder = "192.168.1.100"
$CBuser = "admin"
$CBpassword = "VMware1!"
$CBpassword = ConvertTo-SecureString -String $CBpassword -AsPlainText -Force
$CBcreds = New-Object System.Management.Automation.PSCredential($CBuser,$CBpassword)
$rootPassword = "VMware1!"
$xlsxFile = "C:\VCF\vcf-ems-deployment-parameter.xlsx"
$jsonFile = "C:\VCF\"

$ssh = New-SSHSession -ComputerName $cloudBuilder -Credential $CBcreds -ConnectionTimeout 5 -AcceptKey
$stream = New-SSHShellStream -SSHSession $ssh
$stream.WriteLine("su -")
sleep 1
$stream.WriteLine($rootPassword)
sleep 1
$stream.WriteLine("rm -rf /opt/vmware/sddc-support/cloud_admin_tools/Resources/vcf-ems")
sleep 1
Set-SCPItem -ComputerName $cloudBuilder -Credential $CBcreds -AcceptKey -Force -Path $xlsxFile -Destination /home/admin -Verbose
sleep 1
$stream.WriteLine("/opt/vmware/sddc-support/sos --jsongenerator --jsongenerator-input /home/admin/vcf-ems-deployment-parameter-511.xlsx --jsongenerator-design vcf-ems")
sleep 10
$result = $stream.Read()
if ( $result -match "Successfully changed ownership of files and dir"){
    "vcf-ems.json created successfully"
}
$stream.WriteLine("mv /opt/vmware/sddc-support/cloud_admin_tools/Resources/vcf-ems/vcf-ems.json /home/admin/vcf-ems.json && chown admin:vcf /home/admin/vcf-ems.json")
sleep 1
$stream.WriteLine("ls /home/admin/")
sleep 1
$result = $stream.Read()
if ( $result -match "vcf-ems.json" ) {
"file ready to be pulled"
}
$stream.Close()
$stream.Dispose()
Remove-SSHSession -SSHSession $ssh | out-null

Get-SCPItem -ComputerName $cloudBuilder -Credential $CBcreds -AcceptKey -Force -Path "/home/admin/vcf-ems.json" -PathType File -Destination $jsonFile -Verbose
