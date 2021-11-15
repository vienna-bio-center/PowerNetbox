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
   $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Get

   $CompleteResult = $Result.Results

   do {
      $Result = Invoke-RestMethod -Uri $Result.next @RestParams -Method Get
      $CompleteResult += $Result.Results
   } until ($null -eq $result.next)

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
    .PARAMETER All
       Returns all sites
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       NetBox.Site
    .NOTES
       General notes
    #>

   [CmdletBinding(DefaultParameterSetName = "All")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $Name,

      [Parameter(Mandatory = $true, ParameterSetName = "ById")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $true, ParameterSetName = "All")]
      [Switch]
      $All
   )

   Test-Config | Out-Null
   $URL = "/dcim/sites/"


   if ($Name) {
      $Query = "?name__ic=$($Name)"
   }

   if ($ID) {
      $Query = "?id=$($ID)"
   }

   if ($All) {
      $Query = ""
   }

   $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get

   if ($Result.Count -gt 50) {
      $Result = Get-NextPage -Result $Result
      $Site = $Result
   }
   else {
      $Site = $Result.Results
   }
   $Site.PSObject.TypeNames.Insert(0, "NetBox.Site")
   return $Site
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
    .PARAMETER Confirm
      Confirm the creation of the site
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
      $Confirm = $true
   )

   Test-Config | Out-Null
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

   if ($Confirm) {
      $OutPutObject = [pscustomobject]$Body
      Show-ConfirmDialog -Object $OutPutObject
   }

   $Site = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
   $Site.PSObject.TypeNames.Insert(0, "NetBox.Site")
   return $Site
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

      if ($InputObject) {
         $Name = $InputObject.name
      }

      $Site = Get-Site -Name $Name

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
    .PARAMETER All
       Returns all locations
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       NetBox.Location
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

      [Parameter(Mandatory = $true, ParameterSetName = "All")]
      [Switch]
      $All
   )

   Test-Config | Out-Null
   $URL = "/dcim/locations/"

   # If name contains spaces, use slug instead
   if ($Name -like " ") {
      $Slug = $Name.tolower() -replace " ", "-"
      $Query = "?slug__ic=$($Slug)"
   }
   else {
      $Query = "?q=$($Name)"
   }

   if ($All) {
      $Query = ""
   }

   $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get

   if ($Result.Count -gt 50) {
      $Result = Get-NextPage -Result $Result
      $Location = $Result
   }
   else {
      $Location = $Result.Results
   }
   $Location.PSObject.TypeNames.Insert(0, "NetBox.Location")
   return $Location
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
    .PARAMETER Site
         Site of the location
    .PARAMETER Parent
         Parent of the location
    .PARAMETER CustomFields
         Custom fields of the location
    .PARAMETER Comment
         Comment for location
    .PARAMETER Description
         Description of the location
    .PARAMETER confirm
         Confirm the creation of the location
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       NetBox.Location
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

      [Parameter(Mandatory = $true)]
      $Site,

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
      $Confirm = $true
   )

   Test-Config | Out-Null
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

   if ($Confirm) {
      $OutPutObject = [pscustomobject]$Body
      Show-ConfirmDialog -Object $OutPutObject
   }

   $Location = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
   $Location.PSObject.TypeNames.Insert(0, "NetBox.Location")
   return $Location
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
      if ($InputObject) {
         $Name = $InputObject.name
      }

      $Location = Get-Location -Name $Name

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
    .PARAMETER All
       Returns all racks
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       NetBox.Rack
    .NOTES
       General notes
    #>

   [CmdletBinding(DefaultParameterSetName = "All")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $Name,

      [Parameter(Mandatory = $true, ParameterSetName = "ById")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $true, ParameterSetName = "BySite")]
      [String]
      $Site,

      [Parameter(Mandatory = $true, ParameterSetName = "ByLocation")]
      [String]
      $Location,

      [Parameter(Mandatory = $true, ParameterSetName = "All")]
      [Switch]
      $All
   )

   Test-Config | Out-Null
   $URL = "/dcim/racks/"

   if ($name) {
      $Query = "?name=$($Name)"
   }

   if ($Model) {
      $Query = "?model__ic=$($Model)"
   }

   if ($Manufacturer) {
      $Query = "?manufacturer=$($Manufacturer)"
   }

   if ($Id) {
      $Query = "?id=$($id)"
   }

   if ($MacAddress) {
      $Query = "?mac_address=$($MacAddress)"
   }

   if ($Site) {
      $Query = "?site__ic=$($Site)"
   }

   if ($Location) {
      $Query = "?location__ic=$($Location)"
   }

   if ($All) {
      $Query = ""
   }

   $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get

   if ($Result.Count -gt 50) {
      $Result = Get-NextPage -Result $Result
      $Rack = $Result
   }
   else {
      $Rack = $Result.Results
   }
   $Rack.PSObject.TypeNames.Insert(0, "NetBox.Rack")
   return $Rack
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
    .PARAMETER Site
         Site of the rack
    .PARAMETER Location
         Location of the rack
    .PARAMETER Status
         Status of the rack, Defaults to Active
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
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       NetBox.Rack
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
      $Description,

      [Parameter(Mandatory = $false)]
      [Bool]
      $Confirm = $true
   )

   Test-Config | Out-Null
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

   if ($Confirm) {
      $OutPutObject = [pscustomobject]$Body
      Show-ConfirmDialog -Object $OutPutObject
   }

   $Rack = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
   $Rack.PSObject.TypeNames.Insert(0, "NetBox.Rack")
   return $Rack
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

      if ($InputObject) {
         $Name = $InputObject.name
      }


      $Rack = Get-Rack -Name $Name

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
    .PARAMETER All
       Returns all custom fields
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       NetBox.CustomField
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

      [Parameter(Mandatory = $true, ParameterSetName = "All")]
      [Switch]
      $All
   )

   Test-Config | Out-Null
   $URL = "/extras/custom-fields/"

   if ($Name) {
      $Query = "?name__ic=$($Name)"
   }

   if ($Id) {
      $Query = "?id=$($id)"
   }

   if ($All) {
      $Query = ""
   }

   $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get

   if ($Result.Count -gt 50) {
      $Result = Get-NextPage -Result $Result
      $CustomFields = $Result
   }
   else {
      $CustomFields = $Result.results
   }
   $CustomFields.PSObject.TypeNames.Insert(0, "NetBox.CustomField")
   return $CustomFields
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
      $Confirm = $true
   )

   Test-Config | Out-Null
   $URL = "/extras/custom-fields/"

   $NetBoxContentTypes = New-Object collections.generic.list[object]

   foreach ($ContentType in $ContentTypes) {
      $NetBoxContentType = Get-ContentType -Name $ContentType
      $NetBoxContentTypes += "$($NetBoxContentType.app_label).$($NetBoxContentType.model)"
   }

   $Body = @{
      name          = $Name
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

   $CustomField = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
   $CustomField.PSObject.TypeNames.Insert(0, "NetBox.CustomField")
   return $CustomField

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

      if ($InputObject) {
         $Name = $InputObject.name
         $Id = $InputObject.id
      }
      if ($Name) {
         $CustomField = Get-CustomField -Name $Name
      }
      if ($Id) {
         $CustomField = Get-CustomField -Id $Id
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
    .PARAMETER All
       Retrieves all content types from NetBox
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       Output (if any)
    .NOTES
       General notes
    #>

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

   Test-Config | Out-Null
   $URL = "/extras/content-types/"
   $Query = "?model=$($Name.Replace(' ','').ToLower())"
   if ($All) {
      $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Get
   }
   else {
      $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get
   }

   if ($Result.Count -gt 50) {
      $Result = Get-NextPage -Result $Result
      $ContentType = $Result
   }
   else {
      $ContentType = $Result.results
   }
   $ContentType.PSObject.TypeNames.Insert(0, "NetBox.ContentType")
   return $ContentType
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
   .PARAMETER
   .INPUTS
      Inputs (if any)
   .OUTPUTS
      NetBox.Manufacturer
   .NOTES
      General notes
   #>

   [CmdletBinding(DefaultParameterSetName = "All")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $Name,

      [Parameter(Mandatory = $true, ParameterSetName = "ById")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $true, ParameterSetName = "All")]
      [Switch]
      $All
   )

   Test-Config | Out-Null
   $URL = "/dcim/manufacturers/"

   if ($Name) {
      $Query = "?name__ic=$($Name)"
   }

   if ($Id) {
      $Query = "?id=$($id)"
   }

   if ($All) {
      $Query = ""
   }

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
      Confirm the creation of the location
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
      $Confirm = $true
   )

   Test-Config | Out-Null
   $URL = "/dcim/manufacturers/"

   if ($null -eq $Slug) {
      $Slug
   }
   else {
      $Slug = $Name.tolower() -replace " ", "-"
   }

   $Body = @{
      name          = $Name
      slug          = $Slug
      custum_fields = $CustomFields
   }

   # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
   ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

   if ($Confirm) {
      $OutPutObject = [pscustomobject]$Body
      Show-ConfirmDialog -Object $OutPutObject
   }

   $Manufacturer = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
   $Manufacturer.PSObject.TypeNames.Insert(0, "NetBox.Manufacturer")
   return $Manufacturer
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
    .PARAMETER All
       Returns all device types
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       NetBox.DeviceType
    .NOTES
       General notes
    #>

   [CmdletBinding(DefaultParameterSetName = "All")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByModel")]
      [String]
      $Model,

      [Parameter(Mandatory = $true, ParameterSetName = "ByManufacturer")]
      [String]
      $Manufacturer,

      [Parameter(Mandatory = $true, ParameterSetName = "ById")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $true, ParameterSetName = "Query")]
      [String]
      $Query,

      [Parameter(Mandatory = $true, ParameterSetName = "All")]
      [Switch]
      $All
   )

   Test-Config | Out-Null
   $URL = "/dcim/device-types/"

   if ($Model) {
      $Query = "?model__ic=$($Model)"
   }

   if ($Manufacturer) {
      $Query = "?manufacturer__ic=$($Manufacturer)"
   }

   if ($Id) {
      $Query = "?id=$($id)"
   }

   if ($All) {
      $Query = ""
   }

   $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get

   if ($Result.Count -gt 50) {
      $Result = Get-NextPage -Result $Result
      $DeviceType = $Result
   }
   else {
      $DeviceType = $Result.results
   }
   $DeviceType.PSObject.TypeNames.Insert(0, "NetBox.DeviceType")
   return $DeviceType
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
    .PARAMETER Manufacturer
       Name of the manufacturer
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
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       NetBox.DeviceType
    .NOTES
       General notes
    #>

   param (
      [Parameter(Mandatory = $true)]
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
      [Parameter(Mandatory = $false)]
      [ValidateSet("Fixed", "Modular")]
      $InterfaceType,

      [String]
      [Parameter(Mandatory = $false)]
      [ValidateSet("c14", "c20")]
      $PowerSupplyConnector,

      [Parameter(Mandatory = $false)]
      [Hashtable[]]
      $PowerSupplies,

      [Parameter(Mandatory = $false)]
      [Bool]
      $Confirm = $true
   )

   Test-Config | Out-Null
   $URL = "/dcim/device-types/"

   if ($null -eq $Slug) {
      $Slug
   }
   else {
      $Slug = $Model.tolower() -replace " ", "-" -replace "/", "-" -replace ",", "-"
   }

   if ($Manufacturer -is [String]) {
      $Manufacturer = (Get-Manufacturer -Name $Manufacturer).Id
   }
   else {
      $Manufacturer
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

   # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
   ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

   if ($Confirm) {
      $OutPutObject = [pscustomobject]$Body
      Show-ConfirmDialog -Object $OutPutObject
   }

   $DeviceType = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
   $DeviceType.PSObject.TypeNames.Insert(0, "NetBox.DeviceType")
   return $DeviceType
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
    .PARAMETER All
       Returns all devices
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       NetBox.Device
    .NOTES
       General notes
    #>

   [OutputType("NetBox.Device")]
   [CmdletBinding(DefaultParameterSetName = "All")]
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
      $MacAddress,

      [Parameter(Mandatory = $true, ParameterSetName = "BySite")]
      [String]
      $Site,

      [Parameter(Mandatory = $true, ParameterSetName = "ByLocation")]
      [String]
      $Location,

      [Parameter(Mandatory = $true, ParameterSetName = "ByRack")]
      [String]
      $Rack,

      [Parameter(Mandatory = $true, ParameterSetName = "ByDeviceType")]
      [String]
      $DeviceType,

      [Parameter(Mandatory = $true, ParameterSetName = "All")]
      [Switch]
      $All

   )
   Test-Config | Out-Null
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
      $Query = "?mac_address=$($MacAddress)"
   }

   if ($Site) {
      $Query = "?site__ic=$($Site)"
   }

   if ($Location) {
      $Query = "?Location__ic=$($Location)"
   }

   if ($Rack) {
      $Query = "?rack=$($Rack)"
   }

   if ($DeviceType) {
      $Query = "?device_type_id=$(Get-DeviceType -Model $($DeviceType) | Select-Object -ExpandProperty id)"
   }

   if ($All) {
      $Query = ""
   }

   $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get

   if ($Result.Count -gt 50) {
      $Result = Get-NextPage -Result $Result
      [PSCustomObject]$Device = $Result
   }
   else {
      [PSCustomObject]$Device = $Result.Results
   }
   $Device.PSObject.TypeNames.Insert(0, "NetBox.Device")
   return $Device
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
      [ValidateSet("Server", "Switch", "Leafswitch")]
      $DeviceRole,

      [Parameter(Mandatory = $true)]
      [String]
      $Site,

      [Parameter(Mandatory = $false, ParameterSetName = "ByParameter")]
      [Array]
      $Interfaces,

      [Parameter(Mandatory = $false)]
      [String]
      [ValidateSet("Fixed", "Modular")]
      $InterfaceType,

      [Parameter(Mandatory = $false, ParameterSetName = "ByParameter")]
      [Array]
      $PowerSupplies,

      [Parameter(Mandatory = $false)]
      [String]
      [ValidateSet("c14", "c20")]
      $PowerSupplyConnector,

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

   Test-Config | Out-Null
   $URL = "/dcim/devices/"

   if ($null -eq $Slug) {
      $Slug
   }
   else {
      $Slug = $Name.tolower() -replace " ", "-"
   }

   if ($DeviceType -is [String]) {
      $DeviceType = (Get-DeviceType -Query $DeviceType).Id
   }

   $Body = @{
      name        = $Name
      device_type = $DeviceType
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
      $ParentDevice =
      $Body.parent_device = @{
         name = (Get-Device -Name $ParentDevice).Name
      }
   }

   # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
        ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

   if ($Confirm) {
      $OutPutObject = [pscustomobject]$Body
      Show-ConfirmDialog -Object $OutPutObject
   }

   $Devive = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
   $Devive.PSObject.TypeNames.Insert(0, "NetBox.Device")
   return $Devive
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

      $Device = Get-Device -Model $Name

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
    .PARAMETER All
       Returns all device roles
   .INPUTS
      Inputs (if any)
   .OUTPUTS
      NetBox.DeviceRole
   .NOTES
      General notes
   #>

   [CmdletBinding(DefaultParameterSetName = "All")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $Name,

      [Parameter(Mandatory = $true, ParameterSetName = "ById")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $true, ParameterSetName = "All")]
      [Switch]
      $All
   )

   Test-Config | Out-Null
   $URL = "/dcim/device-roles/"

   if ($name) {
      $Query = "?name=$($Name)"
   }

   if ($Id) {
      $Query = "?id=$($id)"
   }

   if ($All) {
      $Query = ""
   }

   $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get

   if ($Result.Count -gt 50) {
      $Result = Get-NextPage -Result $Result
      $DeviceRole = $Result
   }
   else {
      $DeviceRole = $Result.results
   }
   $DeviceRole.PSObject.TypeNames.Insert(0, "NetBox.DeviceRole")
   return $DeviceRole
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
      Confirm the deletion of the device
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
      $Confirm = $true
   )
   Test-Config | Out-Null
   $URL = "/dcim/device-roles/"

   if ($null -eq $Slug) {
      $Slug
   }
   else {
      $Slug = $Name.tolower() -replace " ", "-"
   }

   $Body = @{
      name        = $Name
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

   $DeviceRole = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
   $DeviceRole.PSObject.TypeNames.Insert(0, "NetBox.DeviceRole")
   return $DeviceRole
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
    .PARAMETER All
       Returns all devices
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       NetBox.InterfaceTemplate
    .NOTES
       General notes
    #>

   [CmdletBinding(DefaultParameterSetName = "All")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $Name,

      [Parameter(Mandatory = $true, ParameterSetName = "ById")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $true, ParameterSetName = "All")]
      [Switch]
      $All
   )

   Test-Config | Out-Null
   $URL = "/dcim/interface-templates/"

   if ($name) {
      $Query = "?name=$($Name)"
   }

   if ($Id) {
      $Query = "?id=$($id)"
   }

   if ($All) {
      $Query = ""
   }

   $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get

   if ($Result.Count -gt 50) {
      $Result = Get-NextPage -Result $Result
      $InterfaceTemplate = $Result
   }
   else {
      $InterfaceTemplate = $Result.results
   }
   $InterfaceTemplate.PSObject.TypeNames.Insert(0, "NetBox.InterfaceTemplate")
   return $InterfaceTemplate

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
    .PARAMETER DeviceType
      Name of the device type
    .PARAMETER Label
      Label of the interface template
    .PARAMETER Type
      Type of the interface template, e.g "1000base-t", "10gbase-x-sfpp" or others
    .PARAMETER ManagementOnly
      Is this interface template only for management?
   .PARAMETER Confirm
      Confirm the deletion of the device
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       NetBox.InterfaceTemplate
    .NOTES
       General notes
    #>

   param (
      [Parameter(Mandatory = $true)]
      [String]
      $Name,

      [Parameter(Mandatory = $true)]
      $DeviceType,

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
      [Bool]
      $Confirm = $true,

      [Parameter(Mandatory = $false)]
      [Switch]
      $FindInterfaceType
   )

   if ($DeviceType -is [String]) {
      $DeviceType = (Get-DeviceType -Query $DeviceType).Id
   }

   Test-Config | Out-Null
   $URL = "/dcim/interface-templates/"

   if ($FindInterfaceType) {
      $Type = $(Get-NetBoxInterfaceType -Linkspeed $Interface.Linkspeed -InterfaceType $InterfaceType)
   }

   $Body = @{
      device_type = $DeviceType
      name        = $Name
      type        = $Type
      mgmt_only   = $ManagmentOnly
   }
   # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
   ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

   if ($Confirm) {
      $OutPutObject = [pscustomobject]$Body
      Show-ConfirmDialog -Object $OutPutObject
   }

   Write-Verbose $DeviceType
   Write-Verbose $Name
   Write-Verbose $Type
   Write-Verbose $ManagmentOnly

   $InterfaceTemplate = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
   $InterfaceTemplate.PSObject.TypeNames.Insert(0, "NetBox.InterfaceTemplate")
   return $InterfaceTemplate
}

