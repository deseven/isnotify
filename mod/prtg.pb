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

Procedure prtgTry(n.i)
  Shared prtgURL.s,prtgLogin.s,prtgPass.s,prtgKey.s,prtgOpenAction.s,prtgLastActive.s
  prtgOpenAction = "http://" + prtgURL + "/alarms.htm?filter_status=5&filter_status=4&filter_status=10&filter_status=13&filter_status=14"
  prtgLastActive = "trying " + FormatDate("%dd.%mm.%yy %hh:%ii:%ss",Date())
  Delay(500)
  Protected res.s = simpleGetData("http://" + prtgURL + "/api/getpasshash.htm?username=" + prtgLogin + "&password=" + prtgPass)
  If FindString(res,"Unauthorized")
    PostEvent(#prtgEvent,#wnd,0,#prtgFailedLogin)
  ElseIf res = "-1"
    PostEvent(#prtgEvent,#wnd,0,#prtgFailed)
  Else
    prtgKey = res
    PostEvent(#prtgEvent,#wnd,0,#prtgOk)
  EndIf
EndProcedure

Procedure prtgCheck(time.i)
  Shared prtgURL.s,prtgLogin.s,prtgKey.s,prtgAlerts.i,prtgRepeatAlert.b,prtgAlertAfter.w,prtgLastActive.s
  Protected dataURL.s,res.s,curAlerts.i,msg.s,oldmsg.s,alerts.PRTGalerts,prev.s
  Protected NewList devices.s()
  dataURL = "http://" + prtgURL + "/api/table.json?content=sensors&output=json&columns=sensor,device,downtimesince&filter_status=5&username=" + prtgLogin + "&passhash=" + prtgKey
  Repeat
    prtgLastActive = "checking " + FormatDate("%dd.%mm.%yy %hh:%ii:%ss",Date())
    toDebug("getting data from PRTG...")
    res = simpleGetData(dataURL)
    msg = ""
    prev = ""
    curAlerts = 0
    res = ReplaceString(res,#CR$,"")
    res = ReplaceString(res,#LF$,"")
    toDebug("PRTG data: " + res)
    If FindString(res,"Unauthorized")
      PostEvent(#prtgEvent,#wnd,0,#prtgFailedLogin)
      ProcedureReturn
    ElseIf Not Len(res) Or res = "-1"
      PostEvent(#prtgEvent,#wnd,0,#prtgFailed)
      ProcedureReturn
    ElseIf ParseJSON(#jsonPRTG,res,#PB_JSON_NoCase)
      ExtractJSONStructure(JSONValue(#jsonPRTG),@alerts.PRTGalerts,PRTGalerts)
      curAlerts = alerts\treesize
      ForEach alerts\sensors()
        If prtgAlertAfter And alerts\sensors()\downtimesince_raw < prtgAlertAfter
          curAlerts - 1
          toDebug("removing fresh alert (" + Str(alerts\sensors()\downtimesince_raw) + " < " + Str(prtgAlertAfter) + ")")
        Else
          AddElement(devices())
          devices() = alerts\sensors()\device
        EndIf
      Next
      SortList(devices(),#PB_Sort_Ascending)
      ForEach devices()
        If devices() <> prev
          prev = devices()
        Else
          DeleteElement(devices())
        EndIf
      Next
      ForEach devices()
        msg + devices() + ", "
      Next
      msg = Left(msg,Len(msg)-2)
      If (prtgRepeatAlert Or msg <> oldmsg) And curAlerts > 0
        oldmsg = msg
        PostEvent(#prtgEvent,#wnd,0,#prtgMsg,@msg)
      Else
        PostEvent(#prtgEvent,#wnd,0,#prtgNomsg)
      EndIf
      prtgAlerts = curAlerts
      FreeJSON(#jsonPRTG)
      ClearStructure(@alerts,PRTGalerts)
      ClearList(devices())
    Else
      PostEvent(#prtgEvent,#wnd,0,#prtgFailed)
      ProcedureReturn
    EndIf
    Delay(time * 1000)
  ForEver
EndProcedure
; IDE Options = PureBasic 5.31 (Windows - x86)
; EnableUnicode
; EnableXP
; EnableBuildCount = 0