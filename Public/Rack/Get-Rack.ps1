function Get-Rack {
    <#
     .SYNOPSIS
        Retrieves a rack from NetBox.
     .DESCRIPTION
        Fetches rack information from NetBox based on provided filters like name, site, location, or slug.
     .EXAMPLE
        PS C:\> Get-NetBoxRack -Location "High Density"
        Retrieves all racks from the "High Density" location.
     .PARAMETER Name
        Name of the rack to filter by.
     .PARAMETER ID
        ID of the rack to filter by.
     .PARAMETER Site
        Site of the rack to filter by.
     .PARAMETER Location
        Location of the rack to filter by.
     .PARAMETER Slug
        Slug identifier of the rack to filter by.
     .INPUTS
        None.
     .OUTPUTS
        NetBox.Rack
     .NOTES
        Retrieves rack details from the NetBox API using specified filters.
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
        $Site,

        [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
        [String]
        $Location,

        [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
        [String]
        $Slug
    )

    begin {
        # Verify configuration and initialize API endpoint
        Test-Config | Out-Null
        $URL = "/dcim/racks/"
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

        if ($Site) {
            $Query = $Query + "site__ic=$($Site)&"
        }

        if ($Location) {
            $Query = $Query + "Location__ic=$($Location)&"
        }

        if ($Slug) {
            $Query = $Query + "slug__ic=$($Slug)&"
        }

        $Query = $Query.TrimEnd("&")

        # Make API request and retrieve the results
        $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

        # Create an empty list to hold the rack objects
        $Racks = New-Object collections.generic.list[object]

        # Process each item in the result and cast to NetBox.Rack type
        foreach ($Item in $Result) {
            [PSCustomObject]$Rack = $item
            $Rack.PSObject.TypeNames.Insert(0, "NetBox.Rack")
            $Racks += $Rack
        }

        # Return the list of racks
        return $Racks
    }
}