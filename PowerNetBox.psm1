function Set-Config {
    param (
        [String]
        $NetboxAPIToken,
        [String]
        $NetboxURL
    )
    $Header = @{
        Authorization = "Token $($NetboxAPIToken)"
    }

    $Script:RestParams = @{
        Headers     = $Header
        ContentType = "application/json"
    }
    $Script:NetboxURL = $NetboxURL.TrimEnd("/")
    Set-Variable -Scope Script -Name NetboxURL
}

function Get-NextPage {
    param (
        $Result
    )
    $CompleteResult = New-Object collections.generic.list[object]
    $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Get

    $CompleteResult = $Result.Results

    do {
        $Result = Invoke-RestMethod -Uri $Result.next @RestParams -Method Get
        $CompleteResult += $Result.Results
    } until ($null -eq $result.next)

    return $CompleteResult
}

function Get-NetBoxInterfaceType {
    param (
        $Linkspeed,
        $InterfaceType
    )

    # Determinte 1GE interface
    if ($Linkspeed -eq "1GE" -and $InterfaceType -eq "fixed") {
        $Type = "1000base-t"
    }
    elseif ($Linkspeed -eq "1GE" -and $InterfaceType -eq "modular") {
        $Type = "1000base-x-sfp"
    }

    # Determinte 10GE interface
    if ($Linkspeed -eq "10GE" -and $InterfaceType -eq "fixed") {
        $Type = "10gbase-t"
    }
    elseif ($Linkspeed -eq "1GE" -and $InterfaceType -eq "modular") {
        $Type = "10gbase-x-sfpp"
    }

    # Determinte 25GE interface
    if ($Linkspeed -eq "25GE" -and $InterfaceType -eq "fixed") {
        $Type = "25gbase-x-sfp28"
    }
    elseif ($Linkspeed -eq "1GE" -and $InterfaceType -eq "modular") {
        $Type = "25gbase-x-sfp28"
    }

    return $Type
}

function Get-Site {
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $Name
    )

    $URL = "/dcim/sites/"
    $Query = "?q=$($Name)"

    $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get

    if ($Result.Count -gt 50) {
        $Result = Get-NextPage -Result $Result
        return $Result
    }
    else {
        return $Result.Results
    }
}

function New-Site {
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
        $Description
    )

    $URL = "/dcim/sites/"

    if ($null -eq $Slug) {
        $Slug
    }
    else {
        $Slug = $Name.tolower() -replace " ", "-"
    }

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

    # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
    ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }


    Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)

}

function Update-Site {
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
        $Description
    )
    FunctionName
}

function Remove-Site {
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $Name
    )

    $URL = "/dcim/sites/"

    $Site = Get-Site -Name $Name

    Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Site.id)) @RestParams -Method Delete

}



function Get-Location {
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $Name
    )

    $URL = "/dcim/locations/"
    $Query = "?q=$($Name)"

    $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get

    if ($Result.Count -gt 50) {
        $Result = Get-NextPage -Result $Result
        return $Result
    }
    else {
        return $Result.Results
    }
}

function New-Location {
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $false)]
        [String]
        $Slug,

        [Parameter(Mandatory = $true)]
        $Site,

        [Parameter(Mandatory = $false)]
        $Parent,

        [Parameter(Mandatory = $false)]
        [String]
        $CustomFields,

        [Parameter(Mandatory = $false)]
        [String]
        $Description
    )

    $URL = "/dcim/locations/"

    if ($null -eq $Slug) {
        $Slug
    }
    else {
        $Slug = $Name.tolower() -replace " ", "-"
    }

    if ($Site -is [String]) {
        $Site = (Get-Site -Name $Site).ID
    }

    if ($Parent -is [String]) {
        $Parent = (Get-Location -Name $Parent).ID
    }

    $Body = @{
        name        = $Name
        slug        = $Slug
        site        = $Site
        parent      = $Parent
        description = $Description
    }

    # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
    ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

    Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)

}



function Get-Rack {
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $Name
    )

    $URL = "/dcim/racks/"
    $Query = "?q=$($Name)"

    $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get

    if ($Result.Count -gt 50) {
        $Result = Get-NextPage -Result $Result
        return $Result
    }
    else {
        return $Result.Results
    }
}


