function Set-Config {
   <#
   .SYNOPSIS
      Required to use PowerNetBox, sets up URL and APIToken for connection
   .DESCRIPTION
      Long description
   .EXAMPLE
      PS C:\> Set-NetBoxConfig -NetboxURL "https://netbox.example.com" -NetboxAPIToken "1277db26a31232132327265bd13221309a567fb67bf"
      Sets up NetBox from https://netbox.example.com with APIToken 1277db26a31232132327265bd13221309a567fb67bf
   .PARAMETER NetboxAPIToken
      APIToken to access NetBox found under "Profiles & Settings" -> "API Tokens" tab
   .PARAMETER NetboxURL
      URL from Netbox, must be https
   #>

   param (
      [String]
      $NetboxAPIToken,

      [String]
      [ValidatePattern ("^(https:\/\/).+")]
      $NetboxURL
   )
   $Header = @{
      Authorization = "Token $($NetboxAPIToken)"
   }

   $Script:RestParams = @{
      Headers       = $Header
      ContentType   = "application/json"
      ErrorVariable = "RestError"
   }
   $Script:NetboxURL = $NetboxURL.TrimEnd("/")
   Set-Variable -Scope Script -Name NetboxURL
   Set-Variable -Scope Script -Name NetboxAPIToken

   # Add /api if not already provided
   if ($NetboxURL -notlike "*api*" ) {
      $Script:NetboxURL = $NetboxURL + "/api"
   }
}

function Test-Config {
   <#
   .SYNOPSIS
      For internal use, checks if NetBox URL and APIToken are set
   .DESCRIPTION
      Long description
   .EXAMPLE
      PS C:\> Test-Config | Out-Null
      Explanation of what the example does
   #>

   if (-not $(Get-Variable -Name NetboxURL) -or -not $(Get-Variable -Name NetboxAPIToken) ) {
      Write-Error "NetboxAPIToken and NetboxURL must be set before calling this function"
      break
   }

}

function Get-NextPage {
   <#
    .SYNOPSIS
       For internal use, gets the next page of results from NetBox
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> Get-NextPage -Result $Result
       Retrieves all items from API call and return them in $CompleteResult
    .PARAMETER Result
       Result from previous API call
    #>

   param (
      [Parameter(Mandatory = $true)]
      $Result
   )
   $CompleteResult = New-Object collections.generic.list[object]

   $CompleteResult += $Result.Results

   if ($null -ne $result.next) {
      do {
         $Result = Invoke-RestMethod -Uri $Result.next @RestParams -Method Get
         $CompleteResult += $Result.Results
      } until ($null -eq $result.next)
   }
   return $CompleteResult
}

function Get-RelatedObjects {
   <#
   .SYNOPSIS
      For internal use, Gets all related objects from NetBox object
   .DESCRIPTION
      Long description
   .EXAMPLE
      PS C:\> <example usage>
      Explanation of what the example does
   .PARAMETER Name
      The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
   .INPUTS
      Inputs (if any)
   .OUTPUTS
      Output (if any)
   .NOTES
      General notes
   #>
   param (
      [Parameter(Mandatory = $true)]
      $Object,

      [Parameter(Mandatory = $true)]
      $ReferenceObjects
   )

   $RelatedObjects = New-Object collections.generic.list[object]

   $RelatedTypes = $Object.PSobject.Properties.name -match "_count"
   foreach ($Type in $RelatedTypes) {
      if ($object.$Type -gt 0) {
         # Determinte between Models and Names
         if ($ReferenceObjects -eq "devicetype") {
            $RelatedObjects += Invoke-Expression "Get-$($Type.TrimEnd("_count")) -Model $($Object.Model)"
         }
         else {
            $RelatedObjects += Invoke-Expression "Get-$($Type.TrimEnd("_count")) -$($ReferenceObjects) '$($Object.Name)'"
         }
      }
   }

   return $RelatedObjects

   # Get referenced objects from errormessage
   $ReferenceObjects = ($ErrorMessage.ErrorRecord | ConvertFrom-Json).Detail.split(":")[1].Split(",")

   # Trim whitespaces from errormessage
   foreach ($Object in $ReferenceObjects) {
      $Object = $Object.Substring(0, $Object.Length - 3).Substring(1)
   }
   return $ReferenceObjects
}

function Show-ConfirmDialog {
   <#
   .SYNOPSIS
      For interal use, Shows a confirmation dialog before executing the command
   .DESCRIPTION
      Long description
   .EXAMPLE
      PS C:\> <example usage>
      Explanation of what the example does
   .PARAMETER Name
      The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
   .INPUTS
      Inputs (if any)
   .OUTPUTS
      Output (if any)
   .NOTES
      General notes
   #>

   param (
      [Parameter(Mandatory = $true)]
      $Object
   )

   "Device Model:"
   $Object | Format-List

   $Title = "New Object Creation"
   $Question = "Are you sure you want to create this object?"

   $Choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
   $Choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList "&Yes"))
   $Choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList "&No"))

   $Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, 1)
   if ($Decision -ne 0) {
      Write-Error "Canceled by User"
      break
   }
}

function Get-InterfaceType {
   <#
    .SYNOPSIS
       Determine the interface type of a device based on linkspeed and connection type
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> Get-NetBoxInterfaceType -Linkspeed 10GE -InterfaceType sfp
       Returns the Netbox interface Type for a 10GBit\s SFP interface
    .PARAMETER Linkspeed
       Speed auf the interface in gigabit/s e.g. 10GE
    .PARAMETER InterfaceType
       Type of the connector e.g. sfp or RJ45 or just fixed / modular
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       NetBox.InterfaceType
    .NOTES
       General notes
    #>

   param (
      [Parameter(Mandatory = $true)]
      $Linkspeed,

      [Parameter(Mandatory = $false)]
      [ValidateSet("Fixed", "Modular", "RJ45", "SFP")]
      $InterfaceType
   )


   # "GE" to Linkspeed if missing
   if ($Linkspeed -notlike "*GE") {
      $Linkspeed = $Linkspeed + "GE"
   }

   # Map aliases
   if ($InterfaceType -eq "SFP") {
      $InterfaceType = "Modular"
   }

   if ($InterfaceType -eq "RJ45") {
      $InterfaceType = "Fixed"
   }

   # Determinte 1GE interface
   if ($Linkspeed -eq "1GE" -and $InterfaceType -eq "Fixed") {
      $Type = "1000base-t"
   }
   elseif ($Linkspeed -eq "1GE" -and $InterfaceType -eq "Modular") {
      $Type = "1000base-x-sfp"
   }

   # Determinte 10GE interface
   if ($Linkspeed -eq "10GE" -and $InterfaceType -eq "Fixed") {
      $Type = "10gbase-t"
   }
   elseif ($Linkspeed -eq "10GE" -and $InterfaceType -eq "Modular") {
      $Type = "10gbase-x-sfpp"
   }

   # Determinte 25GE interface
   if ($Linkspeed -eq "25GE") {
      $Type = "25gbase-x-sfp28"
   }

   # Determinte 40GE interface
   if ($Linkspeed -eq "40GE") {
      $Type = "40gbase-x-qsfpp"
   }

   # Determinte 100GE interface
   if ($Linkspeed -eq "100GE") {
      $Type = "100gbase-x-qsfp28"
   }

   $Type.PSObject.TypeNames.Insert(0, "NetBox.InterfaceType")

   return $Type
}

function Get-Site {
   <#
    .SYNOPSIS
       Retrieves a site from NetBox
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> Get-NetBoxSite -Name VBC
       Returns the Netbox site VBC
    .PARAMETER Name
       Search for a site by name
    .PARAMETER Id
       Search for a site by ID
    .PARAMETER Slug
       Search for a site by slug
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       NetBox.Site
    .NOTES
       General notes
    #>

   param (
      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Name,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Slug
   )

   begin {
      Test-Config | Out-Null
      $URL = "/dcim/sites/"
   }
   process {
      $Query = "?"

      if ($name) {
         $Query = $Query + "name__ic=$($Name)&"
      }

      if ($Id) {
         $Query = $Query + "id=$($id)&"
      }

      if ($Slug) {
         $Query = $Query + "slug__ic=$($Slug)"
      }

      $Query = $Query.TrimEnd("&")

      $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

      $Sites = New-Object collections.generic.list[object]

      foreach ($Item in $Result) {
         [PSCustomObject]$Site = $item
         $Site.PSObject.TypeNames.Insert(0, "NetBox.Site")
         $Sites += $Site
      }

      return $Sites
   }
}

function New-Site {
   <#
    .SYNOPSIS
       Creates a new site in NetBox
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> New-NetBoxSite -Name vbc
       Creates a new site vbc
    .PARAMETER Name
       Name of the site
    .PARAMETER Slug
      Slug of the site, if not specified, it will be generated from the name
    .PARAMETER Status
      Status of the site, active by default
    .PARAMETER Region
      Region of the site
    .PARAMETER Group
      Group of the site
    .PARAMETER CustomFields
      Custom fields of the site
    .PARAMETER Tenant
      Tenant of the site
    .PARAMETER Comment
      Comment of the site
    .PARAMETER Tags
      Tags of the site
    .PARAMETER TagColor
      Tag color of the site
    .PARAMETER Description
      Descripion of the site
    .PARAMETER Confirm
      Confirm the creation of the site
    .PARAMETER Force
      Force the creation of the site
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       NetBox.Site
    .NOTES
       General notes
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

      if ($Confirm) {
         $OutPutObject = [pscustomobject]$Body
         Show-ConfirmDialog -Object $OutPutObject
      }

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

function Update-Site {
   <#
    .SYNOPSIS
       Updates a site in NetBox
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> <example usage>
       Explanation of what the example does
    .PARAMETER Name
       The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       Output (if any)
    .NOTES
       General notes
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
      $Description
   )
   FunctionName
}

function Remove-Site {
   <#
    .SYNOPSIS
       Deletes a site in NetBox
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> Remove-NetBoxSite -Name vbc -Recurse
       Deletes a site vbc and all related objects
    .PARAMETER Name
       Name of the site
    .PARAMETER ID
       ID of the site
    .PARAMETER Recurse
       Deletes all related objects as well
    .PARAMETER Confirm
      Confirm the creation of the site
    .PARAMETER InputObject
      Site object to delete
    .INPUTS
       Netbox Site Object
    .OUTPUTS
       Output (if any)
    .NOTES
       General notes
    #>

   [CmdletBinding(DefaultParameterSetName = "ByName")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $Name,

      [Parameter(Mandatory = $true, ParameterSetName = "ByID")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $false)]
      [Switch]
      $Recurse,

      [Parameter(Mandatory = $false)]
      [Bool]
      $Confirm = $true,

      [Parameter(ValueFromPipeline = $true, ParameterSetName = 'ByInputObject')]
      $InputObject
   )

   begin {
      Test-Config | Out-Null
      $URL = "/dcim/sites/"
   }

   process {
      if (-not ($InputObject.psobject.TypeNames -contains "NetBox.Site")) {
         Write-Error "InputObject is not type NetBox.Site"
         break
      }

      if ($InputObject) {
         $Name = $InputObject.name
         $Id = $InputObject.Id
      }

      if ($Id) {
         $Site = Get-Site -ID $Id
      }
      else {
         $Site = Get-Site -Name $Name
      }

      $RelatedObjects = Get-RelatedObjects -Object $Site -ReferenceObjects Site

      if ($Confirm) {
         Show-ConfirmDialog -Object $Site
      }

      # Remove all related objects
      if ($Recurse) {
         foreach ($Object in $RelatedObjects) {
            Invoke-RestMethod -Uri $Object.url @RestParams -Method Delete | Out-Null
         }
      }

      try {
         Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Site.id) + "/") @RestParams -Method Delete
      }
      catch {
         if ((($RestError.ErrorRecord) | ConvertFrom-Json).Detail -like "Unable to delete object*") {
            Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
            Write-Error "Delete those objects first or run again using -recurse switch"
         }
         else {
            Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
         }

      }
   }
}

function Get-Location {
   <#
    .SYNOPSIS
       Retrieves a location in NetBox
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> Get-NetBoxLocation -Name "Low Density"
       Retrieves the location Low Density
    .PARAMETER Name
       Name of the location
    .PARAMETER ID
       ID of the location
    .PARAMETER Slug
       Search for a location by slug
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       NetBox.Location
    .NOTES
       General notes
    #>

   param (
      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Name,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Slug
   )

   begin {
      Test-Config | Out-Null
      $URL = "/dcim/locations/"
   }

   process {
      $Query = "?"

      # If name contains spaces, use slug instead
      if ($Name -like " ") {
         $Slug = $Name.tolower() -replace " ", "-"
         $Query = $Query + "slug__ic=$($Slug)&"
      }
      else {
         $Query = $Query + "name__ic=$($Name)&"
      }

      if ($Slug) {
         $Query = $Query + "slug__ic=$($Slug)&"
      }

      $Query = $Query.TrimEnd("&")

      $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

      $Locations = New-Object collections.generic.list[object]

      foreach ($Item in $Result) {
         [PSCustomObject]$Location = $item
         $Location.PSObject.TypeNames.Insert(0, "NetBox.Location")
         $Locations += $Location
      }

      return $Locations
   }
}

