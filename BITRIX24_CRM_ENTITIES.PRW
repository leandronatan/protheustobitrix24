#INCLUDE "PROTHEUS.CH"
  
//-----------------------------------------
// Fields position
//-----------------------------------------
#DEFINE POS_cBTX_Field   1
#DEFINE POS_cBTX_Type    2
#DEFINE POS_cERP_Field   3
#DEFINE POS_cERP_Type    4
#DEFINE POS_xFieldData   5
#DEFINE POS_UpdatedTimes 6

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
// Events position
//-----------------------------------------
#DEFINE POS_cEvent     1
#DEFINE POS_cEvtOption 2
#DEFINE POS_cEvtDescri 3


CLASS Bitrix24_CRM_ENTITIES
    
	DATA cEntCode
	DATA cEntity
	DATA cEntItem
	DATA aFieldData
	DATA aMethods
	DATA aEvents
               
	DATA cError
	DATA oJSON
	DATA oWebhook
	
	DATA lUseScheduler

	METHOD New(cEntity) CONSTRUCTOR
	METHOD BTX_FieldGet(cField)
	METHOD BTX_FieldPut(cField,xContent)	
	METHOD ERP_FieldGet(cField)
	METHOD ERP_FieldPut(cField,xContent)	
	METHOD BTX_FieldName(cERPField)
	METHOD ERP_AddLine(cField,aContent)
	METHOD ClearField(cField)  
	METHOD BTX_FdPos(cBTXField)
	METHOD useScheduler()
	
	METHOD FromJSON(cFromJSON,lForceRead)
	METHOD ToJSON()
	

	METHOD GetError()	
	METHOD callMethod(cMethod)

ENDCLASS             
                                
METHOD New(cEntity) CLASS Bitrix24_CRM_ENTITIES
	
	::cEntCode   := ""
	::cEntity    := ""
	::cEntItem   := ""
	::aFieldData := {}
	::aMethods   := {}
	::aEvents    := {}

	::cError     := ""
	::oJSON      := Nil
	::oWebhook   := Nil   
	
	::lUseScheduler := .F.
	
	cEntity := PADR(AllTrim(cEntity),TamSX3("ZH3_ENTBTX")[1])		
	LoadEntity(Self,cEntity)
	LoadMethods(Self)
	LoadFields(Self)
	LoadEvents(Self)
				
Return Self 

METHOD BTX_FdPos(cBTXField) CLASS Bitrix24_CRM_ENTITIES

	Local nReturn := 0
			
	cBTXField := Upper(AllTrim(cBTXField))		
	nReturn   := AScan(Self:aFieldData,{|x| x[POS_cBTX_Field] == cBTXField}) > 0

Return nReturn
       
METHOD BTX_FieldGet(cField) CLASS Bitrix24_CRM_ENTITIES
Return _xFieldGet(Self,AllTrim(cField),POS_cBTX_Field)	
	
METHOD BTX_FieldPut(cField,xContent) CLASS Bitrix24_CRM_ENTITIES
Return _xFieldPut(Self,AllTrim(cField),POS_cBTX_Field,xContent)

METHOD ERP_FieldGet(cField) CLASS Bitrix24_CRM_ENTITIES
Return _xFieldGet(Self,AllTrim(cField),POS_cERP_Field)

METHOD ERP_FieldPut(cField,xContent) CLASS Bitrix24_CRM_ENTITIES
Return _xFieldPut(Self,AllTrim(cField),POS_cERP_Field,xContent)

METHOD BTX_FieldName(cERPField) CLASS Bitrix24_CRM_ENTITIES

	Local nPosField := 0
	Local cReturn   := ""
	
	cERPField := Upper(AllTrim(cERPField))
		
	If (nPosField := AScan(Self:aFieldData,{|x| x[POS_cERP_Field] == cERPField})) > 0
		cReturn := ::aFieldData[nPosField][POS_cBTX_Field]
	EndIf

Return cReturn


