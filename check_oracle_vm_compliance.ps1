# script to check if Oracle VMs sticks to its licensed ESXi hosts
# writes a log file and sends email notification with details
# Written by Vijayarengan.R Date: 24-Jul-2012

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
connect-viserver pnioyvivcm01.ni.ad.newsint
connect-viserver pnipgvivcm01.ni.ad.newsint
connect-viserver newsroomvc5.ni.ad.newsint

# get the array of licensed esxi hosts per cluster
$strOyUnixHosts = @("pnioyvesx051.ni.ad.newsint","pnioyvesx070.ni.ad.newsint","pnioyvesx053.ni.ad.newsint","pnioyvesx055.ni.ad.newsint","pnioyvesx057.ni.ad.newsint")
$strUnixvms = @("PNIWAORADMS01","PNIWAORACGW1","DNIWAORACOE01","DNIWAUXORA04","pvlolxbmca01","TNIWAORACOE01")
#done

$strOYDigitalHosts = @("pnioyvesx085.ni.ad.newsint","pnioyvesx084.ni.ad.newsint","pnioyvesx087.ni.ad.newsint")
$strOYDigitalvms = @("TTODRDB","SOLPRDDB","STOPRDDB","STOSTGDB")
#done


$strPGDigitalHosts = @("pnipgvesx184.ni.ad.newsint","pnipgvesx187.ni.ad.newsint","pnipgvesx186.ni.ad.newsint")
$strPGDigitalvms = @("TTOPRDDB","SOLDRDB","STODRDB","IAMPRDDB","TTOSTGDB")
#done

$strPGOtxtUatHosts = @("nrmpgvesx61.ni.ad.newsint","nrmpgvesx73.ni.ad.newsint","nrmpgvesx75.ni.ad.newsint")
$strPGOtxtUatvms = @("DVPGNRMOPDB1","UVPGNRMOPTXORA")

$strPGOtxtStgProdHosts = @("nrmpgvesx69.ni.ad.newsint")
$strPGOtxtStgProdvms=@("pvpgnrmoptxora","svpgnrmoptxora")

$strOYOtxtProdG6Hosts = @("nrmoyvesx14.ni.ad.newsint","nrmoyvesx21.ni.ad.newsint")
$strOYOtxtProdG6vms=@("pvoynrmoptxora","svoynrmoptxora")

$strOYDMZHosts = @("pnioyvesx071.ni.ad.newsint")
$strOYDMZvms = @("PNIWAINFORA01")



# get formatted date
$date = get-date -uformat "%d-%m-%y"
# define subject for mail, logs
$vmcheck = @"
Oracle VMs - ESXi Host Affinity - Compliance Check as on $date
========================================================

"@


#========= 1 ==========
$vmcheck = $vmcheck + @"

OY Unix Cluster


"@
foreach ($vminst in $strUnixvms)
{
$currHost = get-vm $vminst | get-vmhost
#echo $currhost.name
if ($strOyUnixHosts -match $currhost.name)
{
   #echo "VM $vminst is hosted on ESXi host $currhost.name - Validation passed"
$vmcheck = $vmcheck + @"
VM $vminst is hosted on ESXi host $currhost.name - Validation passed

"@

}
else
{
$vmcheck = $vmcheck + @"
VM $vminst is hosted on noncompliant ESXi server $currhost.name - Validation failed

"@

} 
}

#===================

#========= 2 ==========
$vmcheck = $vmcheck + @"

OY Digital Cluster


"@
foreach ($vminst in $strOYDigitalvms)
{
$currHost = get-vm $vminst | get-vmhost
#echo $currhost.name
if ($strOYDigitalHosts -match $currhost.name)
{
   #echo "VM $vminst is hosted on ESXi host $currhost.name - Validation passed"
$vmcheck = $vmcheck + @"
VM $vminst is hosted on ESX server $currhost.name - Validation passed

"@

}
else
{
$vmcheck = $vmcheck + @"
VM $vminst is hosted on noncompliant ESXi server $currhost.name - Validation failed

"@

} 
}

#===================

#========= 3 ==========
$vmcheck = $vmcheck + @"

PG Digital Cluster


