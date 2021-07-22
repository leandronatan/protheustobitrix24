#INCLUDE "PROTHEUS.CH"

//-----------------------------------------
// Methods position
//-----------------------------------------
#DEFINE POS_cMethod   1
#DEFINE POS_cItem     2
#DEFINE POS_cOption   3
#DEFINE POS_cHasID    4
#DEFINE POS_cHTTP_Req 5
#DEFINE POS_cDescri   6
//-----------------------------------------

CLASS Bitrix24_CRM_ENTITIES_COMPANIES FROM Bitrix24_CRM_ENTITIES

	DATA lCheckCGCDupl 
	DATA cBitrix24_ID

	METHOD New() CONSTRUCTOR	
	METHOD addCompany()
	METHOD deleteCompany()
	METHOD fieldsCompany()
	METHOD getCompany()
	METHOD listCompany()
	METHOD updateCompany()
	METHOD checkDuplicate(lOption)
	METHOD getBitrixID()
				
ENDCLASS
                                
METHOD New() CLASS Bitrix24_CRM_ENTITIES_COMPANIES
	_Super:New("crm.company")
	::lCheckCGCDupl := .T. //Check for A1_CGC duplicated before adding a new company
	::cBitrix24_ID  := ""
	::oJSON := Bitrix24_CRM_JSON():New()
Return Self

METHOD checkDuplicate(lOption) CLASS Bitrix24_CRM_ENTITIES_COMPANIES
	::lCheckDupl := lOption
Return


METHOD addCompany() CLASS Bitrix24_CRM_ENTITIES_COMPANIES
		
	Local oScheduler := Nil
	Local oJSONResp  := Nil
	Local cCGCField  := ""
	Local cCGCFilter := ""
	Local cLine      := ""	
	Local cID        := ""
	Local lReturn    := .F.
	
	If ::lUseScheduler	
		oScheduler := Bitrix24_CRM_SCHEDULER():New()
		oScheduler:oEntity := Self
		oScheduler:cOption := "add"
		oScheduler:Save()			
	Else		
		If ::lCheckCGCDupl		
			cCGCField  := "?" + Self:BTX_FieldName("A1_CGC")
			cCGCFilter := cCGCFilter(Self:ERP_FieldGet("A1_CGC"))
			//Search for duplicated companies using CPF/CNPJ field
			//If mutiple results are found, update the oldest entry only						
			If Self:listCompany({"*","UF_*"},{{cCGCField,cCGCFilter}},{{"DATE_CREATE","ASC"}})	
				cLine := Self:oJSON:readLine()				
				oJSONResp := JSONObject():New()
				oJSONResp:FromJSON(cLine)
				If oJSONResp:hasProperty("ID") 
					cID := oJSONResp["ID"]							
					FreeObj(oJSONResp)
					If !Empty(cID)
						Self:oJSON:Clean()
						Self:oJSON:cID   := cID
						Self:oJSON:cData := '{ "id": "'+cID+'","fields":'+Self:ToJSON()+'}'						
						If Self:callMethod("update")
							oJSONResp := JSONObject():New()
							oJSONResp:FromJSON(Self:oJSON:cReturn)
							If oJSONResp:hasProperty('result') .AND. ValType(oJSONResp['result']) == "L" .AND. oJSONResp['result'] == .T.
								::cBitrix24_ID := cID
								lReturn := .T.
							EndIf
							FreeObj(oJSONResp)						
						EndIf
					EndIf
				EndIf									
			Else
				::oJSON:Clean()
				::oJSON:cData := '{ "fields" : ' + Self:ToJSON() + '}'
				If Self:callMethod("add")                
					oJSONResp := JSONObject():New()
					oJSONResp:FromJSON(::oJSON:cReturn)
					If oJSONResp:hasProperty('result') .AND. ValType(oJSONResp['result']) == "N"
						::oJSON:cID := cValToChar(oJSONResp["result"])
						::cBitrix24_ID := cValToChar(oJSONResp["result"])
						lReturn := .T.				
					EndIf
					FreeObj(oJSONResp)
				EndIf
			EndIf			
		Else
			::oJSON:Clean()
			::oJSON:cData := '{ "fields" : ' + Self:ToJSON() + '}'
			If Self:callMethod("add")                
				oJSONResp := JSONObject():New()
				oJSONResp:FromJSON(::oJSON:cReturn)
				If oJSONResp:hasProperty('result') .AND. ValType(oJSONResp['result']) == "N"
					::oJSON:cID := cValToChar(oJSONResp["result"])
					::cBitrix24_ID := cValToChar(oJSONResp["result"])
					lReturn := .T.				
				EndIf
				FreeObj(oJSONResp)
			EndIf
		EndIf	
	EndIf
	
