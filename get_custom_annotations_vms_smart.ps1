# script to generate inventory with annotation details
# Written - Vijayarengan. R 12-Mar-2013

connect-viserver pnioyvivcm01.ni.ad.newsint
connect-viserver pnipgvivcm01.ni.ad.newsint


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

# get vm details from OY (production)
#foreach ($clusterinst in get-datacenter "oliver's yard" | get-cluster oy_unix_cluster)
foreach ($clusterinst in get-datacenter "oliver's yard" | get-cluster)
{
#foreach ($vminst in get-cluster $clusterinst | get-vm dmsweb)
foreach ($vminst in get-cluster $clusterinst | get-vm)
{

$row=""|select VM,Cluster,CHARGINGCATEGORY,HCLSUPPORTED,IOTRACK,GuestOS,ipaddress,APPBUSINESSUNIT,SERVICEOWNER,dnsname,vmhostname,NOTES,BACKUP,APPINFORMATION,DR


$vMAnnot=$vminst | get-annotation

$row.VM=$vminst.Name
$row.Cluster=$clusterinst.name
$row.CHARGINGCATEGORY=$vMAnnot[3].value
$row.HCLSUPPORTED=$vMAnnot[6].value
$row.IOTRACK=$vMAnnot[7].value
$row.GuestOS=$vminst.guest.osfullname
$row.ipaddress=$vminst.guest.ipaddress[0]
$row.APPBUSINESSUNIT=$vMAnnot[0].value
$row.SERVICEOWNER=$vMAnnot[9].value
$row.dnsname=$vminst.guest.hostname
$row.vmhostname=$vminst.host
$row.NOTES=$vminst.notes
$row.BACKUP=$vMAnnot[2].value
$row.APPINFORMATION=$vMAnnot[1].value
$row.DR=$vMAnnot[5].value

$report+=$row
}
}


# get vm details from PG (production)
#foreach ($clusterinst in get-datacenter "powergate" | get-cluster pg_unix_cluster)
foreach ($clusterinst in get-datacenter "powergate" | get-cluster)
{
#foreach ($vminst in get-cluster $clusterinst | get-vm pvlolxaddm03)
foreach ($vminst in get-cluster $clusterinst | get-vm)
{


$row=""|select VM,Cluster,CHARGINGCATEGORY,HCLSUPPORTED,IOTRACK,GuestOS,ipaddress,APPBUSINESSUNIT,SERVICEOWNER,dnsname,vmhostname,NOTES,BACKUP,APPINFORMATION,DR


$vMAnnot=$vminst | get-annotation

$row.VM=$vminst.Name
$row.Cluster=$clusterinst.name
$row.CHARGINGCATEGORY=$vMAnnot[3].value
$row.HCLSUPPORTED=$vMAnnot[6].value
$row.IOTRACK=$vMAnnot[7].value
$row.GuestOS=$vminst.guest.osfullname
$row.ipaddress=$vminst.guest.ipaddress[0]
$row.APPBUSINESSUNIT=$vMAnnot[0].value
$row.SERVICEOWNER=$vMAnnot[9].value
$row.dnsname=$vminst.guest.hostname
$row.vmhostname=$vminst.host
$row.NOTES=$vminst.notes
$row.BACKUP=$vMAnnot[2].value
$row.APPINFORMATION=$vMAnnot[1].value
$row.DR=$vMAnnot[5].value

$report+=$row
}
}


# get details for regional sites
#foreach ($vminst in get-datacenter "regional sites" | get-vm pvdumsads01 )
foreach ($vminst in get-datacenter "regional sites" | get-vm)
{


$row=""|select VM,Cluster,CHARGINGCATEGORY,HCLSUPPORTED,IOTRACK,GuestOS,ipaddress,APPBUSINESSUNIT,SERVICEOWNER,dnsname,vmhostname,NOTES,BACKUP,APPINFORMATION,DR

$vMAnnot=$vminst | get-annotation

$row.VM=$vminst.Name
$row.Cluster=$clusterinst.name
$row.CHARGINGCATEGORY=$vMAnnot[3].value
$row.HCLSUPPORTED=$vMAnnot[6].value
$row.IOTRACK=$vMAnnot[7].value
$row.GuestOS=$vminst.guest.osfullname
$row.ipaddress=$vminst.guest.ipaddress[0]
$row.APPBUSINESSUNIT=$vMAnnot[0].value
$row.SERVICEOWNER=$vMAnnot[9].value
$row.dnsname=$vminst.guest.hostname
$row.vmhostname=$vminst.host
$row.NOTES=$vminst.notes
$row.BACKUP=$vMAnnot[2].value
$row.APPINFORMATION=$vMAnnot[1].value
$row.DR=$vMAnnot[5].value

$report+=$row
}



$report|export-csv e:\vminventory\Prod_vm_Annotation_vi_smart.csv -NoTypeInformation
$myfile = "e:\vminventory\Prod_vm_Annotation_vi_smart.csv"

$mailattachment = new-object Net.Mail.Attachment($myfile)

$Mymailcontent=@()

$Mymailcontent = @"

Hi Team,

Inventory of Production VMs with annotation taken for $date and attached herewith. The same file VMs_Annotation_vi.csv file is available at e drive vminventory folder at dvlowininfra01 too.

This is an automated task and mail report and get in touch with IO Windows for any assistance.

"@


# send findings as email to required stakeholders.
#$mailto = "IOWindows@news.co.uk,vijayarengan.ramachandran@news.co.uk,jugal.maheshwari@news.co.uk"
$mailto = "vijayarengan.ramachandran@news.co.uk"
$mailsubject = "Production VMs Inventory With Annotations taken - $date"
$mailcontent = $MyMailContent
$mailattachment = new-object Net.Mail.Attachment($myfile)
SendNotificationMail $mailto $mailsubject $mailcontent $mailattachment

disconnect-viserver -Server pnioyvivcm01.ni.ad.newsint -Force:$true -confirm:$false
disconnect-viserver -Server pnipgvivcm01.ni.ad.newsint -Force:$true -confirm:$false
