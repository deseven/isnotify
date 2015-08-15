﻿EnableExplicit
UsePNGImageDecoder()
IncludeFile "../pb-win-notify/wnotify.pbi"
IncludeFile "curl/libcurl-res.pb"
IncludeFile "curl/libcurl-inc.pb"
IncludeFile "const.pb"

EnableExplicit

Define myDir.s = GetPathPart(ProgramFilename())
Define myAppName.s = GetFilePart(ProgramFilename())
Define megaplanState.i = #megaplanTry
Define portalState.i = #portalTry
Define prtgState.i = #prtgTry
Define lastTrayUpdate.i = 0
Define ev.i,n.i
Define enableDebug.b = #False
Define selfUpdate.b = #True
Define notifyTimeout.w = 3000
Define enableMegaplan.b,enablePortal.b,enablePRTG.b
Define megaplanURL.s,megaplanLogin.s,megaplanPass.s,megaplanTime.w,megaplanPos.b
Define portalURL.s,portalLogin.s,portalPass.s,portalTime.w,portalPos.b
Define prtgURL.s,prtgLogin.s,prtgPass.s,prtgTime.w,prtgPos.b
Define iconMy.i
Define iconMegaplanOk.i,iconMegaplanConn.i,iconMegaplanAlert.i
Define iconPortalOk.i,iconPortalConn.i,iconPortalAlert.i
Define iconPRTGOk.i,iconPRTGConn.i,iconPRTGAlert.i
Define iconNotifyMegaplan.i,iconNotifyPortal.i,iconNotifyPRTG.i
Define *megaplanMsg,*portalMsg,*prtgMsg
Define currentOpenAction.s
Define megaplanTryThread.i,portalTryThread.i,prtgTryThread.i
Define megaplanCheckThread.i,portalCheckThread.i,prtgCheckThread.i
Define megaplanKey.s,megaplanOpenAction.s,megaplanAlerts.i
Define portalOpenAction.s,portalAlerts.i
Define prtgKey.s,prtgOpenAction.s,prtgAlerts.i
Define megaplanIcon.i,portalIcon.i,prtgIcon.i
Define curMegaplanIcon.i,curPortalIcon.i,curPRTGIcon.i
Define iconChangeTimer = 0

IncludeFile "proc.pb"
IncludeFile "mod/megaplan.pb"
IncludeFile "mod/portal.pb"
IncludeFile "mod/prtg.pb"

