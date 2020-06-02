
$macTab = @{}

foreach($vm in Get-VM){
    Get-NetworkAdapter -VM $vm | where {$_.MacAddress} | %{
        if($macTab.ContainsKey($_.MacAddress)){
            Write-Host "Duplicate MAC address" $_.MacAddress "in" $vm.Name "and" $macTab[$_.MacAddress]
        }
        else{
            $macTab[$_.MacAddress] = $vm.Name
        }
    } 
}