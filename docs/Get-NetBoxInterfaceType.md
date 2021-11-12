---
external help file: PowerNetBox-help.xml
Module Name: PowerNetBox
online version:
schema: 2.0.0
---

# Get-NetBoxInterfaceType

## SYNOPSIS
Determine the interface type of a device based on linkspeed and connection type

## SYNTAX

```
Get-NetBoxInterfaceType [-Linkspeed] <Object> [[-InterfaceType] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Long description

## EXAMPLES

### EXAMPLE 1
```
Get-NetBoxInterfaceType -Linkspeed 10GE -InterfaceType sfp
Returns the Netbox interface Type for a 10GBit\s SFP interface
```

## PARAMETERS

### -Linkspeed
Speed auf the interface in gigabit/s e.g.
10GE

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InterfaceType
Type of the connector e.g.
sfp or RJ45 or just fixed / modular

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### Inputs (if any)
## OUTPUTS

### NetBox.InterfaceType
## NOTES
General notes

## RELATED LINKS
