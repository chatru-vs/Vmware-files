# script to Health Check Linux critical servers
# Written by Vijayarengan.R Date: 29-Nov-2013 

# script to get guest disk information for vm

#connect to both vCenter servers
connect-viserver pnioyvivcm01.ni.ad.newsint
connect-viserver pnipgvivcm01.ni.ad.newsint

#$snapshotcheck = get-snapshot -vm $vmInst

# Define Datastorethresholds in GB
$CapThres=20
$FreeSpWarThres=120
$FreeSpCritThres=100

# Define Memory thresholds in Percentage
$MemCritThres=85

# Define Disk Thresholds in Percentage
$DiskCriticalThreshold = 20

# Define Data Disk Thresholds in Percentage
$DataDiskCriticalThreshold = 5
$DataDiskMajorThreshold=15
$DataDiskWarningThreshold=25

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



#$strvms = @("PVLOMSEFT01","PVOYMSGENVDP01","PVPGMSGENVDP01","UVOYMSGENVDP01","UVLOMSGENVDP01","UVLOMSGENVDP02","PVBXMSGENVDP01","PVBXMSGENVDP02","PVKNMSGENVDP01","PVKNMSGENVDP02","PVEUMSGENVDP01","PVEUMSGENVDP02","PVKNMSGENVDP01","PVKNMSGENVDP02","PVBXMSGENVDP01","PVBXMSGENVDP02","PVLOMSINTUNE01","PVLOMSINTUNE02","PNIWAAUTOCCVM01","PNIWAAUTOCCVM02","PVOYMSASURA01","PVOYMSASURA02","PVOYMSASURA03","PVOYMSASURA04","PVOYMSASURA05","PVPGMSASURA01","PVPGMSASURA02","PVPGMSASURA03","PVPGMSASURA04","PVPGMSASURA05","PVLOFONT01","PVLOFONT02","PVLOFONT03","PVDUFONT01","PVGLFONT01","PVGLFONT02","PVMAFONT01")


$strvms = @("PVOYMSGENVDP01","PVLOMSEFT01")

$strphyservers = @("ppoymsnway01","pppgmsnway01","nimedplan")

#$strvms = @("PVLOFONT01","PVLOFONT02","PVLOFONT03","PVDUFONT01","PVGLFONT01","PVGLFONT02","PVMAFONT01")


# specify the name of the newsway vm server
#$vmInst="PVOYMSNEWAY01"
#$vmInst="dvlowininfra01"

$MyReport = @"

=======================================================================================






Health Check Status - Information only & No action required.


"@

$MyBadReport = @"

Critical Windows Servers Health Check:

Alerts Needing Urgent Attention:

"@

