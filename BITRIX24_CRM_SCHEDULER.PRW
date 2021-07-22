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

CLASS Bitrix24_CRM_SCHEDULER

	DATA oEntity
	DATA cOption

	METHOD New() CONSTRUCTOR
	METHOD Save()
	METHOD Restore(cLote)
	METHOD Execute()
	METHOD Clean()
				
ENDCLASS    

METHOD New() CLASS Bitrix24_CRM_SCHEDULER
	::oEntity := Nil
	::cOption := ""	
Return Self

METHOD Save() CLASS Bitrix24_CRM_SCHEDULER

	Local cNumLote := ""
	Local cCodEnt  := ""
	Local cNomEnt  := ""
	Local cCodMet  := ""
	Local cNomMet  := ""
	Local cCodWBH  := ""
	Local cItemWBH := ""
	Local cURLWBH  := ""
	Local cOrigem  := ""
	Local cJSONEnv := ""
	Local cJSONRt  := ""
	Local nTries   := ""
	Local cDtEnvi  := ""
	Local cDtPrxt  := ""
	Local cDtRetr  := ""
	Local cStatus  := ""
	Local cLtEntr  := ""
	
	cNumLote := FWUUIDV4()
	cCodEnt  := ::oEntity:cEntCode
	cNomEnt  := ::oEntity:cEntity		
	cCodMet  := ::oEntity:aMethods[AScan(::oEntity:aMethods,{|x| x[POS_cOption] == ::cOption })][POS_cItem]
	cNomMet  := "add"			 
		
	DbSelectArea("ZH4")
	ZH4->(DbSetOrder(2))		
	If ZH4->(DbSeek(xFilial("ZH4")+::oEntity:cEntItem))
		cCodWBH  := ZH4->ZH4_CODIGO
		cItemWBH := ZH4->ZH4_ITEM
		cURLWBH  := ZH4->(AllTrim(ZH4_URL)+AllTrim(ZH4_PATH))
	EndIf
	
	cOrigem  := FUNNAME()
	cJSONEnv := ::oEntity:ToJSON()
	cJSONRt  := "" 
	nTries   := 0
	cDtEnvi  := FWTimeStamp(5)
	cDtPrxt  := "" 
	cDtRetr  := ""
	cStatus  := "20"
	cLtEntr  := ""
	
	RecLock("ZHA",.T.)
	ZHA->ZHA_FILIAL := xFilial("ZHA")
	ZHA->ZHA_LOTE   := cNumLote
	ZHA->ZHA_CODENT := cCodEnt
	ZHA->ZHA_NOMENT := cNomEnt  
	ZHA->ZHA_CODMET := cCodMet
	ZHA->ZHA_NOMMET := cNomMet
	ZHA->ZHA_CODWBH := cCodWBH
	ZHA->ZHA_ITMWBH := cItemWBH
	ZHA->ZHA_URLWBK := cURLWBH
	ZHA->ZHA_ORIGEM := cOrigem
	ZHA->ZHA_JSONEV := cJSONEnv
	ZHA->ZHA_JSONRT := cJSONRt
	ZHA->ZHA_NTRIES := nTries
	ZHA->ZHA_DTENVI := cDtEnvi
	ZHA->ZHA_DTPRXT := cDtPrxt
	ZHA->ZHA_DTRETR := cDtRetr
	ZHA->ZHA_STATUS := cStatus
	ZHA->ZHA_LTENTR := cLtEntr
	ZHA->(MsUnlock())
	
Return   

METHOD Restore(cLote) CLASS Bitrix24_CRM_SCHEDULER

	Local aArea     := GetArea()
	Local cLdEntity := ""
	
	DbSelectArea("ZHA")
	ZHA->(DbSetOrder(1))
	
	If ZHA->(DbSeek(xFilial("ZHA")+cLote))	

		cLdEntity := Lower(AllTrim(ZHA->ZHA_NOMENT))
		
		If cLdEntity == "crm.company"
		
			::cOption := AllTrim(ZHA->ZHA_NOMMET)
			::oEntity := Bitrix24_CRM_ENTITIES_COMPANIES():New()			
			::oEntity:FromJSON(ZHA->ZHA_JSONEV)			
			
		ElseIf cLdEntity == "crm.deals"
			//Include newer implementations in future
		Else
			UserException("Entity not found")		
		EndIf
					
	EndIf

	RestArea(aArea)

Return 

METHOD Clean() CLASS Bitrix24_CRM_SCHEDULER
	FreeObj(::oEntity)
	::oEntity := Nil
	::cOption := ""
Return