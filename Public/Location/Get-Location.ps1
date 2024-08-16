
function Get-Location {
    <#
     .SYNOPSIS
        Retrieves a location in NetBox.
     .DESCRIPTION
        Queries NetBox for a location based on parameters like name, ID, or slug.
     .EXAMPLE
        PS C:\> Get-NetBoxLocation -Name "Low Density"
        Retrieves the location Low Density.
     .PARAMETER Name
        Name of the location.
     .PARAMETER ID
        ID of the location.
     .PARAMETER Slug
        Search for a location by slug.
     .INPUTS
        None
     .OUTPUTS
        NetBox.Location
     .NOTES
        Fetches details about a specific location from NetBox.
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
        Test-Config | Out-Null
        $URL = "/dcim/locations/"
    }

    process {
        # Construct the query string based on provided parameters
        $Query = "?"

        # If name contains spaces, use slug instead
        if ($Name -like " ") {
            $Slug = $Name.tolower() -replace " ", "-"
            $Query = $Query + "slug__ic=$($Slug)&"
        }
        else {
            $Query = $Query + "name__ic=$($Name)&"
        }

        if ($Slug) {
            $Query = $Query + "slug__ic=$($Slug)&"
        }

        $Query = $Query.TrimEnd("&")

        # Retrieve the location(s) from NetBox
        $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

        # Store the results in a list of location objects
        $Locations = New-Object collections.generic.list[object]

        foreach ($Item in $Result) {
            [PSCustomObject]$Location = $item
            $Location.PSObject.TypeNames.Insert(0, "NetBox.Location")
            $Locations += $Location
        }

        return $Locations
    }
}
