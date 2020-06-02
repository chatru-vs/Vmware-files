# Powercli script to check annotations of VM instances
# Author - Vijayarengan R
# Date - 13-Apr-2014

# Send Mail Flag
$SendMailFlag=0

# Define the Array
$VMInventory=@()

$Date=get-date

# Get vM Annotations
connect-viserver pnioyvivcm01.ni.ad.newsint

# set smtp mail server
$smtpServer = "smtprelay1.ni.ad.newsint"
# set Senders mail id
$MailFrom = "IOVM_Tools@news.co.uk"

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

# function to check if its an valid email
Function CheckInvalidMailAddress ($Mailaddress)
{
#$mymail="vijay.rengan@newsint.com"

$Val1=$Mailaddress.EndsWith("news.co.uk")
$Val2=$Mailaddress.EndsWith("newsint.co.uk")
$Val3=$Mailaddress.EndsWith("thetimes.co.uk")
$Val4=$Mailaddress.EndsWith("thesun.co.uk")

if ($val1 -or $val2 -or $val3 -or $val4)
{
#write-host "Valid EMail address"
return $false
}
else
{
return $true
}

}

$MyReport = @"

=======================================================================================
NewsUK Virtual Infrastructure - VM Annotation Checks
=======================================================================================

"@


# Iterate throug all VM Instance and get all required values appended to the defined array
# get vm details from PG (newsroom + production)
#foreach ($clusterinst in get-cluster oy_security_cluster)
foreach ($clusterinst in get-cluster)
{
#foreach ($vminst in get-cluster $clusterinst | get-vm STGVOYNRMMETHSUNGC)
foreach ($vminst in get-cluster $clusterinst | get-vm)
{

$row=""|select Cluster,VM,CHARGINGCATEGORY,HCLSUPPORTED,IOTRACK,GuestOS,ipaddress,APPBUSINESSUNIT,APPINFO,SERVICEOWNER,dnsname,vmhostname,NOTES,BACKUP,APPINFORMATION,DR,Environment,Tier



$vMAnnot=$vminst | get-annotation


$VMName=$vminst.Name
$VMCluster=$clusterinst.name
$VMCHARGINGCATEGORY=$vMAnnot[3].value
$VMHCLSUPPORTED=$vMAnnot[7].value
$VMIOTRACK=$vMAnnot[8].value
$VMGuestOS=$vminst.guest.osfullname
$VMipaddress=$vminst.guest.ipaddress[0]
$VMAPPBUSINESSUNIT=$vMAnnot[0].value
$VMAPPINFO=($vMAnnot | where-object { $_.name -eq "AppInformation"}).value
$VMSERVICEOWNER=($vMAnnot | where-object { $_.name -eq "ServiceOwner"}).value
$VMdnsname=$vminst.guest.hostname
$VMvmhostname=$vminst.host
$VMNOTES=$vminst.notes
$VMBACKUP=$vMAnnot[2].value
$VMAPPINFORMATION=$vMAnnot[1].value
$VMDR=$vMAnnot[5].value
$VMEnvironment=($vMAnnot | where-object { $_.name -eq "Environment"}).value
$VMTier=($vMAnnot | where-object { $_.name -eq "Tier"}).value


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



#call function to validate incorrect email address. returns true if its not a valid mail address
#$serviceOwnerValidation=CheckInvalidMailAddress($TagServiceOwner.value)


$VMInventory+=$row


$VMAnnotated=1
$VMAnnotReport=""

If([System.String]::IsNullOrEmpty($VMSERVICEOWNER))
{
$VMAnnotated=0
$VMAnnotReport+="Service Owner`n"
}

If([System.String]::IsNullOrEmpty($VMAPPBUSINESSUNIT))
{
$VMAnnotated=0
$VMAnnotReport+="APP BUSINESSUNIT`n"
}

if([System.String]::IsNullOrEmpty($VMCHARGINGCATEGORY))
{
$VMAnnotated=0
$VMAnnotReport+= "CHARGING CATEGORY`n"
}

#if([System.String]::IsNullOrEmpty($TagServiceOwner) -or $serviceOwnerValidation)
#{
#$VMAnnotated=0
#$VMAnnotReport+= "TagServiceOwner: $EC2ServiceOwner `n"
#}

<#
if([System.String]::IsNullOrEmpty($VMDR))
{
$VMAnnotated=0
$VMAnnotReport+= "DR`n"
}
#>

if([System.String]::IsNullOrEmpty($VMHCLSUPPORTED))
{
$VMAnnotated=0
$VMAnnotReport+= "HCL Supported`n"
}

<#
if([System.String]::IsNullOrEmpty($VMTier))
{
$VMAnnotated=0
$VMAnnotReport+= "Tier`n"
}
#>



if ($VMAnnotated -eq 0)
{

# Set send mail flag to true
$SendMailFlag=1

write-host VM $vminst has following Annotations Missing or specified incorrectly
write-host $VMAnnotReport

$MyReport += @"

VM $vminst has following Annotations Missing or specified incorrectly

$VMAnnotReport
"@



}

}
}

$MyReport = $MyReport + @"

=======================================================================================

Exception List:


This is an automated mail sent from a script. 
Please get in touch with IOvmteam@news.co.uk for assistance, clarification if required.
=======================================================================================

"@

if ($SendMailFlag)
{

# send findings as email to required stakeholders.
#$mailto = "vijayarengan.ramachandran@news.co.uk"
$mailto = "IOvmteam@news.co.uk,vijayarengan.ramachandran@news.co.uk"
#$mailto = "IOvmteam@news.co.uk,iodatacentreteam@news.co.uk"
#$mailto = "IOvmteam@news.co.uk,iodatacentreteam@news.co.uk,vijayarengan.ramachandran@news.co.uk,michael.holtby@news.co.uk,mike.wedderburn-clarke@news.co.uk,dominic.courtney@news.co.uk,danny.tedora@news.co.uk"

$mailsubject = "News UK Virtual Infrastructure - vCenter: OY - Annotations Check - $date"
$mailcontent = $MyReport
SendNotificationMail $mailto $mailsubject $mailcontent 

}

# Export the values pulled to a CSV file
$VMInventory | export-csv oy_vm_Annotation_Inv.csv -NoTypeInformation

disconnect-viserver pnioyvivcm01.ni.ad.newsint -force:$true -confirm:$false
