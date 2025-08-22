if (Test-Path lib\search) { Remove-Item lib\search -Recurse -Force }
if (Test-Path lib\seller) { Remove-Item lib\seller -Recurse -Force }
if (Test-Path lib\data\product.dart) { Remove-Item lib\data\product.dart -Force }
Write-Host "Cleanup done."
