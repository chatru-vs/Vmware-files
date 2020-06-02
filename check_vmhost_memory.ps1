# script to check if ESXi host memory utilization is high
# writes a log file and sends email notification with Datastore capacity details
# Written by Vijayarengan.R Date: 13-Jun-2012

# set smtp mail server
$smtpServer = "smtprelay1.ni.ad.newsint"
# set Senders mail id
$MailFrom = "VMware_ScriptAdmin@newsint.co.uk"


# Define Memory thresholds in Percentage
$MemWarThres=75
$MemCritThres=90


#get today's date
$Date=get-date


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

$MyReport = @"

NI Virtual Infrastructure: ESXi hosts with High Memory utilization - Report
"@



write-host "Oliver's yard - ESXi host memory utilization check"
$MyReport = $MyReport + @"


Datacentre : Oliver's yard

"@

foreach ($vmhostinst in get-datacenter "oliver's yard" | get-vmhost)
{
	#write-host $vmhostinst.memoryUsageMB
	#write-host $vmhostinst.memoryTotalMB
        $VM_Usage_Percentage= [math]::round($vmhostinst.memoryUsageMB / $vmhostinst.memoryTotalMB * 100	)
	#write-host $VM_Usage_Percentage

	if($VM_Usage_Percentage -gt $MemCritThres -and $vmhostinst.name -ne "pnioyvesx096.ni.ad.newsint")
        {
	    write-host "Critical !! $vmhostinst.name has a memory utilization of $VM_Usage_Percentage Percentage."
$MyReport = $MyReport + @"


Critical !! $vmhostinst has a memory utilization of $VM_Usage_Percentage Percentage.

"@
        }
# Remove comments if warning alerts needs to be checked.
#	elseif($VM_Usage_Percentage -gt $MemWarThres)
#        {
#            write-host "Warning  !! $vmhostinst.name has a memory utilization of $VM_Usage_Percentage Percentage."
#$MyReport = $MyReport + @"
#
#Warning  !! $vmhostinst has a memory utilization of $VM_Usage_Percentage Percentage.
#"@
#        }

        
}


write-host ""
write-host "===================================================================="
write-host ""
$MyReport = $MyReport + @"

==========================================================================

Datacentre : Powergate

"@
write-host "Powergate - ESXi host memory utilization check"
foreach ($vmhostinst in get-datacenter powergate | get-vmhost)
{
	#write-host $vmhostinst.memoryUsageMB
	#write-host $vmhostinst.memoryTotalMB
        $VM_Usage_Percentage= [math]::round($vmhostinst.memoryUsageMB / $vmhostinst.memoryTotalMB * 100	)
	#write-host $VM_Usage_Percentage

	if($VM_Usage_Percentage -gt $MemCritThres -and $vmhostinst.name -ne "PNIPGVESX212.ni.ad.newsint" -and $vmhostinst.name -ne "PNIPGVESX159.ni.ad.newsint" -and $vmhostinst.name -ne "PNIPGVESX208.ni.ad.newsint")
	{
	    write-host "Critical !! $vmhostinst.name has a memory utilization of $VM_Usage_Percentage Percentage."
$MyReport = $MyReport + @"


Critical !! $vmhostinst has a memory utilization of $VM_Usage_Percentage Percentage.

"@

	}
# Remove comments if warning alerts needs to be checked.
#	elseif($VM_Usage_Percentage -gt $MemWarThres)
#        {
#            write-host "Warning  !! $vmhostinst.name has a memory utilization of $VM_Usage_Percentage Percentage."
#$MyReport = $MyReport + @"
#
#Warning  !! $vmhostinst has a memory utilization of $VM_Usage_Percentage Percentage.
#"@
#        }

     
}
write-host "===================================================================="
write-host ""
$MyReport = $MyReport + @"

==========================================================================

"@

$MyReport = $MyReport + @"

DCS Team,
Please raise an incident and assign it to IOWindows team if there were any ESXi hosts with critical memory utilization alerts above.

"@

$MyReport = $MyReport + @"

EXCEPTIONS:

PNIOYVESX059
PNIPGVESX161

Note:
Memory Warning Threshold = 75%
Memory Critical Threshold   = 90%

---------------------------------------------------------------------------------

This is an automated mail sent from a script. 
Please get in touch with IOWindows@newsint.co.uk for assistance, if required.

"@


write-host $MyReport
$MyReport >> D:\\logs\ESXihost_memory\ESXihost_memory.txt

# send findings as email to required stakeholders.
$mailto = "IOvm@news.co.uk,vijayarengan.ramachandran@news.co.uk,iodatacentreteam@news.co.uk"
#$mailto = "vijayarengan.ramachandran@newsint.co.uk"
$mailsubject = "NI Virtual Infrastructure: ESXi hosts with High Memory utilization Report - $date"
$mailcontent = $MyReport
SendNotificationMail $mailto $mailsubject $mailcontent


# disconnect from vCenter servers
disconnect-viserver -Server pnioyvivcm01.ni.ad.newsint -Force:$true -confirm:$false
disconnect-viserver -Server pnipgvivcm01.ni.ad.newsint -Force:$true -confirm:$false
