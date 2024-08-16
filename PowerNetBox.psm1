function Set-Config {
   <#
   .SYNOPSIS
      Required to use PowerNetBox, sets up URL and APIToken for connection.
   .DESCRIPTION
      Sets up the necessary configuration for accessing the NetBox API by providing the NetBox URL and API token.
   .EXAMPLE
      PS C:\> Set-NetBoxConfig -NetboxURL "https://netbox.example.com" -NetboxAPIToken "1277db26a31232132327265bd13221309a567fb67bf"
      Sets up NetBox from https://netbox.example.com with APIToken 1277db26a31232132327265bd13221309a567fb67bf.
   .PARAMETER NetboxAPIToken
      APIToken to access NetBox found under "Profiles & Settings" -> "API Tokens" tab.
   .PARAMETER NetboxURL
      URL from NetBox, must be https.
   #>

   param (
      [String]
      $NetboxAPIToken,

      [String]
      [ValidatePattern ("^(https:\/\/).+")]
      $NetboxURL
   )

   # Setting up headers for API requests
   $Header = @{
      Authorization = "Token $($NetboxAPIToken)"
   }

   # Defining script-level variables for API requests
   $Script:RestParams = @{
      Headers       = $Header
      ContentType   = "application/json"
      ErrorVariable = "RestError"
   }

   # Storing the base URL of the NetBox API
   $Script:NetboxURL = $NetboxURL.TrimEnd("/")
   Set-Variable -Scope Script -Name NetboxURL
   Set-Variable -Scope Script -Name NetboxAPIToken

   # Adding /api to the URL if it is not already provided
   if ($NetboxURL -notlike "*api*" ) {
      $Script:NetboxURL = $NetboxURL + "/api"
   }
}

function Test-Config {
   <#
   .SYNOPSIS
      For internal use, checks if NetBox URL and APIToken are set.
   .DESCRIPTION
      Ensures that both the NetBox URL and API token have been configured before executing other functions.
   .EXAMPLE
      PS C:\> Test-Config | Out-Null
      Verifies that the necessary configuration has been set up.
   #>

   # Check if NetboxURL and NetboxAPIToken are set, otherwise return an error
   if (-not $(Get-Variable -Name NetboxURL) -or -not $(Get-Variable -Name NetboxAPIToken) ) {
      Write-Error "NetboxAPIToken and NetboxURL must be set before calling this function"
      break
   }
}

function Get-NextPage {
   <#
    .SYNOPSIS
       For internal use, gets the next page of results from NetBox.
    .DESCRIPTION
       Retrieves additional pages of results from a paginated NetBox API response.
    .EXAMPLE
       PS C:\> Get-NextPage -Result $Result
       Retrieves all items from API call and returns them in $CompleteResult.
    .PARAMETER Result
       Result from previous API call.
    #>

   param (
      [Parameter(Mandatory = $true)]
      $Result
   )

   # Initialize an empty list to store the complete results
   $CompleteResult = New-Object collections.generic.list[object]

   # Add the current page's results to the complete result list
   $CompleteResult += $Result.Results

   # Continue fetching pages while there is a next page available
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
      For internal use, Gets all related objects from a NetBox object.
   .DESCRIPTION
      Retrieves related objects from a NetBox object based on specific properties like "_count".
   .EXAMPLE
      PS C:\> Get-RelatedObjects -Object $Device -ReferenceObjects "devicetype"
      Retrieves related objects for a given device type.
   .PARAMETER Object
      The NetBox object from which to retrieve related objects.
   .PARAMETER ReferenceObjects
      The reference type to determine the related objects.
   .INPUTS
      None
   .OUTPUTS
      List of related NetBox objects.
   .NOTES
      Internal function to help manage relationships in NetBox data.
   #>
   param (
      [Parameter(Mandatory = $true)]
      $Object,

      [Parameter(Mandatory = $true)]
      $ReferenceObjects
   )

   # Initialize a list to store related objects
   $RelatedObjects = New-Object collections.generic.list[object]

   # Find properties that match the "_count" pattern
   $RelatedTypes = $Object.PSobject.Properties.name -match "_count"
   foreach ($Type in $RelatedTypes) {
      if ($object.$Type -gt 0) {
         # Determine whether to get related objects by Model or Name
         if ($ReferenceObjects -eq "devicetype") {
            $RelatedObjects += Invoke-Expression "Get-$($Type.TrimEnd("_count")) -Model $($Object.Model)"
         }
         else {
            $RelatedObjects += Invoke-Expression "Get-$($Type.TrimEnd("_count")) -$($ReferenceObjects) '$($Object.Name)'"
         }
      }
   }

   return $RelatedObjects

   # The following lines appear to be part of another function or commented-out code.
   # Get referenced objects from error message
   $ReferenceObjects = ($ErrorMessage.ErrorRecord | ConvertFrom-Json).Detail.split(":")[1].Split(",")

   # Trim whitespaces from error message
   foreach ($Object in $ReferenceObjects) {
      $Object = $Object.Substring(0, $Object.Length - 3).Substring(1)
   }
   return $ReferenceObjects
}

function Show-ConfirmDialog {
   <#
   .SYNOPSIS
      For internal use, Shows a confirmation dialog before executing the command.
   .DESCRIPTION
      Displays a confirmation dialog with details about the object that is about to be created or modified.
   .EXAMPLE
      PS C:\> Show-ConfirmDialog -Object $NewSite
      Asks the user to confirm before creating a new site.
   .PARAMETER Object
      The object to display in the confirmation dialog.
   .INPUTS
      None
   .OUTPUTS
      None
   .NOTES
      This function is used to confirm actions that have significant impact.
   #>

   param (
      [Parameter(Mandatory = $true)]
      $Object
   )

   # Display the details of the object
   "Device Model:"
   $Object | Format-List

   # Define the dialog title and question
   $Title = "New Object Creation"
   $Question = "Are you sure you want to create this object?"

   # Define the choices for the user
   $Choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
   $Choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList "&Yes"))
   $Choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList "&No"))

   # Prompt the user for their decision
   $Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, 1)
   if ($Decision -ne 0) {
      Write-Error "Canceled by User"
      break
   }
}

function Get-InterfaceType {
   <#
    .SYNOPSIS
       Determine the interface type of a device based on linkspeed and connection type.
    .DESCRIPTION
       Returns the appropriate NetBox interface type for a device based on its link speed and connector type.
    .EXAMPLE
       PS C:\> Get-NetBoxInterfaceType -Linkspeed 10GE -InterfaceType sfp
       Returns the Netbox interface Type for a 10GBit/s SFP interface.
    .PARAMETER Linkspeed
       Speed of the interface in gigabit/s, e.g., 10GE.
    .PARAMETER InterfaceType
       Type of the connector, e.g., sfp, RJ45, or just fixed/modular.
    .INPUTS
       None
    .OUTPUTS
       NetBox.InterfaceType
    .NOTES
       Internal function to map the device's physical interface to a NetBox interface type.
    #>

   param (
      [Parameter(Mandatory = $true)]
      $Linkspeed,

      [Parameter(Mandatory = $false)]
      [ValidateSet("Fixed", "Modular", "RJ45", "SFP")]
      $InterfaceType
   )

   # Append "GE" to Linkspeed if missing
   if ($Linkspeed -notlike "*GE") {
      $Linkspeed = $Linkspeed + "GE"
   }

   # Map aliases to standardized interface types
   if ($InterfaceType -eq "SFP") {
      $InterfaceType = "Modular"
   }

   if ($InterfaceType -eq "RJ45") {
      $InterfaceType = "Fixed"
   }

   # Determine the specific interface type based on link speed and interface type
   if ($Linkspeed -eq "1GE" -and $InterfaceType -eq "Fixed") {
      $Type = "1000base-t"
   }
   elseif ($Linkspeed -eq "1GE" -and $InterfaceType -eq "Modular") {
      $Type = "1000base-x-sfp"
   }

   if ($Linkspeed -eq "10GE" -and $InterfaceType -eq "Fixed") {
      $Type = "10gbase-t"
   }
   elseif ($Linkspeed -eq "10GE" -and $InterfaceType -eq "Modular") {
      $Type = "10gbase-x-sfpp"
   }

   if ($Linkspeed -eq "25GE") {
      $Type = "25gbase-x-sfp28"
   }

   if ($Linkspeed -eq "40GE") {
      $Type = "40gbase-x-qsfpp"
   }

   if ($Linkspeed -eq "100GE") {
      $Type = "100gbase-x-qsfp28"
   }

   # Return the determined interface type with the appropriate type name
   $Type.PSObject.TypeNames.Insert(0, "NetBox.InterfaceType")

   return $Type
}

