Function Get-publicS3{

     <###########################################################################
    .DESCRIPTION
        This function can be used to get public S3 buckets from aws account.

 
    .PARAMETER ProfileName
        Name of AWS Credential Profile.

    .NOTES
        Name: Get-publicS3                     Author: Saikiran Reddy
        Version: 1.0                           Updated: 2018-08-24
    ##########################################################l#################>

    Param( 
    [Parameter(Mandatory=$true)]
    [string]$ProfileName
    )#end param

    Set-AWSCredential -ProfileName $ProfileName 
	
    #####################################
    #Get all Buckets.
    $S3buckets = Get-S3Bucket 

    #Get list of S3 buckets with public access.
    foreach ( $S3BucketName in $S3buckets.BucketName ) {
        $Grantees = (Get-S3ACL -BucketName  $S3BucketName).Grants.Grantee
        if ($Grantees.URI -eq 'http://acs.amazonaws.com/groups/global/AllUsers') { Write-Output $S3BucketName }
    }
}