function New-Location {
   <#
    .SYNOPSIS
       Creates a location in NetBox
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> New-NetBoxLocation -Parent IMP -Site VBC -Name "Low Densitity"
       Creates a new location Low Densitity as a child of IMP in site VBC
    .PARAMETER Name
         Name of the location
    .PARAMETER Slug
         Slug of the location, if not specified, it will be generated from the name
    .PARAMETER SiteName
         Name of the Site of the location
    .PARAMETER SiteID
         ID of the Site of the location
    .PARAMETER Parent
         Parent of the location
    .PARAMETER CustomFields
         Custom fields of the location
    .PARAMETER Comment
         Comment for location
    .PARAMETER Description
         Description of the location
    .PARAMETER Confirm
         Confirm the creation of the location
    .PARAMETER Force
         Force the creation of the location
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       NetBox.Location
    .NOTES
       General notes
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

      if ($null -eq $Slug) {
         $Slug
      }
      else {
         $Slug = $Name.tolower() -replace " ", "-"
      }

      if ($SiteName) {
         $Site = Get-Site -Name $SiteName
      }

      if ($SiteID) {
         $Site = Get-Site -Id $SiteID
      }

      if ($Parent -is [String]) {
         $Parent = (Get-Location -Name $Parent).ID
      }

      $Body = @{
         name        = (Get-Culture).Textinfo.ToTitleCase($Name)
         slug        = $Slug
         site        = $Site.ID
         parent      = $Parent
         description = $Description
      }

      # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
   ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

      if ($Confirm) {
         $OutPutObject = [pscustomobject]$Body
         Show-ConfirmDialog -Object $OutPutObject
      }

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

function Remove-Location {
   <#
   .SYNOPSIS
      Deletes a location in NetBox
   .DESCRIPTION
      Long description
   .EXAMPLE
      PS C:\> Remove-NetBoxLocation -Name "High Density"
      Deletes the location High Density
    .PARAMETER Name
       Name of the location
    .PARAMETER ID
       ID of the location
    .PARAMETER Recurse
       Deletes all related objects as well
    .PARAMETER Confirm
      Confirm the creation of the location
    .PARAMETER InputObject
      Location object to delete
   .INPUTS
      NetBox.Location
   .OUTPUTS
      Output (if any)
   .NOTES
      General notes
   #>

   [CmdletBinding(DefaultParameterSetName = "ByName")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $Name,

      [Parameter(Mandatory = $true, ParameterSetName = "ByID")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $false)]
      [Switch]
      $Recurse,

      [Parameter(Mandatory = $false)]
      [Bool]
      $Confirm = $true,

      [Parameter(ValueFromPipeline = $true, ParameterSetName = 'ByInputObject')]
      $InputObject
   )

   begin {
      Test-Config | Out-Null
      $URL = "/dcim/locations/"
   }

   process {
      if (-not ($InputObject.psobject.TypeNames -contains "NetBox.Location")) {
         Write-Error "InputObject is not type NetBox.Location"
         break
      }

      if ($InputObject) {
         $Name = $InputObject.name
         $Id = $InputObject.Id
      }

      if ($ID) {
         $Location = Get-Location -Id $Id
      }
      else {
         $Location = Get-Location -Name $Name
      }

      $RelatedObjects = Get-RelatedObjects -Object $Site -ReferenceObjects Location

      if ($Confirm) {
         Show-ConfirmDialog -Object $Location
      }

      # Remove all related objects
      if ($Recurse) {
         foreach ($Object in $RelatedObjects) {
            Invoke-RestMethod -Uri $Object.url @RestParams -Method Delete | Out-Null
         }
      }

      try {
         Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Location.id) + "/") @RestParams -Method Delete
      }
      catch {
         if ((($RestError.ErrorRecord) | ConvertFrom-Json).Detail -like "Unable to delete object*") {
            Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
            Write-Error "Delete those objects first or run again using -recurse switch"
         }
         else {
            Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
         }

      }
   }

}

function Get-Rack {
   <#
    .SYNOPSIS
       Retrives a rack from NetBox
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> Get-NetBoxRack -Location "High Density"
       Retrives all racks from High Density location
    .PARAMETER Name
       Name of the rack
    .PARAMETER ID
       ID of the rack
    .PARAMETER Site
       Site of the rack
    .PARAMETER Location
       Location of the rack
    .PARAMETER Slug
       Search for a rack by slug
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       NetBox.Rack
    .NOTES
       General notes
    #>

   param (
      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Name,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Site,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Location,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Slug
   )

   begin {
      Test-Config | Out-Null
      $URL = "/dcim/racks/"
   }

   process {
      $Query = "?"

      if ($Name) {
         $Query = $Query + "name__ic=$($Name)&"
      }

      if ($Model) {
         $Query = $Query + "model__ic=$($Model)&"
      }

      if ($Manufacturer) {
         $Query = $Query + "manufacturer__ic=$($Manufacturer)&"
      }

      if ($Id) {
         $Query = $Query + "id=$($id)&"
      }

      if ($MacAddress) {
         $Query = $Query + "mac_address=$($MacAddress)"
      }

      if ($Site) {
         $Query = $Query + "site__ic=$($Site)&"
      }

      if ($Location) {
         $Query = $Query + "Location__ic=$($Location)&"
      }

      if ($Slug) {
         $Query = $Query + "slug__ic=$($Slug)&"
      }

      $Query = $Query.TrimEnd("&")

      $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

      $Racks = New-Object collections.generic.list[object]

      foreach ($Item in $Result) {
         [PSCustomObject]$Rack = $item
         $Rack.PSObject.TypeNames.Insert(0, "NetBox.Rack")
         $Racks += $Rack
      }

      return $Racks
   }
}

function New-Rack {
   <#
    .SYNOPSIS
       Creates a new rack in NetBox
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> New-NetBoxRack -Name "T-12" -Location "High density" -Site VBC
       Creates rack "T-12" in location "High Density" in site VBC
    .PARAMETER Name
       Name of the rack
    .PARAMETER Slug
         Slug of the rack, if not specified, it will be generated from the name
    .PARAMETER SiteName
         Name of the Site of the rack
    .PARAMETER SiteID
         ID of the Site of the rack
    .PARAMETER LocationName
         Name of the Location of the rack
    .PARAMETER LocationID
         ID of the Location of the rack, Defaults to 4-post-frame
    .PARAMETER Status
         Status of the rack, Defaults to Active
    .PARAMETER Type
         Type of the rack, Defaults to Active
    .PARAMETER Width
         Width of the rack in inch, default is 19
    .PARAMETER Height
         Height of the rack in U(Units), default is 42
    .PARAMETER Description
         Description of the rack
    .PARAMETER CustomFields
         Custom fields of the rack
    .PARAMETER Confirm
         Confirm the creation of the rack
    .PARAMETER Force
         Force the creation of the rack
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       NetBox.Rack
    .NOTES
       General notes
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
      Test-Config | Out-Null
      $URL = "/dcim/racks/"
   }

   process {
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

      if ($null -eq $Slug) {
         $Slug
      }
      else {
         $Slug = $Name.tolower() -replace " ", "-"
      }

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

      # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
      ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

      if ($Confirm) {
         $OutPutObject = [pscustomobject]$Body
         Show-ConfirmDialog -Object $OutPutObject
      }

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

function Update-Rack {
   <#
    .SYNOPSIS
       Updates a new rack in NetBox
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> New-NetBoxRack -Name "T-12" -Location "High density" -Site VBC
       Creates rack "T-12" in location "High Density" in site VBC
    .PARAMETER Name
       Name of the rack
    .PARAMETER SiteName
       Name of the Site of the rack
    .PARAMETER SiteID
       ID of the Site of the rack
    .PARAMETER LocationName
       Name of the Location of the rack
    .PARAMETER LocationID
       ID of the Location of the rack, Defaults to 4-post-frame
    .PARAMETER Status
       Status of the rack, Defaults to Active
    .PARAMETER Type
       Type of the rack, Defaults to Active
    .PARAMETER Width
       Width of the rack in inch, default is 19
    .PARAMETER Height
       Height of the rack in U(Units), default is 42
    .PARAMETER Description
       Description of the rack
    .PARAMETER CustomFields
       Custom fields of the rack
    .PARAMETER Confirm
       Confirm the creation of the rack
    .PARAMETER Force
       Force the creation of the rack
    .INPUTS
       NetBox.Rack
    .OUTPUTS
       NetBox.Rack
    .NOTES
       General notes
    #>
   [CmdletBinding(DefaultParameterSetName = "ByName")]
   param (
      [Parameter(Mandatory = $true)]
      [String]
      $Name,

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
      Test-Config | Out-Null
      $URL = "/dcim/racks/"
   }

   process {

      $Rack = Get-Rack -Name $Name

      if ($SiteName) {
         $Site = Get-Site -Name $SiteName
      }

      if ($SiteID) {
         $Site = Get-Site -Id $SiteID
      }

      if ($LocationName) {
         $Location = Get-Location -Name $LocationName
      }

      if ($LocationID) {
         $Location = Get-Location -ID $LocationID
      }

      $Body = @{
         name        = (Get-Culture).Textinfo.ToTitleCase($Name)
         site        = $Site.ID
         location    = $Location.ID
         status      = $Status
         type        = $Type
         width       = $Width
         u_height    = $Height
         description = $Description
      }

      # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
      ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

      if ($Confirm) {
         $OutPutObject = [pscustomobject]$Body
         Show-ConfirmDialog -Object $OutPutObject
      }

      if (-Not $Exists) {
         $Rack = Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Rack.id) + "/") @RestParams -Method Patch -Body $($Body | ConvertTo-Json)
         $Rack.PSObject.TypeNames.Insert(0, "NetBox.Rack")
         return $Rack
      }
      else {
         return
      }

   }
}

function Remove-Rack {
   <#
   .SYNOPSIS
      Deletes a rack from NetBox
   .DESCRIPTION
      Long description
   .EXAMPLE
      PS C:\> Remove-NetBoxRack -Name "Y-14"
      Deletes rack "Y-14" in NetBox
   .PARAMETER Name
      Name of the rack
   .PARAMETER ID
      ID of the rack
    .PARAMETER Recurse
       Deletes all related objects as well
    .PARAMETER Confirm
      Confirm the deletion of the rack
    .PARAMETER InputObject
      Rack object to delete
   .INPUTS
      NetBox.Rack
   .OUTPUTS
      Output (if any)
   .NOTES
      General notes
   #>

   [CmdletBinding(DefaultParameterSetName = "ByName")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $Name,

      [Parameter(Mandatory = $true, ParameterSetName = "ByID")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $false)]
      [Switch]
      $Recurse,

      [Parameter(Mandatory = $false)]
      [Bool]
      $Confirm = $true,

      [Parameter(ValueFromPipeline = $true, ParameterSetName = 'ByInputObject')]
      $InputObject
   )
   begin {

      Test-Config | Out-Null
      $URL = "/dcim/racks/"
   }

   process {
      if (-not ($InputObject.psobject.TypeNames -contains "NetBox.Rack")) {
         Write-Error "InputObject is not type NetBox.Rack"
         break
      }

      if ($InputObject) {
         $Name = $InputObject.name
         $Id = $InputObject.id
      }

      if ($Id) {
         $Rack = Get-Rack -ID $Id
      }
      else {
         $Rack = Get-Rack -Name $Name
      }

      $RelatedObjects = Get-RelatedObjects -Object $Rack -ReferenceObjects Rack

      if ($Confirm) {
         Show-ConfirmDialog -Object $Rack
      }

      # Remove all related objects
      if ($Recurse) {
         foreach ($Object in $RelatedObjects) {
            Invoke-RestMethod -Uri $Object.url @RestParams -Method Delete | Out-Null
         }
      }
      try {
         Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Rack.id) + "/") @RestParams -Method Delete
      }
      catch {
         if ((($RestError.ErrorRecord) | ConvertFrom-Json).Detail -like "Unable to delete object*") {
            Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
            Write-Error "Delete those objects first or run again using -recurse switch"
         }
         else {
            Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
         }

      }
   }
}

function Get-CustomField {
   <#
    .SYNOPSIS
       Retrievess a custom field from NetBox
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> Get-NetBoxCustomField -Name "ServiceCatalogID"
       Retrieves custom field "ServiceCatalogID" from NetBox
    .PARAMETER Name
       Name of the custom field
    .PARAMETER ID
       ID of the custom field
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       NetBox.CustomField
    .NOTES
       General notes
    #>

   param (
      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Name,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $Id
   )

   begin {
      Test-Config | Out-Null
      $URL = "/extras/custom-fields/"
   }

   process {
      $Query = "?"

      if ($Name) {
         $Query = $Query + "name__ic=$($Name)&"
      }

      if ($Id) {
         $Query = $Query + "id=$($id)&"
      }

      $Query = $Query.TrimEnd("&")

      $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

      $Customfields = New-Object collections.generic.list[object]

      foreach ($Item in $Result) {
         [PSCustomObject]$Customfield = $item
         $Customfield.PSObject.TypeNames.Insert(0, "NetBox.Customfield")
         $Customfields += $Customfield
      }

      return $Customfields
   }
}

