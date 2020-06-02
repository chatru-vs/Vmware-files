# script to get guest disk information for all file server VMs defined below.
# writes a log file and sends email notification. 
# Written by Vijayarengan.R Date: 24-Feb-2012 


# script to get guest disk information for vm

#connect to both vCenter servers
connect-viserver pnioyvivcm01.ni.ad.newsint
connect-viserver pnipgvivcm01.ni.ad.newsint


# Define Thresholds
$CriticalThreshold = 5
$WarningThreshold = 10

# define list of VMs to check
$strVms = @("PVWAMCFIL01A","PVWAMCFIL01B","PVWAMCFIL02A","PVWAMCFIL02B","PVWAMCFIL03A","PVWAMCFIL03B","PVWAMCFIL04A","PVWAMCFIL04B","PVWAMCFIL05A","PVWAMCFIL05B")
#$strVms = @("PVWAMCFIL01A","PVWAMCFIL01B")

# Get current Date time
$curDateTime = Get-Date

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

$mailsubject = "Disk Capacity report for File Servers on $curDateTime"

$MyReport = @"

Disk Capacity report for File Servers as on $curDateTime

=======================================================================================
"@

foreach ($VMInst in $strVms)

{
$VM = Get-VM $VMInst
$vDisks = $VM.Guest.Disks

#Write-Host $VM.Name
$MyReport += @"

Server: $VM
"@

foreach ($vDisk in $vDisks)
{
$vDrive = $vDisk.Path
$vDiskCap = [math]::Round(($vDisk.Capacity)/1024/1024/1024)
$vDiskFree = [math]::Round(($vDisk.FreeSpace)/1024/1024/1024)
$vDiskFreePercentage = [Math]::Round($vDiskFree/$vDiskCap * 100)

if($vDrive -ne "S:\" -and $vDrive -ne "T:\" -and $vDrive -ne "U:\" -and $vDrive -ne "V:\" -and $vDrive -ne "L:\" -and $vDrive -ne "P:\" -and $vDrive -ne "X:\" -and $vDrive -ne "W:\")
{
$MyReport += @"


Drive                  : $vDrive
Capacity (GB)    : $vDiskCap
FreeSpace (GB): $vDiskFree 
FreeSpace %    : $vDiskFreePercentage

"@



if($vDiskFreePercentage -lt $WarningThreshold -and $vDiskFreePercentage -gt $CriticalThreshold)
{
$MyReport += @"

------------Attention required $vDrive : WARNING !------------
"@
$mailsubject = "Disk Capacity report for Fileservers on $curDateTime - Need Attention"
}
elseif($vDiskFreePercentage -lt $CriticalThreshold)
{
$MyReport += @"

------------Attention required $vDrive : CRITICAL !!!------------
"@
$mailsubject = "Disk Capacity report for Fileservers on $curDateTime - Need Attention - Critical !!"
}
}
}

$MyReport += @"

=======================================================================================
"@
}

$MyReport += @"

Drive S:, T:, U:, V:, X:, W: ignored for free space checks as they are shadow copy drives.
Drive L:, P: ignored for free space checks as they are not active.

Alert Threshold for Critical set for 5% and Warning set for 10%.

"@


Write-Host $MyReport

# write findings to log 
$MyReport >>D:\logs\fileservers\FileServer_DiskReport.txt

$MyReport = $MyReport + @"

---------------------------------------------------------------------------------------
This is an automated mail sent from a script. 
Please get in touch with IOWindows@newsint.co.uk for assistance, if required.
---------------------------------------------------------------------------------------

"@

# send findings as email to required stakeholders.
$mailto = "IOWindows@news.co.uk,iovm@news.co.uk,iodatacentreteam@newsint.co.uk,frank.cadam@news.co.uk"
#$mailto = "sumit.chopra@news.co.uk"
$mailcontent = $MyReport
SendNotificationMail $mailto $mailsubject $mailcontent

#$MyReport | Export-Csv FileServers_Disk_Status.csv -NoTypeInformation
# disconnect from the vCenter servers
disconnect-viserver -Server pnioyvivcm01.ni.ad.newsint -Force:$true -confirm:$false
disconnect-viserver -Server pnipgvivcm01.ni.ad.newsint -Force:$true -confirm:$false
