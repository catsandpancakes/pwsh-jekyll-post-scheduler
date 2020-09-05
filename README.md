# Jekyll Post Scheduler (PowerShell)

## Introduction

This is a script that schedules posts for your Jekyll GitHub repository using PowerShell and the Windows Task Scheduler. 

Do note that this was written and tested on **PowerShell Core 7** and **Windows 10 Version 2004 (build 19041.450)**, so it may not work as expected on other PowerShell versions or other Windows OS builds. 

## Prerequisites

1. Windows 10
2. [Git](https://git-scm.com/) 
3. PowerShell 5.1 or higher
4. Git-scm must be added to `$PATH`.
5. It **should** theoretically run on PowerShell 5.1 but **it is not tested**.

## Some Manual Changes Required

The following front matter is **required** in your post for the script to work as expected: 

```
---
title: PostTitleHere
date: yyyy-MM-dd HH:mm
---
```

**NOTE1:** If your resources/images directory **does not contain a subdirectory for each post**, comment lines **39 and 40**, and uncomment lines **43 and 44**.

**NOTE2:** If your resources/images directory **is not named images**, please change it on either lines **39 and 40** or lines **43 and 44**. If your resources/images **are not .png files**, please change them on the same lines as well. See the following code block for an example of what needs to be changed: 

```
39 $imageFullPath = Get-Content $post | Select-String -NoEmphasis -Raw "(!\[.*.EXTENSION\]\(\/RESOURCEDIR\/.*\/)" | Select-Object -First 1
40 $imagePath = ($imageFullPath -split "(RESOURCEDIR\/.*\/)")[1]

43 $imageFullPath = Get-Content $post | Select-String -NoEmphasis -Raw "(!\[.*.EXTENSION\]\(\/RESOURCEDIR\/)" | Select-Object -First 1
44 $imagePath = ($imageFullPath -split "(RESOURCEDIR\/)")[1]
```

## How to Use

Download the JekyllSchedulePost.psm1 file and make the necessary changes as listed above. Put the script into your `pwsh-install-dir\Modules` folder. To use the functions within the module, you will need to use `Import-Module JekyllSchedulePost` to import it into your PowerShell session. If you want it to be automatically imported every time you start PowerShell, you will need to create a new PowerShell profile or edit your existing one with the `Import-Module` cmdlet.

Once the module is imported, run `JekyllSchedulePost` in your terminal where your Git repository is located. 

## Known Issues

All versions of PowerShell, when run with the `-WindowStyle Hidden` switch will briefly flash the PowerShell console window. This may cause some minor disruption to full screen applications. This cannot be fixed as of now. Even if the scheduled task calls `git.exe` directly, it will also briefly flash the CMD console window.

There is an [issue on the PowerShell GitHub repository](https://github.com/PowerShell/PowerShell/issues/3028) that has been open since January 2017. A future version may fix this issue, and that future version may be coming quite soon if the issue thread is to be believed. 

There is a way to do this with a very dirty workaround by creating VBScripts to execute each `git.exe` command. Each VBScript will in turn be executed by WScript in the Task Scheduler. VBScripts will need to be stored somewhere until the task is executed, and automatically removing said VBScripts would also cause a console window to briefly flash unless that is also done with WScript and yet another VBScript... which feels like a really dirty way of doing things.

## Contact

Please open an issue, or [email me](mailto:ricepancakes@protonmail.com). 
