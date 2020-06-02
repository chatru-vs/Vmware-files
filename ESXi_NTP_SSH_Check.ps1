# script to check SSH & NTP status of all ESXi hosts at Newsroom virtual infrastructure
# writes a log file and sends email notification with snapshot details
# Written by Sumit Chopra: 25-Feb-2015

#connect to all vCenter servers
connect-viserver pvlomsoravcm01.ni.ad.newsint,pvlomsoravcm02.ni.ad.newsint,pnioyvivcm01.ni.ad.newsint,pnipgvivcm01.ni.ad.newsint,newsroomvc5.ni.ad.newsint
#connect-viserver pvlomsoravcm01.ni.ad.newsint,pvlomsoravcm02.ni.ad.newsint


$date=get-date
$sshreport=@()                 # Array for storing SSH status of ESXi hosts
$NTPReport=@()                 # Array for storing NTP status of ESXi hosts
$IncorrectNTPserver=@()        # Array for storing Incorrect NTP Servers status of ESXi hosts


$NI_Hosts = get-vmhost 

$NTPReport = @"


Following host(s) are configured with either Manual NTP startup Policy or Service is not running:

===================================================================================================


"@


$IncorrectNTPserver = @"

Following ESXi hosts are configured with wrong NTP server:

===================================================================================================


"@


$sshreport = @"


Following ESXi hosts has got SSH services running:

===================================================================================================


"@



foreach ($esxi in $NI_Hosts)
{
#$value=0

$ntpservice = Get-VMHostService -VMHost $esxi | Where {$_.Key -eq "ntpd"}
$sshservice = Get-VMHostService -VMHost $esxi | Where {$_.Key -eq "TSM-SSH"}
$ntpserver=get-vmhostntpserver -vmhost $esxi


	If ($ntpservice.Policy -eq "off" -or $ntpservice.running -eq $false) 
	{

$value=1	
$NTPReport = $NTPReport +  @" 

$esxi 

"@
       } 

if($sshservice.Running -eq "true")
{ 

$value=1	
$sshreport = $sshreport + @"

$esxi 

"@
}


if($ntpserver -ne "ntp-tc.newsint.co.uk")

{
$value=1
$IncorrectNTPserver = $IncorrectNTPserver + @"

$esxi configured with "$ntpserver" incorrectly.

"@


}


}



if($value)
{
$Consolidated_Report = $Consolidated_Report + @"

ESXi Hosts NTP & SSH Check


$NTPReport


$sshreport


$IncorrectNTPserver


===================================================================================================
===================================================================================================


DCS Team,
Please raise an incident and assign it to IOWindows team if there were any servers reported above.
---------------------------------------------------------------------------------------------------

This is an automated mail sent from a script. 
Please get in touch with IOvm@news.co.uk for assistance, if required.

"@

# send findings as email to required stakeholders.
$mailto ="iodatacentreteam@news.co.uk"
$CCs="iovm@news.co.uk"
$mailsubject="Virtual Infrastructure NTP & SSH Check - $date"
send-MailMessage -to $mailto -From "VMware_ScriptAdmin@newsint.co.uk" -SmtpServer smtprelay1.ni.ad.newsint -Subject $mailsubject -Body $Consolidated_Report -Cc $ccs    # Send email

}

write-host $Consolidated_Report

#$Consolidated_Report > D:\\logs\SSH_Ntp\sshntp.txt



disconnect-viserver -server pvlomsoravcm01.ni.ad.newsint,pvlomsoravcm02.ni.ad.newsint,pnioyvivcm01.ni.ad.newsint,pnipgvivcm01.ni.ad.newsint,newsroomvc5.ni.ad.newsint -Force:$true -confirm:$false

#disconnect-viserver -server pvlomsoravcm01.ni.ad.newsint,pvlomsoravcm02.ni.ad.newsint



