@{
    # Rules to exclude — these target public PowerShell modules, not CLI dotfiles scripts.
    ExcludeRules = @(
        # Internal helper functions use descriptive verbs (Assert-, Ensure-, Backup-, Sync-)
        # that are not in the approved verb list but are clearer for this codebase.
        'PSUseApprovedVerbs',

        # CLI scripts use Write-Host for colored terminal output intentionally.
        'PSAvoidUsingWriteHost',

        # Internal helpers are not public cmdlets; SupportsShouldProcess adds no value here.
        'PSUseShouldProcessForStateChangingFunctions'
    )
}
