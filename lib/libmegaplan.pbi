#ver = "libmegaplan/1.2"
#curlTimeout = 30

IncludeFile "libcurl-res.pbi"
IncludeFile "libcurl-inc.pbi"

EnableExplicit

Procedure.s hmac_sha1(SecretAccessKey.s,StringToSign.s)
  Protected x.i,xx.i,ipad.s,opad.s,one.s,two.s,out.s
  Protected *ipadt,*opadt
  If(Len(SecretAccessKey) > 64)
    SecretAccessKey = SHA1Fingerprint(@SecretAccessKey, Len(SecretAccessKey))

    For x = 1 To 20
      PokeB(@SecretAccessKey + x - 1, Val("$" + Mid(SecretAccessKey, (x * 2) - 1, 2)))
    Next

    For x = 20 To Len(SecretAccessKey)
      PokeB(@SecretAccessKey + x, 0)
    Next
  EndIf
  SecretAccessKey = LSet(SecretAccessKey, 64, Chr(0))
  ipad.s = LSet(ipad, 64, Chr($36))
  opad.s = LSet(opad, 64, Chr($5C))
  *ipadt = AllocateMemory(64 + Len(StringToSign))
  *opadt = AllocateMemory(64 + 20)
  PokeS(*ipadt,ipad,64)
  PokeS(*opadt,opad,64)

  For x = 1 To 64
    PokeB(*opadt + x - 1, Asc(Mid(opad, x, 1)) ! Asc(Mid(SecretAccessKey, x, 1)))
    PokeB(*ipadt + x - 1, Asc(Mid(ipad, x, 1)) ! Asc(Mid(SecretAccessKey, x, 1)))
  Next
  PokeS(*ipadt + 64, StringToSign, Len(StringToSign))
  one.s = SHA1Fingerprint(*ipadt, MemorySize(*ipadt))

  For x = 64 To 84
    xx + 1
    PokeB(*opadt + x, Val("$" + Mid(one, (xx * 2) - 1, 2)))
  Next
  two.s = SHA1Fingerprint(*opadt, 64 + 20)
  
  out.s = Space(StringByteLength(two)*1.35)
  
  Debug two
  Base64Encoder(@two,StringByteLength(two),@out,StringByteLength(out))
  
  ;FreeMemory(*ipadt) : FreeMemory(*opadt)
  
  ProcedureReturn out.s
EndProcedure

ProcedureDLL.b mega_comparedates(str1.s,str2.s)
  Protected date1.s,time1.s,date2.s,time2.s
  Protected.i date1yyyy,date1mm,date1dd,time1hh,time1mm,time1ss
  Protected.i date2yyyy,date2mm,date2dd,time2hh,time2mm,time2ss
  
  date1.s = StringField(str1,1," ")
  time1.s = StringField(str1,2," ")
  date2.s = StringField(str2,1," ")
  time2.s = StringField(str2,2," ")
  
  date1yyyy = Val(StringField(date1,1,"-"))
  date1mm = Val(StringField(date1,3,"-"))
  date1dd = Val(StringField(date1,2,"-"))
  
  time1hh = Val(StringField(time1,1,":"))
  time1mm = Val(StringField(time1,2,":"))
  time1ss = Val(StringField(time1,3,":"))
  
  date2yyyy = Val(StringField(date2,1,"-"))
  date2mm = Val(StringField(date2,3,"-"))
  date2dd = Val(StringField(date2,2,"-"))
  
  time2hh = Val(StringField(time2,1,":"))
  time2mm = Val(StringField(time2,2,":"))
  time2ss = Val(StringField(time2,3,":"))
  
  If date1yyyy < date2yyyy
    ProcedureReturn #True
  Else
    If date1mm < date2mm
      ProcedureReturn #True
    Else
      If date1dd < date2dd
        ProcedureReturn #True
      Else
        If time1hh < time2hh
          ProcedureReturn #True
        Else
          If time1mm < time2mm
            ProcedureReturn #True
          Else
            If time1ss < time2ss
              ProcedureReturn #True
            EndIf
          EndIf
        EndIf
      EndIf
    EndIf
  EndIf
  
  ProcedureReturn #False

EndProcedure

Procedure.s getTimestamp(now.l,timezone.s)
  Define day.s,month.s,TimeStamp.s
  Select DayOfWeek(now)
    Case 0
      day = "Sun"
    Case 1
      day = "Mon"
    Case 2
      day = "Tue"
    Case 3
      day = "Wed"
    Case 4
      day = "Thu"
    Case 5
      day = "Fri"
    Case 6
      day = "Sat"
    Default
      day = "NaN"
  EndSelect
  Select FormatDate("%mm",now)
    Case "01"
      month = "Jan"
    Case "02"
      month = "Feb"
    Case "03"
      month = "Mar"
    Case "04"
      month = "Apr"
    Case "05"
      month = "May"
    Case "06"
      month = "Jun"
    Case "07"
      month = "Jul"
    Case "08"
      month = "Aug"
    Case "09"
      month = "Sep"
    Case "10"
      month = "Oct"
    Case "11"
      month = "Nov"
    Case "12"
      month = "Dec"
    Default
      month = "NaN"
  EndSelect
  TimeStamp.s = day  + FormatDate(", %dd ",now) + month + FormatDate(" %yyyy %hh:%ii:%ss ",now) + timezone
  ProcedureReturn TimeStamp.s
