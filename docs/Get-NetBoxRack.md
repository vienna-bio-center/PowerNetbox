---
external help file: PowerNetBox-help.xml
Module Name: PowerNetBox
online version:
schema: 2.0.0
---

# Get-NetBoxRack

## SYNOPSIS
Retrives a rack from NetBox

## SYNTAX

### Byname (Default)
```
Get-NetBoxRack [<CommonParameters>]
```

### ByName
```
Get-NetBoxRack -Name <String> [<CommonParameters>]
```

### ById
```
Get-NetBoxRack -Id <Int32> [<CommonParameters>]
```

### BySite
```
Get-NetBoxRack -Site <String> [<CommonParameters>]
```

### ByLocation
```
Get-NetBoxRack -Location <String> [<CommonParameters>]
```

### All
```
Get-NetBoxRack [-All] [<CommonParameters>]
```

## DESCRIPTION
Long description

## EXAMPLES

### EXAMPLE 1
```
Get-NetBoxRack -Location "High Density"
Retrives all racks from High Density location
```

## PARAMETERS

### -Name
Name of the rack

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
ID of the rack

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

### -Site
Site of the rack

```yaml
Type: String
Parameter Sets: BySite
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Location
Location of the rack

```yaml
Type: String
Parameter Sets: ByLocation
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -All
Returns all racks

```yaml
Type: SwitchParameter
Parameter Sets: All
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