function New-CustomField {
   <#
    .SYNOPSIS
       Creates a custom field in NetBox
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> New-NetBoxCustomField -Name "ServiceCatalogID" -Type Integer -ContentTypes Device -Label "Service Catalog ID"
       Creates custom field "ServiceCatalogID" from Type Integer for Contenttype device with the label "Service Catalog ID" in NetBox
    .PARAMETER Name
       Name of the custom field
    .PARAMETER Label
       Label of the custom field
    .PARAMETER Type
         Type of the custom field, e.g. "Integer","Text"
    .PARAMETER ContentTypes
       Content types of the custom field, e.g. "Device"
    .PARAMETER Choices
       Choices of the custom field, e.g. "1,2,3,4,5"
    .PARAMETER Description
       Description of the custom field
    .PARAMETER Required
       Set the custom field as required
    .PARAMETER Confirm
      Confirm the creation of the location
    .PARAMETER Force
      Forces creation of the custom field
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       NetBox.CustomField
    .NOTES
       General notes
    #>

   param (
      [Parameter(Mandatory = $true)]
      [String]
      $Name,

      [Parameter(Mandatory = $true)]
      [ValidateSet("Site", "Location", "Rack", "Device", "Device Role")]
      [String[]]
      $ContentTypes,

      [Parameter(Mandatory = $true)]
      [ValidateSet("text", "integer", "boolean", "date", "url", "select", "multiselect")]
      [String]
      $Type,

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
      $URL = "/extras/custom-fields/"
   }

   process {
      if ($(Get-CustomField -Name $Name )) {
         Write-Warning "CustomField $Name already exists"
         $Exists = $true
      }

      $NetBoxContentTypes = New-Object collections.generic.list[object]

      foreach ($ContentType in $ContentTypes) {
         $NetBoxContentType = Get-ContentType -Name $ContentType
         $NetBoxContentTypes += "$($NetBoxContentType.app_label).$($NetBoxContentType.model)"
      }

      $Body = @{
         name          = (Get-Culture).Textinfo.ToTitleCase($Name)
         label         = $Label
         type          = $Type
         required      = $Required
         choices       = $Choices
         description   = $Description
         content_types = $NetBoxContentTypes
      }

      # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
   ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

      if ($Confirm) {
         $OutPutObject = [pscustomobject]$Body
         Show-ConfirmDialog -Object $OutPutObject
      }

      if (-Not $Exists) {
         $CustomField = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
         $CustomField.PSObject.TypeNames.Insert(0, "NetBox.CustomField")
         return $CustomField
      }
      else {
         return
      }
   }
}

function Remove-CustomField {
   <#
    .SYNOPSIS
       Deletes a custom field from NetBox
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> Remove-NetBoxCustomField -id 3
       Deletes custom field with ID 3 from NetBox
    .PARAMETER Name
       Name of the custom field
    .PARAMETER ID
       ID of the custom field
    .PARAMETER InputObject
       Customfield object to delete
    .INPUTS
       NetBox.CustomField
    .OUTPUTS
       Output (if any)
    .NOTES
       General notes
    #>

   [CmdletBinding(DefaultParameterSetName = "Byname")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $Name,

      [Parameter(Mandatory = $true, ParameterSetName = "ById")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $false)]
      [Switch]
      $Recurse,

      [Parameter(Mandatory = $false)]
      [Bool]
      $Confirm = $true,

      [Parameter(ValueFromPipeline = $true, ParameterSetName = 'ByInputObject')]
      $InputObject
   )

   begin {
      Test-Config | Out-Null
      $URL = "/extras/custom-fields/"
   }

   process {
      if (-not ($InputObject.psobject.TypeNames -contains "NetBox.Customfield")) {
         Write-Error "InputObject is not type NetBox.Customfield"
         break
      }

      if ($InputObject) {
         $Name = $InputObject.name
         $Id = $InputObject.Id
      }

      if ($Id) {
         $CustomField = Get-CustomField -Id $Id
      }
      else {
         $CustomField = Get-CustomField -Name $Name
      }

      $RelatedObjects = Get-RelatedObjects -Object $CustomField -ReferenceObjects CustomField

      if ($Confirm) {
         Show-ConfirmDialog -Object $CustomField
      }

      # Remove all related objects
      if ($Recurse) {
         foreach ($Object in $RelatedObjects) {
            Invoke-RestMethod -Uri $Object.url @RestParams -Method Delete | Out-Null
         }
      }

      try {
         Invoke-RestMethod -Uri $($NetboxURL + $URL + $($CustomField.id) + "/") @RestParams -Method Delete
      }
      catch {
         if ((($RestError.ErrorRecord) | ConvertFrom-Json).Detail -like "Unable to delete object*") {
            Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
            Write-Error "Delete those objects first or run again using -recurse switch"
         }
         else {
            Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
         }
      }
   }
}

function Get-ContentType {
   <#
    .SYNOPSIS
       Retrieves content types from NetBox
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> Get-NetBoxContentType -Name Device
       Retrieves content type "Device" from NetBox
    .PARAMETER Name
       Name of the content type
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       Output (if any)
    .NOTES
       General notes
    #>

   param (
      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [ValidateSet("Site", "Location", "Rack", "Device", "Device Role")]
      [String]
      $Name
   )

   begin {
      Test-Config | Out-Null
      $URL = "/extras/content-types/"
   }

   process {
      $Query = ""

      if ($Name) {
         $Query = "?model=$($Name.Replace(' ','').ToLower())"
      }

      $Query = $Query.TrimEnd("&")

      $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

      $ContentTypes = New-Object collections.generic.list[object]

      foreach ($Item in $Result) {
         [PSCustomObject]$ContentType = $item
         $ContentType.PSObject.TypeNames.Insert(0, "NetBox.ContentType")
         $ContentTypes += $ContentType
      }

      return $ContentTypes
   }
}

function Get-Manufacturer {
   <#
   .SYNOPSIS
      Gets a manufacturer from NetBox
   .DESCRIPTION
      Long description
   .EXAMPLE
      PS C:\> Get-NetBoxManufacturer -Name "Cisco"
      Retrieves manufacturer "Cisco" from NetBox
   .PARAMETER Name
      Name of the manufacturer
   .PARAMETER ID
      ID of the manufacturer
    .PARAMETER Slug
       Search for a manufacturer by slug
   .PARAMETER
   .INPUTS
      Inputs (if any)
   .OUTPUTS
      NetBox.Manufacturer
   .NOTES
      General notes
   #>

   param (
      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Name,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Slug
   )

   begin {
      Test-Config | Out-Null
      $URL = "/dcim/manufacturers/"
   }

   process {
      $Query = "?"

      if ($Name) {
         $Query = $Query + "name__ic=$($Name)&"
      }

      if ($Id) {
         $Query = $Query + "id=$($id)&"
      }

      if ($Slug) {
         $Query = $Query + "slug__ic=$($Slug)&"
      }

      $Query = $Query.TrimEnd("&")

      $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get

      if ($Result.Count -gt 50) {
         $Result = Get-NextPage -Result $Result
         $Manufacturer = $Result
      }
      else {
         $Manufacturer = $Result.results
      }
      $Manufacturer.PSObject.TypeNames.Insert(0, "NetBox.Manufacturer")
      return $Manufacturer
   }
}

function New-Manufacturer {
   <#
   .SYNOPSIS
      Creates a new manufacturer in NetBox
   .DESCRIPTION
      Long description
   .EXAMPLE
      PS C:\> New-NetBoxManufacturer -Name Dell
      Creates manufacturer "Dell" in NetBox
   .PARAMETER Name
      Name of the manufacturer
   .PARAMETER Slug
      Slug of the manufacturer, if not specified, it will be generated from the name
   .PARAMETER Confirm
      Confirm the creation of the manufacturer
    .PARAMETER Force
      Force the creation of the manufacturer
   .INPUTS
      Inputs (if any)
   .OUTPUTS
      NetBox.Manufacturer
   .NOTES
      General notes
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
      Test-Config | Out-Null
      $URL = "/dcim/manufacturers/"
   }

   process {
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

      if ($null -eq $Slug) {
         $Slug
      }
      else {
         $Slug = $Name.tolower() -replace " ", "-"
      }

      $Body = @{
         name          = (Get-Culture).Textinfo.ToTitleCase($Name)
         slug          = $Slug
         custum_fields = $CustomFields
      }

      # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
   ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

      if ($Confirm) {
         $OutPutObject = [pscustomobject]$Body
         Show-ConfirmDialog -Object $OutPutObject
      }

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

function Remove-Manufacturer {
   <#
    .SYNOPSIS
       Deletes a manufacturer from NetBox
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> Remove-NetBoxManufacturer -Name Dell
       Deletes manufacturer "dell" from NetBox
    .PARAMETER Name
       Name of the custom field
    .PARAMETER ID
       ID of the custom field
    .PARAMETER InputObject
       Customfield object to delete
    .INPUTS
       NetBox.CustomField
    .OUTPUTS
       Output (if any)
    .NOTES
       General notes
    #>

   [CmdletBinding(DefaultParameterSetName = "Byname")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $Name,

      [Parameter(Mandatory = $true, ParameterSetName = "ById")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $false)]
      [Switch]
      $Recurse,

      [Parameter(Mandatory = $false)]
      [Bool]
      $Confirm = $true,

      [Parameter(ValueFromPipeline = $true, ParameterSetName = 'ByInputObject')]
      $InputObject
   )

   begin {
      Test-Config | Out-Null
      $URL = "/dcim/manufacturers/"
   }

   process {
      if ($InputObject) {
         $Name = $InputObject.name
         $Id = $InputObject.id
      }
      if ($Name) {
         $Manufacturer = Get-Manufacturer -Name $Name
      }
      if ($Id) {
         $Manufacturer = Get-Manufacturer -Id $Id
      }

      $RelatedObjects = Get-RelatedObjects -Object $Manufacturer -ReferenceObjects Manufacturer

      if ($Confirm) {
         Show-ConfirmDialog -Object $Manufacturer
      }

      # Remove all related objects
      if ($Recurse) {
         foreach ($Object in $RelatedObjects) {
            Invoke-RestMethod -Uri $Object.url @RestParams -Method Delete | Out-Null
         }
      }

      try {
         Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Manufacturer.id) + "/") @RestParams -Method Delete
      }
      catch {
         if ((($RestError.ErrorRecord) | ConvertFrom-Json).Detail -like "Unable to delete object*") {
            Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
            Write-Error "Delete those objects first or run again using -recurse switch"
         }
         else {
            Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
         }
      }
   }
}

function Get-DeviceType {
   <#
    .SYNOPSIS
       Retrieves device types from NetBox
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> Get-NetboxDeviceType -Model "Cisco Catalyst 2960"
       Retrives DeviceType for Cisco Catalyst 2960 from NetBox
    .PARAMETER Model
       Model of the device type
    .PARAMETER Manufacturer
       Manufacturer of the device type
    .PARAMETER ID
       ID of the device type
    .PARAMETER SubDeviceRole
       Search for a device type by sub device role
    .PARAMETER PartNumber
       Search for a device type by part number
    .PARAMETER Slug
       Search for a device type by slug
    .PARAMETER Height
       Search for a device type by height
    .PARAMETER Exact
       Search for exacte match instead of partial
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       NetBox.DeviceType
    .NOTES
       General notes
    #>

   [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
   param (
      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Alias("Name")]
      [String]
      $Model,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Alias("Vendor")]
      [String]
      $Manufacturer,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $SubDeviceRole,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $PartNumber,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Slug,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Height,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Switch]
      $Exact
   )

   begin {
      Test-Config | Out-Null
      $URL = "/dcim/device-types/"
   }

   process {
      $Query = "?"

      if ($Model) {
         if ($Exact) {
            $Query = $Query + "model=$($Model.Replace(" ","%20"))&"
         }
         else {
            $Query = $Query + "model__ic=$($Model)&"
         }
      }

      if ($Manufacturer) {
         $Query = $Query + "manufacturer_id=$((Get-Manufacturer -Name $Manufacturer).ID)&"
      }

      if ($Id) {
         $Query = $Query + "id=$($id)&"
      }

      if ($SubDeviceRole) {
         $Query = $Query + "subdevice_role__ic=$($SubDeviceRole)"
      }

      if ($PartNumber) {
         $Query = $Query + "part_number__ic=$($PartNumber)"
      }

      if ($Slug) {
         if ($Exact) {
            $Query = $Query + "slug=$($Slug)&"
         }
         else {
            $Query = $Query + "slug__ic=$($Slug)&"
         }
      }

      if ($Height) {
         $Query = $Query + "u_height=$($Height)&"
      }

      $Query = $Query.TrimEnd("&")

      $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

      $DeviceTypes = New-Object collections.generic.list[object]

      foreach ($item in $Result) {
         [PSCustomObject]$DeviceType = $item
         $DeviceType.PSObject.TypeNames.Insert(0, "NetBox.DeviceType")
         $DeviceTypes += $DeviceType
      }

      return $DeviceTypes
   }
}

function New-DeviceType {
   <#
    .SYNOPSIS
       Cretaes a new device type in NetBox
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> New-NetboxDeviceType -Model "Cisco Catalyst 2960" -Manufacturer "Cisco" -Height "4"
       Creates device type "Cisco Catalyst 2960" with height 4 from manufacturer "Cisco" in NetBox
    .PARAMETER ManufacturerName
       Name of the manufacturer
    .PARAMETER ManufacturerID
       ID of the manufacturer
    .PARAMETER Model
       Model of the device type
    .PARAMETER Slug
       Slug of the device type, if not specified, it will be generated from the model
     .PARAMETER Height
         Height of the device in U(Units)
     .PARAMETER FullDepth
         Is device fulldepth? defaults to true
     .PARAMETER Partnumber
         Partnumber of the device
     .PARAMETER Interface
         Interfaces of the device, as hashtable
    .PARAMETER SubDeviceRole
       Subdevice role of the device type, "parent" or "child"
    .PARAMETER Confirm
         Confirm the creation of the device type
    .PARAMETER Force
         Force the creation of the device type
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       NetBox.DeviceType
    .NOTES
       General notes
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
      Test-Config | Out-Null
      $URL = "/dcim/device-types/"
   }

   process {
      if ($Model) {
         if (Get-DeviceType -Name $Model -Exact) {
            Write-Warning "DeviceType $Model already exists"
            $Exists = $true
         }
      }
      if ($Slug) {
         if (Get-DeviceType -Slug $Slug -Exact) {
            Write-Warning "DeviceType $Slug already exists"
            $Exists = $true
         }
      }

      if ($null -eq $Slug) {
         $Slug
      }
      else {
         $Slug = $Model.tolower() -replace " ", "-" -replace "/", "-" -replace ",", "-"
      }

      if ($ManufacturerName) {
         $Manufacturer = Get-Manufacturer -Name $ManufacturerName
      }
      if ($ManufacturerID) {
         $Manufacturer = Get-Manufacturer -ID $ManufacturerID
      }

      $Body = @{
         manufacturer   = $Manufacturer.ID
         model          = $Model
         slug           = $Slug
         part_number    = $PartNumber
         u_height       = $Height
         is_full_depth  = $FullDepth
         tags           = $Tags
         custum_fields  = $CustomFields
         subdevice_role = $SubDeviceRole
      }

      # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
      ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

      if ($Confirm) {
         $OutPutObject = [pscustomobject]$Body
         Show-ConfirmDialog -Object $OutPutObject
      }

      if (-Not $Exists) {
         $DeviceType = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
         $DeviceType.PSObject.TypeNames.Insert(0, "NetBox.DeviceType")
         return $DeviceType
      }
      else {
         return
      }
   }
}

