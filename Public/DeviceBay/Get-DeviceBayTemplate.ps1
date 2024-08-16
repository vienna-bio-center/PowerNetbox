function Get-DeviceBayTemplate {
    <#
    .SYNOPSIS
       Retrieves device bay templates from NetBox.
    .DESCRIPTION
       This function retrieves device bay templates from NetBox based on the provided filter parameters.
    .EXAMPLE
       PS C:\> Get-DeviceBayTemplate -Name "Bay1"
       Retrieves the device bay template with the name "Bay1".
    .PARAMETER Name
       The name of the device bay template to retrieve.
    .PARAMETER Id
       The ID of the device bay template to retrieve.
    .PARAMETER DeviceTypeName
       The name of the device type associated with the device bay template.
    .PARAMETER DeviceTypeID
       The ID of the device type associated with the device bay template.
    .INPUTS
       None. This function does not accept piped input.
    .OUTPUTS
       NetBox.DeviceBayTemplate. Returns a list of device bay templates matching the criteria.
    .NOTES
       Ensure that the NetBox connection is configured before using this function.
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
        $URL = "/dcim/device-bay-templates/"
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
            $Query = $Query + "id=$($id)&"
        }

        $Query = $Query.TrimEnd("&")

        $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

        $DeviceBayTemplates = New-Object collections.generic.list[object]

        foreach ($Item in $Result) {
            [PSCustomObject]$DeviceBayTemplate = $item
            $DeviceBayTemplate.PSObject.TypeNames.Insert(0, "NetBox.DeviceBayTemplate")
            $DeviceBayTemplates += $DeviceBayTemplate
        }

        return $DeviceBayTemplates
    }
}