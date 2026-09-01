#==============================================================================================
# MODULO 5: ASIGNACION DE CUPOS (ELEGIBLES)
#==============================================================================================
# Referencia: lineamiento operativo, numerales 5.3.3.1 y 5.4.4 (Actividad 2, Paso 3).
#
# Antes del recorrido aplica los requisitos adicionales fijados por las IES
# (numeral 5.3.3.1): para la Universidad de los Andes (SNIES 1813) se exige
# SABER11_PUNTAJE_GLOBAL >= 370. Quien no lo cumple queda excluido de ESA oferta,
# no de la convocatoria.
#
# Luego recorre a los aspirantes habilitados en el orden de JE5_LLAVE_PER y, para
# cada uno, sus ofertas en orden de PRIORIDAD. Cada oferta tiene DOS bolsas de cupos
# que se evaluan en este orden:
#
#   1) RECOMPOSICION (CUPOS_CONTROL_RECOMP) - se evalua SIEMPRE primero.
#      El detalle de BASE_OFERTA_RECOMP puede traer cupos sin localidad (bolsa
#      ATENEA) o cupos atados a una localidad especifica. Se prefiere el cupo sin
#      localidad; si no queda, se intenta el cupo de la localidad del aspirante.
#      Esta bolsa NO consume presupuesto de FDL.
#
#   2) GENERAL (CUPOS_CONTROL) - solo si no hubo cupo de recomposicion Y el aspirante
#      quedo 'HABILITADO' en el requisito d (no 'HABILITADO_RECOMPOSICION').
#      Requiere ademas que el FDL de su localidad alcance a cubrir el
#      TOTAL_VALOR_COHORTE_ATENEA; si no alcanza se marca FDL_SIN_PRESUPUESTO.
#
# Al asignarse un cupo, las demas ofertas del aspirante quedan INACTIVO ("-").
# Cierra construyendo ESTADO_ELEGIBLE sobre el universo completo persona-oferta.
#----------------------------------------------------------------------------------------------

#===============================================================================
# CALCULO DE ELEGIBLES
# 5.4.4. Actividad 2: Aplicación mecanismo de asignación de cupos
# Paso 3: Asignación de cupos
#===============================================================================

#-------------------------------------------------------------------------------
# PEGUE DATOS PERSONA UNICA A PERSONA-OFERTA
# JE5_LLAVE_PER, HABILITADO, HABILITADO_D, CODLOC, LOCALIDAD
#-------------------------------------------------------------------------------
JE5_PER_OFERTA <- merge(x=JE5_PER_OFERTA, y=JE5[,c("JE5_LLAVE_PER","ID_PERSONA","HABILITADO", "HABILITADO_D", "CODLOC","LOCALIDAD")], by="ID_PERSONA", all = FALSE )

#-------------------------------------------------------------------------------
# CREACION DE POTENCIALES ELEGIBLES
#-------------------------------------------------------------------------------
TMP_ELEGIBLE<- JE5_PER_OFERTA[JE5_PER_OFERTA$HABILITADO=="HABILITADO" 
                              , c("JE5_LLAVE_PER","ID_OFERTA_PROGRAMA", "PRIORIDAD","CODIGO_SNIES_IES", "NOMBRE_INSTITUCION_SUPERIOR","CODIGO_SNIES_PROGRAMA","NOMBRE_PROGRAMA","NIVEL_FORMACION", "ID_PERSONA","ID_PERSONA_OFERTA","CODLOC","LOCALIDAD", "HABILITADO", "HABILITADO_D")]

#-------------------------------------------------------------------------------
# VALIDACIONES POR CONDICIONES ESPECIFICAS IES Y PROGRAMAS
# 5.3.3.1. Requisitos y costos adicionales establecidos por las IES
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PEGUE DATOS PERSONA UNICA A POTENCIALES ELEGIBLES
# SABER11_REGISTRO_SNP,SABER11_PERIODO,SABER11_PUNTAJE_GLOBAL
#-------------------------------------------------------------------------------
TMP_ELEGIBLE <- merge(x=TMP_ELEGIBLE, y=JE5[,c("ID_PERSONA","SABER11_REGISTRO_SNP","SABER11_PERIODO","SABER11_PUNTAJE_GLOBAL")], by="ID_PERSONA", all = FALSE)