foreach ($vmInst in $strvms)
{

# Get current Date time
$curDateTime = Get-Date

$NWY_vm = get-vm $vmInst

Write-Host $NWY_vm

$mailsubject = "The SUN - Critical Windows Servers Health Check on $curDateTime"

$MyBadReport += @"

=======================================================================================

Server $NWY_vm as on $curDateTime

"@

$MyReport += @"

=======================================================================================

Server $NWY_vm as on $curDateTime

"@

######################### Snapshot Check #################################################
$Snapshots = $NWY_vm | get-snapshot 

If ($Snapshots) 
{
 write-host "Snapshot Exists: Yes : BAD"
$MyBadReport += @"

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
$MyBadReport += @"

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
$MyBadReport = $MyBadReport + @"


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
$Nwy_ds = get-vm $NWY_vm | get-datastore
#$vDsCapGB = [math]::round(($Nwy_ds.CapacityMB/1024))
#$vDsFreeSpaceGB = [math]::round(($Nwy_ds.FreeSpaceMB/1024))
$vDsFreeSpaceGB = $Nwy_ds.FreeSpaceGB
$DSName=$Nwy_ds.Name

        if($vDSFreespaceGB -lt $FreeSpCritThres)
        {
	    write-host "Datastore: Freespace:$vDSFreespaceGB GB: Critical."
$MyBadReport+= @"

Datastore: $DSName: Freespace:$vDSFreespaceGB GB: Critical.
"@
        }
        elseif($vDSFreespaceGB -lt $FreeSpWarThres)
        {
	    write-host "Datastore: Freespace:$vDSFreespaceGB GB: BAD"
$MyBadReport+= @"

Datastore: $DSName: Freespace:$vDSFreespaceGB GB: BAD.
"@
        }
        else
	{
	    write-host "Datastore: Freespace:$vDSFreespaceGB GB: GOOD"
$MyReport += @"

Datastore: $DSName Freespace:$vDSFreespaceGB GB: GOOD"
"@
        }
######################### Datastore Check #################################################


######################### Guest OS C Drive check #################################################
$vDisks = $NWY_vm.Guest.Disks
foreach ($vDisk in $vDisks)
{
$vDrive = $vDisk.Path
$vDiskCap = [math]::Round(($vDisk.Capacity)/1024/1024/1024)
$vDiskFree = [math]::Round(($vDisk.FreeSpace)/1024/1024/1024)
$vDiskFreePercentage = [Math]::Round($vDiskFree/$vDiskCap * 100)


#if($vDrive -eq "c:\")
#{
if($vDiskFreePercentage -lt $DataDiskCriticalThreshold)
{
$MyBadReport+= @"

$vDrive Drive: Freespace: $vDiskFreePercentage % : Critical
"@
write-host "$vDrive Drive: Freespace: $vDiskFreePercentage % : Critical"
}
elseif($vDiskFreePercentage -lt $DataDiskMajorThreshold)
{
$MyBadReport+= @"

$vDrive Drive: Freespace: $vDiskFreePercentage % : Major
"@
write-host "$vDrive Drive: Freespace: $vDiskFreePercentage % : Major"
}
elseif($vDiskFreePercentage -lt $DataDiskWarningThreshold)
{
$MyBadReport+= @"

$vDrive Drive: Freespace: $vDiskFreePercentage % : Warning
"@
write-host "$vDrive Drive: Freespace: $vDiskFreePercentage % : Warning"
}
else
{
#<#
write-host "$vDrive Drive: Freespace: $vDiskFreePercentage % : GOOD"
$MyReport += @"

$vDrive Drive: Freespace: $vDiskFreePercentage % : GOOD

"@
##>
}
#}




}

}
######################### Guest OS C Drive check #################################################

######################### Physical Server Health check #################################################

$MyBadReportPserv = @"

=======================================================================================

Physical Server Health Check

"@

foreach($srvinst in $strphyservers)
{

$MyBadReportPserv += @"

=======================================================================================

Server $srvinst as on $curDateTime

"@

$MyReport += @"

=======================================================================================

Server $srvinst as on $curDateTime

"@



$disk = Get-WmiObject Win32_LogicalDisk -computername $srvinst
Select-Object Size,FreeSpace

foreach($diskinst in $disk)
{

$vDrive=$diskinst.DeviceID
$DiskSizeGB=[math]::Round($diskinst.Size/1024/1024/1024,1)
$DiskFreeSpaceGB=[math]::Round($diskinst.FreeSpace/1024/1024/1024,1)

$DiskFreePercentage=[math]::Round($DiskFreeSpaceGB/$DiskSizeGB*100)

<#
Write-Host $diskPartition
write-host $DiskSizeGB
write-host $DiskFreeSpaceGB
write-host $DiskFreeSpacePer
#>

if($DiskFreePercentage -lt $DataDiskCriticalThreshold)
{
$MyBadReportPserv+= @"

$vDrive Drive: Freespace: $DiskFreePercentage % : Critical
"@
write-host "$vDrive Drive: Freespace: $DiskFreePercentage % : Critical"
}
elseif($DiskFreePercentage -lt $DataDiskMajorThreshold)
{
$MyBadReportPserv+= @"

$vDrive Drive: Freespace: $DiskFreePercentage % : Major
"@
write-host "$vDrive Drive: Freespace: $DiskFreePercentage % : Major"
}
elseif($DiskFreePercentage -lt $DataDiskWarningThreshold)
{
$MyBadReportPserv+= @"

$vDrive Drive: Freespace: $DiskFreePercentage % : Warning
"@
write-host "$vDrive Drive: Freespace: $DiskFreePercentage % : Warning"
}
else
{
#<#
write-host "$vDrive Drive: Freespace: $DiskFreePercentage % : GOOD"
$MyReport += @"

$vDrive Drive: Freespace: $DiskFreePercentage % : GOOD

"@
}


}
}


######################### Physical Server Health check #################################################




$MyReport = $MyReport + @"

=======================================================================================

















Exception List:


*******************THRESHOLDS*******************
Disk Critical			: Not less than 5% Freespace
Disk Major			    : Not less than 15% Freespace
Disk Warning			: Not less than 25% Freespace
Datastore Warning       : Not less than 200 GB Free space
Datastore Critical      : Not less than 100 GB Free space
Host Memory Utilization : Not more than 85 %
partition free space    : Not less than 20 %
No of VMs on Datastore  : Not more than 4


This is an automated mail sent from a script. 
Please get in touch with IOWindows@newsint.co.uk for assistance, if required.
---------------------------------------------------------------------------------------

"@

$MyAllReport=$MyBadReport+$MyBadReportPserv+$MyReport

# send findings as email to required stakeholders.
#$mailto = "iovm@news.co.uk,iodatacentreteam@news.co.uk,lakshmi.narasimha@news.co.uk,vijayarengan.ramachandran@news.co.uk"
#$mailto = "vijayarengan.ramachandran@newsint.co.uk,IOWindows@newsint.co.uk"
$mailto = "sumit.chopra@news.co.uk,abhiroop.das@news.co.uk"
#$mailto = "IOWindows@newsint.co.uk,iodatacentreteam@newsint.co.uk,jugal.maheshwari@newsint.co.uk"

$mailcontent = $MyAllReport
SendNotificationMail $mailto $mailsubject $mailcontent



# disconnect from the vCenter servers
disconnect-viserver -Server pnioyvivcm01.ni.ad.newsint -Force:$true -confirm:$false
disconnect-viserver -Server pnipgvivcm01.ni.ad.newsint -Force:$true -confirm:$false
