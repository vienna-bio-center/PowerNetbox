function New-DeviceType {
    <#
     .SYNOPSIS
        Creates a new device type in NetBox.
     .DESCRIPTION
        This function allows you to create a new device type in NetBox by specifying various parameters such as model, manufacturer, height, etc.
     .EXAMPLE
        PS C:\> New-NetboxDeviceType -Model "Cisco Catalyst 2960" -Manufacturer "Cisco" -Height "4"
        Creates a device type "Cisco Catalyst 2960" with height 4 from manufacturer "Cisco" in NetBox.
     .PARAMETER ManufacturerName
        Name of the manufacturer.
     .PARAMETER ManufacturerID
        ID of the manufacturer.
     .PARAMETER Model
        Model of the device type.
     .PARAMETER Slug
        Slug of the device type. If not specified, it will be generated from the model.
     .PARAMETER Height
        Height of the device in U (Units).
     .PARAMETER FullDepth
        Specifies if the device is full-depth. Defaults to true.
     .PARAMETER PartNumber
        Part number of the device.
     .PARAMETER Interface
        Interfaces of the device, as a hashtable.
     .PARAMETER SubDeviceRole
        Subdevice role of the device type, e.g., "parent" or "child".
     .PARAMETER Confirm
        Confirm the creation of the device type.
     .PARAMETER Force
        Force the creation of the device type.
     .INPUTS
        None. You cannot pipe objects to this function.
     .OUTPUTS
        Returns the created NetBox.DeviceType object.
     .NOTES
        This function interacts with the NetBox API to create a new device type.
     #>

    [CmdletBinding(DefaultParameterSetName = "ByName")]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
        [Alias("VendorName")]
        [String]
        $ManufacturerName,

        [Parameter(Mandatory = $true, ParameterSetName = "ByID")]
        [Alias("VendorID")]
        [Int32]
        $ManufacturerID,

        [Parameter(Mandatory = $true)]
        [String]
        [Alias("Name")]
        $Model,

        [Parameter(Mandatory = $false)]
        [String]
        $Slug,

        [Parameter(Mandatory = $false)]
        [String]
        $Height,

        [Parameter(Mandatory = $false)]
        [Bool]
        $FullDepth = $true,

        [Parameter(Mandatory = $false)]
        [String]
        $PartNumber,

        [Parameter(Mandatory = $false)]
        [Hashtable[]]
        $Interfaces,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Parent", "Child")]
        [String]
        $SubDeviceRole,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Fixed", "Modular")]
        [String]
        $InterfaceType,

        [Parameter(Mandatory = $false)]
        [ValidateSet("c14", "c20")]
        [String]
        $PowerSupplyConnector,

        [Parameter(Mandatory = $false)]
        [Hashtable[]]
        $PowerSupplies,

        [Parameter(Mandatory = $false)]
        [Hashtable[]]
        $DeviceBays,

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
        $URL = "/dcim/device-types/"
    }

    process {
        # Check if device type already exists
        if ($Model -and (Get-DeviceType -Model $Model -Exact)) {
            Write-Warning "DeviceType $Model already exists"
            $Exists = $true
        }

        if ($Slug -and (Get-DeviceType -Slug $Slug -Exact)) {
            Write-Warning "DeviceType $Slug already exists"
            $Exists = $true
        }

        # Generate a slug if not provided
        if (-not $Slug) {
            $Slug = $Model.ToLower() -replace " ", "-" -replace "/", "-" -replace ",", "-"
        }

        # Retrieve the manufacturer object
        if ($ManufacturerName) {
            $Manufacturer = Get-Manufacturer -Name $ManufacturerName
        }
        elseif ($ManufacturerID) {
            $Manufacturer = Get-Manufacturer -ID $ManufacturerID
        }

        # Build the request body
        $Body = @{
            manufacturer   = $Manufacturer.ID
            model          = $Model
            slug           = $Slug
            part_number    = $PartNumber
            u_height       = $Height
            is_full_depth  = $FullDepth
            subdevice_role = $SubDeviceRole
        }

        # Remove empty keys from the request body
       ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

        # Confirm creation if requested
        if ($Confirm) {
            $OutPutObject = [pscustomobject]$Body
            Show-ConfirmDialog -Object $OutPutObject
        }

        # Create the device type if it doesn't already exist
        if (-not $Exists) {
            $DeviceType = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
            $DeviceType.PSObject.TypeNames.Insert(0, "NetBox.DeviceType")
            return $DeviceType
        }
        else {
            return
        }
    }
}