"@
foreach ($vminst in $strPGDigitalvms)
{
$currHost = get-vm $vminst | get-vmhost
#echo $currhost.name
if ($strPGDigitalHosts -match $currhost.name)
{
   #echo "VM $vminst is hosted on ESXi host $currhost.name - Validation passed"
$vmcheck = $vmcheck + @"
VM $vminst is hosted on ESX server $currhost.name - Validation passed

"@

}
else
{
$vmcheck = $vmcheck + @"
VM $vminst is hosted on noncompliant ESXi server $currhost.name - Validation failed

"@

} 
}

#===================

#========= 4 ==========
$vmcheck = $vmcheck + @"

OY DMZ Cluster


"@
foreach ($vminst in $strOYDMZvms)
{
$currHost = get-vm $vminst | get-vmhost
#echo $currhost.name
if ($strOYDMZHosts -match $currhost.name)
{
   #echo "VM $vminst is hosted on ESXi host $currhost.name - Validation passed"
$vmcheck = $vmcheck + @"
VM $vminst is hosted on ESX server $currhost.name - Validation passed

"@

}
else
{
$vmcheck = $vmcheck + @"
VM $vminst is hosted on noncompliant ESXi server $currhost.name - Validation failed

"@

} 
}

#===================

#========= 5 ==========
$vmcheck = $vmcheck + @"

PG Opentext UAT Cluster


"@
foreach ($vminst in $strPGOtxtUatvms)
{
$currHost = get-vm $vminst | get-vmhost
#echo $currhost.name
if ($strPGOtxtUatHosts -match $currhost.name)
{
   #echo "VM $vminst is hosted on ESXi host $currhost.name - Validation passed"
$vmcheck = $vmcheck + @"
VM $vminst is hosted on ESX server $currhost.name - Validation passed

"@

}
else
{
$vmcheck = $vmcheck + @"
VM $vminst is hosted on noncompliant ESXi server $currhost.name - Validation failed

"@

} 
}

#===================

#========= 6 ==========
$vmcheck = $vmcheck + @"

PG Opentext UAT Cluster


"@
foreach ($vminst in $strPGOtxtStgProdvms)
{
$currHost = get-vm $vminst | get-vmhost
#echo $currhost.name
if ($strPGOtxtStgProdHosts -match $currhost.name)
{
   #echo "VM $vminst is hosted on ESXi host $currhost.name - Validation passed"
$vmcheck = $vmcheck + @"
VM $vminst is hosted on ESX server $currhost.name - Validation passed

"@

}
else
{
$vmcheck = $vmcheck + @"
VM $vminst is hosted on noncompliant ESXi server $currhost.name - Validation failed

"@

} 
}

#===================

#========= 7 ==========
$vmcheck = $vmcheck + @"

OY Open Text Prod Cluster


"@
foreach ($vminst in $strOYOtxtProdG6vms)
{
$currHost = get-vm $vminst | get-vmhost
#echo $currhost.name
if ($strOYOtxtProdG6Hosts -match $currhost.name)
{
   #echo "VM $vminst is hosted on ESXi host $currhost.name - Validation passed"
$vmcheck = $vmcheck + @"
VM $vminst is hosted on ESX server $currhost.name - Validation passed

"@

}
else
{
$vmcheck = $vmcheck + @"
VM $vminst is hosted on noncompliant ESXi server $currhost.name - Validation failed

"@

} 
}

#===================




$vmcheck = $vmcheck + @"


DCS Team,
Please raise an incident and assign it to IOWindows team & notify I&O Database, if there were any Oracle VMs with validation failed. 


This is an automated mail sent from a script. 
Please get in touch with IOWindows@newsint.co.uk for assistance, if required.

"@


write-host $MyReport
$vmcheck >> D:\\logs\Oracle_vms_license_check.txt


echo $vmcheck

# send findings as email to required stakeholders.
$mailto = "iovm@news.co.uk,iodatabase@news.co.uk, iodatacentreteam@news.co.uk, geoff.duff@news.co.uk,vijayarengan.ramachandran@news.co.uk"
#$mailto = "vijayarengan.ramachandran@news.co.uk"
$mailsubject = "Oracle VM Host Compliance check - $date"
$mailcontent = $vmcheck
SendNotificationMail $mailto $mailsubject $mailcontent

# disconnect both vCenter servers
disconnect-viserver -Server newsroomvc5.ni.ad.newsint -Force:$true -confirm:$false
disconnect-viserver -Server pnipgvivcm01.ni.ad.newsint -Force:$true -confirm:$false
disconnect-viserver -Server pnioyvivcm01.ni.ad.newsint -Force:$true -confirm:$false