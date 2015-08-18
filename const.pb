#myName = "iSnotify"
#myVer = "0.5.0"
#aboutstr = #myName+" "+#myVer+#CRLF$+"written by deseven, 2015"+#CRLF$+#CRLF$+"web: deseven.info"+#CRLF$+"mail: de7@deseven.info"
#myDefUtime = 10
#trayUpdate = 500
#checkUpdateTime = 120
#curlTimeout = 30

#portalBgColor = $c9a380
#megaplanBgColor = $3dc89a
#prtgBgColor = $4848ff

Enumeration message
  #mInfo
  #mQuestion
  #mError
EndEnumeration

Enumeration log
  #lInfo
  #lWarn
  #lErr
EndEnumeration

Enumeration main
  #wnd
  #btnApply
  #btnCancel
  #panTabs
  #cbEnableDebug
  #cbEnableSelfUpdate
  #tbNotifyTimeout
  #capNotifyTimeout
  #cbMegaplanEnabled
  #cbPortalEnabled
  #cbPRTGEnabled
  #capMegaplanURL
  #strMegaplanURL
  #capMegaplanLogin
  #strMegaplanLogin
  #capMegaplanPass
  #strMegaplanPass
  #capMegaplanPos
  #comMegaplanPos
  #capPortalURL
  #strPortalURL
  #capPortalLogin
  #strPortalLogin
  #capPortalPass
  #strPortalPass
  #capPortalPos
  #comPortalPos
  #capPRTGURL
  #strPRTGURL
  #capPRTGLogin
  #strPRTGLogin
  #capPRTGPass
  #strPRTGPass
  #capPRTGPos
  #comPRTGPos
  #capMegaplanTime
  #tbMegaplanTime
  #capPortalTime
  #tbPortalTime
  #capPRTGTime
  #tbPRTGTime
  #cbPRTGRepeatAlert
  #capPRTGAlertAfter
  #tbPRTGAlertAfter
EndEnumeration

Enumeration tabs
  #tabMain
  #tabMegaplan
  #tabPortal
  #tabPRTG
EndEnumeration

Enumeration tray
  #trayMegaplan
  #trayPortal
  #trayPRTG
EndEnumeration

Enumeration menu
  #menu
  #open
  #settings
  #about
  #exit
EndEnumeration

Enumeration encdec
  #encode
  #decode
EndEnumeration

Enumeration settings
  #save
  #load
EndEnumeration

Enumeration type
  #tPortal
  #tMegaplan
EndEnumeration

Enumeration fonts
  #fTitle
  #fText
EndEnumeration

Enumeration types #PB_EventType_FirstCustomValue
  #megaplanErr
  #portalErr
  #prtgErr
  #megaplanTry
  #portalTry
  #prtgTry
  #megaplanTrying
  #portalTrying
  #prtgTrying
  #megaplanOk
  #megaplanFailed
  #megaplanFailedLogin
  #portalOk
  #portalFailed
  #portalFailedLogin
  #prtgOk
  #prtgFailed
  #prtgFailedLogin
  #megaplanMsg
  #portalMsg
  #prtgMsg
  #megaplanNomsg
  #portalNomsg
  #prtgNomsg
EndEnumeration

Enumeration events #PB_Event_FirstCustomValue
  #megaplanEvent
  #portalEvent
  #prtgEvent
EndEnumeration

Structure PRTGalertSensor
  sensor.s
  device.s
  downtimesince.s
  downtimesince_raw.i
EndStructure

Structure PRTGalerts
  ver.s
  treesize.l
  List sensors.PRTGalertSensor()
EndStructure

DataSection
  iconMegaplanOk:
  IncludeBinary "res/megaplan_ok.ico"
  iconMegaplanConn:
  IncludeBinary "res/megaplan_conn.ico"
  iconMegaplanAlert:
  IncludeBinary "res/megaplan_alert.ico"
  iconPortalOk:
  IncludeBinary "res/portal_ok.ico"
  iconPortalConn:
  IncludeBinary "res/portal_conn.ico"
  iconPortalAlert:
  IncludeBinary "res/portal_alert.ico"
  iconPRTGOk:
  IncludeBinary "res/prtg_ok.ico"
  iconPRTGConn:
  IncludeBinary "res/prtg_conn.ico"
  iconPRTGAlert:
  IncludeBinary "res/prtg_alert.ico"
  iconNotifyMegaplan:
  IncludeBinary "res/notify/megaplan.ico"
  iconNotifyPortal:
  IncludeBinary "res/notify/portal.ico"
  iconNotifyPRTG:
  IncludeBinary "res/notify/prtg.ico"
  iconMy:
  IncludeBinary "res/my.ico"
EndDataSection

; IDE Options = PureBasic 5.31 (Windows - x86)
; EnableUnicode
; EnableXP
; EnableBuildCount = 0