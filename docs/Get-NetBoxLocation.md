---
external help file: PowerNetBox-help.xml
Module Name: PowerNetBox
online version:
schema: 2.0.0
---

# Get-NetBoxLocation

## SYNOPSIS
Retrieves a location in NetBox

## SYNTAX

### Byname (Default)
```
Get-NetBoxLocation [<CommonParameters>]
```

### ByName
```
Get-NetBoxLocation -Name <String> [<CommonParameters>]
```

### ById
```
Get-NetBoxLocation -Id <Int32> [<CommonParameters>]
```

### BySlug
```
Get-NetBoxLocation -Slug <String> [<CommonParameters>]
```

### All
```
Get-NetBoxLocation [-All] [<CommonParameters>]
```

## DESCRIPTION
Long description

## EXAMPLES

### EXAMPLE 1
```
Get-NetBoxLocation -Name "Low Density"
Retrieves the location Low Density
```

## PARAMETERS

### -Name
Name of the location

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
ID of the location

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

### -Slug
Search for a location by slug

```yaml
Type: String
Parameter Sets: BySlug
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -All
Returns all locations

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

### NetBox.Location
## NOTES
General notes

## RELATED LINKS
