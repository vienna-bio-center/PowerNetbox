function Get-Site {
    <#
     .SYNOPSIS
        Retrieves a site from NetBox.
     .DESCRIPTION
        Queries NetBox for a site based on parameters like name, ID, or slug.
     .EXAMPLE
        PS C:\> Get-NetBoxSite -Name VBC
        Returns the Netbox site VBC.
     .PARAMETER Name
        Search for a site by name.
     .PARAMETER ID
        Search for a site by ID.
     .PARAMETER Slug
        Search for a site by slug.
     .INPUTS
        None
     .OUTPUTS
        NetBox.Site
     .NOTES
        Fetches details about a specific site from NetBox.
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
        $URL = "/dcim/sites/"
    }

    process {
        # Construct the query string based on provided parameters
        $Query = "?"

        if ($name) {
            $Query = $Query + "name__ic=$($Name)&"
        }

        if ($ID) {
            $Query = $Query + "id=$($id)&"
        }

        if ($Slug) {
            $Query = $Query + "slug__ic=$($Slug)"
        }

        $Query = $Query.TrimEnd("&")

        # Retrieve the site(s) from NetBox
        $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

        # Store the results in a list of site objects
        $Sites = New-Object collections.generic.list[object]

        foreach ($Item in $Result) {
            [PSCustomObject]$Site = $item
            $Site.PSObject.TypeNames.Insert(0, "NetBox.Site")
            $Sites += $Site
        }

        return $Sites
    }
}