TMP_ELEGIBLE$HABILITADO_IES <- NA
# UNIVERSIDAD DE LOS ANDES
TMP_ELEGIBLE[TMP_ELEGIBLE$CODIGO_SNIES_IES==1813 &  !is.na(TMP_ELEGIBLE$SABER11_PUNTAJE_GLOBAL) & TMP_ELEGIBLE$SABER11_PUNTAJE_GLOBAL >=370, "HABILITADO_IES"] <- "1-HABILITADO"
TMP_ELEGIBLE[TMP_ELEGIBLE$CODIGO_SNIES_IES==1813 & is.na(TMP_ELEGIBLE$HABILITADO_IES), "HABILITADO_IES"] <-"2-INHABILITA_CRITERIO_IES" 
# MARCACION VACIOS COMO HABILITADO
TMP_ELEGIBLE[is.na(TMP_ELEGIBLE$HABILITADO_IES), "HABILITADO_IES"] <- "0-NOAPLICA"
cro(TMP_ELEGIBLE$HABILITADO_IES)

# PEGUE RESULTADO HABILITADO IES
JE5_PER_OFERTA <- merge(x=JE5_PER_OFERTA, y=TMP_ELEGIBLE[,c("ID_PERSONA_OFERTA","HABILITADO_IES")],  by="ID_PERSONA_OFERTA", all.x = TRUE )

# EXCLUIR REGISTROS QUE NO CUMPLEN LOS CRITERIOS DE LAS IES
TMP_ELEGIBLE <- TMP_ELEGIBLE[TMP_ELEGIBLE$HABILITADO_IES != "2-INHABILITA_CRITERIO_IES",]
cro(TMP_ELEGIBLE$HABILITADO_IES)

#-------------------------------------------------------------------------------
# ORDENAMIENTO POTENCIALES Y CREACION DE VARIABLES  
#-------------------------------------------------------------------------------
TMP_ELEGIBLE<- TMP_ELEGIBLE[order(TMP_ELEGIBLE$JE5_LLAVE_PER, TMP_ELEGIBLE$PRIORIDAD),] 
TMP_ELEGIBLE$ELEGIBLE <- NA
TMP_ELEGIBLE$ASIGNACION <- NA
TMP_ELEGIBLE$ASIGNACION_DETALLE <- NA
TMP_ELEGIBLE$VALOR_PROGRAMA <- NA


BASE_FDL$PRESUPUESTO_FDL <- BASE_FDL$JE5_Privadas
sum(BASE_FDL[!is.na(BASE_FDL$CODLOC),"PRESUPUESTO_FDL"] )

BASE_OFERTA$CUPOS_CONTROL<-BASE_OFERTA$CUPOS_GENERAL 
sum(BASE_OFERTA$CUPOS_CONTROL)

BASE_OFERTA$CUPOS_CONTROL_RECOMP<-BASE_OFERTA$CUPOS_RECOMPOSICION
sum(BASE_OFERTA$CUPOS_CONTROL_RECOMP)

BASE_OFERTA_RECOMP$CUPOS_CONTROL_RECOMP<-BASE_OFERTA_RECOMP$CUPOS_RECOMPOSICION
sum(BASE_OFERTA_RECOMP$CUPOS_CONTROL_RECOMP)

