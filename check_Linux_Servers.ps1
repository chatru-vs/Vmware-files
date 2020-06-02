# script to Health Check Linux critical servers
# Written by Vijayarengan.R Date: 15-Feb-2013 

# script to get guest disk information for vm

#connect to both vCenter servers
connect-viserver pnioyvivcm01.ni.ad.newsint
connect-viserver pnipgvivcm01.ni.ad.newsint

#$snapshotcheck = get-snapshot -vm $vmInst

# Define Datastorethresholds in GB
$CapThres=20
$FreeSpWarThres=200
$FreeSpCritThres=100

# Define Memory thresholds in Percentage
$MemCritThres=85

# Define Disk Thresholds in Percentage
$DiskCriticalThreshold = 20

# Define Data Disk Thresholds in Percentage
$DataDiskCriticalThreshold = 30

#Define No of vms permitted in NWY server's datastore
$VMscountPermissible = 4

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

$strvms = @("PNIOYNEWSKARMA","PNIWMAGKARMA","PVLOLXGEN","PVLOLXNWY")
#$strvms = @("PVLOLXGEN")
#$strvms = @("PNIOYNEWSKARMA")

# specify the name of the newsway vm server
$vmInst="PVOYMSNEWAY01"
#$vmInst="dvlowininfra01"

$MyReport = @"

Unix / Linux Critical Servers Health Check:

"@


