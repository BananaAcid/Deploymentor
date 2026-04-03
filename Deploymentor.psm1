<#
.SYNOPSIS
    Deploymentor
    
.DESCRIPTION
    Copyright (c) 2026 Nabil Redmann
    Licensed under the MIT License.
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files.
#>

# This is the Root Module that loads all components

function Start-Deploymentor {
    . $PSScriptRoot\deploymentor.ps1 @args
}

Export-ModuleMember -Function *