# RECORRIDO DE INSCRITOS POTENCIALES
for (aspirante in unique(TMP_ELEGIBLE$JE5_LLAVE_PER)) { # RECORRER POR PERSONA ordenada por la LLAVE
  print(paste(aspirante, sep = "|") )
  
  # DATAFRAME DE LA PERSONA
  PERSONA_HABILITADA <- TMP_ELEGIBLE[TMP_ELEGIBLE$JE5_LLAVE_PER==aspirante,]
  #LOCALIDAD DE LA PERSONA
  PERSONA_LOCALIDAD <- unique(PERSONA_HABILITADA$CODLOC)
  
  #SE ORDENA EL DATAFRAME DE LAS OFERTAS DE LA PERSONA POR PRIORIDAD
  PERSONA_HABILITADA<- PERSONA_HABILITADA[order(PERSONA_HABILITADA$PRIORIDAD),] 
  
  # SE RECORRE LAS OFERTAS APLICADAS POR LA PERSONA
  for (prioridad in PERSONA_HABILITADA$PRIORIDAD) {
    
    # DATAFRAME DE LA PERSONA_OFERTA X PRIORIDAD
    PERSONA_OFERTA <- PERSONA_HABILITADA[PERSONA_HABILITADA$PRIORIDAD==prioridad,]
    EVALUAR_OFERTA <- BASE_OFERTA[BASE_OFERTA$ID_OFERTA_PROGRAMA==PERSONA_OFERTA$ID_OFERTA_PROGRAMA,]
    
    # BANDERA PARA RECOMPOSICION
    RECOMPOSICION<- 0
    #---------------------------------------------------------------------------
    #--------------------------------  ANALISIS RECOMPOSICION    ----------------------------
    #---------------------------------------------------------------------------
    if(EVALUAR_OFERTA$CUPOS_CONTROL_RECOMP > 0 & is.na(PERSONA_OFERTA$ELEGIBLE)) {
      
      EVALUAR_OFERTA_DETALLE <- BASE_OFERTA_RECOMP[BASE_OFERTA_RECOMP$ID_OFERTA_PROGRAMA==EVALUAR_OFERTA$ID_OFERTA_PROGRAMA,]
      
      # La oferta tienen registros donde hay cupos
      if(nrow(EVALUAR_OFERTA_DETALLE) > 0){
        
        #OFERTA SIN LOCALIDAD
        EVALUA_SIN_LOC <- EVALUAR_OFERTA_DETALLE[is.na(EVALUAR_OFERTA_DETALLE$CODLOC),]
        
        #OFERTA CON LOCALIDAD
        if(!is.na(PERSONA_LOCALIDAD)){
          # Crear Dataframe unicamente con las ofertas que le aplican por localidad
          EVALUA_CON_LOC <- EVALUAR_OFERTA_DETALLE[!is.na(EVALUAR_OFERTA_DETALLE$CODLOC) & EVALUAR_OFERTA_DETALLE$CODLOC==PERSONA_LOCALIDAD,]  
        }
        
        # SE ELIGE LA MEJOR OFERTA
        if(nrow(EVALUA_SIN_LOC) > 0 ){
          if(EVALUA_SIN_LOC$CUPOS_CONTROL_RECOMP > 0){
            print("DETALLE_ATENEA")
            EVALUAR_OFERTA_DETALLE <- EVALUA_SIN_LOC
            RECOMPOSICION <- 1
          }else if(!is.na(PERSONA_LOCALIDAD) ){
            if(nrow(EVALUA_CON_LOC) > 0){
              if(EVALUA_CON_LOC$CUPOS_CONTROL_RECOMP > 0){
                print("DETALLE_LOC CUANDO NO HAY EN ATENEA")
                EVALUAR_OFERTA_DETALLE <- EVALUA_CON_LOC
                RECOMPOSICION <- 1
              }
            }
          }
          
        }else
          if(!is.na(PERSONA_LOCALIDAD) ){
            if(nrow(EVALUA_CON_LOC) > 0){
              if(EVALUA_CON_LOC$CUPOS_CONTROL_RECOMP > 0){
                print("DETALLE_LOC")
                EVALUAR_OFERTA_DETALLE <- EVALUA_CON_LOC
                RECOMPOSICION <- 1
              }
            }
          }
        
      }# DETALLE DE LA RECOMPOSICION
    }
    #---------------------------------------------------------------------------
    #--------------------------------  CUPOS RECOMPOSICION    ----------------------------
    #---------------------------------------------------------------------------
    if(RECOMPOSICION == 1  & is.na(PERSONA_OFERTA$ELEGIBLE)) {
      if(EVALUAR_OFERTA_DETALLE$CUPOS_CONTROL_RECOMP > 0){
        #---------------------------------------------------------------------------
        ###---------------------------RECOMP---------------------------------------
        #---------------------------------------------------------------------------
        
        #REGISTRO SIN EVALUAR
        if(is.na(PERSONA_OFERTA$ELEGIBLE)) {
          
          print("ASIGNANDO-RECOMPOSICION")
          
          #COMO CUMPLE HACEMOS LAS MARCACIONES CORRESPONDIENTES
          #MARCAMOS DAFRAME PERSONA
          PERSONA_HABILITADA[PERSONA_HABILITADA$ID_PERSONA_OFERTA == PERSONA_OFERTA$ID_PERSONA_OFERTA , "ELEGIBLE"] <- EVALUAR_OFERTA_DETALLE$CUPOS_CONTROL_RECOMP
          PERSONA_HABILITADA[is.na(PERSONA_HABILITADA$ELEGIBLE) & PERSONA_HABILITADA$ID_PERSONA_OFERTA != PERSONA_OFERTA$ID_PERSONA_OFERTA , "ELEGIBLE"] <- "-"
          
          TMP_ELEGIBLE[TMP_ELEGIBLE$ID_PERSONA_OFERTA == PERSONA_OFERTA$ID_PERSONA_OFERTA , "ELEGIBLE"] <- EVALUAR_OFERTA_DETALLE$CUPOS_CONTROL_RECOMP
          TMP_ELEGIBLE[TMP_ELEGIBLE$ID_PERSONA_OFERTA == PERSONA_OFERTA$ID_PERSONA_OFERTA , "ASIGNACION"] <- "RECOMPOSICION"
          TMP_ELEGIBLE[TMP_ELEGIBLE$ID_PERSONA_OFERTA == PERSONA_OFERTA$ID_PERSONA_OFERTA , "ASIGNACION_DETALLE"] <- EVALUAR_OFERTA_DETALLE$LOCALIDAD
          
          TMP_ELEGIBLE[is.na(TMP_ELEGIBLE$ELEGIBLE) & TMP_ELEGIBLE$ID_PERSONA == PERSONA_OFERTA$ID_PERSONA & TMP_ELEGIBLE$ID_PERSONA_OFERTA != PERSONA_OFERTA$ID_PERSONA_OFERTA, "ELEGIBLE"] <- "-"
          TMP_ELEGIBLE[is.na(TMP_ELEGIBLE$ASIGNACION) & TMP_ELEGIBLE$ID_PERSONA == PERSONA_OFERTA$ID_PERSONA & TMP_ELEGIBLE$ID_PERSONA_OFERTA != PERSONA_OFERTA$ID_PERSONA_OFERTA, "ASIGNACION"] <- "INACTIVO_RECOMPOSICION"
          
          #AFECTAMOS CUPO
          nuevo_cupo<- EVALUAR_OFERTA$CUPOS_CONTROL_RECOMP - 1
          BASE_OFERTA[BASE_OFERTA$ID_OFERTA_PROGRAMA==PERSONA_OFERTA$ID_OFERTA_PROGRAMA, "CUPOS_CONTROL_RECOMP" ] <- nuevo_cupo
          
          nuevo_cupod<- EVALUAR_OFERTA_DETALLE$CUPOS_CONTROL_RECOMP - 1
          if(is.na(EVALUAR_OFERTA_DETALLE$CODLOC)){
            BASE_OFERTA_RECOMP[BASE_OFERTA_RECOMP$ID_OFERTA_PROGRAMA==EVALUAR_OFERTA_DETALLE$ID_OFERTA_PROGRAMA & is.na(BASE_OFERTA_RECOMP$CODLOC) , "CUPOS_CONTROL_RECOMP" ] <- nuevo_cupod
          }else{
            BASE_OFERTA_RECOMP[BASE_OFERTA_RECOMP$ID_OFERTA_PROGRAMA==EVALUAR_OFERTA_DETALLE$ID_OFERTA_PROGRAMA & !is.na(BASE_OFERTA_RECOMP$CODLOC) & BASE_OFERTA_RECOMP$CODLOC==EVALUAR_OFERTA_DETALLE$CODLOC, "CUPOS_CONTROL_RECOMP" ] <- nuevo_cupod
          }
        }#FIN REGISTRO SIN EVALUAR
      }
    }# CIERRE CUPOS RECOMPOSICION
    
    #---------------------------------------------------------------------------
    #--------------------------------  CUPOS GENERAL    ----------------------------
    #---------------------------------------------------------------------------
    else 
      if(PERSONA_OFERTA$HABILITADO_D=="HABILITADO"){
        if(EVALUAR_OFERTA$CUPOS_CONTROL > 0 & is.na(PERSONA_OFERTA$ELEGIBLE)) {
          
          
          #PRESUPUESTO PARA LA LOCALIDAD de la PERSONA
          PRESUPUESTO_FDL    <- BASE_FDL[!is.na(BASE_FDL$CODLOC) & BASE_FDL$CODLOC==PERSONA_LOCALIDAD,]
          
          #---------------------------------------------------------------------------
          ###---------------------------GENERAL---------------------------------------
          #---------------------------------------------------------------------------
          
          #REGISTRO SIN EVALUAR
          if(is.na(PERSONA_OFERTA$ELEGIBLE)) {
            
            if(PRESUPUESTO_FDL$PRESUPUESTO_FDL / EVALUAR_OFERTA$TOTAL_VALOR_COHORTE_ATENEA >= 1 ) {
              print("ASIGNANDO-GENERAL")
              
              #COMO CUMPLE HACEMOS LAS MARCACIONES CORRESPONDIENTES
              #MARCAMOS DAFRAME PERSONA
              PERSONA_HABILITADA[PERSONA_HABILITADA$ID_PERSONA_OFERTA == PERSONA_OFERTA$ID_PERSONA_OFERTA , "ELEGIBLE"] <- EVALUAR_OFERTA$CUPOS_CONTROL
              PERSONA_HABILITADA[is.na(PERSONA_HABILITADA$ELEGIBLE) & PERSONA_HABILITADA$ID_PERSONA_OFERTA != PERSONA_OFERTA$ID_PERSONA_OFERTA , "ELEGIBLE"] <- "-"
              
              TMP_ELEGIBLE[TMP_ELEGIBLE$ID_PERSONA_OFERTA == PERSONA_OFERTA$ID_PERSONA_OFERTA , "ELEGIBLE"] <- EVALUAR_OFERTA$CUPOS_CONTROL
              TMP_ELEGIBLE[TMP_ELEGIBLE$ID_PERSONA_OFERTA == PERSONA_OFERTA$ID_PERSONA_OFERTA , "ASIGNACION"] <- "GENERAL"
              TMP_ELEGIBLE[TMP_ELEGIBLE$ID_PERSONA_OFERTA == PERSONA_OFERTA$ID_PERSONA_OFERTA , "ASIGNACION_DETALLE"] <- PRESUPUESTO_FDL$LOCALIDAD
              TMP_ELEGIBLE[TMP_ELEGIBLE$ID_PERSONA_OFERTA == PERSONA_OFERTA$ID_PERSONA_OFERTA , "VALOR_PROGRAMA"] <- EVALUAR_OFERTA$TOTAL_VALOR_COHORTE_ATENEA
              TMP_ELEGIBLE[is.na(TMP_ELEGIBLE$ELEGIBLE) & TMP_ELEGIBLE$ID_PERSONA == PERSONA_OFERTA$ID_PERSONA & TMP_ELEGIBLE$ID_PERSONA_OFERTA != PERSONA_OFERTA$ID_PERSONA_OFERTA, "ELEGIBLE"] <- "-"
              TMP_ELEGIBLE[is.na(TMP_ELEGIBLE$ASIGNACION) & TMP_ELEGIBLE$ID_PERSONA == PERSONA_OFERTA$ID_PERSONA & TMP_ELEGIBLE$ID_PERSONA_OFERTA != PERSONA_OFERTA$ID_PERSONA_OFERTA, "ASIGNACION"] <- "INACTIVO_GENERAL"
              
              #AFECTAMOS CUPO
              nuevo_cupo<- EVALUAR_OFERTA$CUPOS_CONTROL - 1
              BASE_OFERTA[BASE_OFERTA$ID_OFERTA_PROGRAMA==PERSONA_OFERTA$ID_OFERTA_PROGRAMA, "CUPOS_CONTROL" ] <- nuevo_cupo
              
              #AFECTAMOS PRESUPUESTO LOCALIDAD
              BASE_FDL[!is.na(BASE_FDL$CODLOC) & BASE_FDL$CODLOC==PRESUPUESTO_FDL$CODLOC, "PRESUPUESTO_FDL"] <- PRESUPUESTO_FDL$PRESUPUESTO_FDL - EVALUAR_OFERTA$TOTAL_VALOR_COHORTE_ATENEA
            } # CIERRE ASIGNACION
            else
            {
              TMP_ELEGIBLE[TMP_ELEGIBLE$ID_PERSONA_OFERTA == PERSONA_OFERTA$ID_PERSONA_OFERTA , "ASIGNACION"] <- "FDL_SIN_PRESUPUESTO"
            }#SIN PRESUPUESTO
          }#FIN REGISTRO SIN EVALUAR
        }# CIERRE CUPOS
        else if(EVALUAR_OFERTA$CUPOS_CONTROL < 1) {
          #print("--------SIN CUPOS------")
          TMP_ELEGIBLE[TMP_ELEGIBLE$ID_PERSONA_OFERTA == PERSONA_OFERTA$ID_PERSONA_OFERTA , "ASIGNACION"] <- "SIN_CUPOS_GENERAL"
        }
      }#FIN HABILITADO PARA GENERAL
    else if(EVALUAR_OFERTA$CUPOS_CONTROL_RECOMP < 1) {
      #print("--------SIN CUPOS RECOMP------")
      TMP_ELEGIBLE[TMP_ELEGIBLE$ID_PERSONA_OFERTA == PERSONA_OFERTA$ID_PERSONA_OFERTA , "ASIGNACION"] <- "SIN_CUPOS_RECOMPOSICION"
    }
    
  }# CIERRE RECORRIDO OFERTAS DE LA PERSONA
}# CIERRE PERSONA