foreach ($vmInst in $strvms)
{

# Get current Date time
$curDateTime = Get-Date

$NWY_vm = get-vm $vmInst

$mailsubject = "Unix / Linux Critical Servers Health Check on $curDateTime"

$MyReport += @"

=======================================================================================

Server $NWY_vm as on $curDateTime

"@

######################### Snapshot Check #################################################
$Snapshots = $NWY_vm | get-snapshot 

If ($Snapshots) 
{
 write-host "Snapshot Exists: Yes : BAD"
$MyReport += @"

Snapshot Exists: Yes : BAD
"@

}
else
{
	write-host "Snapshot Exists: No : GOOD"
$MyReport += @"

Snapshot Exists: No : GOOD
"@

}
######################### snapshot Check #################################################

######################### VM Tools Check #################################################
$strres=$NWY_vm| % { get-view $_.ID }
$vmToolsstatus = $strres.guest.toolsstatus

if($vmToolsstatus -eq "toolsok")
{
write-host "VMwareTools: $vmToolsstatus : GOOD"
$MyReport += @"

VMwareTools: $vmToolsstatus : GOOD
"@
}
else
{
write-host "VMwareTools: $vmToolsstatus : BAD"
$MyReport += @"

VMwareTools: $vmToolsstatus : BAD
"@
}
######################### VM Tools Check #################################################


######################### VM Host Memory Check #################################################
$vmhostinst=$NWY_vm | get-vmhost
$VM_Usage_Percentage= [math]::round($vmhostinst.memoryUsageMB / $vmhostinst.memoryTotalMB * 100	)

if($VM_Usage_Percentage -gt $MemCritThres)
        {
	    write-host "VM Host Memory Usage: $VM_Usage_Percentage : BAD"
$MyReport = $MyReport + @"


Critical !! VM Host Memory Usage: $VM_Usage_Percentage : BAD

"@
        }
	else
        {
            write-host "VM Host Memory Usage: $VM_Usage_Percentage % : GOOD"
$MyReport = $MyReport + @"

VM Host Memory Usage: $VM_Usage_Percentage % : GOOD
"@
        }

######################### VM Host Memory Check END #################################################



######################### Datastore Check #################################################
$Nwy_ds = $NWY_vm | get-datastore
$vDsCapGB = [math]::round(($Nwy_ds.CapacityMB/1024))
$vDsFreeSpaceGB = [math]::round(($Nwy_ds.FreeSpaceMB/1024))

        if($vDSFreespaceGB -lt $FreeSpCritThres)
        {
	    write-host "Datastore: Freespace:$vDSFreespaceGB GB: UGLY."
$MyReport += @"

Datastore: Datastore: Freespace:$vDSFreespaceGB GB: UGLY.
"@
        }
        elseif($vDSFreespaceGB -lt $FreeSpWarThres)
        {
	    write-host "Datastore: Freespace:$vDSFreespaceGB GB: BAD"
$MyReport += @"

Datastore: Datastore: Freespace:$vDSFreespaceGB GB: BAD.
"@
        }
        else
	{
	    write-host "Datastore: Freespace:$vDSFreespaceGB GB: GOOD"
$MyReport += @"

Datastore: Freespace:$vDSFreespaceGB GB: GOOD"
"@
        }
######################### Datastore Check #################################################

######################### No of VMs Check #################################################
$NwydsVMs = $Nwy_ds| get-vm
$Nwydsvmscount = $NwydsVMs.count

        if($Nwydsvmscount -le $VMscountPermissible)
        {
	    write-host "Number of VMs on Datastore:$NwydsVMscount : GOOD."
$MyReport += @"

Number of VMs on Datastore:$NwydsVMscount : GOOD.
"@
        }
        else
	{
	    write-host "Number of VMs on Datastore:$NwydsVMscount : BAD."
$MyReport += @"

Number of VMs on Datastore:$NwydsVMscount : BAD.
"@
        }
######################### No of VMs Check #################################################

######################### Guest OS C Drive check #################################################
$vDisks = $NWY_vm.Guest.Disks
foreach ($vDisk in $vDisks)
{
$vDrive = $vDisk.Path
$vDiskCap = [math]::Round(($vDisk.Capacity)/1024/1024/1024)
$vDiskFree = [math]::Round(($vDisk.FreeSpace)/1024/1024/1024)
$vDiskFreePercentage = [Math]::Round($vDiskFree/$vDiskCap * 100)


if($vDrive -eq "c:\")
{
if($vDiskFreePercentage -lt $DiskCriticalThreshold)
{
$MyReport += @"

C Drive: Freespace: $vDiskFreePercentage % : BAD
"@
write-host "C Drive: Freespace: $vDiskFreePercentage % : BAD"
}
else
{
write-host "C Drive: Freespace: $vDiskFreePercentage % : GOOD"
$MyReport += @"

C Drive: Freespace: $vDiskFreePercentage % : GOOD

"@
}
}

if($vDrive -eq "d:\")
{
if($vDiskFreePercentage -lt $DataDiskCriticalThreshold)
{
$MyReport += @"

D Drive: Freespace: $vDiskFreePercentage % : BAD
"@
write-host "D Drive: Freespace: $vDiskFreePercentage % : BAD"
}
else
{
write-host "D Drive: Freespace: $vDiskFreePercentage % : GOOD"
$MyReport += @"

D Drive: Freespace: $vDiskFreePercentage % : GOOD
"@
}
}


if($vDrive -eq "/")
{
if($vDiskFreePercentage -lt $DataDiskCriticalThreshold)
{
$MyReport += @"

/ Partition: Freespace: $vDiskFreePercentage % : BAD
"@
write-host "/ Partition: Freespace: $vDiskFreePercentage % : BAD"
}
else
{
write-host "/ Partition: Freespace: $vDiskFreePercentage % : GOOD"
$MyReport += @"

/ Partition: Freespace: $vDiskFreePercentage % : GOOD
"@
}
}

if($vDrive -eq "/data")
{
if($vDiskFreePercentage -lt $DataDiskCriticalThreshold)
{
$MyReport += @"

/data Partition: Freespace: $vDiskFreePercentage % : BAD
"@
write-host "/data Partition: Freespace: $vDiskFreePercentage % : BAD"
}
else
{
write-host "/data Partition: Freespace: $vDiskFreePercentage % : GOOD"
$MyReport += @"

/data Partition: Freespace: $vDiskFreePercentage % : GOOD
"@
}
}


if($vDrive -eq "/karma_live")
{
if($vDiskFreePercentage -lt $DataDiskCriticalThreshold)
{
$MyReport += @"

/karma_live Partition: Freespace: $vDiskFreePercentage % : BAD
"@
write-host "/karma_live Partition: Freespace: $vDiskFreePercentage % : BAD"
}
else
{
write-host "/karma_live Partition: Freespace: $vDiskFreePercentage % : GOOD"
$MyReport += @"

/karma_live Partition: Freespace: $vDiskFreePercentage % : GOOD
"@
}
}

if($vDrive -eq "/karma_archive_live")
{
if($vDiskFreePercentage -lt $DataDiskCriticalThreshold)
{
$MyReport += @"

/karma_archive_live Partition: Freespace: $vDiskFreePercentage % : BAD
"@
write-host "/karma_archive_live Partition: Freespace: $vDiskFreePercentage % : BAD"
}
else
{
write-host "/karma_archive_live Partition: Freespace: $vDiskFreePercentage % : GOOD"
$MyReport += @"

/karma_live Partition: Freespace: $vDiskFreePercentage % : GOOD
"@
}
}

if($vDrive -eq "/karma")
{
if($vDiskFreePercentage -lt $DataDiskCriticalThreshold)
{
$MyReport += @"

/karma Partition: Freespace: $vDiskFreePercentage % : BAD
"@
write-host "/karma Partition: Freespace: $vDiskFreePercentage % : BAD"
}
else
{
write-host "/karma Partition: Freespace: $vDiskFreePercentage % : GOOD"
$MyReport += @"

/karma Partition: Freespace: $vDiskFreePercentage % : GOOD
"@
}
}

if($vDrive -eq "/live")
{
if($vDiskFreePercentage -lt $DataDiskCriticalThreshold)
{
$MyReport += @"

/live Partition: Freespace: $vDiskFreePercentage % : BAD
"@
write-host "/live Partition: Freespace: $vDiskFreePercentage % : BAD"
}
else
{
write-host "/live Partition: Freespace: $vDiskFreePercentage % : GOOD"
$MyReport += @"

/live Partition: Freespace: $vDiskFreePercentage % : GOOD
"@
}
}



if($vDrive -eq "/softproofing")
{
if($vDiskFreePercentage -lt $DataDiskCriticalThreshold)
{
$MyReport += @"

/softproofing Partition: Freespace: $vDiskFreePercentage % : BAD
"@
write-host "/softproofing Partition: Freespace: $vDiskFreePercentage % : BAD"
}
else
{
write-host "/softproofing Partition: Freespace: $vDiskFreePercentage % : GOOD"
$MyReport += @"

/softproofing: Freespace: $vDiskFreePercentage % : GOOD
"@
}
}

if($vDrive -eq "/mag_karma_archive_live")
{
if($vDiskFreePercentage -lt $DataDiskCriticalThreshold)
{
$MyReport += @"

/mag_karma_archive_live Partition: Freespace: $vDiskFreePercentage % : BAD
"@
write-host "/mag_karma_archive_live Partition: Freespace: $vDiskFreePercentage % : BAD"
}
else
{
write-host "/mag_karma_archive_live Partition: Freespace: $vDiskFreePercentage % : GOOD"
$MyReport += @"

/mag_karma_archive_live: Freespace: $vDiskFreePercentage % : GOOD
"@
}
}


if($vDrive -eq "/karma")
{
if($vDiskFreePercentage -lt $DataDiskCriticalThreshold)
{
$MyReport += @"

/karma Partition: Freespace: $vDiskFreePercentage % : BAD
"@
write-host "/karma Partition: Freespace: $vDiskFreePercentage % : BAD"
}
else
{
write-host "/karma Partition: Freespace: $vDiskFreePercentage % : GOOD"
$MyReport += @"

/karma: Freespace: $vDiskFreePercentage % : GOOD
"@
}
}

if($vDrive -eq "/live")
{
if($vDiskFreePercentage -lt $DataDiskCriticalThreshold)
{
$MyReport += @"

/live Partition: Freespace: $vDiskFreePercentage % : BAD
"@
write-host "/live Partition: Freespace: $vDiskFreePercentage % : BAD"
}
else
{
write-host "/live Partition: Freespace: $vDiskFreePercentage % : GOOD"
$MyReport += @"

/live: Freespace: $vDiskFreePercentage % : GOOD
"@
}
}


if($vDrive -eq "/graphics")
{
if($vDiskFreePercentage -lt $DataDiskCriticalThreshold)
{
$MyReport += @"

/graphics Partition: Freespace: $vDiskFreePercentage % : BAD
"@
write-host "/graphics Partition: Freespace: $vDiskFreePercentage % : BAD"
}
else
{
write-host "/graphics Partition: Freespace: $vDiskFreePercentage % : GOOD"
$MyReport += @"

/graphics: Freespace: $vDiskFreePercentage % : GOOD
"@
}
}

if($vDrive -eq "/input")
{
if($vDiskFreePercentage -lt $DataDiskCriticalThreshold)
{
$MyReport += @"

/input Partition: Freespace: $vDiskFreePercentage % : BAD
"@
write-host "/input Partition: Freespace: $vDiskFreePercentage % : BAD"
}
else
{
write-host "/input Partition: Freespace: $vDiskFreePercentage % : GOOD"
$MyReport += @"

/input: Freespace: $vDiskFreePercentage % : GOOD
"@
}
}

if($vDrive -eq "/output")
{
if($vDiskFreePercentage -lt $DataDiskCriticalThreshold)
{
$MyReport += @"

/output Partition: Freespace: $vDiskFreePercentage % : BAD
"@
write-host "/output Partition: Freespace: $vDiskFreePercentage % : BAD"
}
else
{
write-host "/output Partition: Freespace: $vDiskFreePercentage % : GOOD"
$MyReport += @"

/output: Freespace: $vDiskFreePercentage % : GOOD
"@
}
}

if($vDrive -eq "/preopi")
{
if($vDiskFreePercentage -lt $DataDiskCriticalThreshold)
{
$MyReport += @"

/preopi Partition: Freespace: $vDiskFreePercentage % : BAD
"@
write-host "/preopi Partition: Freespace: $vDiskFreePercentage % : BAD"
}
else
{
write-host "/preopi Partition: Freespace: $vDiskFreePercentage % : GOOD"
$MyReport += @"

/preopi: Freespace: $vDiskFreePercentage % : GOOD
"@
}
}


}

}
######################### Guest OS C Drive check #################################################

$MyReport = $MyReport + @"

=======================================================================================

















Exception List:
Datastore check for PNIOYNEWSKARMA : VM is hosted on more than 1 datastores
Datastore check for PNIWMAGKARMA : VM is hosted on more than 1 datastores

*******************THRESHOLDS*******************
Datastore Warning       : Not less than 200 GB Free space
Datastore Critical      : Not less than 100 GB Free space
Host Memory Utilization : Not more than 85 %
partition free space    : Not less than 20 %
No of VMs on Datastore  : Not more than 4


This is an automated mail sent from a script. 
Please get in touch with IOWindows@newsint.co.uk for assistance, if required.
---------------------------------------------------------------------------------------

"@

# send findings as email to required stakeholders.
#$mailto = "IOWindows@newsint.co.uk,iodatacentreteam@newsint.co.uk,prodops@newsint.co.uk,capps@newsint.co.uk ,greg.McGarrick@newsint.co.uk,suresh.malampathi@newsint.co.uk,jugal.maheshwari@newsint.co.uk,lalit.sharma@newsint.co.uk,vijayarengan.ramachandran@newsint.co.uk"
#$mailto = "vijayarengan.ramachandran@newsint.co.uk"
$mailto = "iounixteam@news.co.uk,IOvm@news.co.uk,iodatacentreteam@news.co.uk"

$mailcontent = $MyReport
SendNotificationMail $mailto $mailsubject $mailcontent



# disconnect from the vCenter servers
disconnect-viserver -Server pnioyvivcm01.ni.ad.newsint -Force:$true -confirm:$false
disconnect-viserver -Server pnipgvivcm01.ni.ad.newsint -Force:$true -confirm:$false