function Remove-DeviceType {
   <#
   .SYNOPSIS
      Deletes a device type from NetBox
   .DESCRIPTION
      Long description
   .EXAMPLE
      PS C:\> Remove-NetboxDeviceType -Model "Cisco Catalyst 2960"
      Explanation of what the example does
   .PARAMETER Model
      Model of the device type
   .PARAMETER Recurse
      Deletes all related objects as well
   .PARAMETER Confirm
      Confirm the deletion of the device type
    .PARAMETER InputObject
      device type object to delete
   .INPUTS
      NetBox devicetype object
   .OUTPUTS
      Output (if any)
   .NOTES
      General notes
   #>

   [CmdletBinding(DefaultParameterSetName = "ByName")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $Name,

      [Parameter(Mandatory = $false)]
      [Switch]
      $Recurse,

      [Parameter(Mandatory = $false)]
      [Bool]
      $Confirm = $true,

      [Parameter(ValueFromPipeline = $true, ParameterSetName = 'ByInputObject')]
      $InputObject
   )

   begin {

      Test-Config | Out-Null
      $URL = "/dcim/device-types/"
   }

   process {
      if ($InputObject) {
         $Model = $InputObject.Model
      }

      $DeviceType = Get-DeviceType -Model $Model

      $RelatedObjects = Get-RelatedObjects -Object $DeviceType -ReferenceObjects DeviceType

      if ($Confirm) {
         Show-ConfirmDialog -Object $DeviceType
      }

      # Remove all related objects
      if ($Recurse) {
         foreach ($Object in $RelatedObjects) {
            Invoke-RestMethod -Uri $Object.url @RestParams -Method Delete | Out-Null
         }
      }

      try {
         Invoke-RestMethod -Uri $($NetboxURL + $URL + $($DeviceType.id) + "/") @RestParams -Method Delete
      }
      catch {
         if ((($RestError.ErrorRecord) | ConvertFrom-Json).Detail -like "Unable to delete object*") {
            Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
            Write-Error "Delete those objects first or run again using -recurse switch"
         }
         else {
            Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
         }
      }
   }
}

function Import-DeviceType {
   <#
   .SYNOPSIS
      Short description
   .DESCRIPTION
      Long description
   .EXAMPLE
      PS C:\> <example usage>
      Explanation of what the example does
   .PARAMETER Path
      Path to the yaml file to import
   .INPUTS
      Inputs (if any)
   .OUTPUTS
      Output (if any)
   .NOTES
      General notes
   #>
   [CmdletBinding()]
   param (
      [Parameter()]
      [String]
      [Alias("YamlFile")]
      $Path
   )
   $DeviceType = Get-Content $path | ConvertFrom-Yaml

   Write-Verbose $($DeviceType | Format-Table | Out-String)

   Write-Verbose $($DeviceType.Interfaces | Format-Table | Out-String)

   New-Manufacturer -Name $DeviceType.Manufacturer -Confirm $false | Out-Null

   $NewDeviceTypeParams = @{
      ManufacturerName = $DeviceType.Manufacturer
      Model            = $DeviceType.Model
      Confirm          = $false
   }

   if ($DeviceType.u_height) {
      $NewDeviceTypeParams["height"] = $DeviceType.u_height
   }

   if ($DeviceType.is_full_depth) {
      $NewDeviceTypeParams["FullDepth"] = $DeviceType.is_full_depth
   }

   if ($DeviceType.subdevice_role) {
      $NewDeviceTypeParams["SubDeviceRole"] = $DeviceType.subdevice_role
   }

   if ($DeviceType.part_number) {
      $NewDeviceTypeParams["PartNumber"] = $DeviceType.part_number
   }

   if ($DeviceType.slug) {
      $NewDeviceTypeParams["Slug"] = $DeviceType.slug
   }

   if ($DeviceType."device-bays") {
      $NewDeviceTypeParams["DeviceBays"] = $DeviceType."device-bays"
   }

   Write-Verbose $($NewDeviceTypeParams | Format-Table | Out-String )

   $NewDeviceType = New-DeviceType @NewDeviceTypeParams -Confirm $false | Out-Null

   if ($null -eq $NewDeviceType) {
      $NewDeviceType = Get-NetBoxDeviceType -Model $DeviceType.Model -Manufacturer $DeviceType.Manufacturer
   }

   foreach ($Interface in $DeviceType.interfaces) {
      Write-Verbose "Creating Interfaces"
      New-InterfaceTemplate -Name $Interface.Name -Type $Interface.Type -ManagmentOnly $([System.Convert]::ToBoolean($Interface.mgmt_only)) -DeviceTypeID $NewDeviceType.id -Confirm $false | Out-Null
   }

   foreach ($PSU in $DeviceType."power-ports") {
      Write-Verbose "Creating PSUs"
      New-PowerPortTemplate -Name $PSU.Name -Type $PSU.Type -DeviceTypeID $NewDeviceType.ID -Confirm $false | Out-Null
   }

   foreach ($DeviceBay in $DeviceType."device-bays") {
      Write-Verbose "Creating Device Bays"
      New-DeviceBayTemplate -Name $DeviceBay.Name -DeviceTypeID $NewDeviceType.ID -Confirm $false | Out-Null
   }
}

function Get-Device {
   <#
    .SYNOPSIS
       Retrieves a device from NetBox
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> Get-NetBoxdevice -DeviceType "Cisco Catalyst 2960"
       Retrieves all devices of type "Cisco Catalyst 2960" from NetBox
    .PARAMETER Name
       Name of the device
    .PARAMETER Model
       All devices of this model
    .PARAMETER Manufacturer
       All devices from manufacturer
    .PARAMETER ID
       ID of the device
    .PARAMETER Slug
       Search for a device by slug
    .PARAMETER MacAddress
       MAC address of the device
    .PARAMETER Site
       All devices from Site
    .PARAMETER Location
       All devices from Location
    .PARAMETER Rack
       All devices from Rack
    .PARAMETER DeviceType
       Device type of the device
    .PARAMETER Exact
       Search for exacte match instead of partial
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       NetBox.Device
    .NOTES
       General notes
    #>

   param (
      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Name,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Model,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Alias("Vendor")]
      [String]
      $Manufacturer,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Slug,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $MacAddress,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Site,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Location,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Rack,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $DeviceType,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Switch]
      $Exact
   )

   begin {
      Test-Config | Out-Null
      $URL = "/dcim/devices/"
   }

   process {
      $Query = "?"

      if ($name) {
         if ($Exact) {
            $Query = $Query + "name=$($Name)&"
         }
         else {
            $Query = $Query + "name__ic=$($Name)&"
         }
      }

      if ($Model) {
         $Query = $Query + "model__ic=$($Model)&"
      }

      if ($Manufacturer) {
         $Query = $Query + "manufacturer=$($Manufacturer)&"
      }

      if ($Id) {
         $Query = $Query + "id=$($id)&"
      }

      if ($Slug) {
         $Query = $Query + "slug__ic=$($Slug)&"
      }

      if ($MacAddress) {
         $Query = $Query + "mac_address=$($MacAddress)&"
      }

      if ($Site) {
         $Query = $Query + "site__ic=$($Site)&"
      }

      if ($Location) {
         $Query = $Query + "Location__ic=$($Location)&"
      }

      if ($Rack) {
         $Query = $Query + "rack=$($Rack)&"
      }

      if ($DeviceType) {
         $Query = $Query + "device_type_id=$(Get-DeviceType -Model $($DeviceType) | Select-Object -ExpandProperty id)&"
      }

      $Query = $Query.TrimEnd("&")

      $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

      $Devices = New-Object collections.generic.list[object]

      foreach ($Item in $Result) {
         [PSCustomObject]$Device = $item
         $Device.PSObject.TypeNames.Insert(0, "NetBox.Device")
         $Devices += $Device
      }

      return $Devices
   }
}
function New-Device {
   <#
    .SYNOPSIS
       Creates a new device in NetBox
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> New-NetBoxDevice -Name NewHost -Location "low density" -Rack Y-14 -Position 27 -Height 4 -DeviceRole Server -DeviceType "PowerEdge R6515" -Site VBC
       Adds the device "NewHost" in rack "Y-14" at position "27" in the location "low density" on Site "VBC" as a "server" with device type "PowerEdge R6515"
    .PARAMETER Name
       Name of the device
    .PARAMETER DeviceTypeName
       Name of the Device type of the device
    .PARAMETER DeviceTypeID
       ID of the Device type of the device
    .PARAMETER Site
       Site of the device
    .PARAMETER Location
       Location of the device
    .PARAMETER Rack
       Rack of the device
    .PARAMETER Position
       Position of the device in the rack, lowest occupied
    .PARAMETER Height
       Units of the device in the rack, in (U)
    .PARAMETER DeviceRole
       Role of the device
    .PARAMETER Parentdevice
       Parent device of the device, in case of a chassis
    .PARAMETER Hostname
       Hostname of the device
    .PARAMETER Face
       Face of the device, front or back, default is front
    .PARAMETER Status
       Status of the device, defaults to "active"
    .PARAMETER AssetTag
       Asset tag or serial number of the device
    .PARAMETER CustomFields
       Custom fields of the device
   .PARAMETER Confirm
      Confirm the creation of the device
    .PARAMETER Force
      Force the creation of the device
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       Output (if any)
    .NOTES
       General notes
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
      $Face,

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
      $Confirm = $true,

      [Parameter(Mandatory = $false)]
      [Switch]
      $Force
   )

   begin {
      Test-Config | Out-Null
      $URL = "/dcim/devices/"
   }

   process {
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

      if ($ParentDevice) {
         $Body.parent_device = @{
            name = $ParentDevice
         }
      }

      # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
        ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

      if ($Confirm) {
         $OutPutObject = [pscustomobject]$Body
         Show-ConfirmDialog -Object $OutPutObject
      }

      if (-Not $Exists) {
         $Devive = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
         $Devive.PSObject.TypeNames.Insert(0, "NetBox.Device")
         return $Devive
      }
      else {
         return
      }
   }
}

function Update-Device {
   <#
    .SYNOPSIS
       Creates a new device in NetBox
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> New-NetBoxDevice -Name NewHost -Location "low density" -Rack Y-14 -Position 27 -Height 4 -DeviceRole Server -DeviceType "PowerEdge R6515" -Site VBC
       Adds the device "NewHost" in rack "Y-14" at position "27" in the location "low density" on Site "VBC" as a "server" with device type "PowerEdge R6515"
    .PARAMETER Name
       Name of the device
    .PARAMETER DevuceType
       Device type of the device
    .PARAMETER Site
       Site of the device
    .PARAMETER Location
       Location of the device
    .PARAMETER Rack
       Rack of the device
    .PARAMETER Position
       Position of the device in the rack, lowest occupied
    .PARAMETER Height
       Units of the device in the rack, in (U)
    .PARAMETER DeviceRole
       Role of the device
    .PARAMETER Parentdevice
       Parent device of the device, in case of a chassis
    .PARAMETER Hostname
       Hostname of the device
    .PARAMETER Face
       Face of the device, front or back, default is front
    .PARAMETER Status
       Status of the device, defaults to "active"
    .PARAMETER AssetTag
       Asset tag or serial number of the device
    .PARAMETER CustomFields
       Custom fields of the device
   .PARAMETER Confirm
      Confirm the creation of the device
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       Output (if any)
    .NOTES
       General notes
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
      Test-Config | Out-Null
      $URL = "/dcim/devices/"
   }

   process {
      if ($Name -is [String]) {
         $name = (Get-Device -Query $Name).Id
      }
      else {
         $Name
      }

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

      # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
   ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

      if ($Confirm) {
         $OutPutObject = [pscustomobject]$Body
         Show-ConfirmDialog -Object $OutPutObject
      }

      Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Interface.id) + "/") @RestParams -Method Patch -Body $($Body | ConvertTo-Json)
   }
}