function Get-Site {
   <#
    .SYNOPSIS
       Retrieves a site from NetBox.
    .DESCRIPTION
       Queries NetBox for a site based on parameters like name, ID, or slug.
    .EXAMPLE
       PS C:\> Get-NetBoxSite -Name VBC
       Returns the Netbox site VBC.
    .PARAMETER Name
       Search for a site by name.
    .PARAMETER ID
       Search for a site by ID.
    .PARAMETER Slug
       Search for a site by slug.
    .INPUTS
       None
    .OUTPUTS
       NetBox.Site
    .NOTES
       Fetches details about a specific site from NetBox.
    #>

   param (
      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Name,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $ID,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Slug
   )

   begin {
      Test-Config | Out-Null
      $URL = "/dcim/sites/"
   }

   process {
      # Construct the query string based on provided parameters
      $Query = "?"

      if ($name) {
         $Query = $Query + "name__ic=$($Name)&"
      }

      if ($ID) {
         $Query = $Query + "id=$($id)&"
      }

      if ($Slug) {
         $Query = $Query + "slug__ic=$($Slug)"
      }

      $Query = $Query.TrimEnd("&")

      # Retrieve the site(s) from NetBox
      $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

      # Store the results in a list of site objects
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

function Update-Site {
   <#
    .SYNOPSIS
       Updates a site in NetBox.
    .DESCRIPTION
       Updates an existing site in NetBox with the provided parameters.
    .EXAMPLE
       PS C:\> Update-NetBoxSite -Name vbc -Status active
       Updates the status of the site vbc to active.
    .PARAMETER Name
       Name of the site to update.
    .PARAMETER Slug
       Slug of the site.
    .PARAMETER Status
       Status of the site.
    .PARAMETER Region
       Region of the site.
    .PARAMETER Group
       Group of the site.
    .PARAMETER Tenant
       Tenant of the site.
    .PARAMETER CustomFields
       Custom fields of the site.
    .PARAMETER Comment
       Comment of the site.
    .PARAMETER Tags
       Tags of the site.
    .PARAMETER TagColor
       Tag color of the site.
    .PARAMETER Description
       Description of the site.
    .INPUTS
       None
    .OUTPUTS
       NetBox.Site
    .NOTES
       Updates a site entry in NetBox.
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

   # This function is incomplete. The main logic for updating a site should be implemented here.
   # Example:
   # - Fetch the site by Name or ID
   # - Update the fields provided as parameters
   # - Send a PUT or PATCH request to the NetBox API with the updated site data
}

function Remove-Site {
   <#
    .SYNOPSIS
       Deletes a site in NetBox.
    .DESCRIPTION
       Removes a site from NetBox, optionally including all related objects.
    .EXAMPLE
       PS C:\> Remove-NetBoxSite -Name vbc -Recurse
       Deletes a site vbc and all related objects.
    .PARAMETER Name
       Name of the site to delete.
    .PARAMETER ID
       ID of the site to delete.
    .PARAMETER Recurse
       Deletes all related objects as well.
    .PARAMETER Confirm
       Confirm the deletion of the site.
    .PARAMETER InputObject
       Site object to delete.
    .INPUTS
       NetBox.Site
    .OUTPUTS
       None
    .NOTES
       Deletes a site and optionally its related objects in NetBox.
    #>

   [CmdletBinding(DefaultParameterSetName = "ByName")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $Name,

      [Parameter(Mandatory = $true, ParameterSetName = "ByID")]
      [Int32]
      $ID,

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
      # Validate the InputObject type
      if (-not ($InputObject.psobject.TypeNames -contains "NetBox.Site")) {
         Write-Error "InputObject is not type NetBox.Site"
         break
      }

      # Retrieve site details based on input parameters
      if ($InputObject) {
         $Name = $InputObject.name
         $ID = $InputObject.Id
      }

      if ($ID) {
         $Site = Get-Site -ID $ID
      }
      else {
         $Site = Get-Site -Name $Name
      }

      # Get related objects to potentially delete them as well
      $RelatedObjects = Get-RelatedObjects -Object $Site -ReferenceObjects Site

      # Show confirmation dialog if required
      if ($Confirm) {
         Show-ConfirmDialog -Object $Site
      }

      # Remove all related objects if Recurse is specified
      if ($Recurse) {
         foreach ($Object in $RelatedObjects) {
            Invoke-RestMethod -Uri $Object.url @RestParams -Method Delete | Out-Null
         }
      }

      # Try to delete the site, handling errors appropriately
      try {
         Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Site.ID) + "/") @RestParams -Method Delete
      }
      catch {
         if ((($RestError.ErrorRecord) | ConvertFrom-Json).Detail -like "Unable to delete object*") {
            Write-Error "$($($($RestError.ErrorRecord) | ConvertFrom-Json).detail)"
            Write-Error "Delete those objects first or run again using -recurse switch"
         }
         else {
            Write-Error "$($($($RestError.ErrorRecord) | ConvertFrom-Json).detail)"
         }

      }
   }
}

