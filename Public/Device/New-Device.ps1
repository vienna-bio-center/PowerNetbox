function New-Device {
    <#
     .SYNOPSIS
        Creates a new device in NetBox.
     .DESCRIPTION
        This function allows you to create a new device in NetBox by specifying parameters such as name, device type, site, location, and more.
     .EXAMPLE
        PS C:\> New-NetBoxDevice -Name NewHost -Location "Low Density" -Rack Y-14 -Position 27 -Height 4 -DeviceRole Server -DeviceType "PowerEdge R6515" -Site VBC
        Adds the device "NewHost" in rack "Y-14" at position "27" in the location "Low Density" on Site "VBC" as a "server" with device type "PowerEdge R6515".
     .PARAMETER Name
        The name of the device.
     .PARAMETER DeviceTypeName
        The name of the device type.
     .PARAMETER DeviceTypeID
        The ID of the device type.
     .PARAMETER Site
        The site where the device will be located.
     .PARAMETER Location
        The specific location within the site where the device will be placed.
     .PARAMETER Rack
        The rack where the device will be installed.
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
     .PARAMETER PrimaryIPv4
        The primary IPv4 address of the device (NOT IMPLEMENTED).
     .PARAMETER AssetTag
        The asset tag or serial number of the device.
     .PARAMETER CustomFields
        Custom fields associated with the device.
     .PARAMETER Confirm
        Whether to confirm the creation of the device.
     .PARAMETER Force
        Forces the creation of the device, overriding warnings.
     .INPUTS
        None. You cannot pipe objects to this function.
     .OUTPUTS
        Returns the created device object.
     .NOTES
        This function interacts with the NetBox API to create a new device.
     #>
    [CmdletBinding(DefaultParameterSetName = "ByName")]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
        [String]
        $DeviceTypeName,

        [Parameter(Mandatory = $true, ParameterSetName = "ByID")]
        [Int32]
        $DeviceTypeID,

        [Parameter(Mandatory = $true)]
        [String]
        $DeviceRole,

        [Parameter(Mandatory = $true)]
        [String]
        $Site,

        [Parameter(Mandatory = $true)]
        [String]
        [ValidateSet("DataCenter 4.47", "High Density", "Low Density")]
        $Location,

        [Parameter(Mandatory = $true)]
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
        $PrimaryIPv4,

        [Parameter(Mandatory = $false)]
        [String]
        $AssetTag,

        [Parameter(Mandatory = $false)]
        [Hashtable]
        $CustomFields,

        [Parameter(Mandatory = $false)]
        [Bool]
        $Confirm = $true,

        [Parameter(Mandatory = $false)]
        [Switch]
        $Force
    )

    begin {
        # Test configuration and prepare the API endpoint URL
        Test-Config | Out-Null
        $URL = "/dcim/devices/"
    }

    process {
        # Check if the device already exists
        if ($Name) {
            if (Get-Device -Name $Name -Exact) {
                Write-Warning "Device $Name already exists"
                $Exists = $true
            }
        }

        if ($Slug) {
            if (Get-Device -Slug $Slug) {
                Write-Warning "Device $Slug already exists"
                $Exists = $true
            }
        }

        if ($null -eq $Slug) {
            $Slug
        }
        else {
            $Slug = $Name.tolower() -replace " ", "-"
        }

        # Retrieve device type information
        if ($DeviceTypeName) {
            $DeviceType = Get-DeviceType -Model $DeviceTypeName
        }

        if ($DeviceTypeID) {
            $DeviceType = Get-DeviceType -ID $DeviceTypeID
        }

        if ($null -eq $DeviceType) {
            Write-Error "Device type $($Model) does not exist"
            break
        }

        # Build the request body for the API call
        $Body = @{
            name        = (Get-Culture).Textinfo.ToTitleCase($Name)
            device_type = $DeviceType.ID
            device_role = (Get-DeviceRole -Name $DeviceRole).ID
            site        = (Get-Site -Name $Site).ID
            location    = (Get-Location -Name $Location).ID
            rack        = (Get-Rack -Name $Rack).ID
            position    = $Position
            face        = $Face
            status      = $Status
            asset_tag   = $AssetTag
        }

        # Add custom fields if provided
        if ($CustomFields) {
            $Body.custom_fields = @{}
            foreach ($Key in $CustomFields.Keys) {
                $Body.custom_fields.add($Key, $CustomFields[$Key])
            }
        }

        # Remove empty keys from the request body
       ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

        # Confirm the creation if required
        if ($Confirm) {
            $OutPutObject = [pscustomobject]$Body
            Show-ConfirmDialog -Object $OutPutObject
        }

        # Create the device if it doesn't already exist
        if (-Not $Exists) {
            $Device = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
            $Device.PSObject.TypeNames.Insert(0, "NetBox.Device")
            return $Device
        }
        else {
            return
        }
    }
}