function Get-PowerSupplyType {
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
    .PARAMETER Device
       Name of the parent device
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

   [CmdletBinding(DefaultParameterSetName = "Byname")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $Name,

      [Parameter(Mandatory = $true, ParameterSetName = "ById")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $true, ParameterSetName = "ByDevice")]
      [Int32]
      $Device,

      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [Bool]
      $ManagementOnly,

      [Parameter(Mandatory = $true, ParameterSetName = "All")]
      [Switch]
      $All
   )

   Test-Config | Out-Null
   $URL = "/dcim/interfaces/"

   if ($name) {
      $Query = "?name=$($Name)"
   }

   if ($Id) {
      $Query = "?id=$($Id)"
   }

   if ($Deviec) {
      $Query = "?device__ic=$($Device)"
   }

   if ($ManagementOnly) {
      $Query = "?mgmt_only=$($ManagementOnly.ToString())"
   }

   $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get

   if ($Result.Count -gt 50) {
      $Result = Get-NextPage -Result $Result
      $Interface = $Result
   }
   else {
      $Interface = $Result.results
   }
   $Interface.PSObject.TypeNames.Insert(0, "NetBox.Interface")
   return $Interface
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
   .PARAMETER Device
      Name of the parent device
   .PARAMETER Type
      Type of the interface
   .PARAMETER MacAddress
      MAC address of the interface
   .PARAMETER ManagementOnly
      Is this interface only for management?
   .PARAMETER Confirm
      Confirm the creation of the interface
   .INPUTS
      Inputs (if any)
   .OUTPUTS
      NetBox.Interface
   .NOTES
      General notes
   #>

   param (
      [Parameter(Mandatory = $true)]
      $Device,

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
      $Confirm = $true
   )

   Test-Config | Out-Null
   $URL = "/dcim/interfaces/"

   if ($Device -is [String]) {
      $Device = (Get-Device -Query $Device).Id
   }
   else {
      $Device
   }

   $Body = @{
      device      = $Device
      name        = $Name
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

function Update-Interface {
   <#
   .SYNOPSIS
      Updates an existing interface in netbox
   .DESCRIPTION
      Long description
   .EXAMPLE
      PS C:\> Update-NetBoxInterface -Id "1" -Name "NewInterface" -Type "10gbase-t" -MacAddress "00:00:00:00:00:00"
      Updates an interface with id "1" to have name "NewInterface" with type "10gbase-t" and MAC address "00:00:00:00:00:00"
   .PARAMETER Name
      Name of the interface
   .PARAMETER Device
      Name of the parent device
   .PARAMETER ID
      ID of the interface
   .PARAMETER Type
      Type of the interface
   .PARAMETER MacAddress
      MAC address of the interface
   .PARAMETER ManagementOnly
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
      [Parameter(Mandatory = $true)]
      $Device,

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

   Test-Config | Out-Null
   $URL = "/dcim/interfaces/"

   if ($Device -is [String]) {
      $Device = (Get-Device -Query $Device).Id
   }
   else {
      $Device
   }

   $Interface = Get-Interface -Name $Name

   $Body = @{
      device      = $Device
      name        = $Name
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
    .PARAMETER All
       Returns all power port templates
    .INPUTS
       Inputs (if any)
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

      [Parameter(Mandatory = $true, ParameterSetName = "All")]
      [Switch]
      $All
   )

   Test-Config | Out-Null
   $URL = "/dcim/power-port-templates/"

   if ($name) {
      $Query = "?name=$($Name)"
   }

   if ($Id) {
      $Query = "?id=$($id)"
   }

   if ($All) {
      $Query = ""
   }

   $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get

   if ($Result.Count -gt 50) {
      $Result = Get-NextPage -Result $Result
      $PowerPortTemplates = $Result
   }
   else {
      $PowerPortTemplates = Result.results
   }
   $PowerPortTemplates.PSObject.TypeNames.Insert(0, "NetBox.PowerPortTemplate")
   return $Result.Results

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
    .PARAMETER DeviceType
      Device type of the power port template
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
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       NetBox.PowerPortTemplate
    .NOTES
       General notes
    #>

   param (
      [Parameter(Mandatory = $true)]
      $DeviceType,

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
      $Confirm = $true
   )

   if ($DeviceType -is [String]) {
      $DeviceType = (Get-DeviceType -Query $DeviceType).Id
   }

   Test-Config | Out-Null
   $URL = "/dcim/power-port-templates/"

   $Body = @{
      device_type    = $DeviceType
      name           = $Name
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

   $PowerPortTemplates = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
   $PowerPortTemplates.PSObject.TypeNames.Insert(0, "NetBox.PowerPortTemplate")
   return $PowerPortTemplates
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

   }
   process {
      if ($InputObject) {
         $Name = $InputObject.Name
      }
   }
}