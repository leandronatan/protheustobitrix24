#INCLUDE "PROTHEUS.CH"

CLASS Bitrix24_Webhook

	DATA cCodEnt
	DATA cNomEnt
	DATA cCodMet
	DATA cNomMet
	DATA cCodWeb
	DATA cItmWeb
	DATA cURL	  
	DATA cPath
	DATA cDescWeb
	DATA cReqType
	DATA cMthCall
	DATA lValid  
	DATA cJSON
	
	DATA lSendOK
	DATA cResult
	DATA cLastError
	DATA cStatusCode
	DATA cReason	
	DATA cMethod
		
	METHOD New(cCodEnt,cCodMet,cCodWeb,cMethod) CONSTRUCTOR	
	METHOD IsValid()    
	METHOD SetJSON(cJSON)
	METHOD CallMethod()
	METHOD GetReturn()
	METHOD GetError()
	
ENDCLASS             
                                
METHOD New(cCodEnt,cCodMet,cCodWeb,cMethod) CLASS Bitrix24_Webhook

	DEFAULT cCodEnt := ""
	DEFAULT cCodMet := ""
	DEFAULT cCodWeb := ""
	DEFAULT cMethod := ""
               	
	::cCodEnt     := ""
	::cNomEnt     := ""
	::cCodMet     := ""
	::cNomMet     := ""
	::cCodWeb     := ""
	::cItmWeb     := ""
	::cURL        := ""
	::cPath       := ""
	::cDescWeb    := ""
	::cReqType    := ""
	::cMthCall    := ""
	::lValid      := .F.
	::cJSON       := ""	
	::lSendOK     := .F.
	::cResult     := ""
	::cLastError  := ""
	::cStatusCode := ""
	::cReason     := ""	
	::cMethod     := ""
		
	DbSelectArea("ZH1")
	ZH1->(DbSetOrder(1))

	DbSelectArea("ZH2")
	ZH2->(DbSetOrder(1))
	
	DbSelectArea("ZH4")
	ZH4->(DbSetOrder(2))
	
	If ZH1->(DbSeek(xFilial("ZH1")+cCodEnt))
		If ZH2->(DbSeek(xFilial("ZH2")+cCodEnt+cCodMet))
			If ZH4->(DbSeek(xFilial("ZH4")+cCodWeb))					
				If AllTrim(cMethod) $ "POST/GET/PUT/DELETE"				
					::lValid   := .T.				
					::cCodEnt  := AllTrim(ZH1->ZH1_CODIGO)
					::cNomEnt  := AllTrim(ZH1->ZH1_ENTIDA)
					::cCodMet  := AllTrim(ZH2->ZH2_ITEM)
					::cNomMet  := AllTrim(ZH2->ZH2_METODO)
					::cCodWeb  := AllTrim(ZH4->ZH4_CODIGO)
					::cItmWeb  := AllTrim(ZH4->ZH4_ITEM)
					::cURL     := AllTrim(ZH4->ZH4_URL)
					::cPath    := AllTrim(ZH4->ZH4_PATH)
					::cReqType := AllTrim(ZH4->ZH4_REQTYP)
					::cDescWeb := AllTrim(ZH4->ZH4_DESC)
					::cMthCall := ::cPath + ::cNomMet + "." + ::cReqType
					::cMethod  := AllTrim(cMethod)				
				EndIf				
			EndIf
		EndIf	
	EndIf   
		
Return Self
             
METHOD IsValid() CLASS Bitrix24_Webhook
Return ::lValid   

METHOD SetJSON(cJSON) CLASS Bitrix24_Webhook

	Local oVldJSON := Nil
	Local cMsgErro := ""
	Local lReturn  := .F.

	cJSON := EncodeUTF8(cJSON) 

	oVldJSON := JSONObject():New()	
	cMsgErro := oVldJSON:FromJson(cJSON)
	
	If ValType(cMsgErro) == "C"
		Conout("[Bitrix24_Conexao_Saida] - Falha na validacao do JSON: " + cMsgErro)
	Else
		::cJSON := cJSON //EncodeUTF8(cJSON)
		lReturn := .F.
	EndIf
	
Return lReturn

METHOD CallMethod() CLASS Bitrix24_Webhook

	Local oRest   := Nil
	Local aHeader := {}
	Local lReturn := .F. 

	If ::lValid .AND. !Empty(::cJSON)
					
	    AAdd(aHeader, "Content-Type: application/json")
	    //AAdd(aHeader, "charset: UTF-8")
	
		oRest := FWRest():New(::cURL)
		oRest:SetPath(::cMthCall)  
		oRest:SetPostParams(::cJSON)
		oRest:nTimeOut := 30
	
		If oRest:Post(aHeader)
			::lSendOK := .T.
		EndIf
					
		::cResult     := AllTrim(oRest:GetResult())
		::cLastError  := AllTrim(oRest:GetLastError())
		::cStatusCode := AllTrim(oRest:oResponseH:cStatusCode)
		::cReason     := AllTrim(oRest:oResponseH:cReason)
		
		If ::lSendOK .AND. ::cStatusCode == "200"
			lReturn := .T.
		EndIf
		
	EndIf
	
Return lReturn

METHOD GetReturn() CLASS Bitrix24_Webhook
Return ::cResult

METHOD GetError() CLASS Bitrix24_Webhook
Return ::cLastError