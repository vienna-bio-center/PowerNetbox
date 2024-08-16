function New-Site {
    <#
     .SYNOPSIS
        Creates a new site in NetBox.
     .DESCRIPTION
        Creates a new site in NetBox with specified parameters like name, slug, status, region, etc.
     .EXAMPLE
        PS C:\> New-NetBoxSite -Name vbc
        Creates a new site vbc.
     .PARAMETER Name
        Name of the site.
     .PARAMETER Slug
        Slug of the site; if not specified, it will be generated from the name.
     .PARAMETER Status
        Status of the site, active by default.
     .PARAMETER Region
        Region of the site.
     .PARAMETER Group
        Group of the site.
     .PARAMETER CustomFields
        Custom fields of the site.
     .PARAMETER Tenant
        Tenant of the site.
     .PARAMETER Comment
        Comment of the site.
     .PARAMETER Tags
        Tags of the site.
     .PARAMETER TagColor
        Tag color of the site.
     .PARAMETER Description
        Description of the site.
     .PARAMETER Confirm
        Confirm the creation of the site.
     .PARAMETER Force
        Force the creation of the site.
     .INPUTS
        None
     .OUTPUTS
        NetBox.Site
     .NOTES
        Adds a new site entry in NetBox.
     #>

    param (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $false)]
        [String]
        $Slug,

        [Parameter(Mandatory = $false)]
        [ValidateSet("offline", "active", "planned", "staged", "failed", "inventory", "decommissioning")]
        [String]
        $Status = "active",

        [Parameter(Mandatory = $false)]
        [String]
        $Region,

        [Parameter(Mandatory = $false)]
        [String]
        $Group,

        [Parameter(Mandatory = $false)]
        [String]
        $Tenant,

        [Parameter(Mandatory = $false)]
        [String]
        $CustomFields,

        [Parameter(Mandatory = $false)]
        [String]
        $Comment,

        [Parameter(Mandatory = $false)]
        [String]
        $Tags,

        [Parameter(Mandatory = $false)]
        [String]
        $TagColor,

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
        $URL = "/dcim/sites/"
    }

    process {
        # Check if the site already exists by name or slug
        if ($Name) {
            if (Get-Site -Name $Name) {
                Write-Warning "Site $Name already exists"
                $Exists = $true
            }
        }
        if ($Slug) {
            if (Get-Site -Slug $Slug) {
                Write-Warning "Site $Slug already exists"
                $Exists = $true
            }
        }

        # Generate a slug if it wasn't provided
        if ($null -eq $Slug) {
            $Slug = $Name.tolower() -replace " ", "-"
        }

        # Prepare the body for the API request
        $Body = @{
            name        = $Name
            slug        = $Slug
            status      = $Status
            region      = $Region
            group       = $Group
            tenant      = $Tenant
            comment     = $Comment
            description = $Description
        }

        # Remove empty keys from the body
       ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

        # Show confirmation dialog if required
        if ($Confirm) {
            $OutPutObject = [pscustomobject]$Body
            Show-ConfirmDialog -Object $OutPutObject
        }

        # Create the site if it doesn't already exist
        if (-Not $Exists) {
            $Site = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
            $Site.PSObject.TypeNames.Insert(0, "NetBox.Site")
            return $Site
        }
        else {
            return
        }
    }
}