function Remove-Device {
   <#
   .SYNOPSIS
      Deletes a device from NetBox
   .DESCRIPTION
      Long description
   .EXAMPLE
      PS C:\> Remove-NetBoxDevice -Name NewHost
      Deletes the device NewHost from NetBox
   .PARAMETER Name
      Name of the device
   .PARAMETER Recurse
      Deletes all related objects as well
   .PARAMETER Confirm
      Confirm the deletion of the device
    .PARAMETER InputObject
      device object to delete
   .INPUTS
      NetBox.Device
   .OUTPUTS
      Output (if any)
   .NOTES
      General notes
   #>

   [CmdletBinding(DefaultParameterSetName = "ByName")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $Name,

      [Parameter(Mandatory = $false)]
      [Switch]
      $Recurse,

      [Parameter(Mandatory = $false)]
      [Bool]
      $Confirm = $true,

      [Parameter(ValueFromPipeline = $true, ParameterSetName = 'ByInputObject')]
      $InputObject
   )

   begin {

      Test-Config | Out-Null
      $URL = "/dcim/devices/"
   }
   process {
      if ($InputObject) {
         $Name = $InputObject.name
      }

      $Device = Get-Device -Name $Name

      $RelatedObjects = Get-RelatedObjects -Object $Device -ReferenceObjects Device

      if ($Confirm) {
         Show-ConfirmDialog -Object $Device
      }

      # Remove all related objects
      if ($Recurse) {
         foreach ($Object in $RelatedObjects) {
            Invoke-RestMethod -Uri $Object.url @RestParams -Method Delete | Out-Null
         }
      }

      try {
         Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Device.id) + "/") @RestParams -Method Delete
      }
      catch {
         if ((($RestError.ErrorRecord) | ConvertFrom-Json).Detail -like "Unable to delete object*") {
            Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
            Write-Error "Delete those objects first or run again using -recurse switch"
         }
         else {
            Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
         }
      }
   }
}

function Get-DeviceRole {
   <#
   .SYNOPSIS
      Retrives devices roles from Netbox
   .DESCRIPTION
      Long description
   .EXAMPLE
      PS C:\> Get-NetBoxDeviceRole -Name Server
      Retrives the "Server" device role
   .PARAMETER Name
      Name of the device role
   .PARAMETER ID
      ID of the device role
    .PARAMETER Slug
       Search for a device role by slug
   .INPUTS
      Inputs (if any)
   .OUTPUTS
      NetBox.DeviceRole
   .NOTES
      General notes
   #>

   param (
      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Name,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Slug
   )

   begin {
      Test-Config | Out-Null
      $URL = "/dcim/device-roles/"
   }

   process {
      $Query = "?"

      if ($Name) {
         $Query = $Query + "name__ic=$($Name)&"
      }

      if ($Id) {
         $Query = $Query + "id=$($id)&"
      }

      if ($Slug) {
         $Query = $Query + "slug__ic=$($Slug)&"
      }

      $Query = $Query.TrimEnd("&")

      $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

      $DeviceRoles = New-Object collections.generic.list[object]

      foreach ($Item in $Result) {
         [PSCustomObject]$DeviceRole = $item
         $DeviceRole.PSObject.TypeNames.Insert(0, "NetBox.DeviceRole")
         $DeviceRoles += $DeviceRole
      }

      return $DeviceRoles
   }
}

function New-DeviceRole {
   <#
   .SYNOPSIS
      Creates a new device role in NetBox
   .DESCRIPTION
      Long description
   .EXAMPLE
      PS C:\> New-NetboxDeviceRole -Name "ACI Leafswitch" -VMRole $false
      Creates the "ACI Leafswitch" device role in NetBox
   .PARAMETER Name
      Name of the device role
   .PARAMETER Slug
       Slug of the device role, if not specified, it will be generated from the name
   .PARAMETER Color
      Color of the device role
   .PARAMETER VMRole
      Is this a VM role?
   .PARAMETER Description
      Description of the device role
   .PARAMETER CustomFields
      Custom fields of the device role
   .PARAMETER Confirm
      Confirm the deletion of the device role
    .PARAMETER Force
      Forces the creation of the device role
   .INPUTS
      Inputs (if any)
   .OUTPUTS
      Output (if any)
   .NOTES
      General notes
   #>

   param (
      [Parameter(Mandatory = $true)]
      [String]
      $Name,

      [Parameter(Mandatory = $false)]
      [String]
      $Slug,

      [Parameter(Mandatory = $false)]
      [String]
      $Color,

      [Parameter(Mandatory = $false)]
      [Bool]
      $VMRole,

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
      $URL = "/dcim/device-roles/"
   }

   process {
      if ($Name) {
         if (Get-DeviceRole -Name $Name) {
            Write-Warning "DeviceRole $Name already exists"
            $Exists = $true
         }
      }
      if ($Slug) {
         if (Get-DeviceRole -Slug $Slug) {
            Write-Warning "DeviceRole $Slug already exists"
            $Exists = $true
         }
      }

      if ($null -eq $Slug) {
         $Slug
      }
      else {
         $Slug = $Name.tolower() -replace " ", "-"
      }

      $Body = @{
         name        = (Get-Culture).Textinfo.ToTitleCase($Name)
         slug        = $Slug
         color       = $Color
         vm_role     = $VMRole
         comment     = $Comment
         description = $Description
      }

      # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
   ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

      if ($Confirm) {
         $OutPutObject = [pscustomobject]$Body
         Show-ConfirmDialog -Object $OutPutObject
      }

      if (-Not $Exists) {
         $DeviceRole = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
         $DeviceRole.PSObject.TypeNames.Insert(0, "NetBox.DeviceRole")
         return $DeviceRole
      }
      else {
         return
      }
   }
}

function Remove-DeviceRole {
   <#
    .SYNOPSIS
       Deletes a device role from NetBox
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> Remove-DeviceRole -Name Server
       Deletes device role "server" from NetBox
    .PARAMETER Name
       Name of the custom field
    .PARAMETER ID
       ID of the custom field
    .PARAMETER InputObject
       Customfield object to delete
    .INPUTS
       NetBox.CustomField
    .OUTPUTS
       Output (if any)
    .NOTES
       General notes
    #>

   [CmdletBinding(DefaultParameterSetName = "Byname")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $Name,

      [Parameter(Mandatory = $true, ParameterSetName = "ById")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $false)]
      [Switch]
      $Recurse,

      [Parameter(Mandatory = $false)]
      [Bool]
      $Confirm = $true,

      [Parameter(ValueFromPipeline = $true, ParameterSetName = 'ByInputObject')]
      $InputObject
   )

   begin {
      Test-Config | Out-Null
      $URL = "/dcim/device-roles/"
   }

   process {
      if ($InputObject) {
         $Name = $InputObject.name
         $Id = $InputObject.id
      }
      if ($Name) {
         $DeviceRole = Get-DeviceRole -Name $Name
      }
      if ($Id) {
         $DeviceRole = Get-DeviceRole -Id $Id
      }

      $RelatedObjects = Get-RelatedObjects -Object $DeviceRole -ReferenceObjects DeviceRole

      if ($Confirm) {
         Show-ConfirmDialog -Object $DeviceRole
      }

      # Remove all related objects
      if ($Recurse) {
         foreach ($Object in $RelatedObjects) {
            Invoke-RestMethod -Uri $Object.url @RestParams -Method Delete | Out-Null
         }
      }

      try {
         Invoke-RestMethod -Uri $($NetboxURL + $URL + $($DeviceRole.id) + "/") @RestParams -Method Delete
      }
      catch {
         if ((($RestError.ErrorRecord) | ConvertFrom-Json).Detail -like "Unable to delete object*") {
            Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
            Write-Error "Delete those objects first or run again using -recurse switch"
         }
         else {
            Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
         }
      }
   }
}

function Get-InterfaceTemplate {
   <#
    .SYNOPSIS
       Retrives interface templates from Netbox
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> Get-NetBoxInterfaceType -Name "FastEthernet"
       Retrives the "FastEthernet" interface template
    .PARAMETER Name
       Name of the interface template
   .PARAMETER ID
       ID of the interface template
    .PARAMETER DeviceTypeName
       Search for parent device type by name
    .PARAMETER DeviceTypeID
       Search for parent device type by ID
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       NetBox.InterfaceTemplate
    .NOTES
       General notes
    #>

   param (
      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Name,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $DeviceTypeName,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $DeviceTypeID
   )

   begin {
      Test-Config | Out-Null
      $URL = "/dcim/interface-templates/"
   }

   process {
      $Query = "?"

      if ($Name) {
         $Query = $Query + "name__ic=$($Name)&"
      }

      if ($DeviceTypeName) {
         $Query = $Query + "devicetype_id=$($(Get-DeviceType -Name $DeviceTypeName).ID)&"
      }
      if ($DeviceTypeID) {
         $Query = $Query + "devicetype_id=$($DeviceTypeID)&"
      }

      if ($Id) {
         $Query = $Query + "id=$($id)&"
      }

      $Query = $Query.TrimEnd("&")

      $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

      $InterfaceTemplates = New-Object collections.generic.list[object]

      foreach ($Item in $Result) {
         [PSCustomObject]$InterfaceTemplate = $item
         $InterfaceTemplate.PSObject.TypeNames.Insert(0, "NetBox.InterfaceTemplate")
         $InterfaceTemplates += $InterfaceTemplate
      }

      return $InterfaceTemplates
   }
}

function New-InterfaceTemplate {
   <#
    .SYNOPSIS
       Creates a new interface template in NetBox
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> New-NetBoxInterfaceTemplate -Name "FastEthernet" -Description "FastEthernet" -Type "100base-tx" -DeviceType "Poweredge R6515"
       Creates an interface template "FastEthernet" for devicetype "Poweredge R6515" with type "100base-tx"
    .PARAMETER Name
       Name of the interface template
    .PARAMETER DeviceTypeName
      Name of the device type
    .PARAMETER DeviceTypeID
      ID of the device type
    .PARAMETER Label
      Label of the interface template
    .PARAMETER Type
      Type of the interface template, e.g "1000base-t", "10gbase-x-sfpp" or others
    .PARAMETER ManagementOnly
      Is this interface template only for management?
   .PARAMETER Confirm
      Confirm the creation of the device
    .PARAMETER Force
      Force the creation of the device
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       NetBox.InterfaceTemplate
    .NOTES
       General notes
    #>

   [CmdletBinding(DefaultParameterSetName = "Byname")]
   param (
      [Parameter(Mandatory = $true)]
      [String]
      $Name,

      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $DeviceTypeName,

      [Parameter(Mandatory = $true, ParameterSetName = "ById")]
      [Int32]
      $DeviceTypeID,

      [Parameter(Mandatory = $false)]
      [String]
      $Label,

      #"virtual", "lag", "100base-tx", "1000base-t", "2.5gbase-t", "5gbase-t", "10gbase-t", "10gbase-cx4", "1000base-x-gbic", "1000base-x-sfp", "10gbase-x-sfpp", "10gbase-x-xfp", "10gbase-x-xenpak", "10gbase-x-x2", "25gbase-x-sfp28", "50gbase-x-sfp56", "40gbase-x-qsfpp", "50gbase-x-sfp28", "100gbase-x-cfp", "100gbase-x-cfp2", "200gbase-x-cfp2", "100gbase-x-cfp4", "100gbase-x-cpak", "100gbase-x-qsfp28", "200gbase-x-qsfp56", "400gbase-x-qsfpdd", "400gbase-x-osfp", "ieee802.11a", "ieee802.11g", "ieee802.11n", "ieee802.11ac", "ieee802.11ad", "ieee802.11ax", "gsm", "cdma", "lte", "sonet-oc3", "sonet-oc12", "sonet-oc48", "sonet-oc192", "sonet-oc768", "sonet-oc1920", "sonet-oc3840", "1gfc-sfp", "2gfc-sfp", "4gfc-sfp", "8gfc-sfpp", "16gfc-sfpp", "32gfc-sfp28", "64gfc-qsfpp", "128gfc-sfp28", "infiniband-sdr", "infiniband-ddr", "infiniband-qdr", "infiniband-fdr10", "infiniband-fdr", "infiniband-edr", "infiniband-hdr", "infiniband-ndr", "infiniband-xdr", "t1", "e1", "t3", "e3", "xdsl", "cisco-stackwise", "cisco-stackwise-plus", "cisco-flexstack", "cisco-flexstack-plus", "juniper-vcp", "extreme-summitstack", "extreme-summitstack-128", "extreme-summitstack-256", "extreme-summitstack-512", "other"
      [Parameter(Mandatory = $true)]
      [String]
      $Type,

      [Parameter(Mandatory = $false)]
      [Bool]
      $ManagmentOnly,

      [Parameter(Mandatory = $false)]
      [Switch]
      $FindInterfaceType,

      [Parameter(Mandatory = $false)]
      [String]
      $LinkSpeed,

      [Parameter(Mandatory = $false)]
      [String]
      $InterfaceType,

      [Parameter(Mandatory = $false)]
      [Bool]
      $Confirm = $true,

      [Parameter(Mandatory = $false)]
      [Switch]
      $Force
   )

   begin {
      Test-Config | Out-Null
      $URL = "/dcim/interface-templates/"
   }

   process {
      if ($DeviceTypeName) {
         $DeviceType = Get-DeviceType -Name $DeviceTypeName
      }

      if ($DeviceTypeID) {
         $DeviceType = Get-DeviceType -ID $DeviceTypeID
      }

      if (Get-InterfaceTemplate -DeviceTypeID $DeviceType.ID -Name $Name ) {
         Write-Warning "InterfaceTemplate $($DeviceType.Model) - $Name already exists"
         $Exists = $true
      }

      if ($FindInterfaceType) {
         $Type = $(Get-InterfaceType -Linkspeed $LinkSpeed -InterfaceType $InterfaceType)
      }

      $Body = @{
         name        = (Get-Culture).Textinfo.ToTitleCase($Name)
         device_type = $DeviceType.ID
         type        = $Type
         mgmt_only   = $ManagmentOnly
      }
      # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
      ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

      if ($Confirm) {
         $OutPutObject = [pscustomobject]$Body
         Show-ConfirmDialog -Object $OutPutObject
      }

      if (-Not $Exists) {
         $InterfaceTemplate = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
         $InterfaceTemplate.PSObject.TypeNames.Insert(0, "NetBox.InterfaceTemplate")
         return $InterfaceTemplate
      }
      else {
         return
      }
   }
}
function Get-PowerSupplyType {
   <#
   .SYNOPSIS
      Short description
   .DESCRIPTION
      Long description
   .EXAMPLE
      PS C:\> <example usage>
      Explanation of what the example does
   .PARAMETER Name
      The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
   .INPUTS
      Inputs (if any)
   .OUTPUTS
      Output (if any)
   .NOTES
      General notes
   #>
   param (
      $PowerSupplyConnector
   )

   if ($PowerSupplyConnector -eq "c14") {
      $NetBoxPowerSupplyConnector = "iec-60320-c14"
   }
   if ($PowerSupplyConnector -eq "c20") {
      $NetBoxPowerSupplyConnector = "iec-60320-c20"
   }

   return $NetBoxPowerSupplyConnector
}

