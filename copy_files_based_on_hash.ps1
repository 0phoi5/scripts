<#
    .DESCRIPTION
    This script is useful for copying the images and videos from one directory to another,
    recursively, so that only those pictures and videos that don't already exist in the destination
    are copied over. A bit like rsync, but using file's hashes.
    Very useful for sorting lots of drives with loads of old family photos and videos!
#>

$to_be_sorted = "D:\images"
$destination = "C:\images"

Write-Host "Scanning existing files in $destination and computing hashes..." -ForegroundColor Cyan
$existingHashes = @{}
$existingNames = @{}
Get-ChildItem -Path $destination -Recurse -Include *.jpg,*.jpeg,*.png,*.gif,*.bmp,*.tif,*.tiff,*.mp4,*.avi,*.mov,*.wmv,*.mkv -File -ErrorAction SilentlyContinue |
ForEach-Object {
    $hash = Get-FileHash -Path $_.FullName -Algorithm SHA256
    $existingHashes[$hash.Hash] = $true
    $existingNames[$_.Name.ToLower()] = $_.FullName
    Write-Host "Indexed: $($_.FullName)" -ForegroundColor DarkGray
}

Write-Host "Searching $to_be_sorted recursively for media files..." -ForegroundColor Cyan
Get-ChildItem -Path $to_be_sorted -Recurse -Include *.jpg,*.jpeg,*.png,*.gif,*.bmp,*.tif,*.tiff,*.mp4,*.avi,*.mov,*.wmv,*.mkv -File -ErrorAction SilentlyContinue |
ForEach-Object {
    Write-Host "Checking: $($_.FullName)" -ForegroundColor Yellow
    $hash = Get-FileHash -Path $_.FullName -Algorithm SHA256

    if (-not $existingHashes.ContainsKey($hash.Hash)) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
        $ext = [System.IO.Path]::GetExtension($_.Name)
        $destName = $_.Name
        $counter = 1

        while (Test-Path -Path (Join-Path -Path $to_be_sorted -ChildPath $destName)) {
            $existingPath = Join-Path -Path $to_be_sorted -ChildPath $destName
            $existingHash = Get-FileHash -Path $existingPath -Algorithm SHA256

            if ($existingHash.Hash -eq $hash.Hash) {
                Write-Host "Duplicate found (same hash): Skipping $($_.FullName)" -ForegroundColor Gray
                return
            }

            $destName = "$baseName$counter$ext"
            $counter++
        }

        $finalPath = Join-Path -Path $to_be_sorted -ChildPath $destName
        Write-Host "Copying: $($_.FullName) -> $finalPath" -ForegroundColor Green
        Copy-Item -Path $_.FullName -Destination $finalPath
        $existingHashes[$hash.Hash] = $true
    } else {
        Write-Host "Duplicate found (same hash): Skipping $($_.FullName)" -ForegroundColor Gray
    }
}
