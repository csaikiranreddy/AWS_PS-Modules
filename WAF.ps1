$Instances_All = (Get-EC2Instance -Region $Region).Instances
$Loadbalancers = Get-ELB2LoadBalancer

$Accounts_classic = @()
$Accounts_Application = @()
$Accounts_network = @()

if ($Instances_All.count -gt 0){
    foreach ( $LB in $LoadBalancers ) { 
        if($LB.Type.Value -eq 'application'){
            $Accounts_Application+=$LB
            }
        elseif($LB.Type.Value -eq 'classic'){
            $Accounts_classic+=$LB
            }
        elseif($LB.Type.Value -eq 'network'){
            $Accounts_network+=$LB
            }          
}}


$Accounts = @()
foreach ( $LB in $LoadBalancers ) { 
    $new = New-Object -TypeName psobject 
        $new | Add-Member -MemberType NoteProperty -Name 'LoadBalancer' -Value $LB.LoadBalancerName
        $new | Add-Member -MemberType NoteProperty -Type 'LoadBalancer' -Value $LB.Type.Value
    $Accounts += $new
}
$Accounts





$Region = 'us-east-2'

Initialize-AWSDefaultConfiguration -Region $Region

$GeoMatch_Name = 'Demot'
$Ip_Name = 'Demot'
$Rule_Location = 'Demoloct'
$Rule_Ip = "Demoipt"
$WebACL_Name = 'Demot'
$Default_Value = 'Demot'

