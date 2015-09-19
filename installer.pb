IncludeFile "lib/reg.pbi"

#myName = "iSnotify"

Procedure runLock()
  Protected app.i
  app = CreateSemaphore_(0,0,1,@"solinst")
  If app <> 0 And GetLastError_() = #ERROR_ALREADY_EXISTS
    CloseHandle_(app)
    ProcedureReturn #False
  EndIf
  ProcedureReturn #True
EndProcedure

If Not runLock()
  MessageBox_(0,"Другой экземпляр программы установки уже запущен.",#myName,#MB_OK|#MB_ICONERROR)
  End
EndIf

myDir.s = GetEnvironmentVariable("APPDATA")
If FileSize(myDir) <> -2
  MessageBox_(0,"Не найден %APPDATA%",#myName,#MB_OK|#MB_ICONERROR)
  End 1
EndIf

myDir + "\iSnotify"
If FileSize(myDir) <> -2
  If Not CreateDirectory(myDir)
    MessageBox_(0,"Невозможно создать директорию '" + myDir + "'",#myName,#MB_OK|#MB_ICONERROR)
    End 2
  EndIf
EndIf

UseModule Registry
DeleteValue(#HKEY_CURRENT_USER,"\Software\Microsoft\Windows\CurrentVersion\Run","iSnotify")
If Not WriteValue(#HKEY_CURRENT_USER,"\Software\Microsoft\Windows\CurrentVersion\Run","iSnotify",myDir + "\isn.exe",#REG_SZ)
  MessageBox_(0,"Не удалось добавить " + #myName + " в автозагрузку.",#myName,#MB_OK|#MB_ICONERROR)
  End 5
EndIf

SetCurrentDirectory(myDir)
If InitNetwork() And ReceiveHTTPFile("http://home-nadym.ru/isn/isn_upd.exe","isn_upd.exe")
  updater.i = RunProgram(myDir + "\isn_upd.exe","release",myDir,#PB_Program_Open)
  While ProgramRunning(updater)
    Delay(100)
  Wend
  If ProgramExitCode(updater) = 0
    CloseProgram(updater)
    End 0
  Else
    End 4
  EndIf
Else
  MessageBox_(0,"Не удалось загрузить дистрибутив.",#myName,#MB_OK|#MB_ICONERROR)
  End 3
EndIf
; IDE Options = PureBasic 5.40 LTS Beta 4 (Windows - x86)
; EnableUnicode
; EnableXP
; EnableBuildCount = 0