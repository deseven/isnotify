#myName = "iSnotify"
#myVer = "1.0.0"
#aboutstr = #myName+" "+#myVer+#CRLF$+"written by deseven, 2015"+#CRLF$+#CRLF$+"web: deseven.info"+#CRLF$+"mail: de7@deseven.info"
#myDefUtime = 10
#trayUpdate = 500
#checkUpdateTime = 120
#curlTimeout = 10

#portalBgColor = $c88200
#megaplanBgColor = $6f8c2b
#prtgBgColor = $435bd9
#textColor = $eeeeee

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
  #cbNoFullscreenNotify
  #cbTrayBlink
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
  #cbMegaplanRepeatAlert
  #capPortalTime
  #tbPortalTime
  #cbPortalRepeatAlert
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

Enumeration json
  #jsonMegaplan
  #jsonPortal
  #jsonPRTG
EndEnumeration

Structure message
  title.s
  message.s
  url.s
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