function Get-Interface {
   <#
    .SYNOPSIS
       Get a specific interface from netbox
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> Get-NetBoxInterface -Device "NewHost"
       Get all interfaces from device "NewHost"
    .PARAMETER Name
       Name of the interface
    .PARAMETER ID
       ID of the interface
    .PARAMETER DeviceName
       Name of the parent device
    .PARAMETER DeviceID
       ID of the parent device
    .PARAMETER ManagementOnly
       Is this interface only for management?
    .PARAMETER All
       Returns all interfaces
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       NetBox.Interface
    .NOTES
       General notes
    #>

   param (
      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Name,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $DeviceName,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $DeviceID,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Bool]
      $ManagementOnly
   )

   begin {
      Test-Config | Out-Null
      $URL = "/dcim/interfaces/"
   }

   process {
      $Query = "?"

      if ($Name) {
         $Query = $Query + "name__ic=$($Name)&"
      }

      if ($Id) {
         $Query = $Query + "id=$($id)&"
      }

      if ($DeviceName) {
         $Query = $Query + "device_id=$((Get-NetBoxDevice -Name $DeviceName).ID)&"
      }

      if ($DeviceID) {
         $Query = $Query + "device_id=$((Get-NetBoxDevice -Id $DeviceID).ID)&"
      }

      if ($ManagementOnly) {
         $Query = $Query + "mgmt_only=$($ManagementOnly.ToString())&"
      }

      $Query = $Query.TrimEnd("&")

      $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

      Write-Verbose $($NetboxURL + $URL + $Query)

      $Interfaces = New-Object collections.generic.list[object]

      foreach ($Item in $Result) {
         [PSCustomObject]$Interface = $item
         $Interface.PSObject.TypeNames.Insert(0, "NetBox.Interface")
         $Interfaces += $Interface
      }

      return $Interfaces
   }
}
function New-Interface {
   <#
   .SYNOPSIS
      Creates an interface in netbox
   .DESCRIPTION
      Long description
   .EXAMPLE
      PS C:\> New-NetBoxInterface -Device "NewHost" -Name "NewInterface" -Type "10gbase-t"
      Creates an interface named "NewInterface" on device "NewHost" with type "10gbase-t"
   .PARAMETER Name
      Name of the interface
   .PARAMETER Label
      Label of the interface
   .PARAMETER DeviceName
      Name of the parent device
   .PARAMETER DeviceID
      ID of the parent device
   .PARAMETER Type
      Type of the interface
   .PARAMETER MacAddress
      MAC address of the interface
   .PARAMETER ManagementOnly
      Is this interface only for management?
   .PARAMETER Confirm
      Confirm the creation of the interface
    .PARAMETER Force
      Forces the creation of the interface
   .INPUTS
      Inputs (if any)
   .OUTPUTS
      NetBox.Interface
   .NOTES
      General notes
   #>

   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $DeviceName,

      [Parameter(Mandatory = $true, ParameterSetName = "ById")]
      [Int32]
      $DeviceID,

      [Parameter(Mandatory = $true)]
      [String]
      $Name,

      [Parameter(Mandatory = $false)]
      [String]
      $Label,

      #"virtual", "lag", "100base-tx", "1000base-t", "2.5gbase-t", "5gbase-t", "10gbase-t", "10gbase-cx4", "1000base-x-gbic", "1000base-x-sfp", "10gbase-x-sfpp", "10gbase-x-xfp", "10gbase-x-xenpak", "10gbase-x-x2", "25gbase-x-sfp28", "50gbase-x-sfp56", "40gbase-x-qsfpp", "50gbase-x-sfp28", "100gbase-x-cfp", "100gbase-x-cfp2", "200gbase-x-cfp2", "100gbase-x-cfp4", "100gbase-x-cpak", "100gbase-x-qsfp28", "200gbase-x-qsfp56", "400gbase-x-qsfpdd", "400gbase-x-osfp", "ieee802.11a", "ieee802.11g", "ieee802.11n", "ieee802.11ac", "ieee802.11ad", "ieee802.11ax", "gsm", "cdma", "lte", "sonet-oc3", "sonet-oc12", "sonet-oc48", "sonet-oc192", "sonet-oc768", "sonet-oc1920", "sonet-oc3840", "1gfc-sfp", "2gfc-sfp", "4gfc-sfp", "8gfc-sfpp", "16gfc-sfpp", "32gfc-sfp28", "64gfc-qsfpp", "128gfc-sfp28", "infiniband-sdr", "infiniband-ddr", "infiniband-qdr", "infiniband-fdr10", "infiniband-fdr", "infiniband-edr", "infiniband-hdr", "infiniband-ndr", "infiniband-xdr", "t1", "e1", "t3", "e3", "xdsl", "cisco-stackwise", "cisco-stackwise-plus", "cisco-flexstack", "cisco-flexstack-plus", "juniper-vcp", "extreme-summitstack", "extreme-summitstack-128", "extreme-summitstack-256", "extreme-summitstack-512", "other"
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
      $Confirm = $true,

      [Parameter(Mandatory = $false)]
      [Switch]
      $Force
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

      $Body = @{
         name        = (Get-Culture).Textinfo.ToTitleCase($Name)
         device      = $Device.ID
         type        = $Type
         mgmt_only   = $ManagmentOnly
         mac_address = $MacAddress

      }
      # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
      ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

      if ($Confirm) {
         $OutPutObject = [pscustomobject]$Body
         Show-ConfirmDialog -Object $OutPutObject
      }

      $Interface = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
      $Interface.PSObject.TypeNames.Insert(0, "NetBox.Interface")
      return $Interface
   }
}

function Update-Interface {
   <#
   .SYNOPSIS
      Updates an existing interface in netbox
   .DESCRIPTION
      Long description
   .EXAMPLE
      PS C:\> Update-NetBoxInterface -Id "1" -Name "NewInterface" -Type "10gbase-t" -MacAddress "00:00:00:00:00:00"
      Updates an interface with id "1" to have name "NewInterface" with type "10gbase-t" and MAC address "00:00:00:00:00:00"
    .PARAMETER DeviceName
       Name of the parent device
    .PARAMETER DeviceID
       ID of the parent device
   .PARAMETER Device
      Name of the parent device
   .PARAMETER ID
      ID of the interface
   .PARAMETER Type
      Type of the interface
   .PARAMETER MacAddress
      MAC address of the interface
   .PARAMETER ManagmentOnly
      Is this interface only for management?
   .PARAMETER Confirm
      Confirm the chnages to the interface
   .INPUTS
      Inputs (if any)
   .OUTPUTS
      Output (if any)
   .NOTES
      General notes
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
      $Id,

      [Parameter(Mandatory = $false)]
      [String]
      $Label,

      #"virtual", "lag", "100base-tx", "1000base-t", "2.5gbase-t", "5gbase-t", "10gbase-t", "10gbase-cx4", "1000base-x-gbic", "1000base-x-sfp", "10gbase-x-sfpp", "10gbase-x-xfp", "10gbase-x-xenpak", "10gbase-x-x2", "25gbase-x-sfp28", "50gbase-x-sfp56", "40gbase-x-qsfpp", "50gbase-x-sfp28", "100gbase-x-cfp", "100gbase-x-cfp2", "200gbase-x-cfp2", "100gbase-x-cfp4", "100gbase-x-cpak", "100gbase-x-qsfp28", "200gbase-x-qsfp56", "400gbase-x-qsfpdd", "400gbase-x-osfp", "ieee802.11a", "ieee802.11g", "ieee802.11n", "ieee802.11ac", "ieee802.11ad", "ieee802.11ax", "gsm", "cdma", "lte", "sonet-oc3", "sonet-oc12", "sonet-oc48", "sonet-oc192", "sonet-oc768", "sonet-oc1920", "sonet-oc3840", "1gfc-sfp", "2gfc-sfp", "4gfc-sfp", "8gfc-sfpp", "16gfc-sfpp", "32gfc-sfp28", "64gfc-qsfpp", "128gfc-sfp28", "infiniband-sdr", "infiniband-ddr", "infiniband-qdr", "infiniband-fdr10", "infiniband-fdr", "infiniband-edr", "infiniband-hdr", "infiniband-ndr", "infiniband-xdr", "t1", "e1", "t3", "e3", "xdsl", "cisco-stackwise", "cisco-stackwise-plus", "cisco-flexstack", "cisco-flexstack-plus", "juniper-vcp", "extreme-summitstack", "extreme-summitstack-128", "extreme-summitstack-256", "extreme-summitstack-512", "other"
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
      # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
      ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

      if ($Confirm) {
         $OutPutObject = [pscustomobject]$Body
         Show-ConfirmDialog -Object $OutPutObject
      }

      Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Interface.id) + "/") @RestParams -Method Patch -Body $($Body | ConvertTo-Json)
   }
}

function Remove-Interface {
   <#
   .SYNOPSIS
      Deletes an interface from netbox
   .DESCRIPTION
      Long description
   .EXAMPLE
      PS C:\> Remove-NetBoxInterface -Id "1"
      Deletes an interface with id "1"
   .PARAMETER Name
      Name of the interface
   .PARAMETER ID
      ID of the interface
   .PARAMETER Recurse
      Deletes all related objects as well
   .PARAMETER Confirm
      Confirm the deletion of the interface
    .PARAMETER InputObject
      interface object to delete
   .INPUTS
      NetBox.Interface
   .OUTPUTS
      Output (if any)
   .NOTES
      General notes
   #>

   [CmdletBinding(DefaultParameterSetName = "ByName")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $Name,

      [Parameter(Mandatory = $false)]
      [Switch]
      $Recurse,

      [Parameter(Mandatory = $false)]
      [Bool]
      $Confirm = $true,

      [Parameter(ValueFromPipeline = $true, ParameterSetName = 'ByInputObject')]
      $InputObject
   )

   begin {

      Test-Config | Out-Null
      $URL = "/dcim/interfaces/"
   }

   process {
      if ($InputObject) {
         $Name = $InputObject.name
      }

      $Interface = Get-Interface -Model $Name

      $RelatedObjects = Get-RelatedObjects -Object $Interface -ReferenceObjects Interface

      if ($Confirm) {
         Show-ConfirmDialog -Object $Interface
      }

      # Remove all related objects
      if ($Recurse) {
         foreach ($Object in $RelatedObjects) {
            Invoke-RestMethod -Uri $Object.url @RestParams -Method Delete | Out-Null
         }
      }

      try {
         Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Interface.id) + "/") @RestParams -Method Delete
      }
      catch {
         if ((($RestError.ErrorRecord) | ConvertFrom-Json).Detail -like "Unable to delete object*") {
            Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
            Write-Error "Delete those objects first or run again using -recurse switch"
         }
         else {
            Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
         }
      }
   }
}

function Get-PowerPortTemplate {
   <#
    .SYNOPSIS
       Retrives a power port template from netbox
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> Get-NetBoxPowerPortTemplate -Name "PSU1"
       Retrives Power Port Template with name "PSU1"
    .PARAMETER Name
       Name of the power port template
    .PARAMETER ID
       ID of the power port template
    .PARAMETER DeviceTypeName
       Search for parent device type by name
    .PARAMETER DeviceTypeID
       Search for parent device type by ID
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       Output (if any)
    .NOTES
       General notes
    #>

   param (
      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Name,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $DeviceTypeName,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $DeviceTypeID
   )

   begin {
      Test-Config | Out-Null
      $URL = "/dcim/power-port-templates/"
   }
   process {
      $Query = "?"

      if ($Name) {
         $Query = $Query + "name__ic=$($Name)&"
      }

      if ($DeviceTypeName) {
         $Query = $Query + "devicetype_id=$($(Get-DeviceType -Name $DeviceTypeName).ID)&"
      }
      if ($DeviceTypeID) {
         $Query = $Query + "devicetype_id=$($DeviceTypeID)&"
      }

      if ($Id) {
         $Query = $Query + "id=$($id)&"
      }

      $Query = $Query.TrimEnd("&")

      $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

      $PowerPortTemplates = New-Object collections.generic.list[object]

      foreach ($Item in $Result) {
         [PSCustomObject]$PowerPortTemplate = $item
         $PowerPortTemplate.PSObject.TypeNames.Insert(0, "NetBox.PowerPortTemplate")
         $PowerPortTemplates += $PowerPortTemplate
      }

      return $PowerPortTemplates
   }
}

