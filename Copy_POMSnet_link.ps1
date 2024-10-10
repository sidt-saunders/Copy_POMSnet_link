#This script will copy the POMSnet.lnk to Public Desktop on requested devices
#Author: Sidt Saunders

#----------
#Variables
#----------

$hostname = hostname
$FailCounter = $NumOfDevices = $DeviceCounter = 0
$DeviceCounter = 1
$DeviceType = $DeviceSuffix = $FourLetterPrefix = $DeviceName = $FullNameOfDevice = ""

#----------
#Functions
#----------

#Create log file to store errors
New-Item -Path \\$hostname\C$\Users\$Env:UserName\Desktop\POMSnet_logfile.txt

Function DeviceCount() {
    #Prompt for number of devices
    $NumOfDevices = Read-Host "`nPlease enter the number of devices "
    If ($NumOfDevices -notmatch "[0-9]") {NotValidDeviceCount}
    Else {DevicePrefix}
}

Function NotValidDeviceCount() {
    While ($FailCounter -ne 2) {
        Write-Host ""
        Write-Warning "Use numbers only. "
        $FailCounter++
        DeviceCount
    }
    Write-Host ""
    Write-Error "Too many failed attempts.`nScript will exit in 5 seconds.`n"
    Start-Sleep -Seconds 5
    $FailCounter = 0
    Exit
}

Function DevicePrefix() {
    #Prompt for 4 letter prefix
    $FourLetterPrefix = Read-Host "`nPlease enter the 4 letter prefix (USAL, USHO, USGR, etc) "
    
    #Confirm entered info are letters and only 4 characters long
    If ($FourLetterPrefix.Length -lt 4) {NotValidPrefixLengthShort}
    If ($FourLetterPrefix.Length -gt 4) {NotValidPrefixLengthLong}
    If ($FourLetterPrefix -notmatch "[a-zA-Z]") {NotValidPrefixType}
    Else {LaptopOrDesktop}
}

Function NotValidPrefixType() {
    While ($FailCounter -ne 2) {
        Write-Host ""
        Write-Warning "Use letters from A to Z only. "
        $FailCounter++
        DevicePrefix
    }
    Write-Host ""
    Write-Error "Too many failed attempts.`nScript will exit in 5 seconds.`n"
    Start-Sleep -Seconds 5
    $FailCounter = 0
    Exit
}

Function NotValidPrefixLengthShort() {
    While ($FailCounter -ne 2) {
        Write-Host ""
        Write-Warning "`nToo few characters. "
        $FailCounter++
        DevicePrefix
    }
    Write-Host ""
    Write-Error "Too many failed attempts.`nScript will exit in 5 seconds.`n"
    Start-Sleep -Seconds 5
    $FailCounter = 0
    Exit
}

Function NotValidPrefixLengthLong() {
    While ($FailCounter -ne 2) {
        Write-Host ""
        Write-Warning "`nToo many characters. "
        $FailCounter++
        DevicePrefix
    }
    Write-Host ""
    Write-Error "Too many failed attempts.`nScript will exit in 5 seconds.`n"
    Start-Sleep -Seconds 5
    $FailCounter = 0
    Exit
}

Function LaptopOrDesktop() {
    #Ask if devices are Laptops or Desktops
    #Eventually, I will add a combination feature
    $DeviceType = Read-Host "`nPlease input type of device (L for Laptop, D for Desktop) "
        Switch ($DeviceType) {
        L {[String]$DeviceSuffix = "L"}
        D {[String]$DeviceSuffix = "D"}

        Default {NotValidDeviceType}
    }
    DeviceAssetTagsPrompt
}

Function NotValidDeviceType() {
    While ($FailCounter -ne 2) {
        Write-Host ""
        Write-Warning "That is not a valid device type. "
        $FailCounter++
        LaptopOrDesktop
    }
    Write-Host ""
    Write-Error "Too many failed attempts.`nScript will exit in 5 seconds.`n"
    Start-Sleep -Seconds 5
    $FailCounter = 0
    Exit
}

Function DeviceAssetTagsPrompt() {
    #Prompt about entering asset tags
    Write-Host "`nPlease input the asset tags. Please press Enter after each tag."
    Write-Host "NOTE: The link will be copied as soon as Enter is pressed.`n"
    DeviceAssetTags
}

