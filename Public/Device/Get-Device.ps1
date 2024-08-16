
function Get-Device {
    <#
     .SYNOPSIS
        Retrieves devices from NetBox based on various filters.
     .DESCRIPTION
        This function retrieves device objects from the NetBox API. It supports filtering by model, manufacturer, site, location, rack, and other attributes.
     .EXAMPLE
        PS C:\> Get-Device -DeviceType "Cisco Catalyst 2960"
        Retrieves all devices of type "Cisco Catalyst 2960" from NetBox.
     .PARAMETER Name
        The name of the device.
     .PARAMETER Model
        The model of the device.
     .PARAMETER Manufacturer
        The manufacturer of the device.
     .PARAMETER ID
        The unique ID of the device.
     .PARAMETER Slug
        The slug of the device.
     .PARAMETER MacAddress
        The MAC address of the device.
     .PARAMETER Site
        The site where the device is located.
     .PARAMETER Location
        The specific location within the site where the device is located.
     .PARAMETER Rack
        The rack where the device is installed.
     .PARAMETER DeviceType
        The device type to filter by.
     .PARAMETER Exact
        Specifies whether to perform an exact match on the filters.
     .INPUTS
        None. You cannot pipe objects to this function.
     .OUTPUTS
        Returns a list of device objects that match the provided filters.
     .NOTES
        This function interacts with the NetBox API to retrieve device objects.
     #>

    param (
        [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
        [String]
        $Name,

        [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
        [String]
        $Model,

        [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
        [Alias("Vendor")]
        [String]
        $Manufacturer,

        [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
        [Int32]
        $ID,

        [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
        [String]
        $Slug,

        [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
        [String]
        $MacAddress,

        [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
        [String]
        $Site,

        [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
        [String]
        $Location,

        [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
        [String]
        $Rack,

        [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
        [String]
        $DeviceType,

        [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
        [Switch]
        $Exact
    )

    begin {
        # Test configuration and prepare the API endpoint URL
        Test-Config | Out-Null
        $URL = "/dcim/devices/"
    }

    process {
        # Build the query string based on provided parameters
        $Query = "?"

        if ($Name) {
            $Query += if ($Exact) { "name=$($Name)&" } else { "name__ic=$($Name)&" }
        }
        if ($Model) {
            $Query += "model__ic=$($Model)&"
        }
        if ($Manufacturer) {
            $Query += "manufacturer=$($Manufacturer)&"
        }
        if ($ID) {
            $Query += "id=$($ID)&"
        }
        if ($Slug) {
            $Query += "slug__ic=$($Slug)&"
        }
        if ($MacAddress) {
            $Query += "mac_address=$($MacAddress)&"
        }
        if ($Site) {
            $Query += "site__ic=$($Site)&"
        }
        if ($Location) {
            $Query += "location__ic=$($Location)&"
        }
        if ($Rack) {
            $Query += "rack=$($Rack)&"
        }
        if ($DeviceType) {
            $Query += "device_type_id=$(Get-DeviceType -Model $($DeviceType) | Select-Object -ExpandProperty id)&"
        }

        $Query = $Query.TrimEnd("&")

        # Fetch the result from NetBox
        $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

        # Prepare the output as a list of PSCustomObjects
        $Devices = New-Object collections.generic.list[object]

        foreach ($Item in $Result) {
            [PSCustomObject]$Device = $Item
            $Device.PSObject.TypeNames.Insert(0, "NetBox.Device")
            $Devices += $Device
        }

        return $Devices
    }
}