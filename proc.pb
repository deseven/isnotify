Define logLock.i = CreateMutex()

Declare toLog(msg.s,type.b = #mInfo)
Declare Die()
Declare.s encDec(string.s,mode.b)
Declare.s getData(url.s)
Declare settings(mode.b)
Declare check()

Procedure runLock()
  Protected app.i
  app = CreateSemaphore_(0,0,1,"sol" + #myName)
  If app <> 0 And GetLastError_() = #ERROR_ALREADY_EXISTS
    CloseHandle_(app)
    ProcedureReturn #False
  EndIf
  ProcedureReturn #True
EndProcedure

Procedure getRes()
  Shared iconMegaplanOk.i,iconMegaplanConn.i,iconMegaplanAlert.i
  Shared iconPortalOk.i,iconPortalConn.i,iconPortalAlert.i
  Shared iconPRTGOk.i,iconPRTGConn.i,iconPRTGAlert.i
  Shared iconNotifyMegaplan.i,iconNotifyPortal.i,iconNotifyPRTG.i
  Shared myAppName.s,iconMy.i
  iconMegaplanOk = ImageID(CatchImage(#PB_Any,?iconMegaplanOk))
  iconMegaplanConn = ImageID(CatchImage(#PB_Any,?iconMegaplanConn))
  iconMegaplanAlert = ImageID(CatchImage(#PB_Any,?iconMegaplanAlert))
  iconPortalOk = ImageID(CatchImage(#PB_Any,?iconPortalOk))
  iconPortalConn = ImageID(CatchImage(#PB_Any,?iconPortalConn))
  iconPortalAlert = ImageID(CatchImage(#PB_Any,?iconPortalAlert))
  iconPRTGOk = ImageID(CatchImage(#PB_Any,?iconPRTGOk))
  iconPRTGConn = ImageID(CatchImage(#PB_Any,?iconPRTGConn))
  iconPRTGAlert = ImageID(CatchImage(#PB_Any,?iconPRTGAlert))
  iconNotifyMegaplan = ImageID(CatchImage(#PB_Any,?iconNotifyMegaplan))
  iconNotifyPortal = ImageID(CatchImage(#PB_Any,?iconNotifyPortal))
  iconNotifyPRTG = ImageID(CatchImage(#PB_Any,?iconNotifyPRTG))
  iconMy = ImageID(CatchImage(#PB_Any,?iconMy))
  LoadFont(#fTitle,"Arial",12,#PB_Font_HighQuality|#PB_Font_Bold)
  LoadFont(#fText,"Arial",10,#PB_Font_HighQuality)
EndProcedure

Procedure.s str2ansi(string.s)
  Protected *curlstring 
  If *curlstring : FreeMemory(*curlstring) : EndIf
  *curlstring = AllocateMemory(Len(string) + 1)
  PokeS(*curlstring,string,-1,#PB_Ascii)
  ProcedureReturn PeekS(*curlstring,-1)
EndProcedure

Procedure.s MD5AsciiFingerprint(s.s)
  Protected a.s=s:ProcedureReturn MD5Fingerprint(@a,PokeS(@a,s,-1,#PB_Ascii))  
EndProcedure

Procedure message(message.s,type.b = #mInfo)
  Select type
    Case #mError
      MessageBox_(WindowID(#wnd),message,#myName,#MB_OK|#MB_ICONERROR)
    Case #mQuestion
      If MessageBox_(WindowID(#wnd),message,#myName,#MB_YESNO|#MB_ICONQUESTION) = #IDYES
        ProcedureReturn #True
      Else
        ProcedureReturn #False
      EndIf
    Default
      MessageBox_(WindowID(#wnd),message,#myName,#MB_OK|#MB_ICONINFORMATION)
  EndSelect
  ProcedureReturn #True
EndProcedure

Procedure toLog(msg.s,type.b = #lInfo)
  Shared enableDebug.b,logLock.i
  Protected log.s,logdate.s,logtype.s
  logdate = FormatDate("[%dd.%mm.%yy %hh:%ii:%ss] ",Date())
  Select type
    Case #lWarn
      logtype = "[WARN] "
    Case #lErr
      logtype = "[ERROR] "
    Default
      logtype = "[INFO] "
  EndSelect
  If enableDebug
    log = GetEnvironmentVariable("APPDATA") + "\" + #myName + "\debug.log"
    LockMutex(logLock)
    If OpenFile(0,log,#PB_File_Append)
      WriteStringN(0,logdate + logtype + msg)
      CloseFile(0)
    EndIf
    UnlockMutex(logLock)
  EndIf
  Debug logdate + logtype + msg
EndProcedure

Procedure Die()
  toLog("exiting")
  End 0
EndProcedure

Procedure.s getTimezone()
  Protected timezone.TIME_ZONE_INFORMATION,tzdelta.i
  GetTimeZoneInformation_(@timezone)
  tzdelta = (timezone\DaylightBias + timezone\Bias)/60
  If tzdelta = 0
    ProcedureReturn "+0000"
  ElseIf tzdelta > 0 And tzdelta < 10
    ProcedureReturn "-0" + Str(tzdelta) + "00"
  ElseIf tzdelta >= 10
    ProcedureReturn "-" + Str(tzdelta) + "00"
  ElseIf tzdelta < 0 And tzdelta > -10
    ProcedureReturn "+0" + Str(tzdelta*-1) + "00"
  Else
    ProcedureReturn "+" + Str(tzdelta*-1) + "00"
  EndIf
EndProcedure

Procedure.s encDec(string.s,mode.b)
  If Len(string)
    Protected res.s = Space(1024)
    If mode = #encode
      string = ReverseString(string)
      Base64Encoder(@string,StringByteLength(string),@res,1024)
    Else
      Base64Decoder(@string,StringByteLength(string),@res,1024)
      res = ReverseString(res)
    EndIf
    ProcedureReturn(res)
  EndIf
EndProcedure

Procedure.s getData(url.s)
  Protected res.b,resData.s,curl.i,agent.s
  curl = curl_easy_init()
  url = str2ansi(url)
  agent = str2ansi(#myName + "/" + #myVer)
  If curl
    curl_easy_setopt(curl,#CURLOPT_URL,@url)
    curl_easy_setopt(curl,#CURLOPT_IPRESOLVE,#CURL_IPRESOLVE_V4)
    curl_easy_setopt(curl,#CURLOPT_USERAGENT,@agent)
    curl_easy_setopt(curl,#CURLOPT_TIMEOUT,#curlTimeout)
    curl_easy_setopt(curl,#CURLOPT_WRITEFUNCTION,@RW_LibCurl_WriteFunction())
    res.b = curl_easy_perform(curl)
    resData.s = RW_LibCurl_GetData()
    curl_easy_cleanup(curl.i)
    If res <> 0
      ProcedureReturn "-1"
    Else
      ProcedureReturn resData
    EndIf
  Else
    toLog("can't init curl")
  EndIf
EndProcedure

Procedure settings(mode.b)
  Shared enableDebug.b,selfUpdate.b,notifyTimeout.w
  Shared enableMegaplan.b,enablePortal.b,enablePRTG.b
  Shared megaplanURL.s,megaplanLogin.s,megaplanPass.s,megaplanTime.w,megaplanPos.b,megaplanRepeatAlert.b
  Shared portalURL.s,portalLogin.s,portalPass.s,portalTime.w,portalPos.b,portalRepeatAlert.b
  Shared prtgURL.s,prtgLogin.s,prtgPass.s,prtgTime.w,prtgPos.b,prtgRepeatAlert.b,prtgAlertAfter.w
  Protected config.s = GetEnvironmentVariable("APPDATA") + "/" + #myName
  If FileSize(config) <> -2 : CreateDirectory(config) : EndIf
  OpenPreferences(config + "/config.ini",#PB_Preference_GroupSeparator)
  PreferenceGroup("main")
  If mode = #load
    If ReadPreferenceString("enable_debug","no") = "yes"
      enableDebug = #True
    Else
      enableDebug = #False
    EndIf
    If ReadPreferenceString("self_update","yes") = "yes"
      selfUpdate = #True
    Else
      selfUpdate = #False
    EndIf
    notifyTimeout = ReadPreferenceLong("notification_timeout",4000)
    If ReadPreferenceString("enable_megaplan","no") = "yes"
      enableMegaplan = #True
    Else
      enableMegaplan = #False
    EndIf
    If ReadPreferenceString("enable_portal","no") = "yes"
      enablePortal = #True
    Else
      enablePortal = #False
    EndIf
    If ReadPreferenceString("enable_prtg","no") = "yes"
      enablePRTG = #True
    Else
      enablePRTG = #False
    EndIf
    PreferenceGroup("megaplan")
    megaplanURL = ReadPreferenceString("url","")
    megaplanLogin = ReadPreferenceString("login","")
    megaplanPass = encDec(ReadPreferenceString("password",""),#decode)
    megaplanTime = ReadPreferenceLong("update_time",30)
    megaplanPos = ReadPreferenceLong("notify_position",#wnRB)
    If ReadPreferenceString("repeat_alert","no") = "yes"
      megaplanRepeatAlert = #True
    Else
      megaplanRepeatAlert = #False
    EndIf
    PreferenceGroup("portal")
    portalURL = ReadPreferenceString("url","")
    portalLogin = ReadPreferenceString("login","")
    portalPass = encDec(ReadPreferenceString("password",""),#decode)
    portalTime = ReadPreferenceLong("update_time",30)
    portalPos = ReadPreferenceLong("notify_position",#wnRB)
    If ReadPreferenceString("repeat_alert","no") = "yes"
      portalRepeatAlert = #True
    Else
      portalRepeatAlert = #False
    EndIf
    PreferenceGroup("prtg")
    prtgURL = ReadPreferenceString("url","")
    prtgLogin = ReadPreferenceString("login","")
    prtgPass = encDec(ReadPreferenceString("password",""),#decode)
    prtgTime = ReadPreferenceLong("update_time",30)
    prtgPos = ReadPreferenceLong("notify_position",#wnRB)
    If ReadPreferenceString("repeat_alert","no") = "yes"
      prtgRepeatAlert = #True
    Else
      prtgRepeatAlert = #False
    EndIf
    prtgAlertAfter = ReadPreferenceLong("alert_after",0)
  Else
    If enableDebug
      WritePreferenceString("enable_debug","yes")
    Else
      WritePreferenceString("enable_debug","no")
    EndIf
    If selfUpdate
      WritePreferenceString("self_update","yes")
    Else
      WritePreferenceString("self_update","no")
    EndIf
    WritePreferenceLong("notification_timeout",notifyTimeout)
    If enableMegaplan
      WritePreferenceString("enable_megaplan","yes")
    Else
      WritePreferenceString("enable_megaplan","no")
    EndIf
    If enablePortal
      WritePreferenceString("enable_portal","yes")
    Else
      WritePreferenceString("enable_portal","no")
    EndIf
    If enablePRTG
      WritePreferenceString("enable_prtg","yes")
    Else
      WritePreferenceString("enable_prtg","no")
    EndIf
    PreferenceGroup("megaplan")
    WritePreferenceString("url",megaplanURL)
    WritePreferenceString("login",megaplanLogin)
    WritePreferenceString("password",encDec(megaplanPass,#encode))
    WritePreferenceLong("update_time",megaplanTime)
    WritePreferenceLong("notify_position",megaplanPos)
    If megaplanRepeatAlert
      WritePreferenceString("repeat_alert","yes")
    Else
      WritePreferenceString("repeat_alert","no")
    EndIf
    PreferenceGroup("portal")
    WritePreferenceString("url",portalURL)
    WritePreferenceString("login",portalLogin)
    WritePreferenceString("password",encDec(portalPass,#encode))
    WritePreferenceLong("update_time",portalTime)
    WritePreferenceLong("notify_position",portalPos)
    If portalRepeatAlert
      WritePreferenceString("repeat_alert","yes")
    Else
      WritePreferenceString("repeat_alert","no")
    EndIf
    PreferenceGroup("prtg")
    WritePreferenceString("url",prtgURL)
    WritePreferenceString("login",prtgLogin)
    WritePreferenceString("password",encDec(prtgPass,#encode))
    WritePreferenceLong("update_time",prtgTime)
    WritePreferenceLong("notify_position",prtgPos)
    If prtgRepeatAlert
      WritePreferenceString("repeat_alert","yes")
    Else
      WritePreferenceString("repeat_alert","no")
    EndIf
    WritePreferenceLong("alert_after",prtgAlertAfter)
  EndIf
  ClosePreferences()
EndProcedure

Procedure populateInternal()
  Shared enableDebug.b,selfUpdate.b,notifyTimeout.w
  Shared enableMegaplan.b,enablePortal.b,enablePRTG.b
  Shared megaplanURL.s,megaplanLogin.s,megaplanPass.s,megaplanTime.w,megaplanPos.b,megaplanRepeatAlert.b
  Shared portalURL.s,portalLogin.s,portalPass.s,portalTime.w,portalPos.b,portalRepeatAlert.b
  Shared prtgURL.s,prtgLogin.s,prtgPass.s,prtgTime.w,prtgPos.b,prtgRepeatAlert.b,prtgAlertAfter.w
  If GetGadgetState(#cbEnableDebug) = #PB_Checkbox_Checked
    enableDebug = #True
  Else
    enableDebug = #False
  EndIf
  If GetGadgetState(#cbEnableSelfUpdate) = #PB_Checkbox_Checked
    selfUpdate = #True
  Else
    selfUpdate = #False
  EndIf
  notifyTimeout = GetGadgetState(#tbNotifyTimeout)*100
  If GetGadgetState(#cbMegaplanEnabled) = #PB_Checkbox_Checked
    enableMegaplan = #True
  Else
    enableMegaplan = #False
  EndIf
  megaplanURL = GetGadgetText(#strMegaplanURL)
  megaplanLogin = GetGadgetText(#strMegaplanLogin)
  megaplanPass = GetGadgetText(#strMegaplanPass)
  megaplanPos = GetGadgetState(#comMegaplanPos)
  megaplanTime = GetGadgetState(#tbMegaplanTime)*10
  If GetGadgetState(#cbMegaplanRepeatAlert) = #PB_Checkbox_Checked
    megaplanRepeatAlert = #True
  Else
    megaplanRepeatAlert = #False
  EndIf
  If GetGadgetState(#cbPortalEnabled) = #PB_Checkbox_Checked
    enablePortal = #True
  Else
    enablePortal = #False
  EndIf
  portalURL = GetGadgetText(#strPortalURL)
  portalLogin = GetGadgetText(#strPortalLogin)
  portalPass = GetGadgetText(#strPortalPass)
  portalPos = GetGadgetState(#comPortalPos)
  portalTime = GetGadgetState(#tbPortalTime)*10
  If GetGadgetState(#cbPortalRepeatAlert) = #PB_Checkbox_Checked
    portalRepeatAlert = #True
  Else
    portalRepeatAlert = #False
  EndIf
  If GetGadgetState(#cbPRTGEnabled) = #PB_Checkbox_Checked
    enablePRTG = #True
  Else
    enablePRTG = #False
  EndIf
  prtgURL = GetGadgetText(#strPRTGURL)
  prtgLogin = GetGadgetText(#strPRTGLogin)
  prtgPass = GetGadgetText(#strPRTGPass)
  prtgPos = GetGadgetState(#comPRTGPos)
  prtgTime = GetGadgetState(#tbPRTGTime)*10
  prtgAlertAfter = GetGadgetState(#tbPRTGAlertAfter)*10
  If GetGadgetState(#cbPRTGRepeatAlert) = #PB_Checkbox_Checked
    prtgRepeatAlert = #True
  Else
    prtgRepeatAlert = #False
  EndIf
EndProcedure

Procedure populateGUI()
  Shared enableDebug.b,selfUpdate.b,notifyTimeout.w
  Shared enableMegaplan.b,enablePortal.b,enablePRTG.b
  Shared megaplanURL.s,megaplanLogin.s,megaplanPass.s,megaplanTime.w,megaplanPos.b,megaplanRepeatAlert.b
  Shared portalURL.s,portalLogin.s,portalPass.s,portalTime.w,portalPos.b,portalRepeatAlert.b
  Shared prtgURL.s,prtgLogin.s,prtgPass.s,prtgTime.w,prtgPos.b,prtgRepeatAlert.b,prtgAlertAfter.w
  If enableDebug
    SetGadgetState(#cbEnableDebug,#PB_Checkbox_Checked)
  Else
    SetGadgetState(#cbEnableDebug,#PB_Checkbox_Unchecked)
  EndIf
  If selfUpdate
    SetGadgetState(#cbEnableSelfUpdate,#PB_Checkbox_Checked)
  Else
    SetGadgetState(#cbEnableSelfUpdate,#PB_Checkbox_Unchecked)
  EndIf
  SetGadgetState(#tbNotifyTimeout,notifyTimeout/100)
  SetGadgetText(#capNotifyTimeout,"Показывать уведомления " + Str(notifyTimeout) + " мс")
  If enableMegaplan
    SetGadgetState(#cbMegaplanEnabled,#PB_Checkbox_Checked)
  Else
    SetGadgetState(#cbMegaplanEnabled,#PB_Checkbox_Unchecked)
  EndIf
  If enablePortal
    SetGadgetState(#cbPortalEnabled,#PB_Checkbox_Checked)
  Else
    SetGadgetState(#cbPortalEnabled,#PB_Checkbox_Unchecked)
  EndIf
  If enablePRTG
    SetGadgetState(#cbPRTGEnabled,#PB_Checkbox_Checked)
  Else
    SetGadgetState(#cbPRTGEnabled,#PB_Checkbox_Unchecked)
  EndIf
  SetGadgetText(#strMegaplanURL,megaplanURL)
  SetGadgetText(#strMegaplanLogin,megaplanLogin)
  SetGadgetText(#strMegaplanPass,megaplanPass)
  SetGadgetState(#comMegaplanPos,megaplanPos)
  SetGadgetState(#tbMegaplanTime,megaplanTime/10)
  SetGadgetText(#capMegaplanTime,"Обновлять каждые " + Str(megaplanTime) + " сек")
  If megaplanRepeatAlert
    SetGadgetState(#cbMegaplanRepeatAlert,#PB_Checkbox_Checked)
  Else
    SetGadgetState(#cbMegaplanRepeatAlert,#PB_Checkbox_Unchecked)
  EndIf
  SetGadgetText(#strPortalURL,portalURL)
  SetGadgetText(#strPortalLogin,portalLogin)
  SetGadgetText(#strPortalPass,portalPass)
  SetGadgetState(#comPortalPos,portalPos)
  SetGadgetState(#tbPortalTime,portalTime/10)
  SetGadgetText(#capPortalTime,"Обновлять каждые " + Str(portalTime) + " сек")
  If portalRepeatAlert
    SetGadgetState(#cbPortalRepeatAlert,#PB_Checkbox_Checked)
  Else
    SetGadgetState(#cbPortalRepeatAlert,#PB_Checkbox_Unchecked)
  EndIf
  SetGadgetText(#strPRTGURL,prtgURL)
  SetGadgetText(#strPRTGLogin,prtgLogin)
  SetGadgetText(#strPRTGPass,prtgPass)
  SetGadgetState(#comPRTGPos,prtgPos)
  SetGadgetState(#tbPRTGTime,prtgTime/10)
  SetGadgetText(#capPRTGTime,"Обновлять каждые " + Str(prtgTime) + " сек")
  SetGadgetState(#tbPRTGAlertAfter,prtgAlertAfter/10)
  If prtgAlertAfter
    SetGadgetText(#capPRTGAlertAfter,"Уведомлять после " + Str(prtgAlertAfter) + " сек")
  Else
    SetGadgetText(#capPRTGAlertAfter,"Уведомлять сразу")
  EndIf
  If prtgRepeatAlert
    SetGadgetState(#cbPRTGRepeatAlert,#PB_Checkbox_Checked)
  Else
    SetGadgetState(#cbPRTGRepeatAlert,#PB_Checkbox_Unchecked)
  EndIf
EndProcedure

Procedure checkSettings()
  Shared enableDebug.b,selfUpdate.b,notifyTimeout.w
  Shared enableMegaplan.b,enablePortal.b,enablePRTG.b
  Shared megaplanURL.s,megaplanLogin.s,megaplanPass.s,megaplanTime.w,megaplanPos.b,megaplanRepeatAlert.b
  Shared portalURL.s,portalLogin.s,portalPass.s,portalTime.w,portalPos.b,portalRepeatAlert.b
  Shared prtgURL.s,prtgLogin.s,prtgPass.s,prtgTime.w,prtgPos.b,prtgRepeatAlert.b,prtgAlertAfter.w
  Shared iconMegaplanConn.i,iconPortalConn.i,iconPRTGConn.i
  If enableMegaplan
    If Not Len(megaplanURL) Or Not Len(megaplanLogin) Or Not Len(megaplanPass)
      message("Необходимо указать все параметры для подключения к Мегаплану!",#mError)
      ProcedureReturn #False
    EndIf
    If megaplanTime < 10 : megaplanTime = 10 : EndIf
    If Not IsSysTrayIcon(#trayMegaplan)
      AddSysTrayIcon(#trayMegaplan,WindowID(#wnd),iconMegaplanConn)
      SysTrayIconToolTip(#trayMegaplan,"Мегаплан")
    Else
      ChangeSysTrayIcon(#trayMegaplan,iconMegaplanConn)
    EndIf
  Else
    If IsSysTrayIcon(#trayMegaplan) : RemoveSysTrayIcon(#trayMegaplan) : EndIf
  EndIf
  If enablePortal
    If Not Len(portalURL) Or Not Len(portalLogin) Or Not Len(portalPass)
      message("Необходимо указать все параметры для подключения к Порталу!",#mError)
      ProcedureReturn #False
    EndIf
    If portalTime < 10 : portalTime = 10 : EndIf
    If Not IsSysTrayIcon(#trayPortal)
      AddSysTrayIcon(#trayPortal,WindowID(#wnd),iconPortalConn)
      SysTrayIconToolTip(#trayPortal,"Портал")
    Else
      ChangeSysTrayIcon(#trayPortal,iconPortalConn)
    EndIf
  Else
    If IsSysTrayIcon(#trayPortal) : RemoveSysTrayIcon(#trayPortal) : EndIf
  EndIf
  If enablePRTG
    If Not Len(prtgURL) Or Not Len(prtgLogin) Or Not Len(prtgPass)
      message("Необходимо указать все параметры для подключения к PRTG!",#mError)
      ProcedureReturn #False
    EndIf
    If prtgTime < 10 : prtgTime = 10 : EndIf
    If prtgAlertAfter < 0 : prtgAlertAfter = 0 : EndIf
    If prtgAlertAfter > 600 : prtgAlertAfter = 600 : EndIf
    If Not IsSysTrayIcon(#trayPRTG)
      AddSysTrayIcon(#trayPRTG,WindowID(#wnd),iconPRTGConn)
      SysTrayIconToolTip(#trayPRTG,"PRTG")
    Else
      ChangeSysTrayIcon(#trayPRTG,iconPRTGConn)
    EndIf
  Else
    If IsSysTrayIcon(#trayPRTG) : RemoveSysTrayIcon(#trayPRTG) : EndIf
  EndIf
  ProcedureReturn #True
EndProcedure

Procedure checkUpdate(n.i)
  Shared myDir.s,selfUpdate.b
  Protected version.s,minutes.i
  Repeat
    If selfUpdate
      toLog("checking for updates...")
      version = getData("http://home-nadym.ru/isn/isn.ver")
      If version <> "-1" And Len(version) And FindString(version,"isn") = 1 And version <> "isn" + #myVer
        version = RemoveString(version,"isn")
        toLog("found new version " + version)
        If message("Обнаружена новая версия, обновиться?",#mQuestion)
          toLog("starting updater...")
          RunProgram(myDir + "\isn_upd.exe",version,myDir)
          Die()
        EndIf
      EndIf
    EndIf
    Repeat
      Delay(60000)
      minutes + 1
      If minutes >= #checkUpdateTime
        minutes = 0
        Break
      EndIf
    ForEver
  ForEver
EndProcedure

Procedure updateTrayTooltip(tray.i,value.i)
  Select tray.i
    Case #trayMegaplan
      If IsSysTrayIcon(#trayMegaplan)
        SysTrayIconToolTip(#trayMegaplan,"Мегаплан: " + Str(value))
      EndIf
    Case #trayPortal
      If IsSysTrayIcon(#trayPortal)
        SysTrayIconToolTip(#trayPortal,"Portal: " + Str(value))
      EndIf
    Case #trayPRTG
      If IsSysTrayIcon(#trayPRTG)
        SysTrayIconToolTip(#trayPRTG,"PRTG: " + Str(value))
      EndIf
  EndSelect
EndProcedure

Procedure cleanUp()
  Shared megaplanTryThread.i,portalTryThread.i,prtgTryThread.i
  Shared megaplanCheckThread.i,portalCheckThread.i,prtgCheckThread.i
  Shared prtgKey.s,megaplanKey.s
  Shared megaplanState.i,portalState.i,prtgState.i
  Shared megaplanIcon.i,portalIcon.i,prtgIcon.i
  Shared iconMegaplanConn.i,iconPortalConn.i,iconPRTGConn.i
  Shared megaplanAlerts.i,portalAlerts.i,prtgAlerts.i
  If IsThread(megaplanTryThread) : KillThread(megaplanTryThread) : EndIf
  If IsThread(portalTryThread) : KillThread(portalTryThread) : EndIf
  If IsThread(prtgTryThread) : KillThread(prtgTryThread) : EndIf
  If IsThread(megaplanCheckThread) : KillThread(megaplanCheckThread) : EndIf
  If IsThread(portalCheckThread) : KillThread(portalCheckThread) : EndIf
  If IsThread(prtgCheckThread) : KillThread(prtgCheckThread) : EndIf
  prtgKey = ""
  megaplanKey = ""
  megaplanState = #megaplanTry
  portalState = #portalTry
  prtgState = #prtgTry
  megaplanIcon.i = iconMegaplanConn
  portalIcon.i = iconPortalConn
  prtgIcon.i = iconPRTGConn
  megaplanAlerts = 0
  portalAlerts = 0
  prtgAlerts = 0
EndProcedure

; IDE Options = PureBasic 5.31 (Windows - x86)
; EnableUnicode
; EnableXP
; EnableBuildCount = 0