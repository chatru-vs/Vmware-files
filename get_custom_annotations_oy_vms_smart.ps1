# script to generate inventory with annotation details
# Written - Vijayarengan. R 20-Sep-2013

connect-viserver pnioyvivcm01.ni.ad.newsint
#connect-viserver pnipgvivcm01.ni.ad.newsint


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

$row=""|select Cluster,VM,CHARGINGCATEGORY,HCLSUPPORTED,IOTRACK,GuestOS,ipaddress,APPBUSINESSUNIT,SERVICEOWNER,dnsname,vmhostname,NOTES,BACKUP,APPINFORMATION,DR,Tier

$vMAnnot=$vminst | get-annotation

$row.VM=$vminst.Name
$row.Cluster=$clusterinst.name
$row.CHARGINGCATEGORY=($vMAnnot | where-object { $_.name -eq "Charging Category"}).value
$row.HCLSUPPORTED=($vMAnnot | where-object { $_.name -eq "HCLSUPPORTED"}).value
$row.IOTRACK=($vMAnnot | where-object { $_.name -eq "IOTrack"}).value
$row.GuestOS=$vminst.guest.osfullname
$row.ipaddress=$vminst.guest.ipaddress[0]
$row.APPBUSINESSUNIT=($vMAnnot | where-object { $_.name -eq "AppBusinessUnit"}).value
$row.SERVICEOWNER=($vMAnnot | where-object { $_.name -eq "ServiceOwner"}).value
$row.dnsname=$vminst.guest.hostname
$row.vmhostname=$vminst.host
$row.NOTES=$vminst.notes
$row.BACKUP=($vMAnnot | where-object { $_.name -eq "Backup"}).value
$row.APPINFORMATION=($vMAnnot | where-object { $_.name -eq "AppInformation"}).value
$row.DR=($vMAnnot | where-object { $_.name -eq "DR"}).value
$row.Tier=($vMAnnot | where-object { $_.name -eq "Tier"}).value

$report+=$row
}
}


# get details for regional sites
#foreach ($vminst in get-datacenter "regional sites" | get-vm pvdumsadr01 )
foreach ($clusterinst in get-datacenter "regional sites" | get-cluster)
#foreach ($clusterinst in get-datacenter "regional sites" | get-cluster DU_Infrastructure)
{
foreach ($vminst in get-cluster $clusterinst | get-vm)
#foreach ($vminst in get-cluster $clusterinst | get-vm pvdumsadr01)
{


$row=""|select Cluster,VM,CHARGINGCATEGORY,HCLSUPPORTED,IOTRACK,GuestOS,ipaddress,APPBUSINESSUNIT,SERVICEOWNER,dnsname,vmhostname,NOTES,BACKUP,APPINFORMATION,DR,Tier

$vMAnnot=$vminst | get-annotation

$row.VM=$vminst.Name
$row.Cluster=$clusterinst.name
$row.CHARGINGCATEGORY=($vMAnnot | where-object { $_.name -eq "Charging Category"}).value
$row.HCLSUPPORTED=($vMAnnot | where-object { $_.name -eq "HCLSUPPORTED"}).value
$row.IOTRACK=($vMAnnot | where-object { $_.name -eq "IOTrack"}).value
$row.GuestOS=$vminst.guest.osfullname
$row.ipaddress=$vminst.guest.ipaddress[0]
$row.APPBUSINESSUNIT=($vMAnnot | where-object { $_.name -eq "AppBusinessUnit"}).value
$row.SERVICEOWNER=($vMAnnot | where-object { $_.name -eq "ServiceOwner"}).value
$row.dnsname=$vminst.guest.hostname
$row.vmhostname=$vminst.host
$row.NOTES=$vminst.notes
$row.BACKUP=($vMAnnot | where-object { $_.name -eq "Backup"}).value
$row.APPINFORMATION=($vMAnnot | where-object { $_.name -eq "AppInformation"}).value
$row.DR=($vMAnnot | where-object { $_.name -eq "DR"}).value
$row.Tier=($vMAnnot | where-object { $_.name -eq "Tier"}).value

$report+=$row
}
}



$Date=get-date -uformat "%d-%m-%y"
$CSVFile="E:\vminventory\Prod_oy_vm_Annotations_vi_smart_"
$CSVFile += $Date
$CSVFile += ".csv"


$report|export-csv $CSVFile -NoTypeInformation
$myfile = "e:\vminventory\Prod_oy_vm_Annotation_vi_smart.csv"

$mailattachment = new-object Net.Mail.Attachment($CSVFile)

$Mymailcontent=@()

$Mymailcontent = @"

Hi Team,

Inventory of Production OY VMs with annotation taken for $date and attached herewith. The same file Prod_oy_vm_Annotation_vi_smart.csv file is available at e drive vminventory folder at dvlowininfra01 too.

This is an automated task sending the mail report and get in touch with IO Windows for any assistance.

"@


# send findings as email to required stakeholders.
#$mailto = "iovm@news.co.uk,vijayarengan.ramachandran@news.co.uk,jugal.maheshwari@news.co.uk,mark.duffin@news.co.uk,alan.lewey@news.co.uk,rajesh.nimbark@news.co.uk"
$mailto = "vijayarengan.ramachandran@news.co.uk"
$mailsubject = "Production OY VMs Inventory With Annotations taken - $date"
$mailcontent = $MyMailContent

SendNotificationMail $mailto $mailsubject $mailcontent $mailattachment

disconnect-viserver -Server pnioyvivcm01.ni.ad.newsint -Force:$true -confirm:$false
#disconnect-viserver -Server pnipgvivcm01.ni.ad.newsint -Force:$true -confirm:$false
