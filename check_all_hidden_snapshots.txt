# script to check if snapshots exist for all vms at OY, PG virtual infrastructure
# writes a log file and sends email notification with snapshot details
# Written by Vijayarengan.R Date: 15-Feb-2012 

#connect to both vCenter servers
connect-viserver pnioyvivcm01.ni.ad.newsint
connect-viserver pnipgvivcm01.ni.ad.newsint

$SnapshotAge = 2
#$VM = get-vm dnipgwinlin
#$VM =get-folder Win_Infra | get-vm
$Date=get-date

# set smtp mail server
#$smtpServer = "niexgateway01.ni.ad.newsint"
#$smtpServer = "pvloexmbx01.ni.ad.newsint"
#$smtpServer = "postfix.ni.ad.newsint"
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
$NI_Clusters = get-cluster 
$MyReport = @"

NI Virtual Infrastructure: Snapshot older by 2 days Status 
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

$vms = get-vm
foreach ($vminst in $vms)
{
$diskstring=$vminst.Harddisks[0].filename
#write-host $hardisk[0].filename
#write-host $mystring
$snapdiskmatch=$vminst.Harddisks[0].filename -match "\w*-000\d*.vmdk"
if ($snapdiskmatch)
{
 #write-host "$vminst.name has snapdisk present. checking for visible snapshot"
 $snaps=get-snapshot -vm $vminst.name | measure-object
 #write-host $snaps.count
 if ($snaps.count -eq 0)
  {
	 write-host $vminst.name has hidden snapshot with disk file $diskstring
$MyReport = $MyReport + @"

$vminst.name has hidden snapshot with disk file $diskstring
==============================================

"@
  }
}
}




$MyReport = $MyReport + @"

DCS Team,
Please raise an incident and assign it to IOWindows team if there were any snapshots reported above.
---------------------------------------------------------------------------------
This is an automated mail sent from a script. 
Please get in touch with IOWindows@newsint.co.uk for assistance, if required.

"@

write-host $MyReport
$MyReport > D:\\logs\snapshots\hiddensnapshot_Status.txt

# send findings as email to required stakeholders.
#$mailto = "IOWindows@newsint.co.uk,vijayarengan.ramachandran@newsint.co.uk,iounixteam@newsint.co.uk,iodatacentreteam@newsint.co.uk"
$mailto = "vijayarengan.ramachandran@newsint.co.uk"
$mailsubject = "NI Virtual Infrastructure: Snapshot older by 2 days Status - $date"
$mailcontent = $MyReport
SendNotificationMail $mailto $mailsubject $mailcontent



disconnect-viserver -Server pnioyvivcm01.ni.ad.newsint -Force:$true -confirm:$false
disconnect-viserver -Server pnipgvivcm01.ni.ad.newsint -Force:$true -confirm:$false



