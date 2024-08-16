function New-Interface {
    <#
    .SYNOPSIS
       Creates a new interface in NetBox.
    .DESCRIPTION
       This function creates a new interface in NetBox for the specified device.
    .EXAMPLE
       PS C:\> New-NetBoxInterface -DeviceName "NewHost" -Name "NewInterface" -Type "10gbase-t"
       Creates an interface named "NewInterface" on the device "NewHost" with the type "10gbase-t".
    .PARAMETER DeviceName
       The name of the parent device for the new interface.
    .PARAMETER DeviceID
       The ID of the parent device for the new interface.
    .PARAMETER Name
       The name of the new interface.
    .PARAMETER Label
       The label for the new interface.
    .PARAMETER Type
       The type of the new interface (e.g., "10gbase-t").
    .PARAMETER MacAddress
       The MAC address of the new interface.
    .PARAMETER ManagementOnly
       Indicates if the interface is management-only.
    .PARAMETER Confirm
       Prompts for confirmation before creating the interface.
    .PARAMETER Force
       Forces the creation of the interface even if it might conflict with existing interfaces.
    .INPUTS
       None. This function does not accept piped input.
    .OUTPUTS
       NetBox.Interface. Returns the created interface.
    .NOTES
       Ensure that the parent device exists in NetBox before creating the interface.
    #>

    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
        [String]
        $DeviceName,

        [Parameter(Mandatory = $true, ParameterSetName = "ById")]
        [Int32]
        $DeviceID,

        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $false)]
        [String]
        $Label,

        [Parameter(Mandatory = $true)]
        [String]
        $Type,

        [Parameter(Mandatory = $false)]
        [String]
        $MacAddress,

        [Parameter(Mandatory = $false)]
        [Bool]
        $ManagmentOnly,

        [Parameter(Mandatory = $false)]
        [Bool]
        $Confirm = $true,

        [Parameter(Mandatory = $false)]
        [Switch]
        $Force
    )

    begin {
        Test-Config | Out-Null
        $URL = "/dcim/interfaces/"
    }

    process {
        if ($DeviceName) {
            $Device = Get-Device -Name $DeviceName
        }

        if ($DeviceID) {
            $Device = Get-Device -ID $DeviceID
        }

        $Body = @{
            name        = (Get-Culture).Textinfo.ToTitleCase($Name)
            device      = $Device.ID
            type        = $Type
            mgmt_only   = $ManagmentOnly
            mac_address = $MacAddress
        }
        # Remove empty keys
       ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

        if ($Confirm) {
            $OutPutObject = [pscustomobject]$Body
            Show-ConfirmDialog -Object $OutPutObject
        }

        $Interface = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
        $Interface.PSObject.TypeNames.Insert(0, "NetBox.Interface")
        return $Interface
    }
}
