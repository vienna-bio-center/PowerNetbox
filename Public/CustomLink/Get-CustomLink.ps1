function Get-CustomLink {
    <#
    .SYNOPSIS
       Retrieves a custom link from NetBox.
    .DESCRIPTION
       This function retrieves a custom link from NetBox by name or ID.
    .EXAMPLE
       PS C:\> Get-CustomLink -Name "ServiceCatalogID"
       Retrieves the custom link with the name "ServiceCatalogID".
    .PARAMETER Name
       The name of the custom link to retrieve.
    .PARAMETER ID
       The ID of the custom link to retrieve.
    .INPUTS
       None. This function does not accept piped input.
    .OUTPUTS
       NetBox.CustomLink. Returns a list of custom links matching the criteria.
    .NOTES
       Ensure that the NetBox connection is configured before using this function.
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
        Test-Config | Out-Null
        $URL = "/extras/custom-links/"
    }

    process {
        $Query = "?"

        if ($Name) {
            $Query = $Query + "name__ic=$($Name)&"
        }

        if ($ID) {
            $Query = $Query + "id=$($id)&"
        }

        $Query = $Query.TrimEnd("&")

        $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

        $CustomLinks = New-Object collections.generic.list[object]

        foreach ($Item in $Result) {
            [PSCustomObject]$CustomLink = $item
            $CustomLink.PSObject.TypeNames.Insert(0, "NetBox.CustomLink")
            $CustomLinks += $CustomLink
        }

        return $CustomLinks
    }
}
