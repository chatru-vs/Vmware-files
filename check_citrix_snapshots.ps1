# script to check if snapshots exist for all vms at OY, PG virtual infrastructure
# writes a log file and sends email notification with snapshot details
# Written by Vijayarengan.R Date: 20-Mar-2013 

#connect to both vCenter servers
connect-viserver pnioyvivcm01.ni.ad.newsint
connect-viserver pnipgvivcm01.ni.ad.newsint

$SnapshotAge = 1
#$VM = get-vm dnipgwinlin
#$VM =get-folder Win_Infra | get-vm
$Date=get-date

# set smtp mail server
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



#$NI_Clusters = get-cluster pg_test_dev_cluster
$NI_Clusters = get-cluster Xen_Desktop_Cluster
$MyReport = @"

NI Virtual Infrastructure - Citrix Cluster: Snapshot older by 1 day Status 
"@

foreach ($cluster in $NI_Clusters)
{


$Snapshots = get-cluster $cluster | get-vm | get-snapshot | Where {$_.Created -lt (($Date).AddDays(-$SnapshotAge))} 
#write-host $snapshots.count
	If ($Snapshots) 
	{
	#write-host $cluster
$MyReport = $MyReport + @"


Cluster : $cluster

"@
	foreach ($snapshot in $snapshots)
	{
        $vmname = $snapshot.vm.name
        $snapshotname = $snapshot.name
        
	$MyReport = $MyReport + @"

VM: $vmname has snapshot with name: $snapshotname
"@	
	#write-host $MyReport
	}
        
$MyReport = $MyReport + @"

==============================================

"@
        }
}


$MyReport = $MyReport + @"

Note: Xen_Desktop_Cluster at OY,PG datacentre has snapshots due to mandatory requirements and check with I&O Citrix for further details.


This is an automated mail sent from a script. 
Please get in touch with IOWindows@newsint.co.uk for assistance, if required.

"@

write-host $MyReport
$MyReport > D:\\logs\snapshots\citrix_snapshot_Status.txt

# send findings as email to required stakeholders.
$mailto = "iovm@news.co.uk,iocitrix@news.co.uk,iodatacentreteam@news.co.uk,mike.allen-pugh@news.co.uk"
#$mailto = "sumit.chopra@newsint.co.uk"
#$mailto = "vijayarengan.ramachandran@newsint.co.uk"
$mailsubject = "NI Virtual Infrastructure - Citrix Cluster: Snapshot older by 1 day Status - $date"
$mailcontent = $MyReport
SendNotificationMail $mailto $mailsubject $mailcontent



disconnect-viserver -Server pnioyvivcm01.ni.ad.newsint -Force:$true -confirm:$false
disconnect-viserver -Server pnipgvivcm01.ni.ad.newsint -Force:$true -confirm:$false



