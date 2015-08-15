#myName = "iSN updater"
#root = "http://home-nadym.ru/isn/"
Define myDir.s = GetPathPart(ProgramFilename())
Define myAppName.s = GetFilePart(ProgramFilename())

If Not CountProgramParameters()
  MessageBox_(0,"syntax: " + myAppName + " version",#myName,#MB_OK|#MB_ICONINFORMATION)
  End 1
Else
  Define dataURL.s = #root + ProgramParameter(0) + ".dat"
  Define changesURL.s = #root + ProgramParameter(0) + ".txt"
EndIf

OpenWindow(0,#PB_Ignore,#PB_Ignore,100,20,#myName,#PB_Window_ScreenCentered|#PB_Window_BorderLess)
StickyWindow(0,#True)
TrackBarGadget(0,0,0,100,20,0,100)

WindowEvent()
Delay(1000)
WindowEvent()
; IDE Options = PureBasic 5.31 (Windows - x86)
; EnableUnicode
; EnableXP
; EnableBuildCount = 0