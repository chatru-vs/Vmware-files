# Script to connect to vCenter servers, take snapshots and disconnect from vCenter server
# Written: Vijayarengan - 17-Jan-2012

#connect to both vCenter servers
connect-viserver pnipgvivcm01.ni.ad.newsint

#new-snapshot -vm DNIWRIP01 -Name CR#13367
new-snapshot -vm DNIpgwinlin -Name oy_snap
#new-snapshot -vm pniwarip03 -Name CR#13655
#new-snapshot -vm pniwarip04 -Name CR#13655
#new-snapshot -vm pniwattsmb01 -Name CR#13655

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

$mailto = "sumit.chopra@newsint.co.uk"
#$mailto = "vijayarengan.ramachandran@newsint.co.uk"
$mailsubject = "PNIWARIP03,04 PNIWATTSMB01  - VM Snapshot taken successfully"
$mailcontent = "VM Snapshot taken successfully. Please advise IO windows team to delete the snapshots when the checks has been done"
SendNotificationMail $mailto $mailsubject $mailcontent


# disconnect both vCenter servers
#disconnect-viserver -Server pnioyvivcm01.ni.ad.newsint -Force:$true -confirm:$false
disconnect-viserver -Server pnipgvivcm01.ni.ad.newsint -Force:$true -confirm:$false