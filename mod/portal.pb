Structure portalMessageData
  id.i
  msg.s
  url.s
  priority.i
  ts.s
EndStructure

Structure portalMessages
  List messages.portalMessageData()
EndStructure

Procedure portalTry(n.i)
  Shared portalURL.s,portalLogin.s,portalPass.s,portalOpenAction.s,portalKey.s,portalLastActive.s
  portalOpenAction = "http://" + portalURL + "/msg"
  portalLastActive = "trying " + FormatDate("%dd.%mm.%yy %hh:%ii:%ss",Date())
  Delay(500)
  Protected res.s = simpleGetData("http://" + portalURL + "/msg/api/?auth&login=" + portalLogin + "&pass=" + portalPass)
  If res = "-1"
    PostEvent(#portalEvent,#wnd,0,#portalFailed)
  ElseIf res = "0"
    PostEvent(#portalEvent,#wnd,0,#portalFailedLogin)
  Else
    portalKey = res
    PostEvent(#portalEvent,#wnd,0,#portalOk)
  EndIf
EndProcedure

Procedure portalCheck(time.i)
  Shared portalURL.s,portalKey.s,portalAlerts.i,portalLastMsg.i,portalRepeatAlert.b,portalLastActive.s
  Protected dataURL.s,post.s,agent.s,curl.i,resData.s,msgData.portalMessages
  Shared portalMessages.message()
  dataURL = str2ansi("http://" + portalURL + "/msg/api/?getMessages")
  post = str2ansi("key=" + portalKey)
  agent = str2ansi(#myName + "/" + #myVer)
  Repeat
    portalLastActive = "checking " + FormatDate("%dd.%mm.%yy %hh:%ii:%ss",Date())
    toDebug("getting data from Portal...")
    curl = curl_easy_init()
    If curl
      curl_easy_setopt(curl,#CURLOPT_URL,@dataURL)
      curl_easy_setopt(curl,#CURLOPT_POSTFIELDS,@post)
      curl_easy_setopt(curl,#CURLOPT_USERAGENT,@agent)
      curl_easy_setopt(curl,#CURLOPT_WRITEFUNCTION,@RW_LibCurl_WriteFunction())
      curl_easy_setopt(curl,#CURLOPT_TIMEOUT,#curlTimeout)
      curl_easy_setopt(curl,#CURLOPT_FOLLOWLOCATION,1)
      curl_easy_setopt(curl,#CURLOPT_SSL_VERIFYPEER,0)
      curl_easy_setopt(curl,#CURLOPT_SSL_VERIFYHOST,0)
      curl_easy_perform(curl)
      resData = RW_LibCurl_GetData()
      curl_easy_cleanup(curl)
      If Left(resData,1) = "{" And Right(resData,1) = "}" And Len(resData) >= 15
        resData = uEscapedToString(resData)
        resData = ReplaceString(resData,#CR$,"")
        resData = ReplaceString(resData,#LF$,"")
        toDebug("Portal data: " + resData)
        If ParseJSON(#jsonPortal,resData,#PB_JSON_NoCase)
          ExtractJSONStructure(JSONValue(#jsonPortal),@msgData.portalMessages,portalMessages)
          portalAlerts = ListSize(msgData\messages())
          ClearList(portalMessages())
          If portalAlerts
            ForEach msgData\messages()
              If portalRepeatAlert Or msgData\messages()\id > portalLastMsg
                AddElement(portalMessages())
                If msgData\messages()\priority > 0
                  portalMessages()\title = "Важное сообщение на портале"
                Else
                  portalMessages()\title = "Новое сообщение на портале"
                EndIf
                portalMessages()\message = msgData\messages()\msg
              EndIf
            Next
            ForEach msgData\messages()
              If msgData\messages()\id > portalLastMsg
                portalLastMsg = msgData\messages()\id
              EndIf
            Next
            ClearList(msgData\messages())
            PostEvent(#portalEvent,#wnd,0,#portalMsg)
          Else
            PostEvent(#portalEvent,#wnd,0,#portalNomsg)
          EndIf
          FreeJSON(#jsonPortal)
        Else
          PostEvent(#portalEvent,#wnd,0,#portalFailed)
          ProcedureReturn
        EndIf
      ElseIf resData = "0"
        PostEvent(#portalEvent,#wnd,0,#portalFailed)
        ProcedureReturn
      Else
        PostEvent(#portalEvent,#wnd,0,#portalFailed)
        ProcedureReturn
      EndIf
    Else
      toDebug("can't init curl")
      PostEvent(#portalEvent,#wnd,0,#portalFailed)
      ProcedureReturn
    EndIf
    Delay(time * 1000)
  ForEver
EndProcedure
; IDE Options = PureBasic 5.31 (Windows - x86)
; EnableUnicode
; EnableXP
; EnableBuildCount = 0