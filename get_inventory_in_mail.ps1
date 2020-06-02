# script to get the count of virtual infra servers
# Vijayarengan - 12-Apr

connect-viserver pnioyvivcm01.ni.ad.newsint
connect-viserver pnipgvivcm01.ni.ad.newsint
connect-viserver newsroomvc5.ni.ad.newsint


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



$dcs=get-datacenter
$clusters=get-cluster
$ESXis=get-vmhost
$VMs=get-vm


$dccount=$dcs.count
$clustercount=$clusters.count
$ESXicount=$ESXis.count
$VMcount=$VMs.count

$Summary = @"

Virtual Infrastructure: Inventory Counts

Total No of Datacenter : $dccount
Total No of Cluster: $clustercount
Total No of ESXi host : $ESXicount
Total No of  VMs:$VMcount

"@

foreach ($dcinst in get-datacenter)
{

$dccluster=get-datacenter $dcinst | get-cluster
$dcesxi=get-datacenter $dcinst | get-vmhost
$dcvms=get-datacenter $dcinst | get-vm

$dcclustercount=$dccluster.count
$dcesxicount=$dcesxi.count
$dcvmscount=$dcvms.count
$dcname=$dcinst.name


$DCSummary += @"

Datacenter: $dcname
Total No of  Cluster: $dcclustercount
Total No of ESXi host:$dcesxicount
Total No of  VMs:$dcvmscount

"@

foreach ($clusterinst in get-datacenter $dcinst | get-cluster)
{

$clesxi=get-cluster $clusterinst | get-vmhost
$clvms=get-cluster $clusterinst | get-vm

$clesxicount=$clesxi.count
$clvmscount=$clvms.count
$clusterinstname=$clusterinst.name

$ClSummary += @"

Cluster: $clusterinstname
Total No of ESXi host:$clesxicount
Total No of  VMs:$clvmscount

"@


}

}

$reposummary = $summary + $dcsummary + $clsummary

# send findings as email to required stakeholders.
#$mailto = "IOWindows@newsint.co.uk"
$mailto = "vijayarengan.ramachandran@newsint.co.uk"
$mailsubject = "Virtual Infrastructure Inventory - $date"
$mailcontent = $reposummary
SendNotificationMail $mailto $mailsubject $mailcontent

disconnect-viserver -Server pnioyvivcm01.ni.ad.newsint -Force:$true -confirm:$false
disconnect-viserver -Server pnipgvivcm01.ni.ad.newsint -Force:$true -confirm:$false
disconnect-viserver -Server newsroomvc5.ni.ad.newsint -Force:$true -confirm:$false

