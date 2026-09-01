#==============================================================================================
# MODULO 6: LISTA DE ESPERA
#==============================================================================================
# Referencia: lineamiento operativo, numeral 5.4.4 (Actividad 2).
#
# El tamano de la lista de espera de cada oferta depende de cuantos elegibles logro:
#   - con 4 o mas elegibles: la lista de espera tiene tantos cupos como elegibles
#   - con menos de 4:        la lista de espera se duplica (CANTIDAD * 2)
# asi una oferta pequena no queda sin respaldo ante una sola renuncia.
#
# El recorrido se hace en DOS pasadas, y el orden importa: primero las ofertas de
# RECOMPOSICION con bolsa ATENEA (sin localidad), despues las ofertas financiadas
# por FDL, particionadas por localidad. Cada pasada recorre sus ofertas en orden
# ascendente de ULTIMO_ELEGIBLE (la oferta que "cerro" antes se atiende primero).
#
# Una persona solo puede quedar en lista de espera en UNA oferta: al marcarla,
# sus demas registros pasan a INACTIVO_LISTA_ESPERA.
#----------------------------------------------------------------------------------------------

#===============================================================================
# CALCULO DE LISTA DE ESPERA
# 5.4.4. Actividad 2: Aplicación mecanismo de asignación de cupos
#===============================================================================

# Total elegibles por oferta para cacular Lista Espera 
ELEGIBLES <- sqldf("SELECT ID_OFERTA_PROGRAMA, count(1) ELEGIBLES_GENERAL FROM JE5_PER_OFERTA WHERE ESTADO_ELEGIBLE=='ELEGIBLE' group by ID_OFERTA_PROGRAMA")

# PEGAR ELEFGIBLES A BASE OFERTA
BASE_OFERTA<- merge(x=BASE_OFERTA, y=ELEGIBLES, by="ID_OFERTA_PROGRAMA", all.x = TRUE )
# Normalizar vacios en cero
BASE_OFERTA[is.na(BASE_OFERTA$ELEGIBLES_GENERAL), "ELEGIBLES_GENERAL"] <-0

# CREACION DE VARIABLES PARA CONTROL DE LISTA ESPERA
BASE_OFERTA$CUPOS_ASIGNADOS_LP <- BASE_OFERTA$ELEGIBLES_GENERAL 
BASE_OFERTA[BASE_OFERTA$CUPOS_ASIGNADOS_LP < 4 , "CUPOS_ASIGNADOS_LP" ] <- BASE_OFERTA[BASE_OFERTA$CUPOS_ASIGNADOS_LP < 4 , "CUPOS_ASIGNADOS_LP" ] * 2