Return lReturn
                    
Static Function RemCGCMask(cCGC)
                      
	Local cReturn := ""
	Local cChar   := ""
	Local nI := 0
	
	For nI := 1 To Len(cCGC)
		cChar := SubStr(cCGC,nI,1)
		If cChar $ "1234567890"
			cReturn += cChar
		EndIf
	Next nI

Return cReturn
           
Static Function cCGCFilter(cCGC)

	Local aMaskCNPJ := {}
	Local aMaskCPF  := {}
	Local aMask     := {}
	Local cFilter   := ""
	Local cReturn   := ""
	Local nI  := 0 
	
	aMaskCNPJ := { "@R 99.999.999/9999-99","@R 99999.999/9999-99","@R 99999999/9999-99","@R 999999999999-99",;
				   "@R 99999999999999",    "@R 99.999999999999",  "@R 99.999.999999999","@R 99.999.999/999999",;
				   "@R 99999.999999999",   "@R 99999999/999999",  "@R 999999999999-99"}
                   
	aMaskCPF := { "@R 999.999.999-99","@R 999999.999-99","@R 999999999-99", "@R 99999999999",;
				  "@R 999.99999999",  "@R 999.999.99999","@R 999999.99999"}

	cCGC := RemCGCMask(cCGC)
	aMask := IIF(Len(cCGC) == 14,aMaskCNPJ,aMaskCPF)
		
	For nI := 1 To Len(aMask)
		cFilter += Transform(cCGC,aMask[nI])
		If nI < Len(aMask)
			cFilter +=  + " | "		
		EndIf
	Next nI    
	
	cReturn := cFilter

Return cReturn

METHOD deleteCompany() CLASS Bitrix24_CRM_ENTITIES_COMPANIES
//Not implemented yet
//Return Self:callMethod("delete")
Return .F.

METHOD fieldsCompany() CLASS Bitrix24_CRM_ENTITIES_COMPANIES
//Not implemented yet
//Return Self:callMethod("fields")
Return .F.

METHOD getCompany() CLASS Bitrix24_CRM_ENTITIES_COMPANIES
//Not implemented yet
//Return Self:callMethod("get")
Return .F.

METHOD listCompany(aFields,aFilter,aOrder) CLASS Bitrix24_CRM_ENTITIES_COMPANIES
                             
	Local cJSONEnv    := ""		
	Local oJSONRoot   := Nil
	Local oJSONFilter := Nil
	Local oJSONOrder  := Nil	
	Local lReturn     := .F.	
	Local nI := 0
	
	DEFAULT aFields := {}
	DEFAULT aFilter := {}
	DEFAULT aOrder  := {}

	If Empty(aFields)
		aFields := {"*","UF_*"}
	EndIf
		
	oJSONFilter := JSONObject():New()
	If Empty(aFilter)
		oJSONFilter['TITLE'] := "" 
	Else	
	    For nI := 1 To Len(aFilter)
			oJSONFilter[aFilter[nI][1]] := aFilter[nI][2]
	    Next nI
    EndIf

	oJSONOrder := JSONObject():New()
	If Empty(aOrder)
		oJSONOrder['ID'] := "ASC"	
	Else
	    For nI := 1 To Len(aOrder)
			oJSONOrder[aOrder[nI][1]] := aOrder[nI][2]
	  	Next nI
  	EndIf

	oJSONRoot := JSONObject():New()	
	oJSONRoot['select'] := aFields
	oJSONRoot['filter'] := oJSONFilter
	oJSONRoot['order']  := oJSONOrder	
	cJSONEnv := oJSONRoot:toJSON()
		
	::oJSON:Clean()
	::oJSON:cData := cJSONEnv
	
	If Self:callMethod("list") .AND. ::oJSON:ToDataSet("result")
		If !Empty(::oJSON:aDataSet)
			lReturn := .T.
		EndIf
	EndIf

	FreeObj(oJSONFilter)
	FreeObj(oJSONOrder)
	FreeObj(oJSONRoot)
		
