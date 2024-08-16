
function New-Rack {
    <#
     .SYNOPSIS
        Creates a new rack in NetBox.
     .DESCRIPTION
        Adds a new rack entry to NetBox with the specified parameters.
     .EXAMPLE
        PS C:\> New-NetBoxRack -Name "T-12" -Location "High Density" -Site VBC
        Creates rack "T-12" in location "High Density" at site VBC.
     .PARAMETER Name
        Name of the new rack.
     .PARAMETER Slug
        Slug of the rack. If not specified, it will be generated from the name.
     .PARAMETER SiteName
        Name of the site where the rack is located.
     .PARAMETER SiteID
        ID of the site where the rack is located.
     .PARAMETER LocationName
        Name of the location where the rack is located.
     .PARAMETER LocationID
        ID of the location where the rack is located.
     .PARAMETER Status
        Status of the rack, default is "active".
     .PARAMETER Type
        Type of the rack, default is "4-post-frame".
     .PARAMETER Width
        Width of the rack in inches, default is 19.
     .PARAMETER Height
        Height of the rack in U (Units), default is 42.
     .PARAMETER Description
        Description of the rack.
     .PARAMETER CustomFields
        Custom fields for the rack.
     .PARAMETER Confirm
        If set to true, prompts for confirmation before creation.
     .PARAMETER Force
        Forces creation of the rack, even if it already exists.
     .INPUTS
        None.
     .OUTPUTS
        NetBox.Rack
     .NOTES
        Adds a new rack to NetBox using the specified parameters.
     #>
    [CmdletBinding(DefaultParameterSetName = "ByName")]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $false)]
        [String]
        $Slug,

        [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
        [String]
        $SiteName,

        [Parameter(Mandatory = $true, ParameterSetName = "ByID")]
        [Int32]
        $SiteID,

        [Parameter(Mandatory = $false)]
        [String]
        $LocationName,

        [Parameter(Mandatory = $false)]
        [Int32]
        $LocationID,

        [Parameter(Mandatory = $false)]
        [ValidateSet("offline", "active", "planned", "staged", "failed", "inventory", "decommissioning")]
        [String]
        $Status = "active",

        [Parameter(Mandatory = $false)]
        [ValidateSet("2-post-frame", "4-post-frame", "4-post-cabinet", "wall-frame", "wall-cabinet")]
        [String]
        $Type = "4-post-frame",

        [Parameter(Mandatory = $false)]
        [ValidateSet(10, 19, 21, 23)]
        [Int32]
        $Width = 19,

        [Parameter(Mandatory = $false)]
        [Int32]
        $Height = 42,

        [Parameter(Mandatory = $false)]
        [String]
        $CustomFields,

        [Parameter(Mandatory = $false)]
        [String]
        $Description,

        [Parameter(Mandatory = $false)]
        [Bool]
        $Confirm = $true,

        [Parameter(Mandatory = $false)]
        [Switch]
        $Force
    )

    begin {
        # Verify configuration and initialize API endpoint
        Test-Config | Out-Null
        $URL = "/dcim/racks/"
    }

    process {
        # Check if the rack already exists by name or slug
        if ($Name) {
            if (Get-Rack -Name $Name) {
                Write-Warning "Rack $Name already exists"
                $Exists = $true
            }
        }
        if ($Slug) {
            if (Get-Rack -Slug $Slug) {
                Write-Warning "Rack $Slug already exists"
                $Exists = $true
            }
        }

        # Generate a slug if not provided
        if ($null -eq $Slug) {
            $Slug
        }
        else {
            $Slug = $Name.tolower() -replace " ", "-"
        }

        # Get the Site and Location objects
        if ($SiteName) {
            $Site = Get-Site -Name $SiteName
        }

        if ($SiteID) {
            $Site = Get-Site -Id $SiteID
        }

        if ($LocationName) {
            $Location = Get-Location -Name $Location
        }

        if ($LocationID) {
            $Location = Get-Location -ID $LocationID
        }

        # Prepare the body for the API request
        $Body = @{
            name        = (Get-Culture).Textinfo.ToTitleCase($Name)
            slug        = $Slug
            site        = $Site.ID
            location    = $Location.ID
            status      = $Status
            type        = $Type
            width       = $Width
            u_height    = $Height
            description = $Description
        }

        # Remove empty keys from the body
       ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

        # Show confirmation dialog if required
        if ($Confirm) {
            $OutPutObject = [pscustomobject]$Body
            Show-ConfirmDialog -Object $OutPutObject
        }

        # Create the rack if it doesn't already exist
        if (-Not $Exists) {
            $Rack = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
            $Rack.PSObject.TypeNames.Insert(0, "NetBox.Rack")
            return $Rack
        }
        else {
            return
        }
    }
}