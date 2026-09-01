#==============================================================================================
# MODULO 7: CONSOLIDACION Y EXPORTACION DE RESULTADOS
#==============================================================================================
# 1. RESULTADO: marcacion publicable en SICORE (ELEGIBLE / LISTA_ESPERA / NO_ELEGIBLE).
# 2. PUESTO y PUESTO_LOC: posicion del aspirante dentro de cada oferta, general y por
#    localidad, priorizando 1=ELEGIBLE, 2=LISTA_ESPERA, 3=resto.
# 3. Exportacion a output/JE5_VF_YYYYMMDD.xlsx con siete hojas:
#
#   | Hoja                  | Contenido                                              |
#   |-----------------------|--------------------------------------------------------|
#   | JE5_PER               | Persona unica ordenada por JE5_LLAVE_PER               |
#   | JE5_PER_OFERTA        | Detalle persona-oferta con estado, asignacion y puesto |
#   | JE5_TOTAL             | Cruce de las dos anteriores (archivo total)            |
#   | ORDENAMIENTO          | Auditoria del ordenamiento y sus criterios de desempate|
#   | BASE_FDL              | Presupuesto por localidad y remanente al cierre        |
#   | BASE_OFERTA           | Cupos general y recomposicion, y disponibles al cierre |
#   | DETALLE_OFERTA_RECOMP | Detalle de cupos de recomposicion por localidad        |
#----------------------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#MARCACION PARA PUBLICACION EN SICORE (TIC)
#-------------------------------------------------------------------------------
JE5_PER_OFERTA$RESULTADO <- NA
JE5_PER_OFERTA[JE5_PER_OFERTA$ESTADO_ELEGIBLE %in% c("ELEGIBLE","LISTA_ESPERA"),"RESULTADO"] <- JE5_PER_OFERTA[JE5_PER_OFERTA$ESTADO_ELEGIBLE %in% c("ELEGIBLE","LISTA_ESPERA"),"ESTADO_ELEGIBLE"]
JE5_PER_OFERTA[is.na(JE5_PER_OFERTA$RESULTADO),"RESULTADO"]<-"NO_ELEGIBLE"
cro(JE5_PER_OFERTA$RESULTADO)
cro(JE5_PER_OFERTA$ESTADO_ELEGIBLE, JE5_PER_OFERTA$RESULTADO)

#-------------------------------------------------------------------------------
#CONSTRUCCION DE POSICION DE ELEGIBLES Y LISTA DE ESPERA
#-------------------------------------------------------------------------------
PUESTOS<-  JE5_PER_OFERTA[JE5_PER_OFERTA$ESTADO_ELEGIBLE %in% c("ELEGIBLE","LISTA_ESPERA","DISPONIBLE") ,
                          c( "ID_PERSONA_OFERTA","ID_OFERTA_PROGRAMA","JE5_LLAVE_PER","CODLOC", "ESTADO_ELEGIBLE")]

#PARA EL CALCULO DEL PUESTO SE PRIORIZA 1 ELEGIBLES, 2 LISTA DE ESPERA, 3 EL RESTO
PUESTOS$ORDEN_ESTADO <- 3
PUESTOS[PUESTOS$ESTADO_ELEGIBLE=="ELEGIBLE", "ORDEN_ESTADO"] <-1
PUESTOS[PUESTOS$ESTADO_ELEGIBLE=="LISTA_ESPERA", "ORDEN_ESTADO"] <-2
cro(PUESTOS$ORDEN_ESTADO, PUESTOS$ESTADO_ELEGIBLE)

#CREAR POSICION GENERAL Y POR LOCALIDAD AGRUPADO POR PROGRAMA
PUESTOS <- PUESTOS %>% group_by(ID_OFERTA_PROGRAMA) %>%  arrange(ORDEN_ESTADO,JE5_LLAVE_PER) %>%  mutate(PUESTO = row_number())
PUESTOS <- PUESTOS %>% group_by(ID_OFERTA_PROGRAMA,CODLOC) %>%  arrange(ORDEN_ESTADO,JE5_LLAVE_PER) %>%  mutate(PUESTO_LOC = row_number())

# PEGAR POSICION OFERTA
JE5_PER_OFERTA<- merge(x=JE5_PER_OFERTA, y=PUESTOS[,c("ID_PERSONA_OFERTA","PUESTO","PUESTO_LOC")], by="ID_PERSONA_OFERTA", all.x = TRUE)

#-------------------------------------------------------------------------------
# EXPORTAR RESULTADOS 
#-------------------------------------------------------------------------------
# CONSTRUCCION ARCHIVO TOTAL
JE5_TOTAL<- JE5_PER_OFERTA[,c(1,2,4:11,18,13,3,12,14:15,19:26,32:42,17,43,44)]
JE5_TOTAL <- merge(x=JE5_TOTAL, y=JE5, by="ID_PERSONA", all = FALSE)
names(JE5_TOTAL)

ARCHIVO_SALIDA <- paste0("output/JE5_VF_", format(Sys.Date(), "%Y%m%d"), ".xlsx")

write.xlsx(JE5[order(JE5$JE5_LLAVE_PER),], ARCHIVO_SALIDA, sheetName="JE5_PER", append=TRUE)
wb <- loadWorkbook(ARCHIVO_SALIDA)
addWorksheet(wb,"JE5_PER_OFERTA")
writeData(wb,"JE5_PER_OFERTA",JE5_PER_OFERTA[order(JE5_PER_OFERTA$JE5_LLAVE_PER,JE5_PER_OFERTA$PRIORIDAD),])
addWorksheet(wb,"JE5_TOTAL")
writeData(wb,"JE5_TOTAL",JE5_TOTAL[order(JE5_TOTAL$JE5_LLAVE_PER,JE5_TOTAL$PRIORIDAD),])
addWorksheet(wb,"ORDENAMIENTO")
writeData(wb,"ORDENAMIENTO",ORDENAMIENTO)
addWorksheet(wb,"BASE_FDL")
writeData(wb,"BASE_FDL",BASE_FDL)
addWorksheet(wb,"BASE_OFERTA")
writeData(wb,"BASE_OFERTA",BASE_OFERTA)
addWorksheet(wb,"DETALLE_OFERTA_RECOMP")
writeData(wb,"DETALLE_OFERTA_RECOMP",BASE_OFERTA_RECOMP)
saveWorkbook(wb, ARCHIVO_SALIDA, overwrite = TRUE)

# BORRAR VARIABLES Y DATOS QUE SE USARON EN LOS CALCULOS
