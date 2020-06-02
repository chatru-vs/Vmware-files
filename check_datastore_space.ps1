# script to check if Free disk space of datastores and report by mail
# writes a log file and sends email notification with Datastore capacity details
# Written by Vijayarengan.R Date: 13-Jun-2012

# set smtp mail server
$smtpServer = "smtprelay1.ni.ad.newsint"
# set Senders mail id
$MailFrom = "VMware_ScriptAdmin@newsint.co.uk"


# Define thresholds in GB
$CapThres=20
$FreeSpWarThres=30
$FreeSpCritThres=20

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

NI Virtual Infrastructure: Datastores Free space less than $FreeSpWarThres GB Report
"@



write-host "Oliver's yard - Datastore check"
$MyReport = $MyReport + @"


Datacentre : Oliver's yard

"@

foreach($dsinst in get-datacenter "oliver's yard" | get-datastore)
{
	$vDsCapGB = [math]::round(($dsinst.CapacityMB/1024))
	$vDsFreeSpaceGB = [math]::round(($dsinst.FreeSpaceMB/1024))
	#write-host $vDsCapGB
	#write-host $vDsFreeSpaceGB
        if($vDsCapGB -gt $CapThres -and $vDSFreespaceGB -lt $FreeSpCritThres)
        {
	    write-host "Critical !! $dsinst has got only $vDSFreespaceGB GB available space."

$MyReport = $MyReport + @"


Critical !! $dsinst has got only $vDSFreespaceGB GB available space.
"@

        }
#	elseif($vDsCapGB -gt $CapThres -and $vDSFreespaceGB -lt $FreeSpWarThres)
#        {
#            write-host "Warning  !  $dsinst has got only $vDSFreespaceGB GB available space."
#$MyReport = $MyReport + @"
#
#Warning  !  $dsinst has got only $vDSFreespaceGB GB available space.
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
write-host "Powergate - Datastore check"
foreach($dsinst in get-datacenter powergate | get-datastore)
{
	$vDsCapGB = [math]::round(($dsinst.CapacityMB/1024))
	$vDsFreeSpaceGB = [math]::round(($dsinst.FreeSpaceMB/1024))
	#write-host $vDsCapGB
	#write-host $vDsFreeSpaceGB
        if($vDsCapGB -gt $CapThres -and $vDSFreespaceGB -lt $FreeSpCritThres)
        {
	    write-host "Critical !! $dsinst has got only $vDSFreespaceGB GB available space."

$MyReport = $MyReport + @"


Critical !! $dsinst has got only $vDSFreespaceGB GB available space.
"@

        }
#	elseif($vDsCapGB -gt $CapThres -and $vDSFreespaceGB -lt $FreeSpWarThres)
#        {
#            write-host "Warning  !  $dsinst has got only $vDSFreespaceGB GB available space."
#$MyReport = $MyReport + @"
#
#Warning  !  $dsinst has got only $vDSFreespaceGB GB available space.
#"@
#        }

}
write-host "===================================================================="
write-host ""
$MyReport = $MyReport + @"

==========================================================================

"@

$MyReport = $MyReport + @"

Exemption List:

OY-VSP1-00-C0-13 is replicated passive LUN and can be ingored.
OY-VSP1-00-C0-17 is replicated passive LUN and can be ingored.
OY-VSP1-00-C0-A1 is replicated passive LUN and can be ingored.
OY-VSP1-00-C0-A0 is replicated passive LUN and can be ingored.
PG-VSP1-00-C6-XX datastores are part of investigation cluster and no further actions required.



DCS Team,
Please raise an incident and assign it to IOWindows team if there were any critical datastores alerts above.

"@

$MyReport = $MyReport + @"

Note:
xx-VSP1-00-B2-XX => Dashboard_Cluster
xx-VSP1-00-DA-XX => Digital/Milround_Cluster
xx-VSP1-00-BA-XX => DMZ_Cluster
xx-VSP1-00-C0-XX => Workplace/File_Print_Cluster
xx-VSP1-00-CA-XX => SAP_Cluster
xx-VSP1-00-B0-XX => Unix_Cluster
xx-VSP1-00-A0-XX => Windows/No-DR_Cluster
xx-VSP1-00-C3-XX => XenDesktop_Cluster
xx-VSP1-00-C6-XX => Investigation_Cluster
xx-VSP1-00-A2-XX => Test_Dev_Cluster


Warning Threshold : 30 GB.
Critical Threshold: 20 GB.

---------------------------------------------------------------------------------
This is an automated mail sent from a script. 
Please get in touch with IOWindows@newsint.co.uk for assistance, if required.

"@


write-host $MyReport
$MyReport >> D:\\logs\datastore_capacity\snapshot_Status.txt

# send findings as email to required stakeholders.
$mailto = "iovm@news.co.uk,vijayarengan.ramachandran@news.co.uk,iodatacentreteam@news.co.uk"
#$mailto = "vijayarengan.ramachandran@newsint.co.uk"
$mailsubject = "NI Virtual Infrastructure: Datastores Free Space less than $FreeSpWarThres GB Report - $date"
$mailcontent = $MyReport
SendNotificationMail $mailto $mailsubject $mailcontent


# disconnect from vCenter servers
disconnect-viserver -Server pnioyvivcm01.ni.ad.newsint -Force:$true -confirm:$false
disconnect-viserver -Server pnipgvivcm01.ni.ad.newsint -Force:$true -confirm:$false