function New-PowerPortTemplate {
   <#
    .SYNOPSIS
       Creates new port template in netbox
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> New-NetBoxPowerPortTemplate -Name "PSU1"
       Creates a new power port template with name "PSU1"
    .PARAMETER Name
       Name of the power port template
    .PARAMETER DeviceTypeName
       Name of the Device type of the device
    .PARAMETER DeviceTypeID
       ID of the Device type of the device
    .PARAMETER Type
      Type of the power port template
    .PARAMETER Label
      Label of the power port template
    .PARAMETER MaxiumDraw
      Maximum draw of the power port template
    .PARAMETER AllocatedPower
      Allocated power of the power port template
    .PARAMETER Confirm
      Confirm the creation of the power port template
    .PARAMETER Force
      Forces the creation of the power port template
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       NetBox.PowerPortTemplate
    .NOTES
       General notes
    #>

   [CmdletBinding(DefaultParameterSetName = "Byname")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $DeviceTypeName,

      [Parameter(Mandatory = $true, ParameterSetName = "ByID")]
      [Int32]
      $DeviceTypeID,

      [Parameter(Mandatory = $true)]
      [String]
      $Name,

      [Parameter(Mandatory = $false)]
      [String]
      $Label,

      #"iec-60320-c6", "iec-60320-c8", "iec-60320-c14", "iec-60320-c16", "iec-60320-c20", "iec-60320-c22", "iec-60309-p-n-e-4h", "iec-60309-p-n-e-6h", "iec-60309-p-n-e-9h", "iec-60309-2p-e-4h", "iec-60309-2p-e-6h", "iec-60309-2p-e-9h", "iec-60309-3p-e-4h", "iec-60309-3p-e-6h", "iec-60309-3p-e-9h", "iec-60309-3p-n-e-4h", "iec-60309-3p-n-e-6h", "iec-60309-3p-n-e-9h", "nema-1-15p", "nema-5-15p", "nema-5-20p", "nema-5-30p", "nema-5-50p", "nema-6-15p", "nema-6-20p", "nema-6-30p", "nema-6-50p", "nema-10-30p", "nema-10-50p", "nema-14-20p", "nema-14-30p", "nema-14-50p", "nema-14-60p", "nema-15-15p", "nema-15-20p", "nema-15-30p", "nema-15-50p", "nema-15-60p", "nema-l1-15p", "nema-l5-15p", "nema-l5-20p", "nema-l5-30p", "nema-l5-50p", "nema-l6-15p", "nema-l6-20p", "nema-l6-30p", "nema-l6-50p", "nema-l10-30p", "nema-l14-20p", "nema-l14-30p", "nema-l14-50p", "nema-l14-60p", "nema-l15-20p", "nema-l15-30p", "nema-l15-50p", "nema-l15-60p", "nema-l21-20p", "nema-l21-30p", "cs6361c", "cs6365c", "cs8165c", "cs8265c", "cs8365c", "cs8465c", "ita-c", "ita-e", "ita-f", "ita-ef", "ita-g", "ita-h", "ita-i", "ita-j", "ita-k", "ita-l", "ita-m", "ita-n", "ita-o", "usb-a", "usb-b", "usb-c", "usb-mini-a", "usb-mini-b", "usb-micro-a", "usb-micro-b", "usb-3-b", "usb-3-micro-b", "dc-terminal", "saf-d-grid", "hardwired"
      [Parameter(Mandatory = $true)]
      [String]
      $Type,

      [Parameter(Mandatory = $false)]
      [Int32]
      $MaxiumDraw,

      [Parameter(Mandatory = $false)]
      [Int32]
      $AllocatedDraw,

      [Parameter(Mandatory = $false)]
      [Bool]
      $Confirm = $true,

      [Parameter(Mandatory = $false)]
      [Switch]
      $Force
   )

   begin {
      Test-Config | Out-Null
      $URL = "/dcim/power-port-templates/"
   }

   process {
      if ($DeviceTypeName) {
         $DeviceType = Get-DeviceType -Model $DeviceTypeName
      }

      if ($DeviceTypeID) {
         $DeviceType = Get-DeviceType -ID $DeviceTypeID
      }

      if (Get-PowerPortTemplate -DeviceTypeID $DeviceType.ID -Name $Name ) {
         Write-Warning "PowerPortTemplate $($DeviceType.Model) - $Name already exists"
         $Exists = $true
      }

      $Body = @{
         name           = (Get-Culture).Textinfo.ToTitleCase($Name)
         device_type    = $DeviceType.ID
         type           = $Type
         maximum_draw   = $MaxiumDraw
         allocated_draw = $AllocatedDraw
      }

      # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
      ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

      if ($Confirm) {
         $OutPutObject = [pscustomobject]$Body
         Show-ConfirmDialog -Object $OutPutObject
      }
      if (-Not $Exists) {
         $PowerPortTemplates = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
         $PowerPortTemplates.PSObject.TypeNames.Insert(0, "NetBox.PowerPortTemplate")
         return $PowerPortTemplates
      }
      else {
         return
      }
   }
}

function Remove-PowerPortTemplate {
   <#
   .SYNOPSIS
      Short description
   .DESCRIPTION
      Long description
   .EXAMPLE
      PS C:\> <example usage>
      Explanation of what the example does
   .PARAMETER Name
      The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
   .INPUTS
      NetBox.PowerPortTemplate
   .OUTPUTS
      Output (if any)
   .NOTES
      General notes
   #>

   [CmdletBinding(DefaultParameterSetName = "ByName")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $Name,

      [Parameter(Mandatory = $false)]
      [Switch]
      $Recurse,

      [Parameter(Mandatory = $false)]
      [Bool]
      $Confirm = $true,

      [Parameter(ValueFromPipeline = $true, ParameterSetName = 'ByInputObject')]
      $InputObject
   )
   begin {
      Test-Config | Out-Null
      $URL = "/dcim/power-port-templates/"
   }
   process {
      if ($InputObject) {
         $Name = $InputObject.Name
      }
   }
}

function Get-Cable {
   <#
   .SYNOPSIS
      Gets cables form NetBox
   .DESCRIPTION
      Long description
   .EXAMPLE
      PS C:\> Get-Cable -Device "ServerA"
      Gets all cables for ServerA
   .PARAMETER Label
      Name of the cable
   .PARAMETER ID
      ID of the cable
   .PARAMETER Device
      Name of the parent device
   .PARAMETER Rack
      Name of the parent rack
   .INPUTS
      Inputs (if any)
   .OUTPUTS
      NetBox.Interface
   .NOTES
      General notes
   #>

   param (
      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Label,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Device,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Rack
   )

   begin {
      Test-Config | Out-Null
      $URL = "/dcim/cables/"
   }

   process {
      $Query = "?"

      if ($Label) {
         $Query = $Query + "Label__ic=$($Label)&"
      }

      if ($Id) {
         $Query = $Query + "id=$($id)&"
      }

      if ($Device) {
         $Query = $Query + "device__ic=$($Device)&"
      }

      if ($Rack) {
         $Query = $Query + "rack=$($Rack)&"
      }

      $Query = $Query.TrimEnd("&")

      $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

      $Cables = New-Object collections.generic.list[object]

      foreach ($Item in $Result) {
         [PSCustomObject]$Cable = $item
         $Cable.PSObject.TypeNames.Insert(0, "NetBox.Cable")
         $Cables += $Cable
      }

      return $Cables
   }
}

function New-Cable {
   <#
   .SYNOPSIS
      Creates a new cable in NetBox
   .DESCRIPTION
      Long description
   .EXAMPLE
      PS C:\> New-NetBoxCable -InterfaceA "Gig-E 1" -DeviceA ServerA -InterfaceB "GigabitEthernet1/0/39" -DeviceB SwitchB -Label "Super important Cable" -Type cat6 -Color "aa1409" -Length 100 -LengthUnit m
      Creates a cable between ServerA, Gig-E 1 and SwitchB, GigabitEthernet1/0/39 with the label "Super important Cable" and the type cat6 and the color "aa1409" and the length 100m
   .PARAMETER DeviceAName
      Name of Endpoint Device A of the cable
   .PARAMETER InterfaceAName
      Name Endpoint Interface A of the cable
   .PARAMETER DeviceAID
      ID of Endpoint Device A of the cable
   .PARAMETER InterfaceAID
      ID Endpoint Interface A of the cable
   .PARAMETER DeviceBName
      Name of Endpoint Device B of the cable
   .PARAMETER InterfaceBName
      Name Endpoint Interface B of the cable
   .PARAMETER DeviceBID
      ID of Endpoint Device B of the cable
   .PARAMETER InterfaceBID
      ID Endpoint Interface B of the cable
   .PARAMETER Label
      Label of the cable
   .PARAMETER Type
      Type of the cable, e.g. cat6
   .PARAMETER Color
      Color of the cable, e.g. "aa1409"
   .PARAMETER Length
      Length of the cable, e.g. 10
   .PARAMETER LengthUnit
      Length unit of the cable, e.g. m(eter)
   .PARAMETER Confirm
      Confirm the creation of the cable
   .PARAMETER Force
      Force the creation of the cable (overwrite existing cable)
   .INPUTS
      NetBox.Cable
   .OUTPUTS
      Netbox.Cable
   .NOTES
      General notes
   #>
   [CmdletBinding(DefaultParameterSetName = "ByName")]
   param (
      [Parameter(Mandatory = $false)]
      $DeviceAName,

      [Parameter(Mandatory = $false)]
      [String]
      $InterfaceAName,

      [Parameter(Mandatory = $false)]
      $DeviceAID,

      [Parameter(Mandatory = $false)]
      [String]
      $InterfaceAID,

      [Parameter(Mandatory = $false)]
      $DeviceBName,

      [Parameter(Mandatory = $false)]
      [String]
      $InterfaceBName,

      [Parameter(Mandatory = $false)]
      $DeviceBID,

      [Parameter(Mandatory = $false)]
      [String]
      $InterfaceBID,

      [Parameter(Mandatory = $false)]
      [String]
      $Label,

      [Parameter(Mandatory = $true)]
      [ValidateSet("cat3", "cat5", "cat5e", "cat6", "cat6a", "cat7", "cat7a", "cat8", "dac-active", "dac-passive", "mrj21-trunk", "coaxial", "mmf", "mmf-om1", "mmf-om2", "mmf-om3", "mmf-om4", "mmf-om5", "smf", "smf-os1", "smf-os2", "aoc", "power")]
      [String]
      $Type,

      [Parameter(Mandatory = $false)]
      [String]
      $Color,

      [Parameter(Mandatory = $false)]
      [String]
      $Status,

      [Parameter(Mandatory = $false)]
      [Int32]
      $Length,

      [Parameter(Mandatory = $false)]
      [ValidateSet("km", "m", "cm", "mi", "ft", "in")]
      [String]
      $LengthUnit,

      [Parameter(Mandatory = $false)]
      [Bool]
      $Confirm = $true,

      [Parameter(Mandatory = $false)]
      [Switch]
      $Force
   )

   begin {
      Test-Config | Out-Null
      $URL = "/dcim/cables/"
   }

   process {
      # Gather devices and interfaces
      if ($DeviceAName) {
         $DeviceA = Get-Device -Name $DeviceAName -Exact
      }
      else {
         $DeviceA = Get-Device -ID $DeviceAId
      }

      if ($DeviceBName) {
         $DeviceB = Get-Device -Name $DeviceBName -Exact
      }
      else {
         $DeviceB = Get-Device -ID $DeviceBId
      }

      if ($InterfaceAName) {
         $StartPoint = Get-Interface -DeviceID $DeviceA.ID -Name $InterfaceAName
      }
      else {
         $StartPoint = Get-Interface -DeviceID $DeviceA.ID -ID $InterfaceAID
      }

      if ($InterfaceBName) {
         $EndPoint = Get-Interface -DeviceID $DeviceB.ID -Name $InterfaceBName
      }
      else {
         $EndPoint = Get-Interface -DeviceID $DeviceB.ID -ID $InterfaceBID
      }

      if ($null -eq $Startpoint) {
         Write-Error "InterfaceA $InterfaceA does not exist"
         break
      }

      if ($null -eq $Endpoint) {
         Write-Error "InterfaceB $InterfaceB does not exist"
         break
      }


      if ($StartPoint.ID -eq $EndPoint.ID) {
         Write-Error "Cannot create a cable between the same interface"
         break
      }
      if (($Null -ne $StartPoint.Cable) -or ($Null -ne $EndPoint.Cable)) {
         Write-Error "Cannot create a cable between an interface that already has a cable"
         break
      }

      $Body = @{
         termination_a_type = "dcim.interface"
         termination_a_id   = $StartPoint.id
         termination_b_type = "dcim.interface"
         termination_b_id   = $EndPoint.id
         type               = $Type
         label              = $Label
         color              = $Color
         status             = $Status
         length             = $Length
         length_unit        = $LengthUnit
      }

      # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
      ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

      if ($Confirm) {
         $OutPutObject = [pscustomobject]$Body
         Show-ConfirmDialog -Object $OutPutObject
      }

      $Cable = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
      $Cable.PSObject.TypeNames.Insert(0, "NetBox.Cable")
      return $Cable
   }
}

# function Update-Cable {
#    <#
#    .SYNOPSIS
#       Updates an existing cable in NetBox
#    .DESCRIPTION
#       Long description
#    .EXAMPLE
#       PS C:\> Update-NetBoxCable -Id 1 -Label "Normal Cable" -Color "ffffff"
#       Updates the cable with the id 1 with the label "Normal Cable" and the color "ffffff"
#    .PARAMETER Name
#       The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
#    .INPUTS
#       Inputs (if any)
#    .OUTPUTS
#       Output (if any)
#    .NOTES
#       General notes
#    #>
#    param (
#       [Parameter(Mandatory = $true)]
#       $DeviceA,

#       [Parameter(Mandatory = $true)]
#       [String]
#       $InterfaceA,

#       [Parameter(Mandatory = $true)]
#       $DeviceB,

#       [Parameter(Mandatory = $true)]
#       [String]
#       $InterfaceB,

#       [Parameter(Mandatory = $false)]
#       [String]
#       $Label,

#       [Parameter(Mandatory = $true)]
#       [ValidateSet("cat3", "cat5", "cat5e", "cat6", "cat6a", "cat7", "cat7a", "cat8", "dac-active", "dac-passive", "mrj21-trunk", "coaxial", "mmf", "mmf-om1", "mmf-om2", "mmf-om3", "mmf-om4", "mmf-om5", "smf", "smf-os1", "smf-os2", "aoc", "power")]
#       [String]
#       $Type,