if ($Instances_All.count -gt 0){
    
    #GeoMatch
    #Countries blocked

    $GeoMatch_country_blocked = @([pscustomobject]@{Country='IR'},[pscustomobject]@{Country='SD'},[pscustomobject]@{Country='SY'},[pscustomobject]@{Country='KP'},[pscustomobject]@{Country='CU'})

    $GeoMatchset_ID = (New-WAFRGeoMatchSet -ChangeToken (Get-WAFRChangeToken) -Name $GeoMatch_Name -Region $Region).GeoMatchSet.GeoMatchSetId

    foreach ( $GCB in $GeoMatch_country_blocked ) { 
    
        $GeoMatch_Constraint = New-Object -TypeName Amazon.WAFRegional.Model.GeoMatchConstraint

        $GeoMatch_Constraint.Type = "Country"

        $GeoMatch_Constraint.Value = $GCB.Country

        $GeoMatch_Setupdate = New-Object -TypeName Amazon.WAFRegional.Model.GeoMatchSetUpdate

        $GeoMatch_Setupdate.Action = "Insert"

        $GeoMatch_Setupdate.GeoMatchConstraint = $GeoMatch_Constraint

        Update-WAFRGeoMatchSet -ChangeToken (Get-WAFRChangeToken) -GeoMatchSetId $GeoMatchset_ID -Update $GeoMatch_Setupdate
    }

   
    #Ip
    #IP's Blocked
    
    #$ip_blocked = @([pscustomobject]@{CIDR = '5.59.38.0/23'},[pscustomobject]@{CIDR = '31.28.224.0/19'},[pscustomobject]@{CIDR = '91.235.12.0/22'})

    $ip_blocked = @()

    $Path = "C:\Users\sai 9639\Documents\RegionofCrimea.csv"
    $IP = Import-Csv -Path $Path
    foreach ( $row in $IP ) {
        $new = New-Object -TypeName psobject
            $new | Add-Member -MemberType NoteProperty -Name 'CIDR' -Value $row.name
        $ip_blocked += $new
    }
    
    $Ipset_ID = (New-WAFRIPSet -ChangeToken (Get-WAFRChangeToken) -Name $Ip_Name).IPSet.IPSetId
   
    foreach($IP in $ip_blocked){

        $IPSet_Descriptor = New-Object -TypeName Amazon.WAFRegional.Model.IPSetDescriptor

        $IPSet_Descriptor.Type = "IPV4"

        $IPSet_Descriptor.Value = $IP.CIDR

        $IPSet_setUpdate = New-Object -TypeName Amazon.WAFRegional.Model.IPSetUpdate

        $IPSet_setUpdate.Action = "Insert"

        $IPSet_setUpdate.IPSetDescriptor = $IPSet_Descriptor

        Update-WAFRIPSet -ChangeToken (Get-WAFRChangeToken) -IPSetId $Ipset_ID -Update $IPSet_setUpdate

    }

    
    #Creating Rules

    $Rule_ID1 = (New-WAFRRule -ChangeToken (Get-WAFRChangeToken) -Name $Rule_Location -metricName $Rule_Location).Rule.RuleId

    $Rule_ID2 = (New-WAFRRule -ChangeToken (Get-WAFRChangeToken) -Name $Rule_Ip -metricName $Rule_Ip).Rule.RuleId

    $Rule_predicates1 = New-Object -TypeName Amazon.WAFRegional.Model.Predicate

    $Rule_predicates2 = New-Object -TypeName Amazon.WAFRegional.Model.Predicate

    $Rule_predicates1.Type = "GeoMatch"

    $Rule_predicates2.Type = "IPMatch"

    $Rule_predicates1.DataId = $GeoMatchset_ID

    $Rule_predicates2.DataId = $Ipset_ID

    $Rule_predicates1.Negated = "False"

    $Rule_predicates2.Negated = "False"

    $Rule_setUpdate1 = New-Object -TypeName Amazon.WAFRegional.Model.RuleUpdate

    $Rule_setUpdate1.Action = "Insert"

    $Rule_setUpdate1.Predicate = $Rule_predicates1

    Update-WAFRRule -RuleId $Rule_ID1 -ChangeToken (Get-WAFRChangeToken) -Update $Rule_setUpdate1

    $Rule_setUpdate2 = New-Object -TypeName Amazon.WAFRegional.Model.RuleUpdate

    $Rule_setUpdate2.Action = "Insert"

    $Rule_setUpdate2.Predicate = $Rule_predicates2

    Update-WAFRRule -RuleId $Rule_ID2 -ChangeToken (Get-WAFRChangeToken) -Update $Rule_setUpdate2

    
    
    #Creating WebACL
    
    $WAFACL_ID = (New-WAFRWebACL -ChangeToken (Get-WAFRChangeToken) -DefaultAction_Type Allow -MetricName $WebACL_Name -Name $WebACL_Name ).WebACL.WebACLId

    $Action_Allow = New-Object -TypeName Amazon.WAFRegional.Model.WafAction

    $Action_Allow.Type = "ALLOW"

    $Rule1 = New-Object -TypeName Amazon.WAFRegional.Model.ActivatedRule
    
    $Rule1.Action = $Action_Allow

    $Rule1.Priority = 1

    $Rule1.RuleId = $Rule_ID1

    $Rule1.Type = "REGULAR"

    $Rule2 = New-Object -TypeName Amazon.WAFRegional.Model.ActivatedRule
    
    $Rule2.Action = $Action_Allow

    $Rule2.Priority = 2
    
    $Rule2.RuleId = $Rule_ID2

    $Rule2.Type = "REGULAR"
        
    $WebACL_setupdate1 = New-Object -TypeName Amazon.WAFRegional.Model.WebACLUpdate
	
	$WebACL_setupdate1.Action = "Insert"

    $WebACL_setupdate1.ActivatedRule = $Rule1
        
    $WebACL_setupdate2 = New-Object -TypeName Amazon.WAFRegional.Model.WebACLUpdate

	$WebACL_setupdate2.Action = "Insert"

    $WebACL_setupdate2.ActivatedRule = $Rule2

	Update-WAFRWebACL -ChangeToken (Get-WAFRChangeToken) -Update $WebACL_setupdate1 -WebACLId $WAFACL_ID

    Update-WAFRWebACL -ChangeToken (Get-WAFRChangeToken) -Update $WebACL_setupdate2 -WebACLId $WAFACL_ID

}
