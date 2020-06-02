# script to check if VMs have cd connected at OY, PG virtual infrastructure
# sends email notification with vm details
# Written by Vijayarengan.R Date: 06-Nov-2012 

#connect to both vCenter servers
connect-viserver pnioyvivcm01.ni.ad.newsint
connect-viserver pnipgvivcm01.ni.ad.newsint

$smtpServer = "smtprelay1.ni.ad.newsint"
# set Senders mail id
$MailFrom = "VMware_ScriptAdmin@newsint.co.uk"


# function to send an email
Function SendNotificationMail ($Mailto, $Mailsubject, $mailcontent)
{
    $msg = new-object Net.Mail.MailMessage
    $smtp = new-object Net.Mail.SmtpClient($smtpServer)
    $msg.From = $MailFrom
    $msg.To.Add($Mailto)
    $msg.Subject = $Mailsubject
$MailText = @"
$mailcontent
"@ 
   $msg.Body = $MailText
    $smtp.Send($msg)
}



#$NI_Clusters = get-cluster pg_unix_cluster
$NI_Clusters = get-cluster

$MyReport = @"

NI Virtual Infrastructure: VMs with CDROM connected
"@

foreach ($clusterinst in $NI_Clusters)
{


	$MyReport = $MyReport + @"

Cluster: $clusterinst
"@	

$MyReport = $MyReport + @"

==============================================

"@

   

#$vms_cd = get-cluster $clusterinst | get-vm | where { $_ | get-cddrive | where { $_.ConnectionState.Connected -eq "true" -and $_.ISOPath -like "*.ISO*"} } | #select Name, @{Name="ISOPath";Expression={(Get-CDDrive $_).isopath }}

$vms_cd = get-cluster $clusterinst | get-vm | where { $_ | get-cddrive | where { $_.ConnectionState.Connected -eq "true" -and $_.ISOPath -like "*.ISO*"} } |select Name, @{Name="ISOPath";Expression={(Get-CDDrive $_).isopath }}

#write-host $snapshots.count
	#write-host $cluster

foreach($vms_cdinst in $vms_cd)
{
$vmname=$vms_cdinst.Name
$vmisopath=$vms_cdinst.ISOpath

$MyReport = $MyReport + @"

VM: $vmname has CD connected with an iso image with path $vmisopath
"@
}	

$MyReport = $MyReport + @"

==============================================

"@
}


$MyReport = $MyReport + @"

DCS Team,
Please raise an incident and assign it to IO teams if there were any VMs with CDROMS connected.
---------------------------------------------------------------------------------
This is an automated mail sent from a script. 
Please get in touch with IOWindows@newsint.co.uk for assistance, if required.

"@

write-host $MyReport
$MyReport > D:\\logs\snapshots\snapshot_Status.txt

# send findings as email to required stakeholders.
#$mailto = "IOWindows@newsint.co.uk,vijayarengan.ramachandran@newsint.co.uk,iodatacentreteam@newsint.co.uk,suresh.malampathi@newsint.co.uk,jugal.maheshwari@newsint.co.uk "
$mailto = "vijayarengan.ramachandran@newsint.co.uk"
$mailsubject = "NI Virtual Infrastructure: VMs with CD connected - $date"
$mailcontent = $MyReport
SendNotificationMail $mailto $mailsubject $mailcontent

disconnect-viserver -Server pnioyvivcm01.ni.ad.newsint -Force:$true -confirm:$false
disconnect-viserver -Server pnipgvivcm01.ni.ad.newsint -Force:$true -confirm:$false