If Not runLock()
  message("Другой экземпляр программы уже запущен.",#mError)
  End 2
EndIf

settings(#load)
toLog(#myName + " version " + #myVer + " started")
toLog("loading resources...")
getRes()

toLog("creating GUI...")
OpenWindow(#wnd,#PB_Ignore,#PB_Ignore,400,240,#myName,#PB_Window_SystemMenu|#PB_Window_ScreenCentered|#PB_Window_Invisible)
;SmartWindowRefresh(#wnd,#True)
StickyWindow(#wnd,#True)
PanelGadget(#panTabs,10,10,380,180)
AddGadgetItem(#panTabs,#tabMain,"Основные",iconMy)
CheckBoxGadget(#cbEnableSelfUpdate,10,5,360,20,"Проверять обновления")
CheckBoxGadget(#cbEnableDebug,10,25,360,20,"Вести лог")
TrackBarGadget(#tbNotifyTimeout,5,50,365,30,3,100)
TextGadget(#capNotifyTimeout,10,90,360,20,"",#PB_Text_Center)
AddGadgetItem(#panTabs,#tabMegaplan,"Мегаплан",iconMegaplanOk)
CheckBoxGadget(#cbMegaplanEnabled,10,5,360,20,"Включен")
TextGadget(#capMegaplanURL,10,32,100,20,"HTTPS host[:port]")
StringGadget(#strMegaplanURL,110,30,250,20,"")
TextGadget(#capMegaplanLogin,10,62,100,20,"Логин")
StringGadget(#strMegaplanLogin,110,60,150,20,"")
TextGadget(#capMegaplanPass,10,92,100,20,"Пароль")
StringGadget(#strMegaplanPass,110,90,150,20,"",#PB_String_Password)
TextGadget(#capMegaplanPos,10,123,100,20,"Уведомления")
ComboBoxGadget(#comMegaplanPos,110,120,150,20)
AddGadgetItem(#comMegaplanPos,#wnLT,"Слева сверху")
AddGadgetItem(#comMegaplanPos,#wnLB,"Слева снизу")
AddGadgetItem(#comMegaplanPos,#wnCT,"Центр сверху")
AddGadgetItem(#comMegaplanPos,#wnCB,"Центр снизу")
AddGadgetItem(#comMegaplanPos,#wnRT,"Справа сверху")
AddGadgetItem(#comMegaplanPos,#wnRB,"Справа снизу")
AddGadgetItem(#panTabs,#tabPortal,"Портал",iconPortalOk)
CheckBoxGadget(#cbPortalEnabled,10,5,360,20,"Включен")
TextGadget(#capPortalURL,10,32,100,20,"HTTP host[:port]")
StringGadget(#strPortalURL,110,30,250,20,"")
TextGadget(#capPortalLogin,10,62,100,20,"Логин")
StringGadget(#strPortalLogin,110,60,150,20,"")
TextGadget(#capPortalPass,10,92,100,20,"Пароль")
StringGadget(#strPortalPass,110,90,150,20,"",#PB_String_Password)
TextGadget(#capPortalPos,10,123,100,20,"Уведомления")
ComboBoxGadget(#comPortalPos,110,120,150,20)
AddGadgetItem(#comPortalPos,#wnLT,"Слева сверху")
AddGadgetItem(#comPortalPos,#wnLB,"Слева снизу")
AddGadgetItem(#comPortalPos,#wnCT,"Центр сверху")
AddGadgetItem(#comPortalPos,#wnCB,"Центр снизу")
AddGadgetItem(#comPortalPos,#wnRT,"Справа сверху")
AddGadgetItem(#comPortalPos,#wnRB,"Справа снизу")
AddGadgetItem(#panTabs,#tabPRTG,"PRTG",iconPRTGOk)
CheckBoxGadget(#cbPRTGEnabled,10,5,360,20,"Включен")
TextGadget(#capPRTGURL,10,32,100,20,"HTTP host[:port]")
StringGadget(#strPRTGURL,110,30,250,20,"")
TextGadget(#capPRTGLogin,10,62,100,20,"Логин")
StringGadget(#strPRTGLogin,110,60,150,20,"")
TextGadget(#capPRTGPass,10,92,100,20,"Пароль")
StringGadget(#strPRTGPass,110,90,150,20,"",#PB_String_Password)
TextGadget(#capPRTGPos,10,123,100,20,"Уведомления")
ComboBoxGadget(#comPRTGPos,110,120,150,20)
AddGadgetItem(#comPRTGPos,#wnLT,"Слева сверху")
AddGadgetItem(#comPRTGPos,#wnLB,"Слева снизу")
AddGadgetItem(#comPRTGPos,#wnCT,"Центр сверху")
AddGadgetItem(#comPRTGPos,#wnCB,"Центр снизу")
AddGadgetItem(#comPRTGPos,#wnRT,"Справа сверху")
AddGadgetItem(#comPRTGPos,#wnRB,"Справа снизу")
CloseGadgetList()
ButtonGadget(#btnApply,290,200,100,30,"Применить",#PB_Button_Default)
ButtonGadget(#btnCancel,180,200,100,30,"Отмена")

CreatePopupMenu(#menu)
MenuItem(#open,"Открыть")
MenuBar()
MenuItem(#settings,"Настройки")
MenuItem(#about,"О программе")
MenuBar()
MenuItem(#exit,"Выйти")

toLog("populating GUI...")
populateGUI()

toLog("starting win-notify thread...")
CreateThread(@wnProcess(),20)

toLog("starting update checking thread...")
CreateThread(@checkUpdate(),n)

toLog("all seems to be ok, moving to the main cycle!")

If Not checkSettings()
  toLog("no active services, showing configuration window")
  megaplanState = #megaplanErr
  portalState = #portalErr
  prtgState = #prtgErr
  HideWindow(#wnd,#False)
EndIf
If Not (enableMegaplan Or enablePortal Or enablePRTG)
  toLog("no active services, showing configuration window")
  megaplanState = #megaplanErr
  portalState = #portalErr
  prtgState = #prtgErr
  HideWindow(#wnd,#False)
EndIf

Repeat
  ev = WaitWindowEvent(50)
  If ElapsedMilliseconds() - iconChangeTimer >= #trayUpdate
    iconChangeTimer = ElapsedMilliseconds()
    If IsSysTrayIcon(#trayMegaplan) And megaplanAlerts > 0
      If curMegaplanIcon <> megaplanIcon
        ChangeSysTrayIcon(#trayMegaplan,megaplanIcon)
        curMegaplanIcon = megaplanIcon
      Else
        ChangeSysTrayIcon(#trayMegaplan,iconMegaplanAlert)
        curMegaplanIcon = iconMegaplanAlert
      EndIf
    ElseIf IsSysTrayIcon(#trayMegaplan) And curMegaplanIcon <> megaplanIcon
      ChangeSysTrayIcon(#trayMegaplan,megaplanIcon)
      curMegaplanIcon = megaplanIcon
    EndIf
    If IsSysTrayIcon(#trayPortal) And portalAlerts > 0
      If curPortalIcon <> portalIcon
        ChangeSysTrayIcon(#trayPortal,portalIcon)
        curPortalIcon = portalIcon
      Else
        ChangeSysTrayIcon(#trayPortal,iconPortalAlert)
        curPortalIcon = iconPortalAlert
      EndIf
    ElseIf IsSysTrayIcon(#trayPortal) And curPortalIcon <> portalIcon
      ChangeSysTrayIcon(#trayPortal,portalIcon)
      curPortalIcon = portalIcon
    EndIf
    If IsSysTrayIcon(#trayPRTG) And prtgAlerts > 0
      If curPrtgIcon <> prtgIcon
        ChangeSysTrayIcon(#trayPRTG,prtgIcon)
        curPRTGIcon = prtgIcon
      Else
        ChangeSysTrayIcon(#trayPRTG,iconPrtgAlert)
        curPrtgIcon = iconPrtgAlert
      EndIf
    ElseIf IsSysTrayIcon(#trayPRTG) And curPRTGIcon <> prtgIcon
      ChangeSysTrayIcon(#trayPRTG,prtgIcon)
      curPRTGIcon = prtgIcon
    EndIf
  EndIf
  If enableMegaplan
    If megaplanState = #megaplanTry
      toLog("connecting to Megaplan...")
      megaplanTryThread = CreateThread(@megaplanTry(),n)
      megaplanState = #megaplanTrying
    EndIf
    If ev = #megaplanEvent
      Select EventType()
        Case #megaplanFailed
          toLog("no answer from Megaplan",#lWarn)
          megaplanState = #megaplanTry
          ChangeSysTrayIcon(#trayMegaplan,iconMegaplanConn)
          megaplanIcon = iconMegaplanConn
        Case #megaplanFailedLogin
          toLog("wrong login/password on Megaplan",#lErr)
          megaplanState = #megaplanErr
          ChangeSysTrayIcon(#trayMegaplan,iconMegaplanConn)
          megaplanIcon = iconMegaplanConn
          message("Неверный логин или пароль для подключения к Мегаплану.",#mError)
          HideWindow(#wnd,#False)
        Case #megaplanOk
          toLog("successfully connected to Megaplan!")
          megaplanState = #megaplanOk
          ChangeSysTrayIcon(#trayMegaplan,iconMegaplanOk)
          megaplanIcon = iconMegaplanOk
      EndSelect
    EndIf
  EndIf
  If enablePortal
    If portalState = #portalTry
      toLog("connecting to Portal...")
      portalTryThread = CreateThread(@portalTry(),n)
      portalState = #portalTrying
    EndIf
    If ev = #portalEvent
      Select EventType()
        Case #portalFailed
          toLog("no answer from Portal",#lWarn)
          portalState = #portalTry
          ChangeSysTrayIcon(#trayPortal,iconPortalConn)
          portalIcon = iconPortalConn
        Case #portalFailedLogin
          toLog("wrong login/password on Portal",#lErr)
          portalState = #portalErr
          ChangeSysTrayIcon(#trayPortal,iconPortalConn)
          portalIcon = iconPortalConn
          message("Неверный логин или пароль для подключения к Порталу.",#mError)
          HideWindow(#wnd,#False)
        Case #portalOk
          toLog("successfully connected to Portal!")
          portalState = #portalOk
          ChangeSysTrayIcon(#trayPortal,iconPortalOk)
          portalIcon = iconPortalOk
      EndSelect
    EndIf
  EndIf
  If enablePRTG
    If prtgState = #prtgTry
      toLog("connecting to PRTG...")
      prtgTryThread = CreateThread(@prtgTry(),n)
      prtgState = #prtgTrying
    EndIf
    If ev = #prtgEvent
      Select EventType()
        Case #prtgFailed
          toLog("no answer from PRTG",#lWarn)
          prtgState = #prtgTry
          ChangeSysTrayIcon(#trayPRTG,iconPRTGConn)
          prtgIcon = iconPrtgConn
        Case #prtgFailedLogin
          toLog("wrong login/password on PRTG",#lErr)
          prtgState = #prtgErr
          ChangeSysTrayIcon(#trayPRTG,iconPRTGConn)
          prtgIcon = iconPrtgConn
          message("Неверный логин или пароль для подключения к PRTG.",#mError)
          HideWindow(#wnd,#False)
        Case #prtgOk
          toLog("successfully connected to PRTG!")
          prtgState = #prtgOk
          ChangeSysTrayIcon(#trayPRTG,iconPRTGOk)
          prtgIcon = iconPRTGOk
          prtgCheckThread = CreateThread(@prtgCheck(),prtgTime)
        Case #prtgMsg
          toLog("prtg alerts: " + Str(prtgAlerts))
          *prtgMsg = EventData()
          wnNotify("Alerts: " + Str(prtgAlerts),PeekS(*prtgMsg),prtgPos,notifyTimeout,#prtgBgColor,0,FontID(#fTitle),FontID(#fText),iconNotifyPRTG)
      EndSelect
    EndIf
  EndIf
  If ev = #PB_Event_SysTray
    Select EventGadget()
      Case #trayMegaplan
        currentOpenAction = megaplanOpenAction
      Case #trayPortal
        currentOpenAction = portalOpenAction
      Case #trayPRTG
        currentOpenAction = prtgOpenAction
    EndSelect
    If EventType() = #PB_EventType_LeftClick Or EventType() = #PB_EventType_LeftDoubleClick
      RunProgram(currentOpenAction)
    ElseIf EventType() = #PB_EventType_RightClick
      DisplayPopupMenu(#menu,WindowID(#wnd))
    EndIf
  EndIf
  If ev = #PB_Event_Menu
    Select EventMenu()
      Case #open
        RunProgram(currentOpenAction)
      Case #about
        message(#aboutstr)
      Case #settings
        HideWindow(#wnd,#False)
        SetActiveWindow(#wnd)
      Case #exit
        Die()
    EndSelect
  EndIf
  If ev = #wnCleanup : wnCleanup(EventData()) : EndIf
  If ev = #PB_Event_Gadget
    Select EventGadget()
      Case #tbNotifyTimeout
        SetGadgetText(#capNotifyTimeout,"Показывать уведомления " + Str(GetGadgetState(#tbNotifyTimeout)*100) + " мс")
      Case #btnApply
        If EventType() = #PB_EventType_LeftClick
          populateInternal()
          If Not (enableMegaplan Or enablePortal Or enablePRTG)
            message("Вы не включили ни одну учетную запись.",#mError)
          ElseIf checkSettings()
            HideWindow(#wnd,#True)
            settings(#save)
            populateGUI()
            cleanUp()
          EndIf
        EndIf
      Case #btnCancel
        If EventType() = #PB_EventType_LeftClick
          If enableMegaplan Or enablePortal Or enablePRTG
            HideWindow(#wnd,#True)
            populateGUI()
          Else
            Break
          EndIf
        EndIf
    EndSelect
  EndIf
  If ev = #PB_Event_CloseWindow
    If enableMegaplan Or enablePortal Or enablePRTG
      HideWindow(#wnd,#True)
      populateGUI()
    Else
      Break
    EndIf
  EndIf
ForEver

Die()

; IDE Options = PureBasic 5.31 (Windows - x86)
; EnableUnicode
; EnableXP
; EnableBuildCount = 0