function Get-Location {
   <#
    .SYNOPSIS
       Retrieves a location in NetBox.
    .DESCRIPTION
       Queries NetBox for a location based on parameters like name, ID, or slug.
    .EXAMPLE
       PS C:\> Get-NetBoxLocation -Name "Low Density"
       Retrieves the location Low Density.
    .PARAMETER Name
       Name of the location.
    .PARAMETER ID
       ID of the location.
    .PARAMETER Slug
       Search for a location by slug.
    .INPUTS
       None
    .OUTPUTS
       NetBox.Location
    .NOTES
       Fetches details about a specific location from NetBox.
    #>

   param (
      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Name,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $ID,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Slug
   )

   begin {
      Test-Config | Out-Null
      $URL = "/dcim/locations/"
   }

   process {
      # Construct the query string based on provided parameters
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

      # Retrieve the location(s) from NetBox
      $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

      # Store the results in a list of location objects
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

function Remove-Location {
   <#
   .SYNOPSIS
      Deletes a location in NetBox.
   .DESCRIPTION
      Removes a location from NetBox, optionally including all related objects.
   .EXAMPLE
      PS C:\> Remove-NetBoxLocation -Name "High Density"
      Deletes the location High Density.
    .PARAMETER Name
       Name of the location to delete.
    .PARAMETER ID
       ID of the location to delete.
    .PARAMETER Recurse
       Deletes all related objects as well.
    .PARAMETER Confirm
       Confirm the deletion of the location.
    .PARAMETER InputObject
       Location object to delete.
   .INPUTS
      NetBox.Location
   .OUTPUTS
      None
   .NOTES
      Deletes a location and optionally its related objects in NetBox.
   #>

   [CmdletBinding(DefaultParameterSetName = "ByName")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $Name,

      [Parameter(Mandatory = $true, ParameterSetName = "ByID")]
      [Int32]
      $ID,

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
      # Validate the InputObject type
      if (-not ($InputObject.psobject.TypeNames -contains "NetBox.Location")) {
         Write-Error "InputObject is not type NetBox.Location"
         break
      }

      # Retrieve location details based on input parameters
      if ($InputObject) {
         $Name = $InputObject.name
         $ID = $InputObject.Id
      }

      if ($ID) {
         $Location = Get-Location -Id $ID
      }
      else {
         $Location = Get-Location -Name $Name
      }

      # Get related objects to potentially delete them as well
      $RelatedObjects = Get-RelatedObjects -Object $Location -ReferenceObjects Location

      # Show confirmation dialog if required
      if ($Confirm) {
         Show-ConfirmDialog -Object $Location
      }

      # Remove all related objects if Recurse is specified
      if ($Recurse) {
         foreach ($Object in $RelatedObjects) {
            Invoke-RestMethod -Uri $Object.url @RestParams -Method Delete | Out-Null
         }
      }

      # Try to delete the location, handling errors appropriately
      try {
         Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Location.ID) + "/") @RestParams -Method Delete
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
       Retrieves a rack from NetBox.
    .DESCRIPTION
       Fetches rack information from NetBox based on provided filters like name, site, location, or slug.
    .EXAMPLE
       PS C:\> Get-NetBoxRack -Location "High Density"
       Retrieves all racks from the "High Density" location.
    .PARAMETER Name
       Name of the rack to filter by.
    .PARAMETER ID
       ID of the rack to filter by.
    .PARAMETER Site
       Site of the rack to filter by.
    .PARAMETER Location
       Location of the rack to filter by.
    .PARAMETER Slug
       Slug identifier of the rack to filter by.
    .INPUTS
       None.
    .OUTPUTS
       NetBox.Rack
    .NOTES
       Retrieves rack details from the NetBox API using specified filters.
    #>

   param (
      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Name,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $ID,

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
      # Verify configuration and initialize API endpoint
      Test-Config | Out-Null
      $URL = "/dcim/racks/"
   }

   process {
      # Build query string based on parameters provided
      $Query = "?"

      if ($Name) {
         $Query = $Query + "name__ic=$($Name)&"
      }

      if ($ID) {
         $Query = $Query + "id=$($id)&"
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

      # Make API request and retrieve the results
      $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

      # Create an empty list to hold the rack objects
      $Racks = New-Object collections.generic.list[object]

      # Process each item in the result and cast to NetBox.Rack type
      foreach ($Item in $Result) {
         [PSCustomObject]$Rack = $item
         $Rack.PSObject.TypeNames.Insert(0, "NetBox.Rack")
         $Racks += $Rack
      }

      # Return the list of racks
      return $Racks
   }
}

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

function Update-Rack {
   <#
    .SYNOPSIS
       Updates an existing rack in NetBox.
    .DESCRIPTION
       Updates an existing rack entry in NetBox based on the provided parameters.
    .EXAMPLE
       PS C:\> Update-NetBoxRack -Name "T-12" -Location "High density" -Site VBC
       Updates rack "T-12" in location "High Density" at site VBC.
    .PARAMETER Name
       Name of the rack to update.
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
       If set to true, prompts for confirmation before updating.
    .PARAMETER Force
       Forces the update of the rack.
    .INPUTS
       NetBox.Rack
    .OUTPUTS
       NetBox.Rack
    .NOTES
       Updates an existing rack in NetBox using the specified parameters.
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
      # Verify configuration and initialize API endpoint
      Test-Config | Out-Null
      $URL = "/dcim/racks/"
   }

   process {

      # Retrieve the existing rack
      $Rack = Get-Rack -Name $Name

      # Get the Site and Location objects
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

      # Prepare the body for the API request
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

      # Remove empty keys from the body
      ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

      # Show confirmation dialog if required
      if ($Confirm) {
         $OutPutObject = [pscustomobject]$Body
         Show-ConfirmDialog -Object $OutPutObject
      }

      # Update the rack using a PATCH request
      if (-Not $Exists) {
         $Rack = Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Rack.ID) + "/") @RestParams -Method Patch -Body $($Body | ConvertTo-Json)
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
      Deletes a rack from NetBox.
   .DESCRIPTION
      Removes a rack from NetBox, optionally including all related objects.
   .EXAMPLE
      PS C:\> Remove-NetBoxRack -Name "Y-14"
      Deletes rack "Y-14" from NetBox.
   .PARAMETER Name
      Name of the rack to delete.
   .PARAMETER ID
      ID of the rack to delete.
    .PARAMETER Recurse
       Deletes all related objects as well.
    .PARAMETER Confirm
      Confirm the deletion of the rack.
    .PARAMETER InputObject
      Rack object to delete.
   .INPUTS
      NetBox.Rack
   .OUTPUTS
      None.
   .NOTES
      Deletes a rack and optionally its related objects in NetBox.
   #>

   [CmdletBinding(DefaultParameterSetName = "ByName")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $Name,

      [Parameter(Mandatory = $true, ParameterSetName = "ByID")]
      [Int32]
      $ID,

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

      # Verify configuration and initialize API endpoint
      Test-Config | Out-Null
      $URL = "/dcim/racks/"
   }

   process {
      # Ensure the input object is of the correct type
      if (-not ($InputObject.psobject.TypeNames -contains "NetBox.Rack")) {
         Write-Error "InputObject is not type NetBox.Rack"
         break
      }

      # Retrieve the rack by name or ID
      if ($InputObject) {
         $Name = $InputObject.name
         $ID = $InputObject.ID
      }

      if ($ID) {
         $Rack = Get-Rack -ID $ID
      }
      else {
         $Rack = Get-Rack -Name $Name
      }

      # Retrieve related objects to delete if the recurse option is enabled
      $RelatedObjects = Get-RelatedObjects -Object $Rack -ReferenceObjects Rack

      # Show confirmation dialog if required
      if ($Confirm) {
         Show-ConfirmDialog -Object $Rack
      }

      # Remove all related objects if recurse is enabled
      if ($Recurse) {
         foreach ($Object in $RelatedObjects) {
            Invoke-RestMethod -Uri $Object.url @RestParams -Method Delete | Out-Null
         }
      }

      # Delete the rack
      try {
         Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Rack.ID) + "/") @RestParams -Method Delete
      }
      catch {
         # Handle errors during deletion, especially related object issues
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
       Retrieves a custom field from NetBox.
    .DESCRIPTION
       Fetches custom field information from NetBox based on the provided filters like name or ID.
    .EXAMPLE
       PS C:\> Get-NetBoxCustomField -Name "ServiceCatalogID"
       Retrieves custom field "ServiceCatalogID" from NetBox.
    .PARAMETER Name
       Name of the custom field to filter by.
    .PARAMETER ID
       ID of the custom field to filter by.
    .INPUTS
       None.
    .OUTPUTS
       NetBox.CustomField
    .NOTES
       Retrieves custom field details from NetBox using specified filters.
    #>

   param (
      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Name,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $ID
   )

   begin {
      # Verify configuration and initialize API endpoint
      Test-Config | Out-Null
      $URL = "/extras/custom-fields/"
   }

   process {
      # Build query string based on parameters provided
      $Query = "?"

      if ($Name) {
         $Query = $Query + "name__ic=$($Name)&"
      }

      if ($ID) {
         $Query = $Query + "id=$($id)&"
      }

      $Query = $Query.TrimEnd("&")

      # Make API request and retrieve the results
      $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

      # Create an empty list to hold the custom field objects
      $Customfields = New-Object collections.generic.list[object]

      # Process each item in the result and cast to NetBox.CustomField type
      foreach ($Item in $Result) {
         [PSCustomObject]$Customfield = $item
         $Customfield.PSObject.TypeNames.Insert(0, "NetBox.Customfield")
         $Customfields += $Customfield
      }

      # Return the list of custom fields
      return $Customfields
   }
}

function New-CustomField {
   <#
    .SYNOPSIS
       Creates a custom field in NetBox.
    .DESCRIPTION
       Adds a new custom field to NetBox with the specified parameters.
    .EXAMPLE
       PS C:\> New-NetBoxCustomField -Name "ServiceCatalogID" -Type Integer -ContentTypes Device -Label "Service Catalog ID"
       Creates custom field "ServiceCatalogID" of type Integer for content type "Device" with the label "Service Catalog ID" in NetBox.
    .PARAMETER Name
       Name of the new custom field.
    .PARAMETER Label
       Label for the custom field.
    .PARAMETER Type
       Type of the custom field, e.g., "Integer", "Text".
    .PARAMETER ContentTypes
       Content types for the custom field, e.g., "Device".
    .PARAMETER Choices
       Choices for the custom field, e.g., "1,2,3,4,5".
    .PARAMETER Description
       Description of the custom field.
    .PARAMETER Required
       Specifies whether the custom field is required.
    .PARAMETER Confirm
       If set to true, prompts for confirmation before creation.
    .PARAMETER Force
       Forces creation of the custom field, even if it already exists.
    .INPUTS
       None.
    .OUTPUTS
       NetBox.CustomField
    .NOTES
       Adds a new custom field to NetBox using the specified parameters.
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
      # Verify configuration and initialize API endpoint
      Test-Config | Out-Null
      $URL = "/extras/custom-fields/"
   }

   process {
      # Check if the custom field already exists
      if ($(Get-CustomField -Name $Name )) {
         Write-Warning "CustomField $Name already exists"
         $Exists = $true
      }

      # Prepare content types for the API request
      $NetBoxContentTypes = New-Object collections.generic.list[object]

      foreach ($ContentType in $ContentTypes) {
         $NetBoxContentType = Get-ContentType -Name $ContentType
         $NetBoxContentTypes += "$($NetBoxContentType.app_label).$($NetBoxContentType.model)"
      }

      # Prepare the body for the API request
      $Body = @{
         name          = (Get-Culture).Textinfo.ToTitleCase($Name)
         label         = $Label
         type          = $Type
         required      = $Required
         choices       = $Choices
         description   = $Description
         content_types = $NetBoxContentTypes
      }

      # Remove empty keys from the body
      ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

      # Show confirmation dialog if required
      if ($Confirm) {
         $OutPutObject = [pscustomobject]$Body
         Show-ConfirmDialog -Object $OutPutObject
      }

      # Create the custom field if it doesn't already exist
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
       Deletes a custom field from NetBox.
    .DESCRIPTION
       Removes a custom field from NetBox.
    .EXAMPLE
       PS C:\> Remove-NetBoxCustomField -id 3
       Deletes custom field with ID 3 from NetBox.
    .PARAMETER Name
       Name of the custom field to delete.
    .PARAMETER ID
       ID of the custom field to delete.
    .PARAMETER InputObject
       Custom field object to delete.
    .INPUTS
       NetBox.CustomField
    .OUTPUTS
       None.
    .NOTES
       Deletes a custom field from NetBox based on the specified parameters.
    #>

   [CmdletBinding(DefaultParameterSetName = "ByName")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $Name,

      [Parameter(Mandatory = $true, ParameterSetName = "ById")]
      [Int32]
      $ID,

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
      # Verify configuration and initialize API endpoint
      Test-Config | Out-Null
      $URL = "/extras/custom-fields/"
   }

   process {
      # Ensure the input object is of the correct type
      if (-not ($InputObject.psobject.TypeNames -contains "NetBox.Customfield")) {
         Write-Error "InputObject is not type NetBox.Customfield"
         break
      }

      # Retrieve the custom field by name or ID
      if ($InputObject) {
         $Name = $InputObject.name
         $ID = $InputObject.Id
      }

      if ($ID) {
         $CustomField = Get-CustomField -Id $ID
      }
      else {
         $CustomField = Get-CustomField -Name $Name
      }

      # Retrieve related objects to delete if the recurse option is enabled
      $RelatedObjects = Get-RelatedObjects -Object $CustomField -ReferenceObjects CustomField

      # Show confirmation dialog if required
      if ($Confirm) {
         Show-ConfirmDialog -Object $CustomField
      }

      # Remove all related objects if recurse is enabled
      if ($Recurse) {
         foreach ($Object in $RelatedObjects) {
            Invoke-RestMethod -Uri $Object.url @RestParams -Method Delete | Out-Null
         }
      }

      # Delete the custom field
      try {
         Invoke-RestMethod -Uri $($NetboxURL + $URL + $($CustomField.ID) + "/") @RestParams -Method Delete
      }
      catch {
         # Handle errors during deletion, especially related object issues
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
       Retrieves content types from NetBox.
    .DESCRIPTION
       Fetches content type information from NetBox based on the provided name filter.
    .EXAMPLE
       PS C:\> Get-NetBoxContentType -Name Device
       Retrieves content type "Device" from NetBox.
    .PARAMETER Name
       Name of the content type to filter by.
    .INPUTS
       None.
    .OUTPUTS
       NetBox.ContentType
    .NOTES
       Retrieves content types from NetBox using the specified filters.
    #>

   param (
      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [ValidateSet("Site", "Location", "Rack", "Device", "Device Role")]
      [String]
      $Name
   )

   begin {
      # Verify configuration and initialize API endpoint
      Test-Config | Out-Null
      $URL = "/extras/content-types/"
   }

   process {
      # Build query string based on parameters provided
      $Query = ""

      if ($Name) {
         $Query = "?model=$($Name.Replace(' ','').ToLower())"
      }

      $Query = $Query.TrimEnd("&")

      # Make API request and retrieve the results
      $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

      # Create an empty list to hold the content type objects
      $ContentTypes = New-Object collections.generic.list[object]

      # Process each item in the result and cast to NetBox.ContentType type
      foreach ($Item in $Result) {
         [PSCustomObject]$ContentType = $item
         $ContentType.PSObject.TypeNames.Insert(0, "NetBox.ContentType")
         $ContentTypes += $ContentType
      }

      # Return the list of content types
      return $ContentTypes
   }
}

function Get-Manufacturer {
   <#
   .SYNOPSIS
      Gets a manufacturer from NetBox.
   .DESCRIPTION
      Retrieves manufacturer information from NetBox based on provided filters like name, ID, or slug.
   .EXAMPLE
      PS C:\> Get-NetBoxManufacturer -Name "Cisco"
      Retrieves manufacturer "Cisco" from NetBox.
   .PARAMETER Name
      Name of the manufacturer to filter by.
   .PARAMETER ID
      ID of the manufacturer to filter by.
    .PARAMETER Slug
       Slug identifier of the manufacturer to filter by.
   .INPUTS
      None.
   .OUTPUTS
      NetBox.Manufacturer
   .NOTES
      Retrieves manufacturer details from the NetBox API using specified filters.
   #>

   param (
      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Name,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $ID,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Slug
   )

   begin {
      # Verify configuration and initialize API endpoint
      Test-Config | Out-Null
      $URL = "/dcim/manufacturers/"
   }

   process {
      # Build query string based on parameters provided
      $Query = "?"

      if ($Name) {
         $Query = $Query + "name__ic=$($Name)&"
      }

      if ($ID) {
         $Query = $Query + "id=$($id)&"
      }

      if ($Slug) {
         $Query = $Query + "slug__ic=$($Slug)&"
      }

      $Query = $Query.TrimEnd("&")

      # Make API request and retrieve the results
      $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get

      # Check if multiple pages of results need to be retrieved
      if ($Result.Count -gt 50) {
         $Result = Get-NextPage -Result $Result
         $Manufacturer = $Result
      }
      else {
         $Manufacturer = $Result.results
      }

      # Cast the result to NetBox.Manufacturer type
      $Manufacturer.PSObject.TypeNames.Insert(0, "NetBox.Manufacturer")
      return $Manufacturer
   }
}

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

function Remove-Manufacturer {
   <#
    .SYNOPSIS
       Deletes a manufacturer from NetBox.
    .DESCRIPTION
       Removes a manufacturer from NetBox.
    .EXAMPLE
       PS C:\> Remove-NetBoxManufacturer -Name Dell
       Deletes manufacturer "Dell" from NetBox.
    .PARAMETER Name
       Name of the manufacturer to delete.
    .PARAMETER ID
       ID of the manufacturer to delete.
    .PARAMETER InputObject
       Manufacturer object to delete.
    .INPUTS
       NetBox.Manufacturer
    .OUTPUTS
       None.
    .NOTES
       Deletes a manufacturer from NetBox based on the specified parameters.
    #>

   [CmdletBinding(DefaultParameterSetName = "ByName")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $Name,

      [Parameter(Mandatory = $true, ParameterSetName = "ById")]
      [Int32]
      $ID,

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
      # Verify configuration and initialize API endpoint
      Test-Config | Out-Null
      $URL = "/dcim/manufacturers/"
   }

   process {
      # Ensure the input object is of the correct type
      if ($InputObject) {
         $Name = $InputObject.name
         $ID = $InputObject.ID
      }
      if ($Name) {
         $Manufacturer = Get-Manufacturer -Name $Name
      }
      if ($ID) {
         $Manufacturer = Get-Manufacturer -Id $ID
      }

      # Retrieve related objects to delete if the recurse option is enabled
      $RelatedObjects = Get-RelatedObjects -Object $Manufacturer -ReferenceObjects Manufacturer

      # Show confirmation dialog if required
      if ($Confirm) {
         Show-ConfirmDialog -Object $Manufacturer
      }

      # Remove all related objects if recurse is enabled
      if ($Recurse) {
         foreach ($Object in $RelatedObjects) {
            Invoke-RestMethod -Uri $Object.url @RestParams -Method Delete | Out-Null
         }
      }

      # Delete the manufacturer
      try {
         Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Manufacturer.ID) + "/") @RestParams -Method Delete
      }
      catch {
         # Handle errors during deletion, especially related object issues
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
       Retrieves device types from NetBox.
    .DESCRIPTION
       Retrieves detailed information about device types from the NetBox API based on various filters such as model, manufacturer, ID, and more.
    .EXAMPLE
       PS C:\> Get-NetboxDeviceType -Model "Cisco Catalyst 2960"
       Retrieves DeviceType for "Cisco Catalyst 2960" from NetBox.
    .PARAMETER Model
       The model name of the device type.
    .PARAMETER Manufacturer
       The manufacturer of the device type.
    .PARAMETER ID
       The unique ID of the device type.
    .PARAMETER SubDeviceRole
       Filter device types by their subdevice role.
    .PARAMETER PartNumber
       Filter device types by part number.
    .PARAMETER Slug
       Filter device types by slug.
    .PARAMETER Height
       Filter device types by height.
    .PARAMETER Exact
       Specify if the search should return an exact match instead of a partial one.
    .INPUTS
       None. You cannot pipe objects to this function.
    .OUTPUTS
       Returns a list of device types that match the provided filters.
    .NOTES
       This function interacts with the NetBox API to retrieve device types.
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
      $ID,

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
      # Test configuration and prepare the API endpoint URL
      Test-Config | Out-Null
      $URL = "/dcim/device-types/"
   }

   process {
      # Build the query string based on provided parameters
      $Query = "?"

      if ($Model) {
         $Query += if ($Exact) { "model=$($Model.Replace(" ","%20"))&" } else { "model__ic=$($Model)&" }
      }

      if ($Manufacturer) {
         $Query += "manufacturer_id=$((Get-Manufacturer -Name $Manufacturer).ID)&"
      }

      if ($ID) {
         $Query += "id=$($ID)&"
      }

      if ($SubDeviceRole) {
         $Query += "subdevice_role__ic=$($SubDeviceRole)&"
      }

      if ($PartNumber) {
         $Query += "part_number__ic=$($PartNumber)&"
      }

      if ($Slug) {
         $Query += if ($Exact) { "slug=$($Slug)&" } else { "slug__ic=$($Slug)&" }
      }

      if ($Height) {
         $Query += "u_height=$($Height)&"
      }

      $Query = $Query.TrimEnd("&")

      # Fetch the result from NetBox
      $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

      # Prepare the output as a list of PSCustomObjects
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

function Remove-DeviceType {
   <#
   .SYNOPSIS
      Deletes a device type from NetBox.
   .DESCRIPTION
      This function allows you to delete a device type from NetBox by specifying its model name or ID.
   .EXAMPLE
      PS C:\> Remove-NetboxDeviceType -Model "Cisco Catalyst 2960"
      Deletes the device type "Cisco Catalyst 2960" from NetBox.
   .PARAMETER Model
      The model name of the device type to be deleted.
   .PARAMETER Recurse
      Deletes all related objects as well.
   .PARAMETER Confirm
      Confirm the deletion of the device type.
   .PARAMETER InputObject
      The device type object to delete.
   .INPUTS
      NetBox.DeviceType object.
   .OUTPUTS
      Returns the status of the deletion.
   .NOTES
      This function interacts with the NetBox API to delete a device type.
   #>

   [CmdletBinding(DefaultParameterSetName = "ByName")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $Model,

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
      # Test configuration and prepare the API endpoint URL
      Test-Config | Out-Null
      $URL = "/dcim/device-types/"
   }

   process {
      # Retrieve the device type based on input
      if ($InputObject) {
         $Model = $InputObject.Model
      }

      $DeviceType = Get-DeviceType -Model $Model

      # Fetch related objects if recurse is enabled
      $RelatedObjects = Get-RelatedObjects -Object $DeviceType -ReferenceObjects DeviceType

      # Confirm deletion if requested
      if ($Confirm) {
         Show-ConfirmDialog -Object $DeviceType
      }

      # Remove all related objects if recurse is enabled
      if ($Recurse) {
         foreach ($Object in $RelatedObjects) {
            Invoke-RestMethod -Uri $Object.url @RestParams -Method Delete | Out-Null
         }
      }

      try {
         # Delete the device type
         Invoke-RestMethod -Uri $($NetboxURL + $URL + $($DeviceType.ID) + "/") @RestParams -Method Delete
      }
      catch {
         if ((($RestError.ErrorRecord) | ConvertFrom-Json).Detail -like "Unable to delete object*") {
            Write-Error "$($($($RestError.ErrorRecord) | ConvertFrom-Json).detail)"
            Write-Error "Delete those objects first or run again using the -Recurse switch."
         }
         else {
            Write-Error "$($($($RestError.ErrorRecord) | ConvertFrom-Json).detail)"
         }
      }
   }
}
function Import-DeviceType {
   <#
   .SYNOPSIS
      Imports device types from a YAML file into NetBox.
   .DESCRIPTION
      This function reads YAML files containing device type definitions and imports them into NetBox. It creates the device type, interfaces, power ports, and device bays as specified in the YAML file.
   .EXAMPLE
      PS C:\> Import-DeviceType -Path "C:\device-types\"
      Imports all YAML files from the specified directory into NetBox.
   .PARAMETER Path
      The file path to the directory containing YAML files to import.
   .INPUTS
      None. You cannot pipe objects to this function.
   .OUTPUTS
      Returns the imported device type objects.
   .NOTES
      This function requires the presence of YAML files formatted according to the NetBox device type schema.
   #>
   [CmdletBinding()]
   param (
      [Parameter(Mandatory = $true)]
      [String]
      [Alias("YamlFile")]
      $Path
   )

   # Get all files in the specified path
   $Files = Get-ChildItem -Path $Path

   foreach ($DeviceFile in $Files) {
      # Convert YAML content to PowerShell object
      $DeviceType = Get-Content $DeviceFile.FullName | ConvertFrom-Yaml

      # Log the device type details
      Write-Verbose $($DeviceType | Format-Table | Out-String)
      Write-Verbose $($DeviceType.Interfaces | Format-Table | Out-String)

      # Create manufacturer if it doesn't exist
      New-Manufacturer -Name $DeviceType.Manufacturer -Confirm $false | Out-Null

      # Build parameters for creating a new device type
      $NewDeviceTypeParams = @{
         ManufacturerName = $DeviceType.Manufacturer
         Model            = $DeviceType.Model
         Confirm          = $false
      }

      # Optional parameters based on YAML content
      if ($DeviceType.u_height) {
         $NewDeviceTypeParams["Height"] = $DeviceType.u_height
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

      # Log the new device type parameters
      Write-Verbose $($NewDeviceTypeParams | Format-Table | Out-String)

      # Create the new device type in NetBox
      $NewDeviceType = New-DeviceType @NewDeviceTypeParams -Confirm $false | Out-Null

      # Retrieve the device type if it wasn't created (e.g., it already exists)
      if ($null -eq $NewDeviceType) {
         $NewDeviceType = Get-NetBoxDeviceType -Model $DeviceType.Model -Manufacturer $DeviceType.Manufacturer
      }

      # Create interfaces based on YAML content
      foreach ($Interface in $DeviceType.interfaces) {
         Write-Verbose "Creating Interfaces"
         New-InterfaceTemplate -Name $Interface.Name -Type $Interface.Type -ManagementOnly $([System.Convert]::ToBoolean($Interface.mgmt_only)) -DeviceTypeID $NewDeviceType.ID -Confirm $false | Out-Null
      }

      # Create power ports based on YAML content
      foreach ($PSU in $DeviceType."power-ports") {
         Write-Verbose "Creating PSUs"
         New-PowerPortTemplate -Name $PSU.Name -Type $PSU.Type -DeviceTypeID $NewDeviceType.ID -Confirm $false | Out-Null
      }

      # Create device bays based on YAML content
      foreach ($DeviceBay in $DeviceType."device-bays") {
         Write-Verbose "Creating Device Bays"
         New-DeviceBayTemplate -Name $DeviceBay.Name -DeviceTypeID $NewDeviceType.ID -Confirm $false | Out-Null
      }
   }
}

function Get-Device {
   <#
    .SYNOPSIS
       Retrieves devices from NetBox based on various filters.
    .DESCRIPTION
       This function retrieves device objects from the NetBox API. It supports filtering by model, manufacturer, site, location, rack, and other attributes.
    .EXAMPLE
       PS C:\> Get-Device -DeviceType "Cisco Catalyst 2960"
       Retrieves all devices of type "Cisco Catalyst 2960" from NetBox.
    .PARAMETER Name
       The name of the device.
    .PARAMETER Model
       The model of the device.
    .PARAMETER Manufacturer
       The manufacturer of the device.
    .PARAMETER ID
       The unique ID of the device.
    .PARAMETER Slug
       The slug of the device.
    .PARAMETER MacAddress
       The MAC address of the device.
    .PARAMETER Site
       The site where the device is located.
    .PARAMETER Location
       The specific location within the site where the device is located.
    .PARAMETER Rack
       The rack where the device is installed.
    .PARAMETER DeviceType
       The device type to filter by.
    .PARAMETER Exact
       Specifies whether to perform an exact match on the filters.
    .INPUTS
       None. You cannot pipe objects to this function.
    .OUTPUTS
       Returns a list of device objects that match the provided filters.
    .NOTES
       This function interacts with the NetBox API to retrieve device objects.
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
      $ID,

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
      # Test configuration and prepare the API endpoint URL
      Test-Config | Out-Null
      $URL = "/dcim/devices/"
   }

   process {
      # Build the query string based on provided parameters
      $Query = "?"

      if ($Name) {
         $Query += if ($Exact) { "name=$($Name)&" } else { "name__ic=$($Name)&" }
      }
      if ($Model) {
         $Query += "model__ic=$($Model)&"
      }
      if ($Manufacturer) {
         $Query += "manufacturer=$($Manufacturer)&"
      }
      if ($ID) {
         $Query += "id=$($ID)&"
      }
      if ($Slug) {
         $Query += "slug__ic=$($Slug)&"
      }
      if ($MacAddress) {
         $Query += "mac_address=$($MacAddress)&"
      }
      if ($Site) {
         $Query += "site__ic=$($Site)&"
      }
      if ($Location) {
         $Query += "location__ic=$($Location)&"
      }
      if ($Rack) {
         $Query += "rack=$($Rack)&"
      }
      if ($DeviceType) {
         $Query += "device_type_id=$(Get-DeviceType -Model $($DeviceType) | Select-Object -ExpandProperty id)&"
      }

      $Query = $Query.TrimEnd("&")

      # Fetch the result from NetBox
      $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

      # Prepare the output as a list of PSCustomObjects
      $Devices = New-Object collections.generic.list[object]

      foreach ($Item in $Result) {
         [PSCustomObject]$Device = $Item
         $Device.PSObject.TypeNames.Insert(0, "NetBox.Device")
         $Devices += $Device
      }

      return $Devices
   }
}

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

function Update-Device {
   <#
    .SYNOPSIS
       Updates an existing device in NetBox.
    .DESCRIPTION
       This function updates the attributes of an existing device in NetBox.
    .EXAMPLE
       PS C:\> Update-Device -Name ExistingHost -DeviceType "NewType" -Location "High Density"
       Updates the device "ExistingHost" with a new device type and location.
    .PARAMETER Name
       The name of the device to update.
    .PARAMETER DeviceType
       The new device type for the device.
    .PARAMETER Site
       The site where the device is located.
    .PARAMETER Location
       The specific location within the site where the device is located.
    .PARAMETER Rack
       The rack where the device is installed.
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
    .PARAMETER AssetTag
       The asset tag or serial number of the device.
    .PARAMETER CustomFields
       Custom fields associated with the device.
    .PARAMETER Confirm
       Whether to confirm the update of the device.
    .INPUTS
       None. You cannot pipe objects to this function.
    .OUTPUTS
       Returns the updated device object.
    .NOTES
       This function interacts with the NetBox API to update an existing device.
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
      # Test configuration and prepare the API endpoint URL
      Test-Config | Out-Null
      $URL = "/dcim/devices/"
   }

   process {
      # Retrieve the device ID
      if ($Name -is [String]) {
         $name = (Get-Device -Query $Name).Id
      }
      else {
         $Name
      }

      # Build the request body for the API call
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

      # Remove empty keys from the request body
      ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

      # Confirm the update if required
      if ($Confirm) {
         $OutPutObject = [pscustomobject]$Body
         Show-ConfirmDialog -Object $OutPutObject
      }

      # Update the device in NetBox
      Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Interface.ID) + "/") @RestParams -Method Patch -Body $($Body | ConvertTo-Json)
   }
}

function Remove-Device {
   <#
   .SYNOPSIS
      Deletes a device from NetBox.
   .DESCRIPTION
      This function deletes a device and optionally all related objects from NetBox.
   .EXAMPLE
      PS C:\> Remove-NetBoxDevice -Name NewHost
      Deletes the device "NewHost" from NetBox.
   .PARAMETER Name
      The name of the device to delete.
   .PARAMETER Recurse
      Deletes all related objects as well.
   .PARAMETER Confirm
      Confirms the deletion of the device.
    .PARAMETER InputObject
      The device object to delete.
   .INPUTS
      None. You cannot pipe objects to this function.
   .OUTPUTS
      None.
   .NOTES
      This function interacts with the NetBox API to delete a device.
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
      # Test configuration and prepare the API endpoint URL
      Test-Config | Out-Null
      $URL = "/dcim/devices/"
   }

   process {
      # If the device object is provided through the pipeline, extract the name
      if ($InputObject) {
         $Name = $InputObject.name
      }

      # Retrieve the device information
      $Device = Get-Device -Name $Name

      # Retrieve related objects if the recurse option is selected
      $RelatedObjects = Get-RelatedObjects -Object $Device -ReferenceObjects Device

      # Confirm the deletion if required
      if ($Confirm) {
         Show-ConfirmDialog -Object $Device
      }

      # Delete related objects if the recurse option is selected
      if ($Recurse) {
         foreach ($Object in $RelatedObjects) {
            Invoke-RestMethod -Uri $Object.url @RestParams -Method Delete | Out-Null
         }
      }

      try {
         # Delete the device from NetBox
         Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Device.ID) + "/") @RestParams -Method Delete
      }
      catch {
         # Handle specific errors, such as dependencies that must be deleted first
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
       Retrieves device types from NetBox.
    .DESCRIPTION
       Retrieves detailed information about device types from the NetBox API based on various filters such as model, manufacturer, ID, and more.
    .EXAMPLE
       PS C:\> Get-NetboxDeviceType -Model "Cisco Catalyst 2960"
       Retrieves DeviceType for "Cisco Catalyst 2960" from NetBox.
    .PARAMETER Model
       The model name of the device type.
    .PARAMETER Manufacturer
       The manufacturer of the device type.
    .PARAMETER ID
       The unique ID of the device type.
    .PARAMETER SubDeviceRole
       Filter device types by their subdevice role.
    .PARAMETER PartNumber
       Filter device types by part number.
    .PARAMETER Slug
       Filter device types by slug.
    .PARAMETER Height
       Filter device types by height.
    .PARAMETER Exact
       Specify if the search should return an exact match instead of a partial one.
    .INPUTS
       None. You cannot pipe objects to this function.
    .OUTPUTS
       Returns a list of device types that match the provided filters.
    .NOTES
       This function interacts with the NetBox API to retrieve device types.
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
      $ID,

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
      # Test configuration and prepare the API endpoint URL
      Test-Config | Out-Null
      $URL = "/dcim/device-types/"
   }

   process {
      # Build the query string based on provided parameters
      $Query = "?"

      if ($Model) {
         $Query += if ($Exact) { "model=$($Model.Replace(" ","%20"))&" } else { "model__ic=$($Model)&" }
      }

      if ($Manufacturer) {
         $Query += "manufacturer_id=$((Get-Manufacturer -Name $Manufacturer).ID)&"
      }

      if ($ID) {
         $Query += "id=$($ID)&"
      }

      if ($SubDeviceRole) {
         $Query += "subdevice_role__ic=$($SubDeviceRole)&"
      }

      if ($PartNumber) {
         $Query += "part_number__ic=$($PartNumber)&"
      }

      if ($Slug) {
         $Query += if ($Exact) { "slug=$($Slug)&" } else { "slug__ic=$($Slug)&" }
      }

      if ($Height) {
         $Query += "u_height=$($Height)&"
      }

      $Query = $Query.TrimEnd("&")

      # Fetch the result from NetBox
      $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

      # Prepare the output as a list of PSCustomObjects
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
   }
}

