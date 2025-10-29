param(
  [Parameter(Mandatory = $true)]
  [string]$Bucket,

  # optional
  [string]$Profile,
  [string]$Region,
  [string]$Prefix
)

# Führt die AWS CLI mit korrekt gesplatteten Argumenten aus
function Invoke-Aws {
  param([string[]]$Cmd)

  if (-not $Cmd -or $Cmd.Count -eq 0) {
    throw "Internal: empty AWS command array."
  }

  $all = @()
  if ($Profile) { $all += @("--profile", $Profile) }
  if ($Region)  { $all += @("--region",  $Region)  }
  $all += $Cmd

  # Call-Operator für korrektes Splatting:
  $output = & aws @all
  $exit   = $LASTEXITCODE
  if ($exit -ne 0) {
    throw "AWS CLI command failed ($exit): aws $($all -join ' ')"
  }
  return $output
}

Write-Host "Tagging objects in s3://$Bucket/$Prefix with Tag public=true ..." -ForegroundColor Cyan

$token = $null
do {
  $cmd = @("s3api","list-objects-v2","--bucket",$Bucket)
  if ($Prefix) { $cmd += @("--prefix",$Prefix) }
  if ($token)  { $cmd += @("--continuation-token",$token) }

  $raw = Invoke-Aws -Cmd $cmd
  if (-not $raw) {
    Write-Host "Keine Objekte gefunden." -ForegroundColor Yellow
    break
  }

  $json = $raw | ConvertFrom-Json
  if ($null -eq $json.Contents -or $json.Contents.Count -eq 0) {
    Write-Host "Keine Objekte gefunden." -ForegroundColor Yellow
    break
  }

  foreach ($obj in $json.Contents) {
    $key = $obj.Key
    # Achtung: überschreibt vorhandene Tags.
    Invoke-Aws -Cmd @(
      "s3api","put-object-tagging",
      "--bucket",$Bucket,
      "--key",$key,
      "--tagging","TagSet=[{Key=public,Value=true}]"
    ) | Out-Null
    Write-Host "Tagged: $key"
  }

  $token = $json.NextContinuationToken
} while ($token)

Write-Host "Fertig." -ForegroundColor Green
