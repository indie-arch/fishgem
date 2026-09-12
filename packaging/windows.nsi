Unicode true
!include "MUI2.nsh"
!include "x64.nsh"
Name "FishGem"
OutFile "${OUTPUT}"
InstallDir "$LOCALAPPDATA\Programs\FishGem"
RequestExecutionLevel user
SetCompressor /SOLID lzma
!define MUI_ABORTWARNING
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

Function .onInit
  ${IfNot} ${RunningX64}
    MessageBox MB_OK|MB_ICONSTOP "FishGem requires 64-bit Windows."
    Abort
  ${EndIf}
FunctionEnd

Section "FishGem"
  SetShellVarContext current
  SetOutPath "$INSTDIR"
  File /r "${SOURCE}/*"
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  CreateDirectory "$SMPROGRAMS\FishGem"
  CreateShortcut "$SMPROGRAMS\FishGem\FishGem.lnk" "$INSTDIR\FishGem.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\FishGem" "DisplayName" "FishGem"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\FishGem" "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\FishGem" "UninstallString" '$\"$INSTDIR\Uninstall.exe$\"'
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\FishGem" "DisplayIcon" "$INSTDIR\FishGem.exe"
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\FishGem" "NoModify" 1
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\FishGem" "NoRepair" 1
SectionEnd

Section "Uninstall"
  SetShellVarContext current
  Delete "$SMPROGRAMS\FishGem\FishGem.lnk"
  RMDir "$SMPROGRAMS\FishGem"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\FishGem"
  ; Delete only installed files; saves and user-added files are preserved.
  Delete "$INSTDIR\FishGem.exe"
  Delete "$INSTDIR\README.md"
  Delete "$INSTDIR\licenses\kenney-rpg-base.txt"
  Delete "$INSTDIR\licenses\kenney-fish-pack.txt"
  Delete "$INSTDIR\licenses\godot.txt"
  RMDir "$INSTDIR\licenses"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir "$INSTDIR"
SectionEnd
