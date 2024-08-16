function Get-CustomField {
    <#
     .SYNOPSIS
        Retrieves a custom field from NetBox.
     .DESCRIPTION
        Fetches custom field information from NetBox based on the provided filters like name or ID.
     .EXAMPLE
        PS C:\> Get-NetBoxCustomField -Name "ServiceCatalogID"
        Retrieves custom field "ServiceCatalogID" from NetBox.
     .PARAMETER Name
        Name of the custom field to filter by.
     .PARAMETER ID
        ID of the custom field to filter by.
     .INPUTS
        None.
     .OUTPUTS
        NetBox.CustomField
     .NOTES
        Retrieves custom field details from NetBox using specified filters.
     #>

    param (
        [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
        [String]
        $Name,

        [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
        [Int32]
        $ID
    )

    begin {
        # Verify configuration and initialize API endpoint
        Test-Config | Out-Null
        $URL = "/extras/custom-fields/"
    }

    process {
        # Build query string based on parameters provided
        $Query = "?"

        if ($Name) {
            $Query = $Query + "name__ic=$($Name)&"
        }

        if ($ID) {
            $Query = $Query + "id=$($id)&"
        }

        $Query = $Query.TrimEnd("&")

        # Make API request and retrieve the results
        $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

        # Create an empty list to hold the custom field objects
        $Customfields = New-Object collections.generic.list[object]

        # Process each item in the result and cast to NetBox.CustomField type
        foreach ($Item in $Result) {
            [PSCustomObject]$Customfield = $item
            $Customfield.PSObject.TypeNames.Insert(0, "NetBox.Customfield")
            $Customfields += $Customfield
        }

        # Return the list of custom fields
        return $Customfields
    }
}
