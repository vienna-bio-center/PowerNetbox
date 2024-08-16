function New-Location {
    <#
     .SYNOPSIS
        Creates a location in NetBox.
     .DESCRIPTION
        Creates a new location in NetBox with specified parameters like name, slug, site, etc.
     .EXAMPLE
        PS C:\> New-NetBoxLocation -Parent IMP -Site VBC -Name "Low Density"
        Creates a new location Low Density as a child of IMP in site VBC.
     .PARAMETER Name
        Name of the location.
     .PARAMETER Slug
        Slug of the location; if not specified, it will be generated from the name.
     .PARAMETER SiteName
        Name of the Site of the location.
     .PARAMETER SiteID
        ID of the Site of the location.
     .PARAMETER Parent
        Parent of the location.
     .PARAMETER CustomFields
        Custom fields of the location.
     .PARAMETER Comment
        Comment for the location.
     .PARAMETER Description
        Description of the location.
     .PARAMETER Confirm
        Confirm the creation of the location.
     .PARAMETER Force
        Force the creation of the location.
     .INPUTS
        None
     .OUTPUTS
        NetBox.Location
     .NOTES
        Adds a new location entry in NetBox.
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
        $Parent,

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
        Test-Config | Out-Null
        $URL = "/dcim/locations/"
    }

    process {
        # Check if the location already exists by name or slug
        if ($Name) {
            if (Get-Location -Name $Name) {
                Write-Warning "Location $Name already exists"
                $Exists = $true
            }
        }
        if ($Slug) {
            if (Get-Location -Slug $Slug) {
                Write-Warning "Location $Slug already exists"
                $Exists = $true
            }
        }

        # Generate a slug if it wasn't provided
        if ($null -eq $Slug) {
            $Slug = $Name.tolower() -replace " ", "-"
        }

        # Retrieve the site object by name or ID
        if ($SiteName) {
            $Site = Get-Site -Name $SiteName
        }

        if ($SiteID) {
            $Site = Get-Site -Id $SiteID
        }

        # Convert parent location name to ID if it is a string
        if ($Parent -is [String]) {
            $Parent = (Get-Location -Name $Parent).ID
        }

        # Prepare the body for the API request
        $Body = @{
            name        = (Get-Culture).Textinfo.ToTitleCase($Name)
            slug        = $Slug
            site        = $Site.ID
            parent      = $Parent
            description = $Description
        }

        # Remove empty keys from the body
       ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

        # Show confirmation dialog if required
        if ($Confirm) {
            $OutPutObject = [pscustomobject]$Body
            Show-ConfirmDialog -Object $OutPutObject
        }

        # Create the location if it doesn't already exist
        if (-Not $Exists) {
            $Location = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
            $Location.PSObject.TypeNames.Insert(0, "NetBox.Location")
            return $Location
        }
        else {
            return
        }
    }
}