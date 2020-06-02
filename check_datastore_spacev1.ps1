$dsreport=@()

foreach ($dsinst in get-datastore)
{
	$row=""|select datastore,capacity_GB,freespace_GB
       	$row.datastore=$dsinst.name
	$row.capacity_GB=[math]::round($dsinst.CapacityMB/1024)	
	$row.freespace_GB=[math]::round($dsinst.FreeSpaceMB/1024)
	
	$dsreport+=$row
}


$dsreport|export-csv datastore_capacity.csv -NoTypeInformation