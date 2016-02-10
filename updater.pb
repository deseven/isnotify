UseZipPacker()

#myName = "iSnotify"
#root = "http://home-nadym.ru/isn/"

Enumeration events #PB_Event_FirstCustomValue
  #errorClean
  #cleaned
  #errorStart
  #started
  #errorDown
  #downloaded
  #errorUnp
  #errorUnpLock
  #unpacked
  #finished
EndEnumeration

Define myDir.s = GetPathPart(ProgramFilename())
Define myAppName.s = GetFilePart(ProgramFilename())
Define dataURL.s,changesURL.s,changes.s

Procedure runLock()
  Protected app.i
  app = CreateSemaphore_(0,0,1,@"solupd")
  If app <> 0 And GetLastError_() = #ERROR_ALREADY_EXISTS
    CloseHandle_(app)
    ProcedureReturn #False
  EndIf
  ProcedureReturn #True
EndProcedure

Procedure doUpdate(n.i)
  Shared dataURL.s,changesURL.s,changes.s,myDir.s
  Protected f.s
  If ExamineDirectory(0,myDir,"*.*")
    While NextDirectoryEntry(0)
      If DirectoryEntryType(0) = #PB_DirectoryEntry_File
        f = LCase(DirectoryEntryName(0))
        If Right(f,4) = ".dat" Or Right(f,4) = ".old" 
          DeleteFile(DirectoryEntryName(0),#PB_FileSystem_Force)
        EndIf
        Select f
          Case "isn_install.exe","isn_dbg.exe","libcurl.dll","libeay32.dll","libidn-11.dll","librtmp.dll","libssh2.dll","ssleay32.dll","zlib1.dll"
            DeleteFile(DirectoryEntryName(0),#PB_FileSystem_Force)
        EndSelect
      EndIf
    Wend
    FinishDirectory(0)
  Else
    PostEvent(#errorClean)
  EndIf
  If InitNetwork() : PostEvent(#started) : Else : PostEvent(#errorStart) : ProcedureReturn : EndIf
  If ReceiveHTTPFile(dataURL,"distr.dat") : PostEvent(#downloaded) : Else : PostEvent(#errorDown) : ProcedureReturn : EndIf
  If OpenPack(0,"distr.dat")
    If ExaminePack(0)
      While NextPackEntry(0)
        If FileSize(PackEntryName(0)) >= 0
          If Not DeleteFile(PackEntryName(0),#PB_FileSystem_Force)
            If Not RenameFile(PackEntryName(0),PackEntryName(0) + ".old")
              ClosePack(0)
              DeleteFile("distr.dat",#PB_FileSystem_Force)
              PostEvent(#errorUnpLock)
              ProcedureReturn
            EndIf
          EndIf
        EndIf
        If Not UncompressPackFile(0,PackEntryName(0))
          ClosePack(0)
          DeleteFile("distr.dat",#PB_FileSystem_Force)
          PostEvent(#errorUnp)
          ProcedureReturn
        EndIf
      Wend
    Else
      ClosePack(0)
      DeleteFile("distr.dat",#PB_FileSystem_Force)
      PostEvent(#errorUnp)
      ProcedureReturn
    EndIf
  Else
    DeleteFile("distr.dat",#PB_FileSystem_Force)
    PostEvent(#errorUnp)
    ProcedureReturn
  EndIf
  ClosePack(0)
  DeleteFile("distr.dat",#PB_FileSystem_Force)
  PostEvent(#unpacked)
  If ProgramParameter(0) <> "release"
    If ReceiveHTTPFile(changesURL,"changes.txt")
      ReadFile(0,"changes.txt",#PB_File_NoBuffering)
      While Not Eof(0)
        changes + ReadString(0) + #CRLF$
      Wend
      CloseFile(0)
      DeleteFile("changes.txt",#PB_FileSystem_Force)
    EndIf
  EndIf
  PostEvent(#finished)
EndProcedure

SetCurrentDirectory(myDir)

If Not CountProgramParameters()
  MessageBox_(0,"syntax: " + myAppName + " version",#myName,#MB_OK|#MB_ICONINFORMATION)
  End 1
Else
  dataURL = #root + ProgramParameter(0) + ".zip"
  changesURL = #root + ProgramParameter(0) + ".txt"
EndIf

If Not runLock()
  MessageBox_(0,"Другой экземпляр программы автообновления уже запущен.",#myName,#MB_OK|#MB_ICONERROR)
  End
EndIf

OpenWindow(0,#PB_Ignore,#PB_Ignore,200,46,#myName,#PB_Window_ScreenCentered|#PB_Window_BorderLess)
StickyWindow(0,#True)
ProgressBarGadget(0,0,0,200,30,0,100)
TextGadget(1,0,30,200,16,"Очистка...",#PB_Text_Center)
CreateThread(@doUpdate(),0)

wnd = WindowID(0)

Repeat
  ev = WaitWindowEvent()
  Select ev
    Case #cleaned
      SetGadgetState(0,10)
      SetGadgetText(1,"Подготовка...")
    Case #errorClean
      MessageBox_(wnd,"Не удалось провести предварительную очистку. Пожалуйста удостоверьтесь, что директория '" + myDir + "' доступна для записи и начните обновление заново",#myName,#MB_OK|#MB_ICONERROR)
      End 1
    Case #started
      SetGadgetState(0,15)
      SetGadgetText(1,"Скачиваем обновление...")
    Case #errorStart
      MessageBox_(wnd,"Не удалось инцииализировать сеть.",#myName,#MB_OK|#MB_ICONERROR)
      End 2
    Case #downloaded
      SetGadgetState(0,40)
      SetGadgetText(1,"Устанавливаем обновление...")
    Case #errorDown
      MessageBox_(wnd,"Не удалось скачать обновление. Проверьте доступ к интернету или попробуйте еще раз позднее.",#myName,#MB_OK|#MB_ICONERROR)
      End 3
    Case #unpacked
      SetGadgetState(0,90)
      SetGadgetText(1,"Получаем список изменений...")
    Case #errorUnp
      MessageBox_(wnd,"Скачанное обновление повреждено. Проверьте ваш интернет или попробуйте еще раз позднее.",#myName,#MB_OK|#MB_ICONERROR)
      End 4
    Case #errorUnpLock
      MessageBox_(wnd,"Не удалось установить обновление. Пожалуйста удостоверьтесь, что директория '" + myDir + "' доступна для записи и начните обновление заново",#myName,#MB_OK|#MB_ICONERROR)
      End 5
    Case #finished
      SetGadgetState(0,90)
      SetGadgetText(1,"Готово!")
      If Len(changes)
        changes = #CRLF$ + #CRLF$ + "Изменения:" + #CRLF$ + changes
      EndIf
      If ProgramParameter(0) = "release"
        MessageBox_(wnd,#myName + " успешно установлен.",#myName,#MB_OK|#MB_ICONINFORMATION)
      Else
        MessageBox_(wnd,#myName + " успешно обновлен до версии " + ProgramParameter(0) + changes,#myName,#MB_OK|#MB_ICONINFORMATION)
      EndIf
      RunProgram("isn.exe","",myDir)
      End 0
  EndSelect
ForEver

; IDE Options = PureBasic 5.40 LTS Beta 5 (Windows - x86)
; EnableUnicode
; EnableXP
; EnableBuildCount = 0