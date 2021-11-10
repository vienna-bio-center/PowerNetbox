---
external help file: PowerNetBox-help.xml
Module Name: PowerNetBox
online version:
schema: 2.0.0
---

# New-NetBoxRack

## SYNOPSIS
Creates a new rack in NetBox

## SYNTAX

```
New-NetBoxRack [-Name] <String> [[-Slug] <String>] [-Site] <Object> [[-Location] <Object>] [[-Status] <String>]
 [[-Type] <String>] [[-Width] <Int32>] [[-Height] <Int32>] [[-CustomFields] <String>] [[-Description] <String>]
 [[-Confirm] <Boolean>] [<CommonParameters>]
```

## DESCRIPTION
Long description

## EXAMPLES

### EXAMPLE 1
```
New-NetBoxRack -Name "T-12" -Location "High density" -Site VBC
Creates rack "T-12" in location "High Density" in site VBC
```

## PARAMETERS

### -Name
Name of the rack

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Slug
Slug of the rack, if not specified, it will be generated from the name

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Site
Site of the rack

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Location
Location of the rack

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Status
Status of the rack, Defaults to Active

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: Active
Accept pipeline input: False
Accept wildcard characters: False
```

### -Type
{{ Fill Type Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: 4-post-frame
Accept pipeline input: False
Accept wildcard characters: False
```

### -Width
Width of the rack in inch, default is 19

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: 19
Accept pipeline input: False
Accept wildcard characters: False
```

### -Height
Height of the rack in U(Units), default is 42

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: 42
Accept pipeline input: False
Accept wildcard characters: False
```

### -CustomFields
Custom fields of the rack

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
Description of the rack

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Confirm the creation of the rack

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 11
Default value: True
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
