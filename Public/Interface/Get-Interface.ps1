function Get-Interface {
    <#
     .SYNOPSIS
        Retrieves an interface from NetBox.
     .DESCRIPTION
        This function retrieves an interface from NetBox based on the provided filters such as name, ID, device name, or device ID.
     .EXAMPLE
        PS C:\> Get-NetBoxInterface -DeviceName "NewHost" -Name "eth0"
        Retrieves the interface named "eth0" from the device "NewHost".
     .PARAMETER Name
        The name of the interface to retrieve.
     .PARAMETER ID
        The ID of the interface to retrieve.
     .PARAMETER DeviceName
        The name of the parent device for the interface.
     .PARAMETER DeviceID
        The ID of the parent device for the interface.
     .PARAMETER ManagementOnly
        Boolean indicating whether to filter for management-only interfaces.
     .INPUTS
        None. This function does not accept piped input.
     .OUTPUTS
        NetBox.Interface. Returns a list of interfaces matching the criteria.
     .NOTES
        Ensure the specified device and interface exist in NetBox before attempting to retrieve them.
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
        $DeviceID,

        [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
        [Bool]
        $ManagementOnly
    )

    begin {
        Test-Config | Out-Null
        $URL = "/dcim/interfaces/"
    }

    process {
        $Query = "?"

        if ($Name) {
            $Query = $Query + "name__ic=$($Name)&"
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

        if ($ManagementOnly) {
            $Query = $Query + "mgmt_only=$($ManagementOnly.ToString())&"
        }

        $Query = $Query.TrimEnd("&")

        $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

        Write-Verbose $($NetboxURL + $URL + $Query)

        $Interfaces = New-Object collections.generic.list[object]

        foreach ($Item in $Result) {
            [PSCustomObject]$Interface = $item
            $Interface.PSObject.TypeNames.Insert(0, "NetBox.Interface")
            $Interfaces += $Interface
        }

        return $Interfaces
    }
}