#RECORRER OFERTAS ATENEA
ELEGIBLES_CONTEO <- JE5_PER_OFERTA[JE5_PER_OFERTA$ESTADO_ELEGIBLE=="ELEGIBLE" & JE5_PER_OFERTA$ASIGNACION %in% c("RECOMPOSICION") & JE5_PER_OFERTA$ASIGNACION_DETALLE %in% c("ATENEA"),] %>% group_by(ID_OFERTA_PROGRAMA,ASIGNACION,ASIGNACION_DETALLE) %>% summarise(CANTIDAD =n(), ULTIMO_ELEGIBLE = max(JE5_LLAVE_PER) )
ELEGIBLES_CONTEO<- sqldf("select ROW_NUMBER() OVER( ORDER BY ASIGNACION  DESC, ULTIMO_ELEGIBLE asc  ) AS ID_RECORRIDO
                            ,*
                        from ELEGIBLES_CONTEO")

#-------------------------------------------------------------------------------
# CREACION DE POTENCIALES LISTA DE ESPERA
#-------------------------------------------------------------------------------
TMP_LISTA<-JE5_PER_OFERTA[JE5_PER_OFERTA$ESTADO_ELEGIBLE=="DISPONIBLE",]
TMP_LISTA<- TMP_LISTA[order(TMP_LISTA$JE5_LLAVE_PER),]
TMP_LISTA$ASIGNACION <- NA

BASE_OFERTA$CUPOS_CONTROL_LP<-BASE_OFERTA$CUPOS_ASIGNADOS_LP

# CREACION DE VARIABLES DE ORDENAMIENTO
TMP_LISTA<- sqldf("select *,  
                        ROW_NUMBER() OVER(PARTITION BY ID_OFERTA_PROGRAMA ORDER BY JE5_LLAVE_PER  asc ) AS ORDEN_OFERTA,
                        ROW_NUMBER() OVER(PARTITION BY ID_OFERTA_PROGRAMA,CODLOC ORDER BY JE5_LLAVE_PER  asc ) AS ORDEN_OFERTA_LOCALIDAD
                        from TMP_LISTA")


# a) Regla General, quedaría en lista de espera en el programa más opcionado para ser elegible (Distancia menor entre puesto ultimo elegible y puesto del joven evaluado)
TMP_LISTA<- sqldf("select *,  
                        ROW_NUMBER() OVER(PARTITION BY ID_PERSONA ORDER BY ORDEN_OFERTA asc,ORDEN_OFERTA_LOCALIDAD asc  ) AS MEJOR_OPCION
                        from TMP_LISTA")

# Recorrer por oferta RECOMPOSICION ATENEA
for (oferta in ELEGIBLES_CONTEO$ID_RECORRIDO) {
  print(oferta)
  OFERTA_LISTA_ESPERA <-ELEGIBLES_CONTEO[ELEGIBLES_CONTEO$ID_RECORRIDO==oferta,] 
  
  # FILTRAR LOS POTENCIALES 
  
  if(OFERTA_LISTA_ESPERA$ASIGNACION %in% c("UAESP","UAESP-REMANENTE")){
    LISTA_POTENCIALES <- TMP_LISTA[TMP_LISTA$ID_OFERTA_PROGRAMA==OFERTA_LISTA_ESPERA$ID_OFERTA_PROGRAMA 
                                   & is.na(TMP_LISTA$ASIGNACION)
                                   & !is.na(TMP_LISTA$UAESP)
                                   & TMP_LISTA$ESTADO_ELEGIBLE=="DISPONIBLE"
                                   #& TMP_LISTA$MEJOR_OPCION==1 
                                   ,]
  }else
  {
    LISTA_POTENCIALES <- TMP_LISTA[TMP_LISTA$ID_OFERTA_PROGRAMA==OFERTA_LISTA_ESPERA$ID_OFERTA_PROGRAMA 
                                   & is.na(TMP_LISTA$ASIGNACION)
                                   & TMP_LISTA$ESTADO_ELEGIBLE=="DISPONIBLE"
                                   #& TMP_LISTA$MEJOR_OPCION==1 
                                   ,]  
  }
  
  
  
  # ORDENAR POTENCIALES
  LISTA_POTENCIALES <- sqldf("select *,  
                        ROW_NUMBER() OVER(PARTITION BY ID_OFERTA_PROGRAMA ORDER BY ORDEN_OFERTA  ) AS ID
                        from LISTA_POTENCIALES")
  
  # HACER CORTE HASTA EL MAXIMO POSIBLE A MARCAR COMO LISTA DE ESPERA
  if(OFERTA_LISTA_ESPERA$CANTIDAD  < 4){
    LISTA_POTENCIALES <- LISTA_POTENCIALES[LISTA_POTENCIALES$ID <= OFERTA_LISTA_ESPERA$CANTIDAD * 2 ,] 
  }
  else
  {
    LISTA_POTENCIALES <- LISTA_POTENCIALES[LISTA_POTENCIALES$ID <= OFERTA_LISTA_ESPERA$CANTIDAD ,]  
  }
  
  
  # RECORRER LA LISTA DE POTENCIALES A MARCAR COMO LISTA DE ESPERA
  for (PERSONA_OFERTA in LISTA_POTENCIALES$ID_PERSONA_OFERTA) { 
    
    PERSONA <- LISTA_POTENCIALES[LISTA_POTENCIALES$ID_PERSONA_OFERTA==PERSONA_OFERTA, "ID_PERSONA"]
    
    TMP_LISTA[TMP_LISTA$ID_PERSONA_OFERTA == PERSONA_OFERTA , "ASIGNACION"] <- OFERTA_LISTA_ESPERA$ASIGNACION
    TMP_LISTA[TMP_LISTA$ID_PERSONA_OFERTA == PERSONA_OFERTA, "ESTADO_ELEGIBLE"] <- "LISTA_ESPERA"
    TMP_LISTA[TMP_LISTA$ID_PERSONA_OFERTA != PERSONA_OFERTA & TMP_LISTA$ID_PERSONA ==  PERSONA, "ESTADO_ELEGIBLE"] <- "INACTIVO_LISTA_ESPERA"
    
  } # CERRAR LISTA DE POTENCIALES A MARCAR
  
} # CERRAR RECORRIDO DE OFERTAS DIFERENTES A FDL

#RECORRER OFERTAS FDL
ELEGIBLES_CONTEO <- JE5_PER_OFERTA[JE5_PER_OFERTA$ESTADO_ELEGIBLE=="ELEGIBLE" & JE5_PER_OFERTA$ASIGNACION %in% c("GENERAL","RECOMPOSICION") & !JE5_PER_OFERTA$ASIGNACION_DETALLE %in% c("ATENEA"),] %>% group_by(ID_OFERTA_PROGRAMA, CODLOC) %>% summarise(CANTIDAD =n(), ULTIMO_ELEGIBLE = max(JE5_LLAVE_PER) )

ELEGIBLES_CONTEO<- sqldf("select ROW_NUMBER() OVER( ORDER BY ULTIMO_ELEGIBLE asc  ) AS ID_RECORRIDO
                            ,*
                        from ELEGIBLES_CONTEO")



for (oferta in ELEGIBLES_CONTEO$ID_RECORRIDO) {
  print(oferta)
  OFERTA_LISTA_ESPERA <-ELEGIBLES_CONTEO[ELEGIBLES_CONTEO$ID_RECORRIDO==oferta,] 
  
  # FILTRAR LOS POTENCIALES 
  LISTA_POTENCIALES <- TMP_LISTA[TMP_LISTA$ID_OFERTA_PROGRAMA==OFERTA_LISTA_ESPERA$ID_OFERTA_PROGRAMA 
                                 & !is.na(TMP_LISTA$CODLOC)
                                 & TMP_LISTA$CODLOC == OFERTA_LISTA_ESPERA$CODLOC
                                 & is.na(TMP_LISTA$ASIGNACION) 
                                 & TMP_LISTA$ESTADO_ELEGIBLE=="DISPONIBLE"
                                 #& TMP_LISTA$MEJOR_OPCION==1 
                                 ,]
  
  # ORDENAR POTENCIALES
  LISTA_POTENCIALES <- sqldf("select *,  
                        ROW_NUMBER() OVER(PARTITION BY ID_OFERTA_PROGRAMA ORDER BY ORDEN_OFERTA  ) AS ID
                        from LISTA_POTENCIALES")
  
  # HACER CORTE HASTA EL MAXIMO POSIBLE A MARCAR COMO LISTA DE ESPERA
  if(OFERTA_LISTA_ESPERA$CANTIDAD  < 4){
    LISTA_POTENCIALES <- LISTA_POTENCIALES[LISTA_POTENCIALES$ID <= OFERTA_LISTA_ESPERA$CANTIDAD * 2 ,] 
  }
  else
  {
    LISTA_POTENCIALES <- LISTA_POTENCIALES[LISTA_POTENCIALES$ID <= OFERTA_LISTA_ESPERA$CANTIDAD ,]  
  }
  
  # RECORRER LA LISTA DE POTENCIALES A MARCAR COMO LISTA DE ESPERA
  for (PERSONA_OFERTA in LISTA_POTENCIALES$ID_PERSONA_OFERTA) { 
    
    PERSONA <- LISTA_POTENCIALES[LISTA_POTENCIALES$ID_PERSONA_OFERTA==PERSONA_OFERTA, "ID_PERSONA"]
    
    #TMP_LISTA[TMP_LISTA$ID_PERSONA_OFERTA == PERSONA_OFERTA , "ASIGNACION"] <- OFERTA_LISTA_ESPERA$ASIGNACION
    TMP_LISTA[TMP_LISTA$ID_PERSONA_OFERTA == PERSONA_OFERTA , "ASIGNACION"] <- "FDL"
    TMP_LISTA[TMP_LISTA$ID_PERSONA_OFERTA == PERSONA_OFERTA, "ESTADO_ELEGIBLE"] <- "LISTA_ESPERA"
    TMP_LISTA[TMP_LISTA$ID_PERSONA_OFERTA != PERSONA_OFERTA & TMP_LISTA$ID_PERSONA ==  PERSONA, "ESTADO_ELEGIBLE"] <- "INACTIVO_LISTA_ESPERA"
    
  } # CERRAR LISTA DE POTENCIALES A MARCAR
  
} # CERRAR RECORRIDO DE OFERTAS IGUAL A FDL
cro(TMP_LISTA$ESTADO_ELEGIBLE)

#-------------------------------------------------------------------------------
#AJUSTAR ESTADO PARA PEGAR EN JE5_PER_OFERTA
#-------------------------------------------------------------------------------
colnames(TMP_LISTA)[colnames(TMP_LISTA)=="ESTADO_ELEGIBLE"]<-"ESTADO_LISTA_ESPERA"
colnames(TMP_LISTA)[colnames(TMP_LISTA)=="ASIGNACION"]<-"ASIGNACION_LISTA_ESPERA"
cro(TMP_LISTA$ESTADO_LISTA_ESPERA)

#-------------------------------------------------------------------------------
# PEGAR RESULTADO LISTA DE ESPERA EN PERSONA-OFERTA
#-------------------------------------------------------------------------------
JE5_PER_OFERTA<- merge(x=JE5_PER_OFERTA, y=TMP_LISTA[TMP_LISTA$ESTADO_LISTA_ESPERA!="DISPONIBLE",c("ID_PERSONA_OFERTA","ASIGNACION_LISTA_ESPERA", "ESTADO_LISTA_ESPERA", "ORDEN_OFERTA","ORDEN_OFERTA_LOCALIDAD","MEJOR_OPCION" )], by="ID_PERSONA_OFERTA", all.x = TRUE )
JE5_PER_OFERTA[!is.na(JE5_PER_OFERTA$ESTADO_LISTA_ESPERA),"ESTADO_ELEGIBLE"]<-JE5_PER_OFERTA[!is.na(JE5_PER_OFERTA$ESTADO_LISTA_ESPERA),"ESTADO_LISTA_ESPERA"]
cro(JE5_PER_OFERTA$ESTADO_ELEGIBLE)
