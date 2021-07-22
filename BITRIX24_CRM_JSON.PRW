#INCLUDE "PROTHEUS.CH"
  

CLASS Bitrix24_CRM_JSON

	DATA cID
	DATA cData
	DATA cReturn	
	DATA aDataSet
	DATA nQuantity
	DATA nLine
	DATA cError
	
	METHOD New() CONSTRUCTOR
	METHOD ToDataSet(cTypeData)	
	METHOD readLine()
	METHOD nextLine()
	METHOD lastLine()
	METHOD firstLine()
	METHOD getLine()	
	METHOD GetError()
	METHOD Clean()
	
ENDCLASS             
                                
METHOD New() CLASS Bitrix24_CRM_JSON
	Self:Clean()
Return Self  

METHOD Clean() CLASS Bitrix24_CRM_JSON
	::cID       := ""
	::cData     := ""
	::cReturn   := ""
	::aDataSet  := {} 
	::nQuantity := 0
	::nLine	    := 0
	::cError    := ""
Return

METHOD ToDataSet(cTypeData) CLASS Bitrix24_CRM_JSON
	
	Local oJSON    := Nil
	Local cRetJSON := ""
	Local lReturn  := .T.
	Local nI := 0
	
	cTypeData := Lower(AllTrim(cTypeData))

	oJSON := JSONObject():New()	
	cRetJSON := oJSON:FromJSON(::cReturn)
	 
	If ValType(cRetJSON) == "C"
		::cError := "JSON conversion to object failure: " + cRetJSON
		Conout("[Bitrix24_CRM_JSON] " + ::cError)
		lReturn := .F.
	Else	
		If oJSON:hasProperty(cTypeData)		
			If ValType(oJSON[cTypeData]) == "A"
				For nI := 1 To Len(oJSON[cTypeData])
					AAdd(::aDataSet,oJSON[cTypeData][nI]:toJSON())
				Next nI			
			Else
				AAdd(::aDataSet,oJSON[cTypeData]:toJSON())
			EndIf			
			If Len(::aDataSet) > 0			
				::nQuantity := Len(::aDataSet)
				::nLine := 1
			Else
				::nQuantity := 0
				::nLine := 0
			EndIf
		Else
			::cError := "Property " + cTypeData + " not found"
			Conout("[Bitrix24_CRM_JSON] " + ::cError)
			lReturn := .F.		
		EndIf		
	EndIf 	

Return lReturn 
           
METHOD GetError() CLASS Bitrix24_CRM_JSON
Return ::cError

METHOD readLine() CLASS Bitrix24_CRM_JSON	
	Local cReturn := ""
	If !Empty(::aDataSet)
		cReturn := ::aDataSet[::nLine]
	Else
		cReturn := ""
		::cError := "Invalid DataSet"
	EndIf		
Return cReturn

METHOD nextLine() CLASS Bitrix24_CRM_JSON
	If !Empty(::aDataSet)
		Self::nLine += 1
	EndIf		
Return

METHOD lastLine() CLASS Bitrix24_CRM_JSON
	If !Empty(::aDataSet)
		Self:nLine := ::nQuantity
	EndIf		
Return  

METHOD firstLine() CLASS Bitrix24_CRM_JSON
	If !Empty(::aDataSet)
		Self:nLine := 1
	EndIf	
Return

METHOD getLine() CLASS Bitrix24_CRM_JSON
	Local nReturn := 0
	If !Empty(::aDataSet)
		nReturn := ::nLine
	Else
		cReturn := 0
		::cError := "Invalid DataSet"
	EndIf	
Return nReturn
