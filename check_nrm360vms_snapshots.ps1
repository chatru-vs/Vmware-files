# script to check if snapshots exist for pre-press vms
# writes a log file and sends email notification with snapshot details
# Written by Vijayarengan.R Date: 19-Jan-2012

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

#connect to both vCenter servers
connect-viserver newsroomvc5.ni.ad.newsint

# give the list of VMs to check. values given in array format.
$strvms = @("dvoynrmmeth1","sivoynrmmeth1","sivoynrmmeth2","uvoynrmmethtim1","uvoynrmmethtim2","tvoynrmmethtim1","tvoynrmmethtim2","pnipgvmnwrm5","DVPGNWRMOTX1","DVPGNRMOPTX1","DVPGNRMOPTX2","DVPGNRMOPTX3")

#$strvms = @("dnipgwinlin","jeytest","PNIWASAMBA01","PNIWMAGKARMA")





# get formatted date
$date = get-date -uformat "%d-%m-%y"
# define subject for mail, logs
$snapresult = @"
VDR Backup for Newsroom VMs - Snapshot status - $date
========================================================
"@

# loop in through the VM array and check for snapshot
for ($index=0; $index -lt $strvms.count; $index++)
{
$snap_found = get-snapshot -vm $strvms[$index]

# Write none, if snapshot is not found
if ($snap_found.name.length -le 1)
{
$snap_found = "none"
}

$vm = $strvms[$index]
$snapresult = $snapresult + @"


Checked Snapshot for VM: $vm
Snapshot Found           : $snap_found

"@
# Write findings to console
write-host $snapresult
}

$snapresultemail = $snapresult + @"

------------------------------------------------------------------------------------------------------
This is an automated mail sent from a script. 
Please get in touch with IOWindows@newsint.co.uk for assistance, if required.

"@

# Write findings to console
#write-host $snapresult
# write findings to log 
#$snapresult >> D:\\logs\vdr_backups\VDR_NRM360VMs_snapshot_Status.txt

# send findings as email to required stakeholders.
$mailto = "vijayarengan.ramachandran@news.co.uk,iodatacentreteam@news.co.uk,IOvm@news.co.uk,iounixteam@news.co.uk,jas.naul@news.co.uk"
#$mailto = "vijayarengan.ramachandran@newsint.co.uk"
$mailsubject = "VDR Backup for Newsroom VMs - Snapshot status - $date"
$mailcontent = $snapresultemail
SendNotificationMail $mailto $mailsubject $mailcontent


# disconnect both vCenter servers
disconnect-viserver -Server newsroomvc5.ni.ad.newsint -Force:$true -confirm:$false
