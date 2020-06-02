# Script to connect to vCenter servers, take snapshots and disconnect from vCenter server
# Written: Vijayarengan - 17-Jan-2012

#connect to both vCenter servers
connect-viserver pnioyvivcm01.ni.ad.newsint
connect-viserver pnipgvivcm01.ni.ad.newsint
connect-viserver newsroomvc5.ni.ad.newsint

# TAke snapshot for VMs specified below. patch name specified.
# test vms
#new-snapshot -vm dvlolxwininfra -Name Task#21945_Tarandeep_Kaur

# production vms 
# count 6

foreach($vm in(cat D:\vcadmin\scripts\vmwpcli\MS_Patch_Snapshots\list_create.txt))
{

new-snapshot -vm $vm -Name MSPatch_Snapshot
}
#get-snapshot -vm  $vm -Name SnapshotPatch_29012014 | remove-snapshot -confirm:$false
#new-snapshot -vm $vm -Name MSPatch_13thMarch2014
#new-snapshot -vm  TVWASAPDBSR1 -Name Task#25371_Amar
#new-snapshot -vm  TVWASAPASSR1 -Name Task#25371_Amar

# snippet to send email
#$smtpServer = "niexgateway01.ni.ad.newsint"
#$smtpServer = "postfix.ni.ad.newsint"
$smtpServer = "smtprelay1.ni.ad.newsint"
$MailFrom = "VMware_ScriptAdmin@newsint.co.uk"

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

$mailto = "iowindows@news.co.uk"
#$mailto = "amar.malik@newsint.co.uk,iounixteam@newsint.co.uk,IOWindows@newsint.co.uk,vijayarengan.ramachandran@newsint.co.uk"
$mailsubject = "Windows Patching VM Snapshot Created"
$mailcontent = "VMs specified had been taken a snapshot. Its good to go ahead with the change. "
SendNotificationMail $mailto $mailsubject $mailcontent


# disconnect both vCenter servers
disconnect-viserver -Server pnioyvivcm01.ni.ad.newsint -Force:$true -confirm:$false
disconnect-viserver -Server pnipgvivcm01.ni.ad.newsint -Force:$true -confirm:$false
disconnect-viserver -Server newsroomvc5.ni.ad.newsint -Force:$true -confirm:$false