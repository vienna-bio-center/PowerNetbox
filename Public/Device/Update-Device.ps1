function Update-Device {
    <#
     .SYNOPSIS
        Updates an existing device in NetBox.
     .DESCRIPTION
        This function updates the attributes of an existing device in NetBox.
     .EXAMPLE
        PS C:\> Update-Device -Name ExistingHost -DeviceType "NewType" -Location "High Density"
        Updates the device "ExistingHost" with a new device type and location.
     .PARAMETER Name
        The name of the device to update.
     .PARAMETER DeviceType
        The new device type for the device.
     .PARAMETER Site
        The site where the device is located.
     .PARAMETER Location
        The specific location within the site where the device is located.
     .PARAMETER Rack
        The rack where the device is installed.
     .PARAMETER Position
        The position of the device in the rack (lowest occupied U).
     .PARAMETER Height
        The height of the device in rack units (U).
     .PARAMETER DeviceRole
        The role of the device, e.g., Server, Router, Switch.
     .PARAMETER ParentDevice
        The parent device for the device, in case of a chassis.
     .PARAMETER Hostname
        The hostname for the device.
     .PARAMETER Face
        The face of the device in the rack (front or back).
     .PARAMETER Status
        The status of the device (active, offline, etc.).
     .PARAMETER AssetTag
        The asset tag or serial number of the device.
     .PARAMETER CustomFields
        Custom fields associated with the device.
     .PARAMETER Confirm
        Whether to confirm the update of the device.
     .INPUTS
        None. You cannot pipe objects to this function.
     .OUTPUTS
        Returns the updated device object.
     .NOTES
        This function interacts with the NetBox API to update an existing device.
     #>

    param (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $true)]
        $DeviceType,

        [Parameter(Mandatory = $true)]
        [String]
        $DeviceRole,

        [Parameter(Mandatory = $true)]
        [String]
        $Site,

        [Parameter(Mandatory = $false)]
        [String]
        [ValidateSet("DataCenter 4.47", "High Density", "Low Density")]
        $Location,

        [Parameter(Mandatory = $false)]
        [String]
        $Rack,

        [Parameter(Mandatory = $false)]
        [String]
        $Position,

        [Parameter(Mandatory = $false)]
        [String]
        $Height,

        [Parameter(Mandatory = $false)]
        [String]
        $Hostname,

        [Parameter(Mandatory = $false)]
        [String]
        $ParentDevice,

        [Parameter(Mandatory = $false)]
        [String]
        [ValidateSet("front", "back")]
        $Face = "front",

        [Parameter(Mandatory = $false)]
        [String]
        [ValidateSet("offline", "active", "planned", "staged", "failed", "inventory", "decommissioning")]
        $Status = "active",

        [Parameter(Mandatory = $false)]
        [String]
        $AssetTag,

        [Parameter(Mandatory = $false)]
        [Hashtable]
        $CustomFields,

        [Parameter(Mandatory = $false)]
        [Bool]
        $Confirm = $true
    )

    begin {
        # Test configuration and prepare the API endpoint URL
        Test-Config | Out-Null
        $URL = "/dcim/devices/"
    }

    process {
        # Retrieve the device ID
        if ($Name -is [String]) {
            $name = (Get-Device -Query $Name).Id
        }
        else {
            $Name
        }

        # Build the request body for the API call
        $Body = @{
            name          = (Get-Culture).Textinfo.ToTitleCase($Name)
            device_type   = $DeviceType
            device_role   = (Get-DeviceRole -Name $DeviceRole).ID
            site          = (Get-Site -Name $Site).ID
            location      = (Get-Location -Name $Location).ID
            rack          = (Get-Rack -Name $Rack).ID
            position      = $Position
            face          = $Face
            status        = $Status
            asset_tag     = $AssetTag
            parent_device = @{
                name = $ParentDevice
            }
        }

        # Remove empty keys from the request body
       ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

        # Confirm the update if required
        if ($Confirm) {
            $OutPutObject = [pscustomobject]$Body
            Show-ConfirmDialog -Object $OutPutObject
        }

        # Update the device in NetBox
        Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Interface.ID) + "/") @RestParams -Method Patch -Body $($Body | ConvertTo-Json)
    }
}