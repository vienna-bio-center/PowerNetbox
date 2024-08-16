function Get-Cable {
    <#
    .SYNOPSIS
       Retrieves cables from NetBox.
    .DESCRIPTION
       This function gets cables from NetBox based on various filter parameters.
    .EXAMPLE
       PS C:\> Get-Cable -Device "ServerA"
       Retrieves all cables for the device "ServerA".
    .PARAMETER Label
       The label of the cable.
    .PARAMETER ID
       The ID of the cable.
    .PARAMETER Device
       The name of the parent device.
    .PARAMETER Rack
       The name of the parent rack.
    .INPUTS
       None.
    .OUTPUTS
       NetBox.Cable
    .NOTES
       Ensure that the device or rack specified exists in NetBox.
    #>

    param (
        [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
        [String]
        $Label,

        [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
        [Int32]
        $ID,

        [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
        [String]
        $Device,

        [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
        [String]
        $Rack
    )

    begin {
        Test-Config | Out-Null
        $URL = "/dcim/cables/"
    }

    process {
        $Query = "?"

        if ($Label) {
            $Query = $Query + "Label__ic=$($Label)&"
        }

        if ($ID) {
            $Query = $Query + "id=$($id)&"
        }

        if ($Device) {
            $Query = $Query + "device__ic=$($Device)&"
        }

        if ($Rack) {
            $Query = $Query + "rack=$($Rack)&"
        }

        $Query = $Query.TrimEnd("&")

        $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

        $Cables = New-Object collections.generic.list[object]

        foreach ($Item in $Result) {
            [PSCustomObject]$Cable = $item
            $Cable.PSObject.TypeNames.Insert(0, "NetBox.Cable")
            $Cables += $Cable
        }

        return $Cables
    }
}