cro(TMP_ELEGIBLE$ASIGNACION)
cro(TMP_ELEGIBLE$ASIGNACION_DETALLE,TMP_ELEGIBLE$ASIGNACION )

#-------------------------------------------------------------------------------
# PEGAR RESULTADO EN PERSONA-OFERTA
#-------------------------------------------------------------------------------
dim(JE5_PER_OFERTA)
JE5_PER_OFERTA<- merge(x=JE5_PER_OFERTA, y=TMP_ELEGIBLE[,c("ID_PERSONA_OFERTA","ELEGIBLE", "ASIGNACION", "ASIGNACION_DETALLE","VALOR_PROGRAMA")], by="ID_PERSONA_OFERTA", all.x = TRUE )
dim(JE5_PER_OFERTA)

#-------------------------------------------------------------------------------
# CONSTRUCCCION ESTADO ELEGIBLE
#-------------------------------------------------------------------------------
JE5_PER_OFERTA$ESTADO_ELEGIBLE<- NA
JE5_PER_OFERTA[is.na(JE5_PER_OFERTA$ESTADO_ELEGIBLE) & JE5_PER_OFERTA$PRIORIDAD > 3  ,"ESTADO_ELEGIBLE"]<-"NO_ELEGIBLE"
JE5_PER_OFERTA[!is.na(JE5_PER_OFERTA$ASIGNACION) & is.na(JE5_PER_OFERTA$ESTADO_ELEGIBLE) & JE5_PER_OFERTA$ASIGNACION %in% c("GENERAL","RECOMPOSICION")  ,"ESTADO_ELEGIBLE"]<-"ELEGIBLE"
JE5_PER_OFERTA[!is.na(JE5_PER_OFERTA$ELEGIBLE) & JE5_PER_OFERTA$ELEGIBLE=="-" ,"ESTADO_ELEGIBLE"]<-"INACTIVO"
JE5_PER_OFERTA[is.na(JE5_PER_OFERTA$ESTADO_ELEGIBLE),"ESTADO_ELEGIBLE"]<-"DISPONIBLE"
JE5_PER_OFERTA[JE5_PER_OFERTA$HABILITADO!="HABILITADO","ESTADO_ELEGIBLE"]<-"NO_ELEGIBLE"
JE5_PER_OFERTA[!is.na(JE5_PER_OFERTA$HABILITADO_IES) & JE5_PER_OFERTA$HABILITADO_IES=="2-INHABILITA_CRITERIO_IES","ESTADO_ELEGIBLE"]<-"NO_ELEGIBLE"


cro(JE5_PER_OFERTA$ESTADO_ELEGIBLE)
cro(JE5_PER_OFERTA$ASIGNACION, JE5_PER_OFERTA$ESTADO_ELEGIBLE)

# BORRAR VARIABLES Y DATAFRAME QUE NO CUMPLEN SU OBJETO PARA EL CALCULO Y NO SE USAN MAS
rm(EVALUA_CON_LOC,EVALUA_SIN_LOC,EVALUAR_OFERTA,EVALUAR_OFERTA_DETALLE,PERSONA_HABILITADA,PERSONA_OFERTA,PRESUPUESTO_FDL,aspirante,nuevo_cupo,nuevo_cupod,PERSONA_LOCALIDAD,prioridad,RECOMPOSICION)
