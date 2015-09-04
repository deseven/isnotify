Structure megaplanContentAuthor
  id.i
  name.s
EndStructure

Structure megaplanContentSubject
  id.i
  name.s
  type.s
EndStructure

Structure megaplanContent
  subject.megaplanContentSubject
  text.s
  author.megaplanContentAuthor
EndStructure

Structure megaplanSubject
  id.i
  type.s
EndStructure

Structure megaplanNotification
  id.i
  subject.megaplanSubject
  content.s
  contentComment.megaplanContent
  timeCreated.s
  name.s
EndStructure

Structure megaplanNotifications
  List notifications.megaplanNotification()
EndStructure

Structure megaplanAuth
  Map status.s()
  Map mdata.s()
EndStructure

Structure megaplanQuery
  Map status.s()
  mdata.megaplanNotifications
EndStructure

Structure megaplanTask
  id.i
  Name.s
  Status.s
  Deadline.s
  Owner.s
  responsible.s
  favorite.s
  timeCreated.s
  message.s
EndStructure

Structure megaplanProject
  id.i
  Name.s
  Status.s
  Deadline.s
  Owner.s
EndStructure

Structure megaplanApprovals
  List tasks.megaplanTask()
  List projects.megaplanTask()
EndStructure

Structure megaplanQueryApp
  Map status.s()
  mdata.megaplanApprovals
EndStructure

