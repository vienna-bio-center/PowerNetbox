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
