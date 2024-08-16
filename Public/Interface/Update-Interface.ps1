function Update-Interface {
    <#
    .SYNOPSIS
       Updates an existing interface in NetBox.
    .DESCRIPTION
       This function updates an existing interface in NetBox with the new details provided by the user.
    .EXAMPLE
       PS C:\> Update-NetBoxInterface -ID "1" -Name "NewInterface" -Type "10gbase-t" -MacAddress "00:00:00:00:00:00"
       Updates an interface with ID "1" to have the name "NewInterface", type "10gbase-t", and MAC address "00:00:00:00:00:00".
    .PARAMETER DeviceName
       The name of the parent device for the interface.
    .PARAMETER DeviceID
       The ID of the parent device for the interface.
    .PARAMETER Name
       The name of the interface.
    .PARAMETER ID
       The ID of the interface.
    .PARAMETER Type
       The type of the interface (e.g., "10gbase-t").
    .PARAMETER MacAddress
       The MAC address of the interface.
    .PARAMETER ManagementOnly
       Indicates if the interface is management-only.
    .PARAMETER Confirm
       Prompts for confirmation before making changes to the interface.
    .INPUTS
       None. This function does not accept piped input.
    .OUTPUTS
       None. This function does not return a value.
    .NOTES
       Ensure that the interface exists in NetBox before attempting to update it.
    #>

    [CmdletBinding(DefaultParameterSetName = "Byname")]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ByDeviceName")]
        [Parameter(Mandatory = $false, ParameterSetName = "ByName")]
        [Parameter(Mandatory = $false, ParameterSetName = "ById")]
        [String]
        $DeviceName,

        [Parameter(Mandatory = $true, ParameterSetName = "ByDeviceId")]
        [Parameter(Mandatory = $false, ParameterSetName = "ByName")]
        [Parameter(Mandatory = $false, ParameterSetName = "ById")]
        [Int32]
        $DeviceID,

        [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
        [String]
        $Name,

        [Parameter(Mandatory = $true, ParameterSetName = "ById")]
        [Int32]
        $ID,

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
        $Confirm = $true
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

        $Interface = Get-Interface -Name $Name -DeviceID $Device.ID

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

        Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Interface.ID) + "/") @RestParams -Method Patch -Body $($Body | ConvertTo-Json)
    }
}