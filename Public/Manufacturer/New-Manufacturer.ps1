function New-Manufacturer {
    <#
    .SYNOPSIS
       Creates a new manufacturer in NetBox.
    .DESCRIPTION
       Adds a new manufacturer entry to NetBox with the specified parameters.
    .EXAMPLE
       PS C:\> New-NetBoxManufacturer -Name Dell
       Creates manufacturer "Dell" in NetBox.
    .PARAMETER Name
       Name of the new manufacturer.
    .PARAMETER Slug
       Slug of the manufacturer. If not specified, it will be generated from the name.
    .PARAMETER Confirm
       If set to true, prompts for confirmation before creation.
     .PARAMETER Force
       Forces creation of the manufacturer, even if it already exists.
    .INPUTS
       None.
    .OUTPUTS
       NetBox.Manufacturer
    .NOTES
       Adds a new manufacturer to NetBox using the specified parameters.
    #>

    param (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $false)]
        [String]
        $Slug,

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
        $URL = "/dcim/manufacturers/"
    }

    process {
        # Check if the manufacturer already exists by name or slug
        if ($Name) {
            if (Get-Manufacturer -Name $Name) {
                Write-Warning "Manufacturer $Name already exists"
                if ($Force) {
                    $Exists = $true
                }
                else {
                    return
                }
            }
        }
        if ($Slug) {
            if (Get-Manufacturer -Slug $Slug) {
                Write-Warning "Manufacturer $Slug already exists"
                if ($Force) {
                    $Exists = $true
                }
                else {
                    return
                }
            }
        }

        # Generate a slug if not provided
        if ($null -eq $Slug) {
            $Slug
        }
        else {
            $Slug = $Name.tolower() -replace " ", "-"
        }

        # Prepare the body for the API request
        $Body = @{
            name          = (Get-Culture).Textinfo.ToTitleCase($Name)
            slug          = $Slug
            custum_fields = $CustomFields
        }

        # Remove empty keys from the body
       ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

        # Show confirmation dialog if required
        if ($Confirm) {
            $OutPutObject = [pscustomobject]$Body
            Show-ConfirmDialog -Object $OutPutObject
        }

        # Create the manufacturer if it doesn't already exist
        if (-Not $Exists) {
            $Manufacturer = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
            $Manufacturer.PSObject.TypeNames.Insert(0, "NetBox.Manufacturer")
            return $Manufacturer
        }
        else {
            return
        }
    }
}