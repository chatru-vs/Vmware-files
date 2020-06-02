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


$report=@()

# get vm details from PG (newsroom + production)
foreach ($clusterinst in get-cluster)
{
foreach ($vminst in get-cluster $clusterinst | get-vm)
{


$row=""|select VM,Cluster,APPBUSINESSUNIT,APPINFORMATION,BACKUP,CHARGINGCATEGORY,CREATEDBY,DR,HCLSUPPORTED,IOTRACK,SERVICEOWNER,VMCREATEDON,NOTES


$vMAnnot=$vminst | get-annotation

$row.VM=$vminst.Name
$row.Cluster=$clusterinst.name
$row.APPBUSINESSUNIT=$vMAnnot[0].value
$row.APPINFORMATION=$vMAnnot[1].value
$row.BACKUP=$vMAnnot[2].value
$row.CHARGINGCATEGORY=$vMAnnot[3].value
$row.CREATEDBY=$vMAnnot[4].value
$row.DR=$vMAnnot[5].value
$row.HCLSUPPORTED=$vMAnnot[7].value
$row.IOTRACK=$vMAnnot[8].value
$row.SERVICEOWNER=$vMAnnot[11].value
$row.VMCREATEDON=$vMAnnot[12].value
$row.NOTES=$vminst.notes

$report+=$row
}
}


$report|export-csv e:\vminventory\VMs_Annotation_vi_newsroom.csv -NoTypeInformation


$Mymailcontent=@()

$Mymailcontent = @"

Hi Team,

Inventory of VMs with annotation taken for $date. Please secure the VMs_Annotation_vi_newsroom.csv file generated at e drive vminventory folder at dvlowininfra01, to google doc.

This is an automated task and mail report and get in touch with IO Windows for any assistance.

"@


# send findings as email to required stakeholders.
$mailto = "IOWindows@news.co.uk,vijayarengan.ramachandran@news.co.uk,jugal.maheshwari@news.co.uk"
#$mailto = "vijayarengan.ramachandran@news.co.uk"
$mailsubject = "Newsroom VM Inventory With Annotations taken - $date"
$mailcontent = $MyMailContent
SendNotificationMail $mailto $mailsubject $mailcontent

disconnect-viserver -Server newsroomvc5.ni.ad.newsint -Force:$true -confirm:$false
