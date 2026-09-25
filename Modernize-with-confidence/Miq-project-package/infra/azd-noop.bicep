// The complete fallback-aware infrastructure deployment is intentionally run by
// the preprovision azd hook. This no-op subscription deployment lets azd complete
// its standard provision phase without creating a second resource group.
targetScope = 'subscription'

output managedBy string = 'deploy.ps1 via azd preprovision hook'
