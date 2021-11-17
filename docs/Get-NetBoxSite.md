---
external help file: PowerNetBox-help.xml
Module Name: PowerNetBox
online version:
schema: 2.0.0
---

# Get-NetBoxSite

## SYNOPSIS
Retrieves a site from NetBox

## SYNTAX

### All (Default)
```
Get-NetBoxSite [-All] [<CommonParameters>]
```

### ByName
```
Get-NetBoxSite -Name <String> [<CommonParameters>]
```

### ById
```
Get-NetBoxSite -Id <Int32> [<CommonParameters>]
```

### BySlug
```
Get-NetBoxSite -Slug <String> [<CommonParameters>]
```

## DESCRIPTION
Long description

## EXAMPLES

### EXAMPLE 1
```
Get-NetBoxSite -Name VBC
Returns the Netbox site VBC
```

## PARAMETERS

### -Name
Search for a site by name

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
Search for a site by ID

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
Search for a site by slug

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
Returns all sites

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

### NetBox.Site
## NOTES
General notes

## RELATED LINKS
