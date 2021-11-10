---
external help file: PowerNetBox-help.xml
Module Name: PowerNetBox
online version:
schema: 2.0.0
---

# Get-NetBoxInterface

## SYNOPSIS
Get a specific interface from netbox

## SYNTAX

### Byname (Default)
```
Get-NetBoxInterface [<CommonParameters>]
```

### ByName
```
Get-NetBoxInterface -Name <String> -ManagementOnly <Boolean> [<CommonParameters>]
```

### ById
```
Get-NetBoxInterface -Id <Int32> [<CommonParameters>]
```

### ByDevice
```
Get-NetBoxInterface -Device <Int32> [<CommonParameters>]
```

## DESCRIPTION
Long description

## EXAMPLES

### EXAMPLE 1
```
Get-NetBoxInterface -Device "NewHost"
Get all interfaces from device "NewHost"
```

## PARAMETERS

### -Name
Name of the interface

```yaml
Type: String
Parameter Sets: ByName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Id
ID of the interface

```yaml
Type: Int32
Parameter Sets: ById
Aliases:

Required: True
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Device
Name of the parent device

```yaml
Type: Int32
Parameter Sets: ByDevice
Aliases:

Required: True
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -ManagementOnly
Is this interface only for management?

```yaml
Type: Boolean
Parameter Sets: ByName
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### Inputs (if any)
## OUTPUTS

### Output (if any)
## NOTES
General notes

## RELATED LINKS
