# script to generate inventory with annotation details
# Written - Vijayarengan. R 13-sep-2013

connect-viserver newsroomvc5.ni.ad.newsint


$Date=get-date

# set smtp mail server
$smtpServer = "smtprelay1.ni.ad.newsint"
# set Senders mail id
$MailFrom = "VMware_ScriptAdmin@newsint.co.uk"

$vminst=$args[0]


# function to send an email
Function SendNotificationMail ($Mailto, $Mailsubject, $mailcontent, $mailattachment)
{
    $msg = new-object Net.Mail.MailMessage
    $smtp = new-object Net.Mail.SmtpClient($smtpServer)
    $msg.From = $MailFrom
    $msg.To.Add($Mailto)
    $msg.Subject = $Mailsubject
    $msg.Attachments.Add($mailattachment)
$MailText = @"
$mailcontent
"@ 
   $msg.Body = $MailText
    $smtp.Send($msg)
}


$report=@()

# get vm details from PG (newsroom + production)
#foreach ($clusterinst in get-cluster oy_eidos_production)
foreach ($clusterinst in get-cluster)
{
#foreach ($vminst in get-cluster $clusterinst | get-vm PNIOYNRMSTICCI)
foreach ($vminst in get-cluster $clusterinst | get-vm)
{

$row=""|select Cluster,VM,CHARGINGCATEGORY,HCLSUPPORTED,IOTRACK,GuestOS,ipaddress,APPBUSINESSUNIT,APPINFO,SERVICEOWNER,dnsname,vmhostname,NOTES,BACKUP,APPINFORMATION,DR,Environment,Tier


$vMAnnot=$vminst | get-annotation

$row.VM=$vminst.Name
$row.Cluster=$clusterinst.name
$row.CHARGINGCATEGORY=$vMAnnot[3].value
$row.HCLSUPPORTED=$vMAnnot[7].value
$row.IOTRACK=$vMAnnot[8].value
$row.GuestOS=$vminst.guest.osfullname
$row.ipaddress=$vminst.guest.ipaddress[0]
$row.APPBUSINESSUNIT=$vMAnnot[0].value
$row.APPINFO=($vMAnnot | where-object { $_.name -eq "AppInformation"}).value
$row.SERVICEOWNER=($vMAnnot | where-object { $_.name -eq "ServiceOwner"}).value
$row.dnsname=$vminst.guest.hostname
$row.vmhostname=$vminst.host
$row.NOTES=$vminst.notes
$row.BACKUP=$vMAnnot[2].value
$row.APPINFORMATION=$vMAnnot[1].value
$row.DR=$vMAnnot[5].value
$row.Environment=($vMAnnot | where-object { $_.name -eq "Environment"}).value
$row.Tier=($vMAnnot | where-object { $_.name -eq "Tier"}).value

$report+=$row
}
}

$Date=get-date -uformat "%d-%m-%y"
$CSVFile="E:\vminventory\NRM_vms_Annotationss_vi_smart_"
$CSVFile += $Date
$CSVFile += ".csv"

write-host $csvfile

$report|export-csv $CSVFile -NoTypeInformation
$myfile = $CSVFile

$Mymailcontent=@()

$Mymailcontent = @"

Hi Team,

Inventory of VMs with annotation taken for $date. Please secure the VMs_Annotations_vi_newsroom.csv file generated at e drive vminventory folder at dvlowininfra01, to google doc.

This is an automated task and mail report and get in touch with IO Windows for any assistance.

"@


# send findings as email to required stakeholders.
$mailto = "iovm@news.co.uk,vijayarengan.ramachandran@news.co.uk,jugal.maheshwari@news.co.uk,mark.duffin@news.co.uk,alan.lewey@news.co.uk,rajesh.nimbark@news.co.uk"
#$mailto = "vijayarengan.ramachandran@news.co.uk"
$mailsubject = "Newsroom VM Inventory With Annotations taken - $date"
$mailcontent = $MyMailContent
$mailattachment = new-object Net.Mail.Attachment($myfile)
SendNotificationMail $mailto $mailsubject $mailcontent $mailattachment

disconnect-viserver -Server newsroomvc5.ni.ad.newsint -Force:$true -confirm:$false