METHOD ERP_AddLine(cField,aContent) CLASS Bitrix24_CRM_ENTITIES
                               
	Local oJSONLine := JSONObject():New()
	Local cContent  := ""
	
	If Len(aContent) == 2
		oJSONLine["VALUE_TYPE"] := aContent[1]
		oJSONLine["VALUE"] := aContent[2]
	ElseIf Len(aContent) == 3        
		oJSONLine["VALUE_TYPE"] := aContent[1]
		oJSONLine["VALUE"] := aContent[2]
		oJSONLine["ID"] := aContent[3]
	EndIf
		
	cContent := oJSONLine:ToJSON()
	FreeObj(oJSONLine)

Return _xFieldPut(Self,AllTrim(cField),POS_cERP_Field,{cContent},.F.)
   
METHOD ClearField(cField) CLASS Bitrix24_CRM_ENTITIES
	
	Local nPosField := 0
	Local lReturn := .F.
	
	//Search for BTX or ERP field, allowing the user to use the field at your own choice
	If (nPosField := AScan(::aFieldData,{|x| x[POS_cBTX_Field] == cField})) > 0
		lReturn := .T.
	ElseIf (nPosField := AScan(::aFieldData,{|x| x[POS_cERP_Field] == cField})) > 0
		lReturn := .T.	
	EndIf

	If lReturn > 0
		Do Case
			Case ::aFieldData[nPosField][POS_cERP_Type] == "C" ; ::aFieldData[nPosField][POS_xFieldData] := ""
			Case ::aFieldData[nPosField][POS_cERP_Type] == "N" ; ::aFieldData[nPosField][POS_xFieldData] := 0
			Case ::aFieldData[nPosField][POS_cERP_Type] == "D" ; ::aFieldData[nPosField][POS_xFieldData] := CToD("//")
			Case ::aFieldData[nPosField][POS_cERP_Type] == "A" ; ::aFieldData[nPosField][POS_xFieldData] := {}
			Otherwise ; ::aFieldData[nI][POS_xFieldData] := Nil
		EndCase		
	EndIf
	
Return lReturn


METHOD useScheduler() CLASS Bitrix24_CRM_ENTITIES
	::lUseScheduler := .T.
Return

METHOD FromJSON(cFromJSON,lForceRead) CLASS Bitrix24_CRM_ENTITIES

	Local oJSON      := Nil
	Local xContent   := Nil
	Local cField     := ""
	Local cRetJSON   := ""
	Local lReturn    := .T.
	Local nLenData   := Len(::aFieldData)
	Local aDataTemp  := {}
	Local aMultiData := {}
	Local nI := 0
	Local nJ := 0
			         
	DEFAULT lForceRead := .F. 
				
	oJSON := JSONObject():New() 
	cRetJSON := oJSON:FromJSON(cFromJSON)
 
	If ValType(cRetJSON) == "C"
		::cError := "JSON conversion to object failure: "
		Conout("[Bitrix24_CRM_ENTITIES] " + ::cError)
		lReturn := .F.
	Else
		aDataTemp := AClone(::aFieldData) //Backup old FieldData if an error ocurs
		ClearData(::aFieldData) //Clear FieldData
		For nI := 1 To nLenData			                                                           		               		
			cField := ::aFieldData[nI][POS_cBTX_Field]
			If oJSON:HasProperty(cField)
				xContent := oJSON[AllTrim(::aFieldData[nI][POS_cBTX_Field])]
				If ValType(xContent) == "A"
					aMultiData := {}
					For nJ := 1 To Len(oJSON[AllTrim(::aFieldData[nI][POS_cBTX_Field])])
						AAdd(aMultiData,oJSON[AllTrim(::aFieldData[nI][POS_cBTX_Field])][nJ]:ToJSON())					
					Next nJ
					Self:BTX_FieldPut(::aFieldData[nI][POS_cBTX_Field],aMultiData)
				Else
					Self:BTX_FieldPut(::aFieldData[nI][POS_cBTX_Field],xContent)
				EndIf
			ElseIf !lForceRead                                  
				//If an error was ocuried, restore the old data
				::aFieldData := AClone(aDataTemp) 
				::cError := "JSON to object error. Field " + cField + " wasn't found in dictionary."
				Conout("[Bitrix24_CRM_ENTITIES] " + ::cError)
				lReturn := .F.
				EXIT
			EndIf
		Next nI		
	EndIf 
	
	FreeObj(oJSON)

