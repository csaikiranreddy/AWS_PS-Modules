function createWAF(){
    
    Param(
        
        #Codes for countries - 'Iran - IR','Korea - KR','Russian - RU'
        [Parameter(Mandatory=$true)]
        [ValidateSet('IR','KR','RU')]
        [string] $GeoMatch_country_blocked,
        
        #IPV4 address if IPV^ change in code.
        [Parameter(Mandatory=$true)]
        [string] $ip_blocked,
        
        [Parameter(Mandatory=$true)]
        [string] $GeoMatch_Name,
        
        [Parameter(Mandatory=$true)]
        [string] $Ip_Name,
       
        [Parameter(Mandatory=$true)]
        [string] $Rule_Name,
        [Parameter(Mandatory=$true)]
        
        [string] $WebACL_Name,
        [Parameter(Mandatory=$true)]
        [string] $Default_Value
    )

    #Test
    #$GeoMatch_country_blocked = 'IR'
    #$ip_blocked = '192.0.2.0/24'
    #$GeoMatch_Name = 'Demot2'
    #$Ip_Name = 'Demot2'
    #$Rule_Location = 'Demoloct2'
    #$Rule_Ip = "Demoipt2"
    #$WebACL_Name = 'Demot2'
    #$Default_Value = 'Demot2'

    
    #Blocks Traffic from specified country

    $GeoMatchset_ID = (New-WAFGeoMatchSet -ChangeToken (Get-WAFChangeToken) -Name $GeoMatch_Name).GeoMatchSet.GeoMatchSetId

    $GeoMatch_Constraint = New-Object -TypeName Amazon.WAF.Model.GeoMatchConstraint

    $GeoMatch_Constraint.Type = "Country"

    $GeoMatch_Constraint.Value = $GeoMatch_country_blocked

    $GeoMatch_Setupdate = New-Object -TypeName Amazon.WAF.Model.GeoMatchSetUpdate

    $GeoMatch_Setupdate.Action = "Insert"

    $GeoMatch_Setupdate.GeoMatchConstraint = $GeoMatch_Constraint

    Update-WAFGeoMatchSet -ChangeToken (Get-WAFChangeToken) -GeoMatchSetId $GeoMatchset_ID -Update $GeoMatch_Setupdate



    #Blocks Traffic from specified Id

    $Ipset_ID = (New-WAFIPSet -ChangeToken (Get-WAFChangeToken) -Name $Ip_Name).IPSet.IPSetId

    $IPSet_Descriptor = New-Object -TypeName Amazon.WAF.Model.IPSetDescriptor

    $IPSet_Descriptor.Type = "IPV4"

    $IPSet_Descriptor.Value = $ip_blocked

    $IPSet_setUpdate = New-Object -TypeName Amazon.WAF.Model.IPSetUpdate

    $IPSet_setUpdate.Action = "Insert"

    $IPSet_setUpdate.IPSetDescriptor = $IPSet_Descriptor

    Update-WAFIPSet -ChangeToken (Get-WAFChangeToken) -IPSetId $Ipset_ID -Update $IPSet_setUpdate

    #Create a rule for the web ACL

    $Rule_ID1 = (New-WAFRule -ChangeToken (Get-WAFChangeToken) -Name $Rule_Location -metricName $Rule_Location).Rule.RuleId

    $Rule_ID2 = (New-WAFRule -ChangeToken (Get-WAFChangeToken) -Name $Rule_Ip -metricName $Rule_Ip).Rule.RuleId

    $Rule_predicates1 = New-Object -TypeName Amazon.WAF.Model.Predicate

    $Rule_predicates2 = New-Object -TypeName Amazon.WAF.Model.Predicate

    $Rule_predicates1.Type = "GeoMatch"

    $Rule_predicates2.Type = "IPMatch"

    $Rule_predicates1.DataId = $GeoMatchset_ID

    $Rule_predicates2.DataId = $Ipset_ID

    $Rule_predicates1.Negated = "False"

    $Rule_predicates2.Negated = "False"

    $Rule_setUpdate1 = New-Object -TypeName Amazon.WAF.Model.RuleUpdate

    $Rule_setUpdate1.Action = "Insert"

    $Rule_setUpdate1.Predicate = $Rule_predicates1

    Update-WAFRule -RuleId $Rule_ID1 -ChangeToken (Get-WAFChangeToken) -Update $Rule_setUpdate1

    $Rule_setUpdate2 = New-Object -TypeName Amazon.WAF.Model.RuleUpdate

    $Rule_setUpdate2.Action = "Insert"

    $Rule_setUpdate2.Predicate = $Rule_predicates2

    Update-WAFRule -RuleId $Rule_ID2 -ChangeToken (Get-WAFChangeToken) -Update $Rule_setUpdate2

    #Create a WebACL

    $WAFACL_ID = (New-WAFWebACL -ChangeToken (Get-WAFChangeToken) -DefaultAction_Type Allow -MetricName $WebACL_Name -Name $WebACL_Name).WebACL.WebACLId

    $Action_Allow = New-Object -TypeName Amazon.WAF.Model.WafAction

    $Action_Allow.Type = "ALLOW"

    $Rule1 = New-Object -TypeName Amazon.WAF.Model.ActivatedRule
    
    $Rule1.Action = $Action_Allow

    $Rule1.Priority = 1

    $Rule1.RuleId = $Rule_ID1

    $Rule1.Type = "REGULAR"

    $Rule2 = New-Object -TypeName Amazon.WAF.Model.ActivatedRule
    
    $Rule2.Action = $Action_Allow

    $Rule2.Priority = 2
    
    $Rule2.RuleId = $Rule_ID2

    $Rule2.Type = "REGULAR"

    $WebACL_setupdate1 = New-Object -TypeName Amazon.WAF.Model.WebACLUpdate
	
	$WebACL_setupdate1.Action = "Insert"

    $WebACL_setupdate1.ActivatedRule = $Rule1
        
    $WebACL_setupdate2 = New-Object -TypeName Amazon.WAF.Model.WebACLUpdate

	$WebACL_setupdate2.Action = "Insert"

    $WebACL_setupdate2.ActivatedRule = $Rule2

	Update-WAFWebACL -ChangeToken (Get-WAFChangeToken) -Update $WebACL_setupdate1 -WebACLId $WAFACL_ID

    Update-WAFWebACL -ChangeToken (Get-WAFChangeToken) -Update $WebACL_setupdate2 -WebACLId $WAFACL_ID
    
}