function Remove-DeviceType {
   <#
   .SYNOPSIS
      Deletes a device type from NetBox.
   .DESCRIPTION
      This function deletes a specified device type from NetBox using its ID or model name.
   .EXAMPLE
      PS C:\> Remove-NetboxDeviceType -Model "Cisco Catalyst 2960"
      Deletes the device type "Cisco Catalyst 2960" from NetBox.
   .PARAMETER Model
      Model of the device type to be deleted.
   .PARAMETER Slug
      Slug of the device type to be deleted.
   .PARAMETER ID
      ID of the device type to be deleted.
   .PARAMETER Force
      Force deletion without confirmation.
   .INPUTS
      None. You cannot pipe objects to this function.
   .OUTPUTS
      Returns the status of the deletion.
   .NOTES
      This function interacts with the NetBox API to delete a device type.
   #>

   param (
      [Parameter(Mandatory = $false, ParameterSetName = "ByName")]
      [Alias("Name")]
      [String]
      $Model,

      [Parameter(Mandatory = $false, ParameterSetName = "BySlug")]
      [String]
      $Slug,

      [Parameter(Mandatory = $false, ParameterSetName = "ByID")]
      [Int32]
      $ID,

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
      # Determine the correct device type ID based on the input
      if ($ID) {
         $DeviceTypeID = $ID
      }
      elseif ($Model) {
         $DeviceTypeID = (Get-DeviceType -Model $Model -Exact).id
      }
      elseif ($Slug) {
         $DeviceTypeID = (Get-DeviceType -Slug $Slug -Exact).id
      }

      # Confirm deletion if not forced
      if (-not $Force) {
         Show-ConfirmDialog -Object "Are you sure you want to delete DeviceType with ID $DeviceTypeID?"
      }

      # Perform deletion
      $Result = Invoke-RestMethod -Uri "$NetboxURL$URL$DeviceTypeID/" @RestParams -Method Delete

      if ($Result) {
         Write-Host "DeviceType deleted successfully."
      }
      else {
         Write-Warning "Failed to delete DeviceType."
      }

      return $Result
   }
}
function Get-PowerPortTemplate {
   <#
   .SYNOPSIS
      Retrieves a power port template from NetBox.
   .DESCRIPTION
      This function fetches power port templates from NetBox, allowing you to filter by name, ID, device type name, or device type ID.
   .EXAMPLE
      PS C:\> Get-NetBoxPowerPortTemplate -Name "PSU1"
      Retrieves the Power Port Template with the name "PSU1".
   .PARAMETER Name
      The name of the power port template.
   .PARAMETER ID
      The ID of the power port template.
   .PARAMETER DeviceTypeName
      The name of the parent device type.
   .PARAMETER DeviceTypeID
      The ID of the parent device type.
   .INPUTS
      None. You cannot pipe objects to this function.
   .OUTPUTS
      Returns a list of power port templates as NetBox.PowerPortTemplate objects.
   .NOTES
      This function interacts with the NetBox API to retrieve power port templates based on the provided filters.
   #>

   param (
      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Name,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $ID,

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

      if ($ID) {
         $Query = $Query + "id=$($ID)&"
      }

      $Query = $Query.TrimEnd("&")

      $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

      $PowerPortTemplates = New-Object collections.generic.list[object]

      foreach ($Item in $Result) {
         [PSCustomObject]$PowerPortTemplate = $Item
         $PowerPortTemplate.PSObject.TypeNames.Insert(0, "NetBox.PowerPortTemplate")
         $PowerPortTemplates += $PowerPortTemplate
      }

      return $PowerPortTemplates
   }
}
function New-PowerPortTemplate {
   <#
   .SYNOPSIS
      Creates a new power port template in NetBox.
   .DESCRIPTION
      This function creates a new power port template in NetBox using the provided parameters.
   .EXAMPLE
      PS C:\> New-PowerPortTemplate -Name "PSU1" -DeviceTypeName "ServerModel" -Type "iec-60320-c14"
      Creates a new power port template named "PSU1" for the device type "ServerModel" with the type "iec-60320-c14".
   .PARAMETER Name
      The name of the power port template.
   .PARAMETER DeviceTypeName
      The name of the device type associated with this power port template.
   .PARAMETER DeviceTypeID
      The ID of the device type associated with this power port template.
   .PARAMETER Type
      The type of the power port (e.g., "iec-60320-c14").
   .PARAMETER Label
      The label for the power port template.
   .PARAMETER MaxiumDraw
      The maximum draw capacity for the power port template.
   .PARAMETER AllocatedPower
      The allocated power for the power port template.
   .PARAMETER Confirm
      If specified, prompts the user for confirmation before creating the power port template.
   .PARAMETER Force
      Forces the creation of the power port template even if one with the same name exists.
   .INPUTS
      None.
   .OUTPUTS
      NetBox.PowerPortTemplate
   .NOTES
      Ensure that the device type name or ID provided exists in NetBox.
   #>

   [CmdletBinding(DefaultParameterSetName = "ByName")]
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

      if (Get-PowerPortTemplate -DeviceTypeID $DeviceType.ID -Name $Name) {
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

      # Remove empty keys
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
      Removes a power port template from NetBox.
   .DESCRIPTION
      This function deletes a power port template in NetBox using the provided name or input object.
   .EXAMPLE
      PS C:\> Remove-PowerPortTemplate -Name "PSU1"
      Deletes the power port template named "PSU1".
   .PARAMETER Name
      The name of the power port template to remove.
   .PARAMETER Recurse
      If specified, removes all related objects.
   .PARAMETER Confirm
      If specified, prompts the user for confirmation before removing the power port template.
   .PARAMETER InputObject
      A pipeline input object representing the power port template to remove.
   .INPUTS
      NetBox.PowerPortTemplate
   .OUTPUTS
      None.
   .NOTES
      Ensure that the power port template exists before attempting to remove it.
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

      if ($Confirm) {
         Show-ConfirmDialog -Object $InputObject
      }

      try {
         Invoke-RestMethod -Uri $($NetboxURL + $URL + $Name + "/") @RestParams -Method Delete
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

function Get-Cable {
   <#
   .SYNOPSIS
      Retrieves cables from NetBox.
   .DESCRIPTION
      This function gets cables from NetBox based on various filter parameters.
   .EXAMPLE
      PS C:\> Get-Cable -Device "ServerA"
      Retrieves all cables for the device "ServerA".
   .PARAMETER Label
      The label of the cable.
   .PARAMETER ID
      The ID of the cable.
   .PARAMETER Device
      The name of the parent device.
   .PARAMETER Rack
      The name of the parent rack.
   .INPUTS
      None.
   .OUTPUTS
      NetBox.Cable
   .NOTES
      Ensure that the device or rack specified exists in NetBox.
   #>

   param (
      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Label,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $ID,

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

      if ($ID) {
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
      Creates a new cable in NetBox.
   .DESCRIPTION
      This function creates a new cable in NetBox between two interfaces on devices.
   .EXAMPLE
      PS C:\> New-Cable -DeviceAName "ServerA" -InterfaceAName "Gig-E 1" -DeviceBName "SwitchB" -InterfaceBName "GigabitEthernet1/0/39" -Type "cat6"
      Creates a new cat6 cable between the specified interfaces on ServerA and SwitchB.
   .PARAMETER DeviceAName
      Name of Endpoint Device A of the cable.
   .PARAMETER InterfaceAName
      Name of Endpoint Interface A of the cable.
   .PARAMETER DeviceAID
      ID of Endpoint Device A of the cable.
   .PARAMETER InterfaceAID
      ID of Endpoint Interface A of the cable.
   .PARAMETER DeviceBName
      Name of Endpoint Device B of the cable.
   .PARAMETER InterfaceBName
      Name of Endpoint Interface B of the cable.
   .PARAMETER DeviceBID
      ID of Endpoint Device B of the cable.
   .PARAMETER InterfaceBID
      ID of Endpoint Interface B of the cable.
   .PARAMETER Label
      The label for the cable.
   .PARAMETER Type
      The type of the cable (e.g., "cat6").
   .PARAMETER Color
      The color of the cable.
   .PARAMETER Length
      The length of the cable.
   .PARAMETER LengthUnit
      The unit of length for the cable.
   .PARAMETER Confirm
      If specified, prompts the user for confirmation before creating the cable.
   .PARAMETER Force
      Forces the creation of the cable even if one already exists.
   .INPUTS
      NetBox.Cable
   .OUTPUTS
      NetBox.Cable
   .NOTES
      Ensure that the interfaces and devices specified exist in NetBox.
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
         termination_a_id   = $StartPoint.ID
         termination_b_type = "dcim.interface"
         termination_b_id   = $EndPoint.ID
         type               = $Type
         label              = $Label
         color              = $Color
         status             = $Status
         length             = $Length
         length_unit        = $LengthUnit
      }

      # Remove empty keys
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

function Remove-Cable {
   <#
   .SYNOPSIS
      Deletes a cable from NetBox.
   .DESCRIPTION
      This function deletes a cable from NetBox using the specified parameters.
   .EXAMPLE
      PS C:\> Remove-Cable -Label "Important Cable"
      Deletes the cable with the label "Important Cable".
   .PARAMETER Label
      The label of the cable to delete.
   .PARAMETER ID
      The ID of the cable to delete.
   .PARAMETER Confirm
      If specified, prompts the user for confirmation before deleting the cable.
   .INPUTS
      NetBox.Cable
   .OUTPUTS
      None.
   .NOTES
      Ensure that the cable specified exists in NetBox.
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
         Show-ConfirmDialog -Object $Cable
      }

      try {
         Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Cable.ID) + "/") @RestParams -Method Delete
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
      Retrieves device bay templates from NetBox.
   .DESCRIPTION
      This function retrieves device bay templates from NetBox based on the provided filter parameters.
   .EXAMPLE
      PS C:\> Get-DeviceBayTemplate -Name "Bay1"
      Retrieves the device bay template with the name "Bay1".
   .PARAMETER Name
      The name of the device bay template to retrieve.
   .PARAMETER Id
      The ID of the device bay template to retrieve.
   .PARAMETER DeviceTypeName
      The name of the device type associated with the device bay template.
   .PARAMETER DeviceTypeID
      The ID of the device type associated with the device bay template.
   .INPUTS
      None. This function does not accept piped input.
   .OUTPUTS
      NetBox.DeviceBayTemplate. Returns a list of device bay templates matching the criteria.
   .NOTES
      Ensure that the NetBox connection is configured before using this function.
   #>

   param (
      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Name,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $ID,

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

      if ($ID) {
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

      return $DeviceBayTemplates
   }
}

function New-DeviceBayTemplate {
   <#
   .SYNOPSIS
      Creates a new device bay template in NetBox.
   .DESCRIPTION
      This function creates a new device bay template in NetBox using the provided parameters.
   .EXAMPLE
      PS C:\> New-DeviceBayTemplate -Name "Bay1" -DeviceTypeName "ServerModel"
      Creates a new device bay template named "Bay1" for the device type "ServerModel".
   .PARAMETER Name
      The name of the device bay template.
   .PARAMETER DeviceTypeName
      The name of the device type associated with this device bay template.
   .PARAMETER DeviceTypeID
      The ID of the device type associated with this device bay template.
   .PARAMETER Label
      The label for the device bay template.
   .PARAMETER Description
      A description for the device bay template.
   .PARAMETER Confirm
      If specified, prompts the user for confirmation before creating the device bay template.
   .PARAMETER Force
      Forces the creation of the device bay template even if one with the same name exists.
   .INPUTS
      None. This function does not accept piped input.
   .OUTPUTS
      NetBox.DeviceBayTemplate. Returns the created device bay template.
   .NOTES
      Ensure that the device type exists in NetBox before attempting to create a template.
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

      # Remove empty keys
      ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

      if ($Confirm) {
         $OutPutObject = [pscustomobject]$Body
         Show-ConfirmDialog -Object $OutPutObject
      }

      if (-Not $Exists) {
         $DeviceBayTemplate = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
         $DeviceBayTemplate.PSObject.TypeNames.Insert(0, "NetBox.DeviceBayTemplate")
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
      Retrieves device bays from NetBox.
   .DESCRIPTION
      This function retrieves device bays from NetBox based on the provided filter parameters.
   .EXAMPLE
      PS C:\> Get-DeviceBay -DeviceName "Chassis"
      Retrieves all device bays for the device "Chassis".
   .PARAMETER Name
      The name of the device bay to retrieve.
   .PARAMETER Id
      The ID of the device bay to retrieve.
   .PARAMETER DeviceName
      The name of the parent device associated with the device bay.
   .PARAMETER DeviceID
      The ID of the parent device associated with the device bay.
   .INPUTS
      None. This function does not accept piped input.
   .OUTPUTS
      NetBox.DeviceBay. Returns a list of device bays matching the criteria.
   .NOTES
      Ensure that the NetBox connection is configured before using this function.
   #>

   param (
      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Name,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $ID,

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

      if ($ID) {
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
      Creates a new device bay in NetBox.
   .DESCRIPTION
      This function creates a new device bay in NetBox associated with a specified parent device.
   .EXAMPLE
      PS C:\> New-DeviceBay -DeviceName "Chassis" -Name "Bay1"
      Creates a new device bay named "Bay1" for the device "Chassis".
   .PARAMETER Name
      The name of the device bay to create.
   .PARAMETER DeviceName
      The name of the parent device for the device bay.
   .PARAMETER DeviceID
      The ID of the parent device for the device bay.
   .PARAMETER InstalledDeviceName
      The name of the installed (child) device for the device bay.
   .PARAMETER InstalledDeviceID
      The ID of the installed (child) device for the device bay.
   .PARAMETER Label
      A label for the device bay.
   .PARAMETER Confirm
      If specified, prompts the user for confirmation before creating the device bay.
   .PARAMETER Force
      Forces the creation of the device bay even if one already exists with the same name.
   .INPUTS
      None. This function does not accept piped input.
   .OUTPUTS
      NetBox.DeviceBay. Returns the created device bay.
   .NOTES
      Ensure that the parent device and any installed devices are present in NetBox before creating a device bay.
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

      # Remove empty keys
      ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

      if ($Confirm) {
         $OutPutObject = [pscustomobject]$Body
         Show-ConfirmDialog -Object $OutPutObject
      }

      $DeviceBay = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
      $DeviceBay.PSObject.TypeNames.Insert(0, "NetBox.DeviceBay")
      return $DeviceBay
   }
}

function Update-DeviceBay {
   <#
   .SYNOPSIS
      Updates an existing device bay in NetBox.
   .DESCRIPTION
      This function updates an existing device bay in NetBox with new details provided by the user.
   .EXAMPLE
      PS C:\> Update-DeviceBay -DeviceName "Chassis" -Name "Bay1" -InstalledDeviceName "Server1"
      Updates the device bay "Bay1" in "Chassis" to associate it with "Server1".
   .PARAMETER Name
      The name of the device bay to update.
   .PARAMETER DeviceName
      The name of the parent device.
   .PARAMETER DeviceID
      The ID of the parent device.
   .PARAMETER InstalledDeviceName
      The name of the installed (child) device.
   .PARAMETER InstalledDeviceID
      The ID of the installed (child) device.
   .PARAMETER Label
      A label for the device bay.
   .PARAMETER Confirm
      If specified, prompts the user for confirmation before updating the device bay.
   .PARAMETER Force
      Forces the update even if it would conflict with existing data.
   .INPUTS
      None. This function does not accept piped input.
   .OUTPUTS
      NetBox.DeviceBay. Returns the updated device bay.
   .NOTES
      Ensure that the device and installed device are present in NetBox before updating the device bay.
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

      # Remove empty keys
      ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

      if ($Confirm) {
         $OutPutObject = [pscustomobject]$Body
         Show-ConfirmDialog -Object $OutPutObject
      }

      $DeviceBay = Invoke-RestMethod -Uri $($NetboxURL + $URL + $($DeviceBay.ID) + "/") @RestParams -Method Patch -Body $($Body | ConvertTo-Json)
      $DeviceBay.PSObject.TypeNames.Insert(0, "NetBox.DeviceBay")
      return $DeviceBay
   }
}

function Get-CustomLink {
   <#
   .SYNOPSIS
      Retrieves a custom link from NetBox.
   .DESCRIPTION
      This function retrieves a custom link from NetBox by name or ID.
   .EXAMPLE
      PS C:\> Get-CustomLink -Name "ServiceCatalogID"
      Retrieves the custom link with the name "ServiceCatalogID".
   .PARAMETER Name
      The name of the custom link to retrieve.
   .PARAMETER ID
      The ID of the custom link to retrieve.
   .INPUTS
      None. This function does not accept piped input.
   .OUTPUTS
      NetBox.CustomLink. Returns a list of custom links matching the criteria.
   .NOTES
      Ensure that the NetBox connection is configured before using this function.
   #>

   param (
      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Name,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $ID
   )

   begin {
      Test-Config | Out-Null
      $URL = "/extras/custom-links/"
   }

   process {
      $Query = "?"

      if ($Name) {
         $Query = $Query + "name__ic=$($Name)&"
      }

      if ($ID) {
         $Query = $Query + "id=$($id)&"
      }

      $Query = $Query.TrimEnd("&")

      $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

      $CustomLinks = New-Object collections.generic.list[object]

      foreach ($Item in $Result) {
         [PSCustomObject]$CustomLink = $item
         $CustomLink.PSObject.TypeNames.Insert(0, "NetBox.CustomLink")
         $CustomLinks += $CustomLink
      }

      return $CustomLinks
   }
}

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

function Remove-CustomLink {
   <#
   .SYNOPSIS
      Removes a custom link from NetBox.
   .DESCRIPTION
      This function removes a custom link from NetBox by name or ID.
   .EXAMPLE
      PS C:\> Remove-CustomLink -ID 3
      Removes the custom link with ID 3 from NetBox.
   .PARAMETER Name
      The name of the custom link to remove.
   .PARAMETER ID
      The ID of the custom link to remove.
   .PARAMETER InputObject
      The custom link object to remove.
   .INPUTS
      NetBox.CustomLink. You can pipe a custom link object to this function.
   .OUTPUTS
      None. This function does not return a value.
   .NOTES
      Ensure that the custom link exists before attempting to remove it.
   #>

   [CmdletBinding(DefaultParameterSetName = "ByName")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $Name,

      [Parameter(Mandatory = $true, ParameterSetName = "ById")]
      [Int32]
      $ID,

      [Parameter(Mandatory = $false)]
      [Bool]
      $Confirm = $true,

      [Parameter(ValueFromPipeline = $true, ParameterSetName = 'ByInputObject')]
      $InputObject
   )

   begin {
      Test-Config | Out-Null
      $URL = "/extras/custom-links/"
   }

   process {
      if (-not ($InputObject.psobject.TypeNames -contains "NetBox.CustomLink")) {
         Write-Error "InputObject is not of type NetBox.CustomLink"
         break
      }

      if ($InputObject) {
         $Name = $InputObject.name
         $ID = $InputObject.Id
      }

      if ($ID) {
         $CustomLink = Get-CustomLink -Id $ID
      }
      else {
         $CustomLink = Get-CustomLink -Name $Name
      }

      $RelatedObjects = Get-RelatedObjects -Object $CustomLink -ReferenceObjects CustomLink

      if ($Confirm) {
         Show-ConfirmDialog -Object $CustomLink
      }

      # Remove all related objects
      if ($Recurse) {
         foreach ($Object in $RelatedObjects) {
            Invoke-RestMethod -Uri $Object.url @RestParams -Method Delete | Out-Null
         }
      }

      try {
         Invoke-RestMethod -Uri $($NetboxURL + $URL + $($CustomLink.ID) + "/") @RestParams -Method Delete
      }
      catch {
         if ((($RestError.ErrorRecord) | ConvertFrom-Json).Detail -like "Unable to delete object*") {
            Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
            Write-Error "Delete those objects first or run again using the -recurse switch"
         }
         else {
            Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
         }
      }
   }
}

function Get-IPAddress {
   <#
   .SYNOPSIS
      Retrieves an IP address from NetBox.
   .DESCRIPTION
      This function retrieves an IP address from NetBox by address, DNS name, or ID.
   .EXAMPLE
      PS C:\> Get-IPAddress -Address "192.168.1.10"
      Retrieves the IP address "192.168.1.10" from NetBox.
   .PARAMETER Address
      The IP address to retrieve.
   .PARAMETER DNSName
      The DNS name associated with the IP address.
   .PARAMETER ID
      The ID of the IP address to retrieve.
   .INPUTS
      None. This function does not accept piped input.
   .OUTPUTS
      NetBox.IP. Returns a list of IP addresses matching the criteria.
   .NOTES
      Ensure that the IP address or DNS name exists in NetBox before retrieving it.
   #>

   param (
      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Address,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Alias("HostName")]
      [String]
      $DNSName,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $ID
   )

   begin {
      Test-Config | Out-Null
      $URL = "/ipam/ip-addresses/"
   }

   process {
      $Query = "?"

      if ($Address) {
         $Query = $Query + "address=$($address)&"
      }

      if ($DNSName) {
         $Query = $Query + "dns_name__ic=$($DNSName)&"
      }

      if ($ID) {
         $Query = $Query + "id=$($id)&"
      }

      $Query = $Query.TrimEnd("&")

      $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

      $IPs = New-Object collections.generic.list[object]

      foreach ($Item in $Result) {
         [PSCustomObject]$IP = $item
         $IP.PSObject.TypeNames.Insert(0, "NetBox.IP")
         $IPs += $IP
      }

      return $IPs
   }
}

function New-IPAddress {
   <#
   .SYNOPSIS
      Creates a new IP address in NetBox.
   .DESCRIPTION
      This function creates a new IP address in NetBox using the provided address and subnet.
   .EXAMPLE
      PS C:\> New-IPAddress -Address "192.168.1.10" -Subnet "24"
      Creates a new IP address "192.168.1.10" with a subnet mask of "24".
   .PARAMETER Address
      The IP address to create.
   .PARAMETER Subnet
      The subnet mask for the IP address.
   .PARAMETER DNSName
      The DNS name associated with the IP address.
   .PARAMETER Status
      The status of the IP address (e.g., "active", "planned").
   .INPUTS
      None. This function does not accept piped input.
   .OUTPUTS
      NetBox.IP. Returns the created IP address.
   .NOTES
      Ensure that the subnet and DNS name (if provided) are valid before creating the IP address.
   #>

   param (
      [Parameter(Mandatory = $True)]
      [String]
      $Address,

      [Parameter(Mandatory = $True)]
      [String]
      $Subnet,

      [Parameter(Mandatory = $false)]
      [Alias("HostName")]
      [String]
      $DNSName,

      [Parameter(Mandatory = $false)]
      [ValidateSet("offline", "active", "planned", "staged", "failed", "inventory", "decommissioning")]
      [String]
      $Status = "active"
   )

   begin {
      Test-Config | Out-Null
      $URL = "/ipam/ip-addresses/"
   }

   process {
      if ($Address) {
         if (Get-IPAddress -Address $Address) {
            Write-Warning "IP Address $Address already exists"
            $Exists = $true
         }
      }

      $Body = @{
         address  = "$Address/$Subnet"
         status   = $Status
         dns_name = $DNSName
      }

      if ($CustomFields) {
         $Body.custom_fields = @{}
         foreach ($Key in $CustomFields.Keys) {
            $Body.custom_fields.add($Key, $CustomFields[$Key])
         }
      }

      # Remove empty keys
      ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

      if ($Confirm) {
         $OutPutObject = [pscustomobject]$Body
         Show-ConfirmDialog -Object $OutPutObject
      }

      if (-Not $Exists) {
         $IPAddress = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
         $IPAddress.PSObject.TypeNames.Insert(0, "NetBox.IP")
         return $IPAddress
      }
      else {
         return
      }
   }
}

function Update-IPAddress {
   <#
   .SYNOPSIS
      Updates an existing IP address in NetBox.
   .DESCRIPTION
      This function updates an existing IP address in NetBox with new details provided by the user.
   .EXAMPLE
      PS C:\> Update-IPAddress -Address "192.168.1.10" -DNSName "server1.example.com"
      Updates the IP address "192.168.1.10" to associate it with "server1.example.com".
   .PARAMETER Address
      The IP address to update.
   .PARAMETER Subnet
      The subnet mask for the IP address.
   .PARAMETER DNSName
      The DNS name associated with the IP address.
   .PARAMETER Status
      The status of the IP address (e.g., "active", "planned").
   .INPUTS
      None. This function does not accept piped input.
   .OUTPUTS
      NetBox.IP. Returns the updated IP address.
   .NOTES
      Ensure that the IP address and DNS name (if provided) are valid before updating the IP address.
   #>

   param (
      [Parameter(Mandatory = $True)]
      [String]
      $Address,

      [Parameter(Mandatory = $True)]
      [String]
      $Subnet,

      [Parameter(Mandatory = $false)]
      [Alias("HostName")]
      [String]
      $DNSName,

      [Parameter(Mandatory = $false)]
      [ValidateSet("offline", "active", "planned", "staged", "failed", "inventory", "decommissioning")]
      [String]
      $Status = "active"
   )

   begin {
      Test-Config | Out-Null
      $URL = "/ipam/ip-addresses/"
   }

   process {
      if ($Address) {
         $IPAddress = Get-IPAddress -Address $Address
      }

      if ($ID) {
         $IPAddress = Get-IPAddress -ID $ID
      }

      $Body = @{
         address  = "$Address/$Subnet"
         status   = $Status
         dns_name = $DNSName
      }

      # Remove empty keys
      ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

      if ($Confirm) {
         $OutPutObject = [pscustomobject]$Body
         Show-ConfirmDialog -Object $OutPutObject
      }

      Invoke-RestMethod -Uri $($NetboxURL + $URL + $($IPAddress.ID) + "/") @RestParams -Method Patch -Body $($Body | ConvertTo-Json)
   }
}

function Remove-IPAddress {
   <#
   .SYNOPSIS
      Removes an IP address from NetBox.
   .DESCRIPTION
      This function removes an IP address from NetBox by address, DNS name, or ID.
   .EXAMPLE
      PS C:\> Remove-IPAddress -Address "192.168.1.10"
      Removes the IP address "192.168.1.10" from NetBox.
   .PARAMETER Address
      The IP address to remove.
   .PARAMETER DNSName
      The DNS name associated with the IP address.
   .PARAMETER ID
      The ID of the IP address to remove.
   .PARAMETER Confirm
      If specified, prompts the user for confirmation before removing the IP address.
   .INPUTS
      NetBox.IP. You can pipe an IP address object to this function.
   .OUTPUTS
      None. This function does not return a value.
   .NOTES
      Ensure that the IP address exists in NetBox before attempting to remove it.
   #>

   param (
      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Address,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Alias("HostName")]
      [String]
      $DNSName,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $ID,

      [Parameter(Mandatory = $false)]
      [Bool]
      $Confirm = $true,

      [Parameter(ValueFromPipeline = $true, ParameterSetName = 'ByInputObject')]
      $InputObject
   )

   begin {
      Test-Config | Out-Null
      $URL = "/ipam/ip-addresses/"
   }

   process {
      if ($Address) {
         $IPAddress = Get-IPAddress -Address $Address
      }

      if ($ID) {
         $IPAddress = Get-IPAddress -ID $ID
      }

      if ($Confirm) {
         Show-ConfirmDialog -Object $IPAddress
      }

      try {
         Invoke-RestMethod -Uri $($NetboxURL + $URL + $($IPAddress.ID) + "/") @RestParams -Method Delete
      }
      catch {
         if ((($RestError.ErrorRecord) | ConvertFrom-Json).Detail -like "Unable to delete object*") {
            Write-Error "$($($($RestError.ErrorRecord) | ConvertFrom-Json).detail)"
            Write-Error "Delete those objects first or run again using the -recurse switch"
         }
         else {
            Write-Error "$($($($RestError.ErrorRecord) | ConvertFrom-Json).detail)"
         }
      }
   }
}


# function Get-IPRange {
#    <#
#    .SYNOPSIS
#       Short description
#    .DESCRIPTION
#       Long description
#    .EXAMPLE
#       PS C:\> <example usage>
#       Explanation of what the example does
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
#       OptionalParameters
#    )

# }

# function New-IPRange {
#    <#
#    .SYNOPSIS
#       Short description
#    .DESCRIPTION
#       Long description
#    .EXAMPLE
#       PS C:\> <example usage>
#       Explanation of what the example does
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
#       OptionalParameters
#    )
#    FunctionName
# }

# function Remove-IPRange {
#    <#
#    .SYNOPSIS
#       Short description
#    .DESCRIPTION
#       Long description
#    .EXAMPLE
#       PS C:\> <example usage>
#       Explanation of what the example does
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
#       OptionalParameters
#    )

# }

# function Get-IPPrefix {
#    <#
#    .SYNOPSIS
#       Short description
#    .DESCRIPTION
#       Long description
#    .EXAMPLE
#       PS C:\> <example usage>
#       Explanation of what the example does
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
#       OptionalParameters
#    )

# }

# function New-IPPrefix {
#    <#
#    .SYNOPSIS
#       Short description
#    .DESCRIPTION
#       Long description
#    .EXAMPLE
#       PS C:\> <example usage>
#       Explanation of what the example does
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
#       OptionalParameters
#    )
#    FunctionName
# }

# function Remove-IPPrefix {
#    <#
#    .SYNOPSIS
#       Short description
#    .DESCRIPTION
#       Long description
#    .EXAMPLE
#       PS C:\> <example usage>
#       Explanation of what the example does
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
#       OptionalParameters
#    )

# }