Return lReturn

Static Function ClearData(aDataTemp)

	Local nI := 0
		
	For nI := 1 To Len(aDataTemp)
		Do Case
			Case aDataTemp[nI][POS_cERP_Type] == "C" ; aDataTemp[nI][POS_xFieldData] := ""
			Case aDataTemp[nI][POS_cERP_Type] == "N" ; aDataTemp[nI][POS_xFieldData] := 0
			Case aDataTemp[nI][POS_cERP_Type] == "D" ; aDataTemp[nI][POS_xFieldData] := CToD("//")
			Case aDataTemp[nI][POS_cERP_Type] == "A" ; aDataTemp[nI][POS_xFieldData] := {}
			Otherwise ; ::aFieldData[nI][POS_xFieldData] := Nil
		EndCase
		aDataTemp[nI][POS_UpdatedTimes] := 0				
	Next nI
		
Return


METHOD ToJSON() CLASS Bitrix24_CRM_ENTITIES

	Local oJSON      := Nil
	Local oJSONMulti := Nil	
	Local nLenData   := Len(::aFieldData)
	Local cReturn    := ""
	Local nI  := 0
	Local nJ  := 0
		                    
	oJSON := JSONObject():New()
	For nI := 1 To nLenData
		If ::aFieldData[nI][POS_UpdatedTimes] > 0 		
			If ::aFieldData[nI][POS_cERP_Type] == "A"				
				//Multifields		  		
		  		oJSON[::aFieldData[nI][POS_cBTX_Field]] := {}
				For nJ := 1 To Len(::aFieldData[nI][POS_xFieldData])
			  		oJSONMulti := JSONObject():New()
			  		oJSONMulti:FromJSON(::aFieldData[nI][POS_xFieldData][nJ])			  		
			  		AAdd(oJSON[::aFieldData[nI][POS_cBTX_Field]],oJSONMulti)				
				Next nJ				
			Else			
				oJSON[::aFieldData[nI][POS_cBTX_Field]] := AllTrim(::aFieldData[nI][POS_xFieldData])
			EndIf
		EndIf
	Next nI
	
	cReturn := oJSON:toJSON()	
	FreeObj(oJSON)

Return cReturn

METHOD GetError() CLASS Bitrix24_CRM_ENTITIES	
Return ::cError

METHOD callMethod(cMethod) CLASS Bitrix24_CRM_ENTITIES
	                
	Local oWebhook  := Nil	
	Local cEntity   := ""
	Local cWebhook  := ""
	Local cHTTP_Req := ""
	Local lReturn   := .F.

	DEFAULT cID := ""
	
	cMethod := Lower(AllTrim(cMethod))
		
	If (nPosMethod := AScan(::aMethods,{|x| x[POS_cOption] == cMethod})) > 0
		If ::aMethods[nPosMethod][POS_cHasID] == "S" .AND. Empty(::oJSON:cID)
			::cError := "ID is required for Method " + cMethod
			Conout("[Bitrix24_CRM_ENTITIES_COMPANIES] " + ::cError)
		Else    		    
			cEntity   := ::cEntCode
			cMethod   := ::aMethods[nPosMethod][POS_cItem]
			cWebhook  := PADR(::cEntItem,TamSX3("ZH4_ITEM")[1])
			cHTTP_Req := ::aMethods[nPosMethod][POS_cHTTP_Req]
			oWebHook  := Bitrix24_Webhook():New(cEntity,cMethod,cWebhook,cHTTP_Req)
			If oWebHook:IsValid()  
				oWebHook:SetJSON(Self:oJSON:cData)		
				If oWebHook:CallMethod()
					Self:oJSON:cReturn := oWebHook:GetReturn()
					lReturn := .T.
				Else
					Self:oJSON:cReturn := oWebHook:GetError()
				EndIf			
			Else
				::cError := "Invalid webhook configuration"
				Conout("[Bitrix24_CRM_ENTITIES_COMPANIES] " + ::cError)
			EndIf
		EndIf							
	Else    
		::cError := "Method " + cMethod + " not found"
		Conout("[Bitrix24_CRM_ENTITIES_COMPANIES] " + ::cError)
	EndIf
	