function New-Rack {
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $false)]
        [String]
        $Slug,

        [Parameter(Mandatory = $true)]
        $Site,

        [Parameter(Mandatory = $false)]
        $Location,

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
        $Description
    )

    $URL = "/dcim/racks/"

    if ($null -eq $Slug) {
        $Slug
    }
    else {
        $Slug = $Name.tolower() -replace " ", "-"
    }

    if ($Site -is [String]) {
        $Site = (Get-Site -Name $Site).ID
    }

    if ($Location -is [String]) {
        $Location = (Get-Location -Name $Location).ID
    }

    $Body = @{
        name        = $Name
        slug        = $Slug
        site        = $Site
        location    = $Location
        status      = $Status
        type        = $Type
        width       = $Width
        u_height    = $Height
        description = $Description
    }

    # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
    ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

    Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)

}

function Get-CustomField {
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $Name
    )

    $URL = "/extras/custom-fields/"
    $Query = "?q=$($Name)"

    $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get

    if ($Result.Count -gt 50) {
        $Result = Get-NextPage -Result $Result
        return $Result
    }
    else {
        return $Result.Results
    }
}

function New-CustomField {
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Site", "Location", "Rack", "Device", "Device Role")]
        [String[]]
        $ContentTypes,

        [Parameter(Mandatory = $false)]
        [ValidateSet("text", "integer", "boolean", "date", "url", "select", "multiselect")]
        [String]
        $Type = "4-post-frame",

        [Parameter(Mandatory = $true)]
        [String]
        $Label,

        [Parameter(Mandatory = $false)]
        [Bool]
        $Required,

        [Parameter(Mandatory = $false)]
        [String[]]
        $Choices,

        [Parameter(Mandatory = $false)]
        [String]
        $Description
    )

    $URL = "/extras/custom-fields/"

    $Body = @{
        name        = $Name
        label       = $Label
        type        = $Type
        required    = $Required
        choices     = $Choices
        description = $Description
    }

    # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
    ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

    Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)

}


function Get-ContentType {
    [CmdletBinding(DefaultParameterSetName = "SingleItem")]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "SingleItem")]
        [Parameter(Mandatory = $false, ParameterSetName = "AllItems")]
        [ValidateSet("Site", "Location", "Rack", "Device", "Device Role")]
        [String]
        $Name,

        [Parameter(Mandatory = $false, ParameterSetName = "SingleItem")]
        [Parameter(Mandatory = $true, ParameterSetName = "AllItems")]
        [Switch]
        $All
    )

    $URL = "/extras/content-types/"
    $Query = "?model=$($Name.Replace(' ',''))"
    if ($All) {
        $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Get
    }
    else {
        $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get
    }

    if ($Result.Count -gt 50) {
        $Result = Get-NextPage -Result $Result
        return $Result
    }
    else {
        return $Result.Results
    }
}

function Get-DeviceType {
    [CmdletBinding(DefaultParameterSetName = "ByModel")]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ByModel")]
        [String]
        $Model,

        [Parameter(Mandatory = $true, ParameterSetName = "ByManufacturer")]
        [String]
        $Manufacturer,

        [Parameter(Mandatory = $true, ParameterSetName = "ById")]
        [Int32]
        $Id
    )

    $URL = "/dcim/device-types/"

    if ($Model) {
        $Query = "?model=$($Model)"
    }

    if ($Manufacturer) {
        $Query = "?manufacturer=$($Manufacturer)"
    }
    if ($Id) {
        $Query = "?id=$($id)"
    }

    $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get

    if ($Result.Count -gt 50) {
        $Result = Get-NextPage -Result $Result
        return $Result
    }
    else {
        return $Result.Results
    }
}

function New-DeviceType {
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $Manufacturer,

        [Parameter(Mandatory = $true)]
        [String]
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

        [String]
        [Parameter(Mandatory = $true)]
        [ValidateSet("fixed", "modular")]
        $InterfaceType,

        [String]
        [Parameter(Mandatory = $true)]
        [ValidateSet("c14", "c20")]
        $PowerSupplyConnector,

        [Parameter(Mandatory = $false)]
        [Hashtable[]]
        $PowerSupplies
    )

    $URL = "/dcim/device-types/"

    $Body = @{
        manufacturer  = $Manufacturer
        model         = $Model
        slug          = $Slug
        part_number   = $PartNumber
        u_height      = $Height
        is_full_depth = $FullDepth
        tags          = $Tags
        custum_fields = $CustomFields
    }

    # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
    ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

    $DeviceType = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)

    foreach ($Interface in $Interfaces) {
        $InterfaceBody = [PSCustomObject]@{
            device_type = $DeviceType.ID
            name        = $Interface.ID
            type        = $(Get-NetBoxInterfaceType -Linkspeed $Interface.Linkspeed -InterfaceType $InterfaceType)
            mac_address = $Interface.MacAddress
            mgmt_only   = $Interface.Management
        }
    }
}

