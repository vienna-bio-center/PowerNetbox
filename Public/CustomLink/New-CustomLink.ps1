function New-CustomLink {
    <#
    .SYNOPSIS
       Creates a new custom link in NetBox.
    .DESCRIPTION
       This function creates a new custom link in NetBox using the provided parameters.
    .EXAMPLE
       PS C:\> New-CustomLink -Name "ServiceCatalogID" -LinkText "View Service Catalog" -LinkURL "http://example.com" -ContentType "Device"
       Creates a new custom link named "ServiceCatalogID" for the "Device" content type.
    .PARAMETER Name
       The name of the custom link to create.
    .PARAMETER LinkText
       The text displayed for the custom link.
    .PARAMETER LinkURL
       The URL that the custom link points to.
    .PARAMETER ContentType
       The content type that the custom link is associated with (e.g., "Device").
    .PARAMETER Weight
       The display order of the custom link (lower numbers appear first).
    .PARAMETER GroupName
       The group name of the custom link; links with the same group name are displayed as a dropdown.
    .PARAMETER ButtonClass
       The color class of the link button.
    .PARAMETER NewWindow
       If true, the link opens in a new window (default is true).
    .PARAMETER Confirm
       If specified, prompts the user for confirmation before creating the custom link.
    .PARAMETER Force
       Forces the creation of the custom link even if one already exists with the same name.
    .INPUTS
       None. This function does not accept piped input.
    .OUTPUTS
       NetBox.CustomLink. Returns the created custom link.
    .NOTES
       Ensure that the content type specified exists in NetBox before creating the custom link.
    #>

    param (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Site", "Location", "Rack", "Device", "Device Role")]
        [String]
        $ContentType,

        [Parameter(Mandatory = $true)]
        [String]
        $LinkText,

        [Parameter(Mandatory = $true)]
        [String]
        $LinkURL,

        [Parameter(Mandatory = $false)]
        [Int32]
        $Weight,

        [Parameter(Mandatory = $false)]
        [String]
        $GroupName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("outline-dark", "ghost-dark", "blue", "indigo", "purple", "pink", "red", "orange", "yellow", "green", "teal", "cyan", "secondary")]
        [String]
        $ButtonClass,

        [Parameter(Mandatory = $false)]
        [Bool]
        $NewWindow = $true,

        [Parameter(Mandatory = $false)]
        [Bool]
        $Confirm = $true,

        [Parameter(Mandatory = $false)]
        [Switch]
        $Force
    )

    begin {
        Test-Config | Out-Null
        $URL = "/extras/custom-links/"
    }

    process {
        if ($(Get-CustomLink -Name $Name )) {
            Write-Warning "CustomLink $Name already exists"
            $Exists = $true
        }

        $NetBoxContentType = "$((Get-ContentType -Name $ContentType).app_label).$((Get-ContentType -Name $ContentType).model)"

        $Body = @{
            name         = (Get-Culture).Textinfo.ToTitleCase($Name)
            link_text    = $LinkText
            link_url     = $LinkURL
            weight       = $Weight
            group_name   = $GroupName
            button_class = $ButtonClass
            new_window   = $NewWindow
            content_type = $NetBoxContentType
        }

        # Remove empty keys
       ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

        if ($Confirm) {
            $OutPutObject = [pscustomobject]$Body
            Show-ConfirmDialog -Object $OutPutObject
        }

        if (-Not $Exists) {
            $CustomLink = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
            $CustomLink.PSObject.TypeNames.Insert(0, "NetBox.CustomLink")
            return $CustomLink
        }
        else {
            return
        }
    }
}
