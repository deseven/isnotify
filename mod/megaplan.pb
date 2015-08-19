Structure megaplanContentAuthor
  Id.i
  Name.s
EndStructure

Structure megaplanContentSubject
  Id.i
  Name.s
  Type.s
EndStructure

Structure megaplanContent
  Subject.megaplanContentSubject
  Text.s
  Author.megaplanContentAuthor
EndStructure

Structure megaplanSubject
  Id.i
  Type.s
EndStructure

Structure megaplanNotification
  Id.i
  Subject.megaplanSubject
  Content.s
  ContentComment.megaplanContent
  TimeCreated.s
  Name.s
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

Import "..\lib\libmegaplan.lib"
  mega_comparedates(date1.s,date2.s)
  mega_auth(login.s,password.s,base_url.s,agent.s = #myName + "/" + #myVer)
  mega_query(access_id.s,secret_key.s,query.s,base_url.s,timezone.s,agent.s = #myName + "/" + #myVer)
EndImport

Procedure.s uEscapedToString(string$) ;can be compiled as both ASCII and Unicode
  Protected len, pos, hex$, result$, unicode.c, char$, uChar$ = Space(1)
  len = Len(string$)
  For pos=1 To len
    char$ = Mid(string$,pos,1)
    If char$ = "\" And Mid(string$,pos+1,1) = "u"
      hex$ = Mid(string$,pos+2,4)
      If #PB_Compiler_Unicode=#False And Left(hex$,2) <> "00" ;this char can't fit within the extended ASCII table
        result$ + "?"
      Else
        unicode = Val("$"+hex$) ;the returned quad truncates fine
        PokeC(@uChar$,unicode)
        result$ + uChar$
      EndIf
      pos + 5
    Else
      result$ + char$
    EndIf
  Next
  ProcedureReturn result$
EndProcedure

Procedure megaplanTry(n.i)
  Shared megaplanURL.s,megaplanLogin.s,megaplanPass.s,megaplanKey.s,megaplanAccess.s,megaplanOpenAction.s
  Protected query.s,resData.s,auth.megaplanAuth
  Protected *resData
  megaplanOpenAction = "http://" + megaplanURL + "/activity/"
  query = "/BumsCommonApiV01/User/authorize.api"
  Delay(500)
  *resData = mega_auth(str2ansi(megaplanLogin),str2ansi(megaplanPass),str2ansi(megaplanURL))
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
    If ParseJSON(1,resData,#PB_JSON_NoCase)
      ExtractJSONStructure(JSONValue(1),@auth.megaplanAuth,megaplanAuth)
      megaplanKey = auth\mdata("SecretKey")
      megaplanAccess = auth\mdata("AccessId")
      ;Debug megaplanAccess + "/" + megaplanKey
      FreeJSON(1)
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
  Shared megaplanURL.s,megaplanLogin.s,megaplanKey.s,megaplanAccess.s,megaplanAlerts.i,megaplanLastMsg.i,megaplanRepeatAlert.b
  Protected query.s,resData.s,resHTTP.w,queryRes.megaplanQuery,curAlerts.i,tz.s
  Shared megaplanMessages.megaplanMessage()
  Protected *resData
  Repeat
    tz = getTimezone()
    toLog("getting data from Megaplan [" + tz + "]...")
    query = "/BumsCommonApiV01/Informer/notifications.api?Group=1"
    *resData = mega_query(str2ansi(megaplanAccess),str2ansi(megaplanKey),str2ansi(query),str2ansi(megaplanURL),str2ansi(tz))
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
    If resData = "-1"
      PostEvent(#megaplanEvent,#wnd,0,#megaplanFailed)
      ProcedureReturn
    ElseIf resData = "0"
      PostEvent(#megaplanEvent,#wnd,0,#megaplanFailed)
      ProcedureReturn
    Else
      resData = ReplaceString(resData,#DQUOTE$ + "data" + #DQUOTE$ + ":{",#DQUOTE$ + "mdata" + #DQUOTE$ + ":{")
      resData = uEscapedToString(resData)
      resData = ReplaceString(resData,#DQUOTE$ + "Content" + #DQUOTE$ + ":{" + #DQUOTE$,#DQUOTE$ + "ContentComment" + #DQUOTE$ + ":{" + #DQUOTE$)
      Debug resData
      If ParseJSON(1,resData,#PB_JSON_NoCase)
        ExtractJSONStructure(JSONValue(1),@queryRes.megaplanQuery,megaplanQuery)
        megaplanAlerts = ListSize(queryRes\mdata\notifications())
        ClearList(megaplanMessages())
        ForEach queryRes\mdata\notifications()
          If megaplanRepeatAlert Or queryRes\mdata\notifications()\Id > megaplanLastMsg
            AddElement(megaplanMessages())
            megaplanMessages()\title = queryRes\mdata\notifications()\Name
            If Len(queryRes\mdata\notifications()\ContentComment\Subject\Name)
              megaplanMessages()\message = "Задача " + #DQUOTE$ + queryRes\mdata\notifications()\ContentComment\Subject\Name + #DQUOTE$ + ", " + queryRes\mdata\notifications()\ContentComment\Author\Name + ":" + #CRLF$ + queryRes\mdata\notifications()\ContentComment\Text
            Else
              megaplanMessages()\message = queryRes\mdata\notifications()\Content
            EndIf
          EndIf
        Next
        ForEach queryRes\mdata\notifications()
          If queryRes\mdata\notifications()\Id > megaplanLastMsg
            megaplanLastMsg = queryRes\mdata\notifications()\Id
          EndIf
        Next
        FreeJSON(1)
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