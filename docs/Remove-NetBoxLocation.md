---
external help file: PowerNetBox-help.xml
Module Name: PowerNetBox
online version:
schema: 2.0.0
---

# Remove-NetBoxLocation

## SYNOPSIS
Deletes a location in NetBox

## SYNTAX

### ByName (Default)
```
Remove-NetBoxLocation -Name <String> [-Recurse] [-Confirm <Boolean>] [<CommonParameters>]
```

### ByInputObject
```
Remove-NetBoxLocation [-Recurse] [-Confirm <Boolean>] [-InputObject <Object>] [<CommonParameters>]
```

## DESCRIPTION
Long description

## EXAMPLES

### EXAMPLE 1
```
Remove-NetBoxLocation -Name "High Density"
Deletes the location High Density
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

### -Recurse
Deletes all related objects as well

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Confirm the creation of the location

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -InputObject
Location object to delete

```yaml
Type: Object
Parameter Sets: ByInputObject
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### NetBox.Location
## OUTPUTS

### Output (if any)
## NOTES
General notes

## RELATED LINKS
