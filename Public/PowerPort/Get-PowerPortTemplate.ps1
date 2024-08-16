function Get-PowerPortTemplate {
    <#
    .SYNOPSIS
       Retrieves a power port template from NetBox.
    .DESCRIPTION
       This function fetches power port templates from NetBox, allowing you to filter by name, ID, device type name, or device type ID.
    .EXAMPLE
       PS C:\> Get-NetBoxPowerPortTemplate -Name "PSU1"
       Retrieves the Power Port Template with the name "PSU1".
    .PARAMETER Name
       The name of the power port template.
    .PARAMETER ID
       The ID of the power port template.
    .PARAMETER DeviceTypeName
       The name of the parent device type.
    .PARAMETER DeviceTypeID
       The ID of the parent device type.
    .INPUTS
       None. You cannot pipe objects to this function.
    .OUTPUTS
       Returns a list of power port templates as NetBox.PowerPortTemplate objects.
    .NOTES
       This function interacts with the NetBox API to retrieve power port templates based on the provided filters.
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
        $DeviceTypeName,

        [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
        [Int32]
        $DeviceTypeID
    )

    begin {
        Test-Config | Out-Null
        $URL = "/dcim/power-port-templates/"
    }

    process {
        $Query = "?"

        if ($Name) {
            $Query = $Query + "name__ic=$($Name)&"
        }

        if ($DeviceTypeName) {
            $Query = $Query + "devicetype_id=$($(Get-DeviceType -Name $DeviceTypeName).ID)&"
        }

        if ($DeviceTypeID) {
            $Query = $Query + "devicetype_id=$($DeviceTypeID)&"
        }

        if ($ID) {
            $Query = $Query + "id=$($ID)&"
        }

        $Query = $Query.TrimEnd("&")

        $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

        $PowerPortTemplates = New-Object collections.generic.list[object]

        foreach ($Item in $Result) {
            [PSCustomObject]$PowerPortTemplate = $Item
            $PowerPortTemplate.PSObject.TypeNames.Insert(0, "NetBox.PowerPortTemplate")
            $PowerPortTemplates += $PowerPortTemplate
        }

        return $PowerPortTemplates
    }
}