$Region = 
$instances_id = 
$AZ =
$Access_Key = 
$Secret_Key = 
$Profile_Name =
$volume_Type =

#Set-AWSCredentials -StoreAs $Keys -AccessKey $Access_Key  -SecretKey $Secret_Key
#Initialize-AWSDefaultConfiguration -ProfileName $Profile_Name -Region $Region
#Stop the instance specified.
Stop-EC2Instance -InstanceId $instances_id
#wait untill the instance is stopped.
While((Get-EC2Instance -InstanceId $instance_id -Region $Region).Instances[0].State.Name.Value -ne 'stopped'){
    Start-Sleep -s 10
}
#Get all the volumes attached to the instance.
$Volumes_ID = Get-EC2Volume -Region $Region
#Loop through all the volumes attached to the instance.
foreach($Volumes in $Volumes_ID){ 
if($instances_id -eq $Volumes.Attachment.InstanceId){ 
#Get the device name.
$Volume_Device = $Volumes.Attachment.Device
#Create a snapshot from volume.
$Snapshot_Id = New-EC2Snapshot -VolumeId $Volumes.VolumeId -Description "This is a Encrypted snapshot"
#Wait till snap shot is available.
While((Get-EC2Snapshot -SnapshotId $Snapshot_Id.SnapshotId).Status.Value -ne 'completed'){ 
    Start-Sleep -s 10
}
#Encrypt the snapshot by creating copy of original snapshot.
$encrypted_snapshot_id = Copy-EC2Snapshot -SourceSnapshotId $Snapshot_Id.SnapshotId -Encrypted $true -SourceRegion $Region -Description "This is a Encrypted snapshot"
#wait untill new encrypted snap shot is create.
While((Get-EC2Snapshot -SnapshotId $encrypted_snapshot_id).Status.Value -ne 'completed'){ 
    Start-Sleep -s 10
}
#create a new volume from encrypted snapshot
$encrypted_volume_id = New-EC2Volume -SnapshotId $encrypted_snapshot_id -AvailabilityZone $AZ -VolumeType $volume_Type
#wait untill new encrypted volume is created.
While((Get-EC2Volume -VolumeId $encrypted_volume_id.VolumeId).status.Value -ne 'available'){ 
    Start-Sleep -s 10
}
#Detach the volume from the instance and attach at the same position.
Dismount-EC2Volume -VolumeId $Volumes.Attachment.VolumeId -InstanceId $instances_id -Device $Volumes.Attachment.Device 
Start-Sleep -s 10
$NEw_Attached_Volume = Add-EC2Volume -InstanceId $instances_id -VolumeId $encrypted_volume_id.VolumeId -Device $Volumes.Attachment.Device


}
}
