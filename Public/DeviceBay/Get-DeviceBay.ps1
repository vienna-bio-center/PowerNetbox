function Get-DeviceBay {
    <#
    .SYNOPSIS
       Retrieves device bays from NetBox.
    .DESCRIPTION
       This function retrieves device bays from NetBox based on the provided filter parameters.
    .EXAMPLE
       PS C:\> Get-DeviceBay -DeviceName "Chassis"
       Retrieves all device bays for the device "Chassis".
    .PARAMETER Name
       The name of the device bay to retrieve.
    .PARAMETER Id
       The ID of the device bay to retrieve.
    .PARAMETER DeviceName
       The name of the parent device associated with the device bay.
    .PARAMETER DeviceID
       The ID of the parent device associated with the device bay.
    .INPUTS
       None. This function does not accept piped input.
    .OUTPUTS
       NetBox.DeviceBay. Returns a list of device bays matching the criteria.
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
        $DeviceName,

        [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
        [Int32]
        $DeviceID
    )

    begin {
        Test-Config | Out-Null
        $URL = "/dcim/device-bays/"
    }

    process {
        $Query = "?"

        if ($Name) {
            $Query = $Query + "name=$($Name)&"
        }

        if ($ID) {
            $Query = $Query + "id=$($id)&"
        }

        if ($DeviceName) {
            $Query = $Query + "device_id=$((Get-NetBoxDevice -Name $DeviceName).ID)&"
        }

        if ($DeviceID) {
            $Query = $Query + "device_id=$((Get-NetBoxDevice -Id $DeviceID).ID)&"
        }

        $Query = $Query.TrimEnd("&")

        $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

        Write-Verbose $($NetboxURL + $URL + $Query)

        $DeviceBays = New-Object collections.generic.list[object]

        foreach ($Item in $Result) {
            [PSCustomObject]$DeviceBay = $item
            $DeviceBay.PSObject.TypeNames.Insert(0, "NetBox.DeviceBay")
            $DeviceBays += $DeviceBay
        }

        return $DeviceBays
    }
}