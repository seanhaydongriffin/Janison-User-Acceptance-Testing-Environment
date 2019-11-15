;!include nsDialogs.nsh
;!include LogicLib.nsh


; example1.nsi
;
; This script is perhaps one of the simplest NSIs you can make. All of the
; optional settings are left to their default settings. The installer simply 
; prompts the user asking them where to install, and drops a copy of example1.nsi
; there. 

XPStyle on
SilentInstall silent

;--------------------------------

; The name of the installer
Name "Janison User Acceptance Testing Environment"

; The file to write
OutFile "Janison User Acceptance Testing Environment portable.exe"

; The default installation directory
InstallDir "C:\Janison User Acceptance Testing Environment"

; Request application privileges for Windows Vista
RequestExecutionLevel user

;--------------------------------


; Pages

;Page directory
;Page instfiles


;--------------------------------


; The stuff to install
Section "" ;No components page, name is not important

  ; Set output path to the installation directory.
  SetOutPath $TEMP
  
  ; Put file there
  File "Janison User Acceptance Testing Environment.exe"
  File "curl.exe"
  File *.dll

  Exec "$TEMP\Janison User Acceptance Testing Environment.exe"

SectionEnd ; end the section