Import "..\lib\libmegaplan.lib"
  mega_comparedates(date1.s,date2.s)
  mega_auth(login.s,password.s,base_url.s,agent.s = #myName + "/" + #myVer)
  mega_query(access_id.s,secret_key.s,query.s,base_url.s,timezone.s,agent.s = #myName + "/" + #myVer)
EndImport

Procedure megaplanTry(n.i)
  Shared megaplanURL.s,megaplanLogin.s,megaplanPass.s,megaplanKey.s,megaplanAccess.s,megaplanOpenAction.s,megaplanLastActive.s
  Protected query.s,resData.s,auth.megaplanAuth
  Protected *resData
  megaplanLastActive = "trying " + FormatDate("%dd.%mm.%yy %hh:%ii:%ss",Date())
  megaplanOpenAction = "http://" + megaplanURL + "/activity/"
  query = "/BumsCommonApiV01/User/authorize.api"
  Delay(500)
  Shared globalCurlLock.i
  LockMutex(globalCurlLock)
  *resData = mega_auth(str2ansi(megaplanLogin),str2ansi(megaplanPass),str2ansi(megaplanURL))
  UnlockMutex(globalCurlLock)
  If *resData
    resData = PeekS(*resData,-1,#PB_UTF8)
    If Not Len(resData)
      PostEvent(#megaplanEvent,#wnd,0,#megaplanFailed)
      ProcedureReturn
    EndIf
  Else
    PostEvent(#megaplanEvent,#wnd,0,#megaplanFailed)
    ProcedureReturn
  EndIf
  If resData = "-1"
    PostEvent(#megaplanEvent,#wnd,0,#megaplanFailed)
  ElseIf resData = "0"
    PostEvent(#megaplanEvent,#wnd,0,#megaplanFailedLogin)
  Else
    resData = ReplaceString(resData,#DQUOTE$ + "data" + #DQUOTE$ + ":{",#DQUOTE$ + "mdata" + #DQUOTE$ + ":{")
    If ParseJSON(#jsonMegaplan,resData,#PB_JSON_NoCase)
      ExtractJSONStructure(JSONValue(#jsonMegaplan),@auth.megaplanAuth,megaplanAuth)
      megaplanKey = auth\mdata("SecretKey")
      megaplanAccess = auth\mdata("AccessId")
      FreeJSON(#jsonMegaplan)
      If Len(megaplanKey) And Len(megaplanAccess)
        PostEvent(#megaplanEvent,#wnd,0,#megaplanOk)
      Else
        PostEvent(#megaplanEvent,#wnd,0,#megaplanFailed)
      EndIf
    Else
      PostEvent(#megaplanEvent,#wnd,0,#megaplanFailed)
    EndIf
  EndIf
EndProcedure

Procedure megaplanCheck(time.i)
  Shared megaplanURL.s,megaplanLogin.s,megaplanKey.s,megaplanAccess.s,megaplanAlerts.i,megaplanLastMsg.i,megaplanRepeatAlert.b,megaplanLastActive.s
  Protected query.s,resData.s,resHTTP.w,queryRes.megaplanQuery,queryAppRes.megaplanQueryApp,curAlerts.i,tz.s
  Shared megaplanMessages.message()
  Protected *resData
  Shared globalCurlLock.i
  Repeat
    megaplanLastActive = "checking " + FormatDate("%dd.%mm.%yy %hh:%ii:%ss",Date())
    tz = getTimezone()
    toDebug("getting data from Megaplan [" + tz + "]...")
    query = "/BumsCommonApiV01/Informer/notifications.api"
    LockMutex(globalCurlLock)
    *resData = mega_query(str2ansi(megaplanAccess),str2ansi(megaplanKey),str2ansi(query),str2ansi(megaplanURL),str2ansi(tz))
    UnlockMutex(globalCurlLock)
    If *resData
      resData = PeekS(*resData,-1,#PB_UTF8)
      If Not Len(resData)
        PostEvent(#megaplanEvent,#wnd,0,#megaplanFailed)
        ProcedureReturn
      EndIf
    Else
      PostEvent(#megaplanEvent,#wnd,0,#megaplanFailed)
      ProcedureReturn
    EndIf
    ;PostEvent(#megaplanEvent,#wnd,0,#megaplanFailed)
    ;ProcedureReturn
    If resData = "-1" Or resData = "0"
      PostEvent(#megaplanEvent,#wnd,0,#megaplanFailed)
      ProcedureReturn
    Else
      resData = ReplaceString(resData,#DQUOTE$ + "data" + #DQUOTE$ + ":{",#DQUOTE$ + "mdata" + #DQUOTE$ + ":{")
      resData = uEscapedToString(resData)
      resData = ReplaceString(resData,#DQUOTE$ + "Content" + #DQUOTE$ + ":{" + #DQUOTE$,#DQUOTE$ + "ContentComment" + #DQUOTE$ + ":{" + #DQUOTE$)
      resData = ReplaceString(resData,#CR$,"")
      resData = ReplaceString(resData,#LF$,"")
      toDebug("Megaplan data: " + resData)
      If ParseJSON(#jsonMegaplan,resData,#PB_JSON_NoCase)
        ExtractJSONStructure(JSONValue(#jsonMegaplan),@queryRes.megaplanQuery,megaplanQuery)
        megaplanAlerts = ListSize(queryRes\mdata\notifications())
        ClearList(megaplanMessages())
        ForEach queryRes\mdata\notifications()
          If megaplanRepeatAlert Or queryRes\mdata\notifications()\Id > megaplanLastMsg
            AddElement(megaplanMessages())
            megaplanMessages()\title = queryRes\mdata\notifications()\name
            megaplanMessages()\title = ReplaceString(megaplanMessages()\title,"&quot;",#DQUOTE$)
            If Len(queryRes\mdata\notifications()\ContentComment\Subject\Name)
              megaplanMessages()\message = "Задача " + #DQUOTE$ + queryRes\mdata\notifications()\ContentComment\Subject\Name + #DQUOTE$ + ", " + queryRes\mdata\notifications()\ContentComment\Author\Name + ":" + #CRLF$ + queryRes\mdata\notifications()\ContentComment\Text
            Else
              megaplanMessages()\message = queryRes\mdata\notifications()\Content
            EndIf
            megaplanMessages()\message = ReplaceString(megaplanMessages()\message,"&quot;",#DQUOTE$)
          EndIf
        Next
        ForEach queryRes\mdata\notifications()
          If queryRes\mdata\notifications()\Id > megaplanLastMsg
            megaplanLastMsg = queryRes\mdata\notifications()\Id
          EndIf
        Next
        FreeJSON(#jsonMegaplan)
        If ListSize(queryRes\mdata\notifications()) : ClearList(queryRes\mdata\notifications()) : EndIf
        If megaplanAlerts > 0
          PostEvent(#megaplanEvent,#wnd,0,#megaplanMsg)
        Else
          PostEvent(#megaplanEvent,#wnd,0,#megaplanNomsg)
        EndIf
      Else
        PostEvent(#megaplanEvent,#wnd,0,#megaplanFailed)
        ProcedureReturn
      EndIf
    EndIf
    Delay(time * 1000)
  ForEver
EndProcedure
; IDE Options = PureBasic 5.31 (Windows - x86)
; EnableUnicode
; EnableXP
; EnableBuildCount = 0