Function DeviceAssetTags() {
    #Ask for the asset tags
    While ($DeviceCounter -le $NumOfDevices) {
        $DeviceName = Read-Host "$DeviceCounter "
        #Create full computer name
        $FullNameOfDevice = $FourLetterPrefix.ToUpper() + $DeviceName + $DeviceSuffix.ToUpper()
        #Check if device pings
        $PingTest = Test-Connection -ComputerName $FullNameOfDevice -Quiet -Count 1 -ErrorAction SilentlyContinue
        If ($PingTest) {
            $DeviceCounter++
            CopyLinkToDevice
        }
        Else {
            Write-Warning "$FullNameOfDevice did not ping. Please see log file."
            Add-Content -Path \\$hostname\C$\Users\$Env:UserName\Desktop\POMSnet_logfile.txt -Value "$FullNameOfDevice - did not ping."
            $DeviceCounter++
            DeviceAssetTags
        }
    }
    ScriptFinished
}

Function CopyLinkToDevice() {
    #Check for location of Public Desktop
    $PublicDesktopLocation = [Environment]::GetFolderPath('CommonDesktopDirectory')
    $PDLForNetwork = $PublicDesktopLocation.Substring(3)
    #Copy the link to the device
    $Source = "\\USALPLATP01\DropBox\Sidt_Saunders\Scripts\Script_Files\Copy_POMSnet_link\POMSnet.lnk"
    $Destination = "\\$FullNameOfDevice\C$\$PDLForNetwork"
    Copy-Item -Path $Source -Destination $Destination
    ConfirmCopy
}

Function ConfirmCopy() {
    #Confirm that link has been copied
    [String]$ConfirmFileExists = Test-Path -Path $Destination\POMSnet.lnk
    If ($ConfirmFileExists -eq $False) {
        Write-Host ""
        Write-Warning "File failed to copy. Please see log file."
        Add-Content -Path \\$hostname\C$\Users\$Env:UserName\Desktop\POMSnet_logfile.txt -Value "$FullNameOfDevice - failed to copy POMSNet shortcut"
        DeviceAssetTags
    }
    Else {
        DeviceAssetTags
    }
}

Function ScriptFinished() {
    Write-Host "`nScript has finished running.`n" -ForegroundColor DarkGreen
    ConfirmLogFileNotEmptyAndView
}

Function ConfirmLogFileNotEmptyAndView() {
    [String]$IsLogEmpty = [String]::IsNullOrEmpty((Get-Content \\$hostname\C$\Users\$Env:UserName\Desktop\POMSnet_logfile.txt))
    If ($IsLogEmpty -eq $False) {
        Write-Host "`nWould you like to view the log file? (Y/N)"
        Write-Host "NOTE: Selecting No will delete the file. : " -NoNewline
        $LogFileView = Read-Host
        Switch ($LogFileView) {
            Y {
                & C:\Windows\System32\notepad.exe \\$hostname\C$\Users\$Env:UserName\Desktop\POMSnet_logfile.txt
                Pause
             EndOfScript
            
            }
            N {
                Remove-Item -Path \\$hostname\C$\Users\$Env:UserName\Desktop\POMSnet_logfile.txt -Force
             EndOfScript
            
            }

            Default {NotValidViewLog}
        }
    }
    Else {
     EndOfScript
    
    }
}

Function NotValidViewLog() {
    While ($FailCounter -ne 2) {
        Write-Host ""
        Write-Warning "Invalid entry. "
        $FailCounter++
        ConfirmLogFileNotEmptyAndView
    }
    Write-Host ""
    Write-Error "Too many failed attempts.`nScript will exist in 5 seconds."
    Start-Sleep -Seconds 5
    $FailCounter = 0
    Exit
}

Function EndOfScript() {
    Write-Host "`n`nThank you for using this script.`n" -BackgroundColor Black -ForegroundColor White
    Pause
    Exit
}

#----------
#Script
#----------

Clear-Host
Write-Host "`nThis script will copy the POMSNet link to the Public Desktop." -BackgroundColor Black -ForegroundColor White
Write-Host "`nPress CTRL + C at any time to quit the script.`n"
Write-Host "------------------------------"
Start-Sleep -Seconds 2
DeviceCount