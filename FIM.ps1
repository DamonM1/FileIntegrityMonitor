

write-Host ""
write-Host "What would you like to do?"
write-Host ""
write-Host "    A) Collect new Baseline?"
write-Host "    B) Begin monitoring files with saved Baseline?"
write-Host ""

$response = Read-Host -Prompt "Please enter 'A' or 'B'"

Function Calculate-File-Hash($filepath) {
    $filehash = Get-FileHash -Path $filepath -Algorithm SHA512
    return $filehash
}

# $hash = Calculate-File-Hash "C:\Users\Usr\Desktop\FMI\Files\a.txt"

Function Erase-Baseline-If-Already-Exists() {
    $baselineExists = Test-Path -Path .\.baseline.txt

    if ($baselineExists) {
        #Delete it 
        Remove-Item -Path .\baseline.txt
    }
}

#If user enters A collect new baseline 
if ($response -eq "A".ToUpper()) {
    # Delete baseline.txt if it already exists
    Erase-Baseline-If-Already-Exists
    # Calculate Hash from the target files and store in baseline.txt
    # Collect all files in the target folder
    $files = Get-ChildItem -Path .\Files

    # For each file, calculate the hash, and write to baseline.txt
    foreach ($f in $files) {
       $hash =  Calculate-File-Hash $f.FullName
       "$($hash.Path)|$($hash.Hash)" | Out-File -FilePath baseline.txt -Append
    }
}
elseif ($response -eq "B".ToUpper()) {
    $fileHashDictionary = @{}
    # Load file|hash from baseline.txt and store them in a dictionary 
    $filePathsAndHashes = Get-Content -Path .\baseline.txt

    foreach ($f in $filePathsAndHashes) {
        $fileHashDictionary.add($f.Split("|")[0],$f.Split("|")[1])
    }

    $fileHashDictionary
    # Beging monitoring files with saved Baseline
    while ($true) {
        Start-Sleep -Seconds 1

        $files = Get-ChildItem -Path .\Files

        # For each file, calculate the hash, and write to baseline.txt
        foreach ($f in $files) {
           $hash =  Calculate-File-Hash $f.FullName
           #"$($hash.Path)|$($hash.Hash)" | Out-File -FilePath baseline.txt -Append

           # Notify if a new file has been created
           if ($fileHashDictionary[$hash.Path] -eq $null) {
                # A new file has been created!
                Write-Host "$($hash.Path) has been created!" -ForegroundColor Green
           }
           else {
               # Notify if a new file has been changed
               if ($fileHashDictionary[$hash.Path] -eq $hash.Hash){
                    # The file has not changed
               }
               else {
                    # File file has been compromised!, notify the user 
                    Write-Host "$($hash.Path) has changed!!!" -ForegroundColor Red
               }
           }
           
          

        }
        foreach ($key in $fileHashDictionary.Keys) {
                $baselineFileStillExists = Test-Path -Path $key
                if (-Not $baselineFileStillExists) {
                    # One of the baseline files must have been deleted, notify the user
                    Write-Host "$($key) has been deleted!" -ForegroundColor DarkRed
                }
           }
    }
}