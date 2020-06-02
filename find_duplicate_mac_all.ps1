# script to check if VMs with duplicate MACs exists at OY, PG virtual infrstructure.
# writes a log file and sends email notification
# Written by Vijayarengan.R Date: 30-Jul-2012 


#connect to both vCenter servers
connect-viserver pnioyvivcm01.ni.ad.newsint
connect-viserver pnipgvivcm01.ni.ad.newsint

$date=get-date

# define arrays
$VMArray_OY = @{}
$VM_Macs_OY = @{}

$VMArray_PG = @{}
$VM_Macs_PG = @{}


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


$MyReport = @"

NI Virtual Infrastructure: VMs with Duplicate MACs - $date
"@



# Get macs and its vm name in oy datacenter.
$oyindex=0
foreach($vm in get-datacenter "oliver's yard" | Get-VM)
#foreach($vm in get-vmhost pnioyvesx069.ni.ad.newsint | Get-VM)
{
    
    $nw = Get-NetworkAdapter -VM $vm 
    foreach ($nwinst in $nw)
    {
    	$VMArray_Oy[$oyindex] = $nwinst.Parent
	    $VM_Macs_Oy[$oyindex] = $nwinst.MacAddress
	    #write-host $oyindex
	    #write-host $VMArray_Oy[$oyindex]
	    #write-host $VM_Macs_Oy[$oyindex]
    $oyindex = $oyindex + 1
     }
}

$oyvmniccount = $oyindex - 1


# Get macs and its vm name in oy datacenter.
$pgindex=0
foreach($vm in get-datacenter "powergate" | Get-VM)
#foreach($vm in get-vmhost pnipgvesx184.ni.ad.newsint | Get-VM)
{
    $nw = Get-NetworkAdapter -VM $vm 
    foreach ($nwinst in $nw)
    {    
    $VMArray_pg[$pgindex] = $nwinst.Parent
    $VM_Macs_pg[$pgindex] = $nwinst.MacAddress
    #write-host $pgindex
    #write-host $VMArray_pg[$pgindex]
    #write-host $VM_Macs_pg[$pgindex]
    $pgindex = $pgindex + 1
    }
}

$pgvmniccount = $pgindex - 1

$oyindex=0
$pgindex=0

# compare macs at oy vms against macs at pg vm and report if found
for($oyindex=0;$oyindex -le $oyvmniccount;$oyindex++)
#for($oyindex=0;$oyindex -lt $VM_Macs_Oy.length;$oyindex++)
{
    $Mac_to_check = $VM_Macs_Oy[$oyindex]
    #write-host inside_loop
    for ($pgindex=0;$pgindex -le $pgvmniccount;$pgindex++)
    {
      #write-host checking $Mac_to_check with $VM_Macs_pg[$pgindex]
      if($mac_to_check -eq $VM_Macs_pg[$pgindex] -and $Mac_to_check.length -gt 0) 
	{
              #write-host VM $VMArray_Oy[$oyindex] with MAC $VM_Macs_Oy[$oyindex] conflicts with VM $VMArray_pg[$pgindex] with MAC $VM_Macs_pg[$pgindex] 
                $oyvm = $VMArray_Oy[$oyindex]
                $oyvmmac = $VM_Macs_Oy[$oyindex]
                $pgvm = $VMArray_pg[$pgindex]
                $pgvmmac = $VM_Macs_pg[$pgindex]

		$MyReport = $MyReport + @"

VM $oyvm with MAC $oyvmmac conflicts with VM $pgvm with MAC $pgvmmac
"@	
	#write-host $MyReport
        }
      else
        {
         	$MyReport = $MyReport + @"

All Clean. No MAC duplicates detected with VMs !!
"@	
	#write-host $MyReport

        } 
    }
}

$MyReport = $MyReport + @"

===================================================================================================================

DCS Team,
Please raise an incident and assign it to IOWindows team if there were any VMs with duplicate MACs reported above.
-------------------------------------------------------------------------------------------------------------------

This is an automated mail sent from a script. 
Please get in touch with IOWindows@newsint.co.uk for assistance, if required.

"@

write-host $MyReport
$MyReport > D:\\logs\snapshots\snapshot_Status.txt

# send findings as email to required stakeholders.
#$mailto = "IOWindows@newsint.co.uk,vijayarengan.ramachandran@newsint.co.uk,ionetworkteam@newsint.co.uk,iounixteam@newsint.co.uk,iodatacentreteam@newsint.co.uk"
$mailto = "vijayarengan.ramachandran@newsint.co.uk"
$mailsubject = "NI Virtual Infrastructure: VMs with Duplicate MACs - $date"
$mailcontent = $MyReport
SendNotificationMail $mailto $mailsubject $mailcontent

disconnect-viserver -Server pnioyvivcm01.ni.ad.newsint -Force:$true -confirm:$false
disconnect-viserver -Server pnipgvivcm01.ni.ad.newsint -Force:$true -confirm:$false