function Get-Device {
    [CmdletBinding(DefaultParameterSetName = "Byname")]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
        [String]
        $Name,

        [Parameter(Mandatory = $true, ParameterSetName = "ByModel")]
        [String]
        $Model,

        [Parameter(Mandatory = $true, ParameterSetName = "ByManufacturer")]
        [String]
        $Manufacturer,

        [Parameter(Mandatory = $true, ParameterSetName = "ById")]
        [Int32]
        $Id,

        [Parameter(Mandatory = $true, ParameterSetName = "ByMac")]
        [String]
        $MacAddress

    )
    $URL = "/dcim/devices/"

    if ($name) {
        $Query = "?name=$($Name)"
    }

    if ($Model) {
        $Query = "?model=$($Model)"
    }

    if ($Manufacturer) {
        $Query = "?manufacturer=$($Manufacturer)"
    }
    if ($Id) {
        $Query = "?id=$($id)"
    }
    if ($MacAddress) {
        $Query = "?mac_address$($MacAddress)"
    }

    $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get

    if ($Result.Count -gt 50) {
        $Result = Get-NextPage -Result $Result
        return $Result
    }
    else {
        return $Result.Results
    }

}

function New-Device {
    param (

        [String]
        [Parameter(Mandatory = $true)]
        $Manufacturer,

        [String]
        [Parameter(Mandatory = $true, ParameterSetName = "ByParameter")]
        $Model,

        [String]
        [Parameter(ParameterSetName = "ByParameter")]
        $PartNumber,

        [String]
        [Parameter(ParameterSetName = "ByParameter")]
        $AssetTag,

        [Array]
        [Parameter(Mandatory = $true, ParameterSetName = "ByParameter")]
        $Interfaces,

        [String]
        [Parameter(Mandatory = $true)]
        [ValidateSet("fixed", "modular")]
        $InterfaceType,

        [Array]
        [Parameter(Mandatory = $true, ParameterSetName = "ByParameter")]
        $PowerSupplies,

        [String]
        [Parameter(Mandatory = $true)]
        [ValidateSet("c14", "c20")]
        $PowerSupplyConnector,

        [String]
        [Parameter(Mandatory = $true)]
        [ValidateSet("DataCenter 4.47", "High Density", "Low Density")]
        $Location,

        [String]
        [Parameter(Mandatory = $true)]
        $Rack,

        [String]
        [Parameter(Mandatory = $true)]
        $Position,

        [String]
        [Parameter(Mandatory = $true)]
        $Height,

        [String]
        [Parameter(Mandatory = $true)]
        $Hostname,

        [String]
        [Parameter(Mandatory = $true)]
        [ValidateSet("Server", "Switch", "Leafswitch")]
        $DeviceRole,

        [String]
        [ValidateSet("front", "back")]
        $Face = "front",

        [String]
        [ValidateSet("offline", "active", "planned", "staged", "failed", "inventory", "decommissioning")]
        $Status = "active",

        [Hashtable]
        [Parameter(Mandatory = $false)]
        $CustomFields
    )

    $URL = "/dcim/devices/"

    if ($null -eq $Slug) {
        $Slug
    }
    else {
        $Slug = $Name.tolower() -replace " ", "-"
    }


    $Body = @{
        manufacturer  = $Manufacturer
        model         = $Model
        slug          = $Slug
        part_number   = $PartNumber
        u_height      = $Height
        is_full_depth = $FullDepth
        tags          = $Tags
        custum_fields = $CustomFields
    }

    name          = $Name
    device_type   = Get-DeviceType
    device_role   = ((Invoke-RestMethod -Uri "$NetBoxAPI/dcim/device-roles/?q=$($DeviceRole)" @RestParams).Results).ID
    site          = ((Invoke-RestMethod -Uri "$NetBoxAPI/dcim/sites/?q=$($Site)" @RestParams).Results).ID
    location      = ((Invoke-RestMethod -Uri "$NetBoxAPI/dcim/locations/?q=$($Location)" @RestParams).Results).ID
    rack          = ((Invoke-RestMethod -Uri "$NetBoxAPI/dcim/racks/?q=$($Rack)" @RestParams).Results).ID
    position      = $Position
    face          = $Face
    status        = $Status
    asset_tag     = $AssetTag
    custom_fields = @{
        LOM = $LOM
    }

    # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
        ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

    Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)


}
