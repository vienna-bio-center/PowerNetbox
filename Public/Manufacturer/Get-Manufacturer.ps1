function Get-Manufacturer {
    <#
    .SYNOPSIS
       Gets a manufacturer from NetBox.
    .DESCRIPTION
       Retrieves manufacturer information from NetBox based on provided filters like name, ID, or slug.
    .EXAMPLE
       PS C:\> Get-NetBoxManufacturer -Name "Cisco"
       Retrieves manufacturer "Cisco" from NetBox.
    .PARAMETER Name
       Name of the manufacturer to filter by.
    .PARAMETER ID
       ID of the manufacturer to filter by.
     .PARAMETER Slug
        Slug identifier of the manufacturer to filter by.
    .INPUTS
       None.
    .OUTPUTS
       NetBox.Manufacturer
    .NOTES
       Retrieves manufacturer details from the NetBox API using specified filters.
    #>

    param (
        [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
        [String]
        $Name,

        [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
        [Int32]
        $ID,

        [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
        [String]
        $Slug
    )

    begin {
        # Verify configuration and initialize API endpoint
        Test-Config | Out-Null
        $URL = "/dcim/manufacturers/"
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

        if ($Slug) {
            $Query = $Query + "slug__ic=$($Slug)&"
        }

        $Query = $Query.TrimEnd("&")

        # Make API request and retrieve the results
        $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get

        # Check if multiple pages of results need to be retrieved
        if ($Result.Count -gt 50) {
            $Result = Get-NextPage -Result $Result
            $Manufacturer = $Result
        }
        else {
            $Manufacturer = $Result.results
        }

        # Cast the result to NetBox.Manufacturer type
        $Manufacturer.PSObject.TypeNames.Insert(0, "NetBox.Manufacturer")
        return $Manufacturer
    }
}