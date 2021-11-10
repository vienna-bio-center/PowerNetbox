---
external help file: PowerNetBox-help.xml
Module Name: PowerNetBox
online version:
schema: 2.0.0
---

# Get-NetBoxDeviceType

## SYNOPSIS
Retrieves device types from NetBox

## SYNTAX

### ByModel (Default)
```
Get-NetBoxDeviceType -Model <String> [<CommonParameters>]
```

### ByManufacturer
```
Get-NetBoxDeviceType -Manufacturer <String> [<CommonParameters>]
```

### ById
```
Get-NetBoxDeviceType -Id <Int32> [<CommonParameters>]
```

### Query
```
Get-NetBoxDeviceType -Query <String> [<CommonParameters>]
```

## DESCRIPTION
Long description

## EXAMPLES

### EXAMPLE 1
```
Get-NetboxDeviceType -Model "Cisco Catalyst 2960"
Retrives DeviceType for Cisco Catalyst 2960 from NetBox
```

## PARAMETERS

### -Model
Model of the device type

```yaml
Type: String
Parameter Sets: ByModel
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Manufacturer
Manufacturer of the device type

```yaml
Type: String
Parameter Sets: ByManufacturer
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Id
ID of the device type

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

### -Query
{{ Fill Query Description }}

```yaml
Type: String
Parameter Sets: Query
Aliases:

Required: True
Position: Named
Default value: None
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