Return lReturn

METHOD updateCompany(cUniverID,cType) CLASS Bitrix24_CRM_ENTITIES_COMPANIES

	Local oJSONResp := Nil
	Local cField    := ""
	Local cContent  := ""
	Local cLine     := ""
	Local cID       := ""
	Local lReturn   := .F.
		
	DEFAULT cType := ""
	
	If Empty(cType) .OR. Upper(AllTrim(cType)) == "BTX"
		//---------------------------------------------------------------------------
		// Use Bitrix ID Field (best way)
		//---------------------------------------------------------------------------
		Self:oJSON:Clean()
		Self:oJSON:cID   := AllTrim(cUniverID)
		Self:oJSON:cData := '{ "id": "'+AllTrim(cUniverID)+'","fields":'+Self:ToJSON()+'}'						
		If Self:callMethod("update")
			oJSONResp := JSONObject():New()
			oJSONResp:FromJSON(Self:oJSON:cReturn)
			If oJSONResp:hasProperty('result') .AND. ValType(oJSONResp['result']) == "L" .AND. oJSONResp['result'] == .T.
				::cBitrix24_ID := cID
				lReturn := .T.
			EndIf
			FreeObj(oJSONResp)				
		EndIf
		//---------------------------------------------------------------------------
	Else
		//---------------------------------------------------------------------------
		// Use ERP ID or CPF/CNPJ to get the ID before update
		//---------------------------------------------------------------------------	
		If Upper(AllTrim(cType)) == "ERP"
			cField   := Self:BTX_FieldName("A1_XERPID")
			cContent := AllTrim(cUniverID)
		ElseIf Upper(AllTrim(cType)) == "CGC"
			cField   := "?" + Self:BTX_FieldName("A1_CGC")
			cContent := cCGCFilter(Self)
		Else
			UserException("Invalid query type")
		EndIf		
		//Search for duplicated companies using CPF/CNPJ field or ERP ID
		//If mutiple results were found, update the oldest entry only						
		If Self:listCompany({"*","UF_*"},{{cField,cContent}},{{"DATE_CREATE","ASC"}})
			cLine := Self:oJSON:readLine()			
			oJSONResp := JSONObject():New()
			oJSONResp:FromJSON(cLine)
			If oJSONResp:hasProperty("ID")
				cID  := oJSONResp["ID"]
				FreeObj(oJSONResp)
				If !Empty(cID)
					Self:oJSON:Clean()
					Self:oJSON:cID   := cID
					Self:oJSON:cData := '{ "id": "'+cID+'","fields":'+Self:ToJSON()+'}'						
					If Self:callMethod("update")
						oJSONResp := JSONObject():New()
						oJSONResp:FromJSON(Self:oJSON:cReturn)
						If oJSONResp:hasProperty('result') .AND. ValType(oJSONResp['result']) == "L" .AND. oJSONResp['result'] == .T.
							::cBitrix24_ID := cID
							lReturn := .T.
						EndIf
						FreeObj(oJSONResp)				
					EndIf
				EndIf
			EndIf
		EndIf
		//---------------------------------------------------------------------------				            
	EndIf	
	
Return lReturn

METHOD getBitrixID() CLASS Bitrix24_CRM_ENTITIES_COMPANIES
Return ::cBitrix24_ID
