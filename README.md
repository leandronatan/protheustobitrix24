# protheustobitrix24
Um framework de integração do ERP Protheus com o Bitrix24, facilitando a troca de informações entre as diferentes plataformas

Possui um dicionário de dados, representando os campos no Protheus e o correspondente no Bitrix, além de uma classe abstrata representando as entidades. Para cada entidade específica, a ideia é realizar a implementação de cada uma delas.

Nesta primeira versão, foi feita a implementação do cadastro de clientes. Exemplo:

oCompany := Bitrix24_CRM_ENTITIES_COMPANIES():New()<br>
oCompany:ERP_FieldPut("TIPO_EMP","CUSTOMER")<br>
oCompany:ERP_FieldPut("A1_CGC",SA1->A1_CGC)<br>
oCompany:ERP_FieldPut("A1_NREDUZ",SA1->A1_NREDUZ)<br>
oCompany:ERP_FieldPut("A1_NOME",SA1->A1_NOME)<br>
oCompany:ERP_FieldPut("ENDERECO","Rua do Teste, 1234, Curitiba - PR")<br>
oCompany:ERP_AddLine("TELEFONE",{"WORK","4112345678"})<br>
oCompany:ERP_AddLine("TELEFONE",{"MOBILE","41999999999"})<br>
oCompany:ERP_AddLine("EMAIL",{"WORK","work.email@email.com"})<br>
oCompany:ERP_AddLine("EMAIL",{"HOME","home.email@email.com"})<br>
oCompany:addCompany()<br>

Futuramente, será preciso implementar as outras entidades, e também um middleware para troca de informações do Bitrix24 para o Protheus, já que as mensagens via WebHook do Bitrix são enviados apenas os IDs e o nome do evento.
