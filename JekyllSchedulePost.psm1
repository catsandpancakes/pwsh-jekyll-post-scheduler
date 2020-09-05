#############################################
# Author: ricepancakes                      #
# GitHub: github.com/catsandpancakes        #
# Contact: ricepancakes@protonmail.com      #
#                                           #
# Licensed under the MIT license.           #
#############################################

function JekyllSchedulePost(){
    $global:error.Clear()

    #Clean old scheduled posts.
    Write-Host "Cleaning up old scheduled tasks...`n"
    JekyllCleanScheduledPost

    $currentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm"
    $status = & git status 2>&1 | Out-String
    $gitDir = Get-Location

    if($status -match "fatal: not a git repository"){
        Write-Host "Please run this script in a valid Git repository.`n" -BackgroundColor Red -ForegroundColor White
    }
    else{
        if($status -match "Untracked files" -and "_posts"){
            Write-Host "Scheduling commit...`n"

            $posts = $status | findstr -i "_posts"

            foreach($post in $posts){
                try{
                    # Get post datetime to compare with current datetime.
                    $post = $post.Trim()
                    $date = Get-Content $post | Select-String -NoEmphasis -Raw "date: " | Select-Object -First 1
                    $postDate = $date.Substring(6,19) | Get-Date -Format "yyyy-MM-dd HH:mm" -ErrorAction Stop

                    # Get image path from post content.
                    # Change images to something else if your resource directory is not under /images/
                    # Comment the following section if images do not have a subdirectory. 
                    $imageFullPath = Get-Content $post | Select-String -NoEmphasis -Raw "(!\[.*.png\]\(\/images\/.*\/)" | Select-Object -First 1
                    $imagePath = ($imageFullPath -split "(images\/.*\/)")[1]

                    # Uncomment the following section if images do not have a subdirectory.
                    #$imageFullPath = Get-Content $post | Select-String -NoEmphasis -Raw "(!\[.*.png\]\(\/images\/)" | Select-Object -First 1
                    #$imagePath = ($imageFullPath -split "(images\/)")[1]

                    # Get post title from post content.
                    $postFullTitle = Get-Content $post | Select-String -NoEmphasis -Raw "title: " | Select-Object -First 1
                    $postTitle = ($postFullTitle -split "(title\: )")[2]

                    if($postDate -gt $currentDateTime){
                        if($imagePath -ne $null){
                            Write-Host "Scheduling $post and $imagePath...`n"
                        }
                        else{
                            Write-Host "Scheduling $post...`n"
                        }

                        # Change all forward slashes to backslashes for scheduled task. 
                        $post = $post -replace "/", "\"
                        $imagePath = $imagePath -replace "/", "\"

                        # Create scheduled task - git add, git commit, git push
                        $gitActions = @()
                        $gitActions += New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-windowstyle hidden -noni -nop -command & git -C $gitDir add $gitDir\$post"
                        if($imagePath -ne ""){
                            $gitActions += New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-windowstyle hidden -noni -nop -command & git -C $gitDir add $gitDir\$imagePath"
                        }
                        $gitActions += New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-windowstyle hidden -noni -nop -command & git -C $gitDir commit -m 'updated $postTitle'"
                        $gitActions += New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-windowstyle hidden -noni -nop -command & git -C $gitDir push"
                        
                        # Define trigger at post date
                        $schedTrigger = New-ScheduledTaskTrigger -Once -At $postDate
                        
                        # Define general settings
                        $schedSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -WakeToRun -Compatibility Win8 -StartWhenAvailable

                        try{
                            Register-ScheduledTask -Action $gitActions -Trigger $schedTrigger -TaskName "JekyllScheduledPost_$postTitle" -Settings $schedSettings -ErrorAction Stop > $null
                            Write-Host "Commit successfully scheduled as JekyllScheduledPost_$postTitle on $postDate." -BackgroundColor Green -ForegroundColor Black
                        }catch{
                            if($global:error -match "Cannot create a file when that file already exists."){
                                Write-Host "$postTitle already scheduled for commit. Skipping.`n" -BackgroundColor Yellow -ForegroundColor Black
                            }
                            else{
                                Write-Host "Commit schedule unsuccessful.`nSee the following error message for more details:`n" -BackgroundColor Red -ForegroundColor White
                                Write-Host "Error: $global:error" -BackgroundColor Red -ForegroundColor White
                            }
                        }
                    }
                    elseif($postDate -le $currentDateTime){
                        # Don't schedule posts if date is less than current datetime. 
                        Write-Host "Post is older than current date. No scheduled job will be created." -BackgroundColor Yellow -ForegroundColor Black
                        Write-Host "Please manually commit $post and $imagePath.`n" -BackgroundColor Yellow -ForegroundColor Black
                    }
                }catch{
                    if($global:error -match "was not recognized as a valid DateTime"){
                        Write-Host "Invalid date. Skipping $post."
                    }
                    else{
                        Write-Host "Unspecified error. Skipping $post.`nSee the following error message for more details:`n" -BackgroundColor Red -ForegroundColor White
                        Write-Host "Error: $global:error" -BackgroundColor Red -ForegroundColor White
                    }
                }
            }
        }
        else{
            Write-Host "No pending posts to schedule.`n" -BackgroundColor Yellow -ForegroundColor Black
        }
    }
}

function JekyllCleanScheduledPost(){
    $tasks = Get-ScheduledTask | Where-Object TaskName -Match "JekyllScheduledPost" | Get-ScheduledTaskInfo | Select-Object TaskName, NextRunTime

    foreach($task in $tasks){
        try{
            if($task.NextRunTime -eq $null){
                Write-Host "$($task.TaskName) has expired. Deleting..." -BackgroundColor Yellow -ForegroundColor Black
                Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$false -ErrorAction Stop
                Write-Host "$($task.TaskName) deleted.`n" -BackgroundColor Green -ForegroundColor Black
            }
        }catch{
            Write-Host "Unspecified error. See the following error message for more details:`n" -BackgroundColor Red -ForegroundColor White
            Write-Host "Error: $global:error`n" -BackgroundColor Red -ForegroundColor White
        }
    }
}