#       [Parameter(Mandatory = $false)]
#       [String]
#       $Color,

#       [Parameter(Mandatory = $false)]
#       [String]
#       $Status,

#       [Parameter(Mandatory = $false)]
#       [Int32]
#       $Length,

#       [Parameter(Mandatory = $false)]
#       [Bool]
#       $Confirm = $true,

#       [Parameter(Mandatory = $false)]
#       [Switch]
#       $Force
#    )

#    begin {
#       Test-Config | Out-Null
#       $URL = "/dcim/cables/"
#    }

#    process {
#       $Body = @{
#          termination_a_type = "dcim.interface"
#          termination_a_id   = $(Get-Interface -DeviceName $DeviceA -Interface $InterfaceA).id
#          termination_b_type = "dcim.interface"
#          termination_b_id   = $(Get-Interface -DeviceName $DeviceB -Interface $InterfaceB).id
#          type               = $Type
#          label              = $Label
#          color              = $Color
#          status             = $Status
#          length             = $Length
#       }

#       # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
#    ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

#       if ($Confirm) {
#          $OutPutObject = [pscustomobject]$Body
#          Show-ConfirmDialog -Object $OutPutObject
#       }

#       $Cable = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Patch -Body $($Body | ConvertTo-Json)
#       $Cable.PSObject.TypeNames.Insert(0, "NetBox.Cable")
#       return $Cable
#    }
# }

function Remove-Cable {
   <#
   .SYNOPSIS
      Deletes a cable from NetBox
   .DESCRIPTION
      Long description
   .EXAMPLE
      PS C:\> Remove-NetboxCable -Id 1
      Deletes cable with the id 1
   .PARAMETER Label
      Label of the Cable
   .PARAMETER ID
      ID of the Cable
   .PARAMETER Confirm
      Confirm the deletion of the cable
   .INPUTS
      Inputs (if any)
   .OUTPUTS
      Output (if any)
   .NOTES
      General notes
   #>
   param (
      [Parameter(Mandatory = $True)]
      [String]
      $Label,

      [Parameter(Mandatory = $false)]
      [String]
      $ID,

      [Parameter(Mandatory = $false)]
      [Bool]
      $Confirm = $true,

      [Parameter(Mandatory = $false)]
      [Switch]
      $Force
   )

   begin {
      Test-Config | Out-Null
      $URL = "/dcim/cables/"
   }
   process {
      if ($Label) {
         $Cable = Get-Cable -Label $Label
      }
      elseif ($ID) {
         $Cable = Get-Cable -ID $ID
      }
      else {
         Write-Error "Either -Label or -ID must be specified"
      }

      if ($Confirm) {
         Show-ConfirmDialog -Object $Interface
      }

      try {
         Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Cable.id) + "/") @RestParams -Method Delete
      }
      catch {
         if ((($RestError.ErrorRecord) | ConvertFrom-Json).Detail -like "Unable to delete object*") {
            Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
            Write-Error "Delete those objects first or run again using -recurse switch"
         }
         else {
            Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
         }
      }
   }
}

function Get-DeviceBayTemplate {
   <#
   .SYNOPSIS
      Short description
   .DESCRIPTION
      Long description
   .EXAMPLE
      PS C:\> <example usage>
      Explanation of what the example does
   .PARAMETER Name
      Name of the device bay
   .PARAMETER Id
      Id of the device bay
   .PARAMETER DeviceTypeName
      Name of the device Type
   .PARAMETER DeviceTypeID
      ID of the device type
   .INPUTS
      Inputs (if any)
   .OUTPUTS
      Output (if any)
   .NOTES
      General notes
   #>

   param (
      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Name,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $DeviceTypeName,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $DeviceTypeID


   )
   begin {
      Test-Config | Out-Null
      $URL = "/dcim/device-bay-templates/"
   }
   process {
      $Query = "?"

      if ($Name) {
         $Query = $Query + "name__ic=$($Name)&"
      }

      if ($DeviceTypeName) {
         $Query = $Query + "devicetype_id=$($(Get-DeviceType -Name $DeviceTypeName).ID)&"
      }
      if ($DeviceTypeID) {
         $Query = $Query + "devicetype_id=$($DeviceTypeID)&"
      }

      if ($Id) {
         $Query = $Query + "id=$($id)&"
      }

      $Query = $Query.TrimEnd("&")

      $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

      $DeviceBayTemplates = New-Object collections.generic.list[object]

      foreach ($Item in $Result) {
         [PSCustomObject]$DeviceBayTemplate = $item
         $DeviceBayTemplate.PSObject.TypeNames.Insert(0, "NetBox.DeviceBayTemplate")
         $DeviceBayTemplates += $DeviceBayTemplate
      }

      return $InterfaceTemplates
   }
}

function New-DeviceBayTemplate {
   <#
   .SYNOPSIS
      Short description
   .DESCRIPTION
      Long description
   .EXAMPLE
      PS C:\> <example usage>
      Explanation of what the example does
   .PARAMETER Name
      Name of the device bay
    .PARAMETER DeviceTypeName
       Search for parent device type by name
    .PARAMETER DeviceTypeID
       Search for parent device type by ID
   .INPUTS
      Inputs (if any)
   .OUTPUTS
      Output (if any)
   .NOTES
      General notes
   #>

   [CmdletBinding(DefaultParameterSetName = "ByName")]
   param (
      [Parameter(Mandatory = $true)]
      [String]
      $Name,

      [Parameter(Mandatory = $false, ParameterSetName = "ByName")]
      [String]
      $DeviceTypeName,

      [Parameter(Mandatory = $false, ParameterSetName = "ByID")]
      [Int32]
      $DeviceTypeID,

      [Parameter(Mandatory = $false)]
      [String]
      $Label,

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
      $URL = "/dcim/device-bay-templates/"
   }

   process {
      if ($DeviceTypeName) {
         $DeviceType = Get-DeviceType -Model $DeviceTypeName
      }

      if ($DeviceTypeID) {
         $DeviceType = Get-DeviceType -ID $DeviceTypeID
      }

      $Body = @{
         name        = (Get-Culture).Textinfo.ToTitleCase($Name)
         device_type = $DeviceType.ID
         label       = $Label
         description = $Description
      }

      # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
      ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

      if ($Confirm) {
         $OutPutObject = [pscustomobject]$Body
         Show-ConfirmDialog -Object $OutPutObject
      }

      if (-Not $Exists) {
         $DeviceBayTemplate = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
         $DeviceBayTemplate.PSObject.TypeNames.Insert(0, "NetBox.InterfaceTemplate")
         return $DeviceBayTemplate
      }
      else {
         return
      }
   }
}

function Get-DeviceBay {
   <#
   .SYNOPSIS
      Get a specific device from netbox
   .DESCRIPTION
      Long description
   .EXAMPLE
      PS C:\> Get-NetBoxDeviceBay -Device "Chassis"
      Get all device bays for device "Chassis"
   .PARAMETER Name
      Name of the devicebay
   .PARAMETER Id
      Id of the devicebay
   .PARAMETER DeviceName
      Name of the parent device
   .PARAMETER DeviceID
      Id of the parent device
   .INPUTS
      NetBox.DeviceBay
   .OUTPUTS
      NetBox.DeviceBay
   .NOTES
      General notes
   #>

   param (
      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Name,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $DeviceName,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $DeviceID
   )

   begin {
      Test-Config | Out-Null
      $URL = "/dcim/device-bays/"
   }

   process {
      $Query = "?"

      if ($Name) {
         $Query = $Query + "name=$($Name)&"
      }

      if ($Id) {
         $Query = $Query + "id=$($id)&"
      }

      if ($DeviceName) {
         $Query = $Query + "device_id=$((Get-NetBoxDevice -Name $DeviceName).ID)&"
      }

      if ($DeviceID) {
         $Query = $Query + "device_id=$((Get-NetBoxDevice -Id $DeviceID).ID)&"
      }

      $Query = $Query.TrimEnd("&")

      $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

      Write-Verbose $($NetboxURL + $URL + $Query)

      $DeviceBays = New-Object collections.generic.list[object]

      foreach ($Item in $Result) {
         [PSCustomObject]$DeviceBay = $item
         $DeviceBay.PSObject.TypeNames.Insert(0, "NetBox.DeviceBay")
         $DeviceBays += $DeviceBay
      }

      return $DeviceBays
   }
}

function New-DeviceBay {
   <#
   .SYNOPSIS
      Creates an devicebay in netbox
   .DESCRIPTION
      Long description
   .EXAMPLE
      PS C:\> New-NetBoxDeviceBay -Device "Chassis" -Name "1"
      Creates a devicebay with name "1" for device "Chassis"
   .PARAMETER Name
      Name of the devicebay
   .PARAMETER DeviceName
      Name of the parent device
   .PARAMETER DeviceID
      Id of the parent device
   .PARAMETER InstalledDeviceName
      Name of the installed / child device
   .PARAMETER InstalledDeviceID
      Id of the installed / child device
   .INPUTS
      NetBox.DeviceBay
   .OUTPUTS
      NetBox.DeviceBay
   .NOTES
      General notes
   #>

   param (

      [Parameter(Mandatory = $true)]
      [String]
      $Name,

      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $DeviceName,

      [Parameter(Mandatory = $true, ParameterSetName = "ById")]
      [Int32]
      $DeviceID,

      [Parameter(Mandatory = $false)]
      [String]
      $Label,

      [Parameter(Mandatory = $false)]
      [String]
      $InstalledDeviceName,

      [Parameter(Mandatory = $false)]
      [String]
      $InstalledDeviceID,

      [Parameter(Mandatory = $false)]
      [Bool]
      $Confirm = $true,

      [Parameter(Mandatory = $false)]
      [Switch]
      $Force
   )

   begin {
      Test-Config | Out-Null
      $URL = "/dcim/device-bays/"
   }

   process {
      if ($DeviceName) {
         $Device = Get-Device -Name $DeviceName
      }

      if ($DeviceID) {
         $Device = Get-Device -ID $DeviceID
      }

      if ($InstalledDeviceName) {
         $InstalledDevice = Get-Device -Name InstalledDeviceName
      }

      if ($InstalledDeviceID) {
         $InstalledDevice = Get-Device -ID InstalledDeviceID
      }

      $Body = @{
         name             = (Get-Culture).Textinfo.ToTitleCase($Name)
         device           = $Device.ID
         installed_device = $InstalledDevice.ID
      }

      # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
      ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

      if ($Confirm) {
         $OutPutObject = [pscustomobject]$Body
         Show-ConfirmDialog -Object $OutPutObject
      }

      $DeviceBay = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
      $DeviceBay.PSObject.TypeNames.Insert(0, "NetBox.Devicebay")
      return $DeviceBay
   }
}

function Update-DeviceBay {
   <#
   .SYNOPSIS
      Updates an devicebay in netbox
   .DESCRIPTION
      Long description
   .EXAMPLE
      PS C:\> Update-NetBoxDeviceBay -Device "Chassis" -Name "1"
      Creates a devicebay with name "1" for device "Chassis"
   .PARAMETER Name
      Name of the devicebay
   .PARAMETER DeviceName
      Name of the parent device
   .PARAMETER DeviceID
      Id of the parent device
   .PARAMETER InstalledDeviceName
      Name of the installed / child device
   .PARAMETER InstalledDeviceID
      Id of the installed / child device
   .INPUTS
      NetBox.DeviceBay
   .OUTPUTS
      NetBox.DeviceBay
   .NOTES
      General notes
   #>

   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $DeviceName,

      [Parameter(Mandatory = $true, ParameterSetName = "ById")]
      [Int32]
      $DeviceID,

      [Parameter(Mandatory = $true)]
      [String]
      $Name,

      [Parameter(Mandatory = $false)]
      [String]
      $Label,

      [Parameter(Mandatory = $false)]
      [String]
      $InstalledDeviceName,

      [Parameter(Mandatory = $false)]
      [String]
      $InstalledDeviceID,

      [Parameter(Mandatory = $false)]
      [Bool]
      $Confirm = $true,

      [Parameter(Mandatory = $false)]
      [Switch]
      $Force
   )
   begin {
      Test-Config | Out-Null
      $URL = "/dcim/device-bays/"
   }

   process {
      if ($DeviceName) {
         $Device = Get-Device -Name $DeviceName -Exact
      }

      if ($DeviceID) {
         $Device = Get-Device -ID $DeviceID
      }

      if ($InstalledDeviceName) {
         $InstalledDevice = Get-Device -Name $InstalledDeviceName -Exact
      }

      if ($InstalledDeviceID) {
         $InstalledDevice = Get-Device -ID $InstalledDeviceID
      }

      $DeviceBay = Get-DeviceBay -Name $Name -DeviceId $Device.ID

      $Body = @{
         name             = (Get-Culture).Textinfo.ToTitleCase($Name)
         device           = @{
            id   = $Device.ID
            name = $Device.Name
         }
         installed_device = @{
            name = $InstalledDevice.Name
            id   = $InstalledDevice.ID
         }
      }

      # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
      ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

      if ($Confirm) {
         $OutPutObject = [pscustomobject]$Body
         Show-ConfirmDialog -Object $OutPutObject
      }

      $DeviceBay = Invoke-RestMethod -Uri $($NetboxURL + $URL + $($DeviceBay.id) + "/") @RestParams -Method Patch -Body $($Body | ConvertTo-Json)
      $DeviceBay.PSObject.TypeNames.Insert(0, "NetBox.Devicebay")
      return $DeviceBay
   }
}