Return lReturn

Static Function LoadEntity(oObj,cEntity)

	Local lReturn := .F.
	
	BeginSQL Alias "__TMPZH1"
		SELECT	* FROM %Table:ZH1%
		WHERE	ZH1_FILIAL = %xFilial:ZH1% AND 
				ZH1_ENTIDA = %Exp:cEntity% AND
				%NotDel%
	EndSQL
		
	If __TMPZH1->(!EoF())
		oObj:cEntity  := AllTrim(__TMPZH1->ZH1_ENTIDA)
		oObj:cEntCode := __TMPZH1->ZH1_CODIGO
		oObj:cEntItem := Upper(AllTrim(__TMPZH1->ZH1_ITEM))
		lReturn := .T.
	EndIf
		
	__TMPZH1->(DbCloseArea())

Return lReturn
               
Static Function LoadMethods(oObj)

	Local cMethod   := ""
	Local cItem     := ""
	Local cOption   := ""
	Local cHasID    := ""
	Local cDescri   := ""
	Local cHTTP_Req := ""
			
	BeginSQL Alias "__TMPZH2"
		SELECT	* FROM %Table:ZH2%
		WHERE	ZH2_FILIAL = %xFilial:ZH2% AND
				ZH2_CODENT = %Exp:oObj:cEntCode% AND
				%NotDel%
		ORDER BY ZH2_ITEM
	EndSQL
	
	If __TMPZH2->(!EoF())		
		While __TMPZH2->(!EoF())		
			cMethod   := Lower(AllTrim(__TMPZH2->ZH2_METODO))
			cItem     := __TMPZH2->ZH2_ITEM
			cOption   := Lower(AllTrim(__TMPZH2->ZH2_OPCAO))
			cHasID    := AllTrim(__TMPZH2->ZH2_HAS_ID)
			cHTTP_Req := Upper(AllTrim(__TMPZH2->ZH2_HTTPRQ))
			cDescri   := Lower(AllTrim(__TMPZH2->ZH2_DESCRI))	
			//----------------------------------------------------------------
			// Update #DEFINE entries if you need to add more fields
			//----------------------------------------------------------------
			AAdd(oObj:aMethods,{cMethod,;   // POS_cMethod   1
								cItem,;     // POS_cItem     2
			                    cOption,;   // POS_cOption   3
			                    cHasID,;    // POS_cHasID    4
			                    cHTTP_Req,; // POS_cHTTP_Req 5
			                    cDescri})   // POS_cDescri   6
			//----------------------------------------------------------------			
			__TMPZH2->(DbSkip())
		End
	EndIf
	
	__TMPZH2->(DbCloseArea())

Return
             
Static Function LoadFields(oObj)

	Local cBTX_Field := ""
	Local cBTX_Type  := ""
	Local cERP_Field := ""
	Local cERP_Type  := ""
	Local xFieldData := Nil

	BeginSQL Alias "__TMPZH3"
		SELECT	* FROM %Table:ZH3%
		WHERE	ZH3_FILIAL = %xFilial:ZH3% AND 
				ZH3_CODENT = %Exp:oObj:cEntCode% AND
				ZH3_USADO  = %Exp:"S"% AND
				%NotDel%
	EndSQL
	
	If __TMPZH3->(!EoF())	
		While __TMPZH3->(!EoF())		
			cBTX_Field := AllTrim(__TMPZH3->ZH3_CP_BTX)
			cBTX_Type  := AllTrim(__TMPZH3->ZH3_TP_BTX)
			cERP_Field := AllTrim(__TMPZH3->ZH3_CP_ERP)
			cERP_Type  := AllTrim(__TMPZH3->ZH3_TP_ERP)
			cFieldData := ""			          
			Do Case
				Case cERP_Type == "C"
					xFieldData := ""				
				Case cERP_Type == "N"
					xFieldData := 0
				Case cERP_Type == "D"
					xFieldData := CToD("//")
				Case cERP_Type == "A"
					xFieldData := {}
				Otherwise
					xFieldData := Nil
			EndCase			
			//----------------------------------------------------------------
			// Update #DEFINE entries if you need to add more fields
			//----------------------------------------------------------------
			AAdd(oObj:aFieldData,{cBTX_Field,; // POS_cBTX_Field   1
			                      cBTX_Type,;  // POS_cBTX_Type    2
			                      cERP_Field,; // POS_cERP_Field   3
			                      cERP_Type,;  // POS_cERP_Type    4
			                      xFieldData,; // POS_xFieldData   5
			                      0})          // POS_UpdatedTimes 6
			//----------------------------------------------------------------		
			__TMPZH3->(DbSkip())
		End
	EndIf
	
	__TMPZH3->(DbCloseArea())

