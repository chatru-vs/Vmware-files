# script to Health Check Newsroom vCenter server VM NEWSROOMVC5
# Written by Vijayarengan.R Date: 08-JUL-2013 

# script to get guest disk information for vm

#connect to both vCenter servers
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
$VMscountPermissible = 3

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

$strvms = @("NEWSROOMVC5")
#$strvms = @("PVOYMSNEWAY01")

# specify the name of the newsway vm server
$vmInst="NEWSROOMVC5"
#$vmInst="dvlowininfra01"

$MyReport = @"

NEWSROOM vCenter Server Health Check:

"@


foreach ($vmInst in $strvms)
{

# Get current Date time
$curDateTime = Get-Date

$NRMVC5_vm = get-vm $vmInst

$mailsubject = "NEWSROOM vCenter Server Health Check on $curDateTime"

$MyReport += @"

=======================================================================================


Server $NRMVC5_vm as on $curDateTime

"@



######################### Snapshot Check #################################################
$Snapshots = $NRMVC5_vm | get-snapshot 

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
$strres=$NRMVC5_vm| % { get-view $_.ID }
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
$vmhostinst=$NRMVC5_vm | get-vmhost
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
$Nwy_ds = $NRMVC5_vm | get-datastore
if($Nwy_ds.count -gt 1)
{
	$Nwy_ds = $NWY_ds[0]
}
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
$vDisks = $NRMVC5_vm.Guest.Disks
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

if($vDrive -eq "e:\")
{
if($vDiskFreePercentage -lt $DataDiskCriticalThreshold)
{
$MyReport += @"

E Drive: Freespace: $vDiskFreePercentage % : BAD
"@
write-host "E Drive: Freespace: $vDiskFreePercentage % : BAD"
}
else
{
write-host "E Drive: Freespace: $vDiskFreePercentage % : GOOD"
$MyReport += @"

E Drive: Freespace: $vDiskFreePercentage % : GOOD
"@
}
}

}

}
######################### Guest OS C Drive check #################################################

$MyReport = $MyReport + @"

=======================================================================================
















*******************THRESHOLDS*******************
Datastore Warning       : Not less than 200 GB Free space
Datastore Critical      : Not less than 100 GB Free space
Host Memory Utilization : Not more than 85 %
OS C Drive free space   : Not less than 20 %
DATA D Drive free space   : Not less than 30 %
DATA E Drive free space   : Not less than 30 %
No of VMs on Datastore  : Not more than 3


This is an automated mail sent from a script. 
Please get in touch with IOWindows@newsint.co.uk for assistance, if required.
---------------------------------------------------------------------------------------

"@

# send findings as email to required stakeholders.
#$mailto = "IOWindows@newsint.co.uk,iovm@news.co.uk,iodatacentreteam@newsint.co.uk,jugal.maheshwari@news.co.uk,vijayarengan.ramachandran@news.co.uk"
$mailto = "IOvm@news.co.uk,iodatacentreteam@news.co.uk,vijayarengan.ramachandran@news.co.uk"
$mailcontent = $MyReport
SendNotificationMail $mailto $mailsubject $mailcontent



# disconnect from the vCenter servers
disconnect-viserver -Server pnipgvivcm01.ni.ad.newsint -Force:$true -confirm:$false
