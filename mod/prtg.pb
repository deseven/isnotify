
Procedure prtgTry(n.i)
  Shared prtgURL.s,prtgLogin.s,prtgPass.s,prtgKey.s,prtgOpenAction.s
  prtgOpenAction = "http://" + prtgURL + "/alarms.htm?filter_status=5&filter_status=4&filter_status=10&filter_status=13&filter_status=14"
  Protected res.s = getData("http://" + prtgURL + "/api/getpasshash.htm?username=" + prtgLogin + "&password=" + prtgPass)
  Delay(500)
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
  Shared prtgURL.s,prtgLogin.s,prtgKey.s,prtgAlerts.i
  Protected dataURL.s,res.s,curAlerts.i,msg.s,oldmsg.s,alerts.PRTGalerts,prev.s
  Protected NewList devices.s()
  dataURL = "http://" + prtgURL + "/api/table.json?content=sensors&output=json&columns=sensor,device&filter_status=5&username=" + prtgLogin + "&passhash=" + prtgKey
  Repeat
    toLog("getting data from PRTG...")
    res = getData(dataURL)
    msg = ""
    prev = ""
    curAlerts = 0
    If FindString(res,"Unauthorized")
      PostEvent(#prtgEvent,#wnd,0,#prtgFailedLogin)
      ProcedureReturn
    ElseIf ParseJSON(0,res,#PB_JSON_NoCase)
      ExtractJSONStructure(JSONValue(0),@alerts.PRTGalerts,PRTGalerts)
      curAlerts = alerts\treesize
      ForEach alerts\sensors()
        AddElement(devices())
        devices() = alerts\sensors()\device
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
      If msg <> oldmsg And curAlerts > 0
        oldmsg = msg
        PostEvent(#prtgEvent,#wnd,0,#prtgMsg,@msg)
      Else
        PostEvent(#prtgEvent,#wnd,0,#prtgNomsg)
      EndIf
      prtgAlerts = curAlerts
      FreeJSON(0)
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