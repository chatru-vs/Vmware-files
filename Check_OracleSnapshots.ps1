# script to check if snapshots exist for all vms at Newsroom virtual infrastructure
# writes a log file and sends email notification with snapshot details
# Written by Vijayarengan.R Date: 15-Feb-2012 

#connect to both vCenter servers
connect-viserver pvlomsoravcm01.ni.ad.newsint,pvlomsoravcm02.ni.ad.newsint

$SnapshotAge = 1
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

Oracle Virtual Infrastructure: Snapshot older by 1 days Status 
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

DCS Team,
Please raise an incident and assign it to IOWindows team if there were any snapshots reported above.
---------------------------------------------------------------------------------

This is an automated mail sent from a script. 
Please get in touch with IOvm@news.co.uk for assistance, if required.

"@

write-host $MyReport
$MyReport > D:\\logs\snapshots\snapshot_Status_Oracle.txt

# send findings as email to required stakeholders.
$mailto = "IOvm@news.co.uk,iodatacentreteam@news.co.uk,iounixteam@news.co.uk"
#$mailto = "sumit.chopra@news.co.uk"
$mailsubject = "Oracle Virtual Infrastructure: Snapshot older by 1 days Status - $date"
$mailcontent = $MyReport
SendNotificationMail $mailto $mailsubject $mailcontent



disconnect-viserver -Server pvlomsoravcm01.ni.ad.newsint,pvlomsoravcm02.ni.ad.newsint -Force:$true -confirm:$false