Return
         
Static Function LoadEvents(oObj)

	Local cEvent     := ""
	Local cEvtOption := ""
	Local cEvtDescri := ""

	BeginSQL Alias "__TMPZH7"
		SELECT	* FROM %Table:ZH7%
		WHERE	ZH7_FILIAL = %xFilial:ZH7% AND 
				ZH7_CODENT = %Exp:oObj:cEntCode% AND
				%NotDel%
		ORDER BY ZH7_CODENT, ZH7_ITEM
	EndSQL
	
	If __TMPZH7->(!EoF())	
		While __TMPZH7->(!EoF())
			cEvent     := AllTrim(__TMPZH7->ZH7_EVENTO)
			cEvtOption := AllTrim(__TMPZH7->ZH7_OPCAO)
			cEvtDescri := AllTrim(__TMPZH7->ZH7_DESCRI)						
			//----------------------------------------------------------------
			// Update #DEFINE entries if you need to add more fields
			//----------------------------------------------------------------
			AAdd(oObj:aEvents,{cEvent,;      // POS_cEvent     1
			                   cEvtOption,;  // POS_cEvtOption 2
			                   cEvtDescri}) // POS_cEvtDescri 3
			//----------------------------------------------------------------		
			__TMPZH7->(DbSkip())
		End
	EndIf
	
	__TMPZH7->(DbCloseArea())	

Return

Static Function _xFieldGet(oObj,cField,nOpcField)
	
	Local nPosField := AScan(oObj:aFieldData,{|x| x[nOpcField] == cField})
	Local xReturn   := Nil

	If nPosField > 0
		xReturn := oObj:aFieldData[nPosField][POS_xFieldData]
	Else
		UserException("Field " + cField + " doesn't exist")
	EndIf

Return xReturn

Static Function _xFieldPut(oObj,cField,nOpcField,xContent,lClrArray)

	Local nPosField := AScan(oObj:aFieldData,{|x| x[nOpcField] == cField})
	
	DEFAULT lClrArray := .T.

	If nPosField > 0			
		If ValType(xContent) != oObj:aFieldData[nPosField][POS_cERP_Type]
			UserException("Field type of " + oObj:aFieldData[nPosField][POS_cERP_Type] + " doesn't match in dictionary. " + CRLF + ;
						  "Type send: " + ValType(xContent) + ", dictionary type: " + oObj:aFieldData[nPosField][POS_cERP_Type])
		Else
			If ValType(xContent) == "A"
				If lClrArray
					oObj:aFieldData[nPosField][POS_xFieldData] := AClone(xContent)				
				Else
					AAdd(oObj:aFieldData[nPosField][POS_xFieldData],xContent[1])
				EndIf
			Else
				oObj:aFieldData[nPosField][POS_xFieldData] := xContent
			EndIf
			//The counter is increased everytime a field is updated.
			//Used in JSON conversion, it will generate only the updated fields.
			oObj:aFieldData[nPosField][POS_UpdatedTimes] += 1
		EndIf
	Else
		UserException("Field " + AllTrim(cField) + " doesn't exist")
	EndIf

Return