EndProcedure

ProcedureDLL.s mega_auth(login.s,password.s,base_url.s,agent.s = #ver)
  Protected curl.i,url.s,post.s,res.b,resData.s,resHTTP.w
  url = "https://" + base_url + "/BumsCommonApiV01/User/authorize.api"
  post = "Login=" + login + "&Password=" + MD5Fingerprint(@password,StringByteLength(password))
  curl = curl_easy_init()
  If curl
    curl_easy_setopt(curl,#CURLOPT_URL,@url)
    curl_easy_setopt(curl,#CURLOPT_USERAGENT,@agent)
    curl_easy_setopt(curl,#CURLOPT_POSTFIELDS,@post)
    curl_easy_setopt(curl,#CURLOPT_WRITEFUNCTION,@RW_LibCurl_WriteFunction())
    curl_easy_setopt(curl,#CURLOPT_TIMEOUT,#curlTimeout)
    curl_easy_setopt(curl,#CURLOPT_FOLLOWLOCATION,1)
    curl_easy_setopt(curl,#CURLOPT_SSL_VERIFYPEER,0)
    curl_easy_setopt(curl,#CURLOPT_SSL_VERIFYHOST,0)
    res = curl_easy_perform(curl)
    resData = RW_LibCurl_GetData()
    curl_easy_getinfo(curl,#CURLINFO_RESPONSE_CODE,@resHTTP)
    curl_easy_cleanup(curl)
    Debug res
    If res = 0
      If resHTTP <> 403 And resHTTP <> 401 
        ProcedureReturn resData
      Else
        ProcedureReturn "0"
      EndIf
    Else
      ProcedureReturn "-1"
    EndIf
  Else
    ProcedureReturn "-1"
  EndIf
EndProcedure

ProcedureDLL.s mega_query(access_id.s,secret_key.s,query.s,base_url.s,timezone.s,agent.s = #ver)
  Protected curl.i,url.s,res.b,resData.s,resHTTP.w,now.l,signature.s,*Headers
  curl = curl_easy_init()
  If curl
    
    now = Date()
    
    signature = "GET" + #LF$ + #LF$ + #LF$ + GetTimestamp(now,timezone) + #LF$ + base_url + query
    ;secret_key = PeekS(str2curl(secret_key),-1,#PB_Ascii)
    ;signature = PeekS(str2curl(signature),-1,#PB_Ascii)
    ;Debug signature
    signature = hmac_sha1(secret_key,signature)
    url = "https://" + base_url + query
    curl_easy_setopt(curl,#CURLOPT_URL,@url)
    curl_easy_setopt(curl,#CURLOPT_USERAGENT,@agent)
    curl_easy_setopt(curl,#CURLOPT_WRITEFUNCTION,@RW_LibCurl_WriteFunction())
    curl_easy_setopt(curl,#CURLOPT_TIMEOUT,#curlTimeout)
    curl_easy_setopt(curl,#CURLOPT_FOLLOWLOCATION,1)
    curl_easy_setopt(curl,#CURLOPT_SSL_VERIFYPEER,0)
    curl_easy_setopt(curl,#CURLOPT_SSL_VERIFYHOST,0)
    
    *Headers = curl_slist_append(*Headers,"Date: " + getTimestamp(now,timezone))
    *Headers = curl_slist_append(*Headers,"X-Authorization: " + access_id + ":" + signature)
    *Headers = curl_slist_append(*Headers,"Accept: application/json")
    curl_easy_setopt(curl,#CURLOPT_HTTPHEADER,*Headers)
    ;Debug "Date: " + getTimestamp(now,timezone)
    ;Debug "X-Authorization: " + access_id + ":" + signature
    
    ; running query
    res = curl_easy_perform(curl)
    curl_easy_getinfo(curl,#CURLINFO_RESPONSE_CODE,@resHTTP)
    curl_slist_free_all(*Headers)
    curl_easy_cleanup(curl)
    
    If res = 0
      If resHTTP <> 403 And resHTTP <> 401 
        ProcedureReturn RW_LibCurl_GetData()
      Else
        ;Debug resHTTP
        ;Debug RW_LibCurl_GetData()
        ProcedureReturn "0"
      EndIf
    Else
      ProcedureReturn "-1"
    EndIf
  Else
    ProcedureReturn "-1"
  EndIf
EndProcedure

; IDE Options = PureBasic 5.31 (Windows - x86)
; EnableUnicode
; EnableXP
; EnableBuildCount = 0