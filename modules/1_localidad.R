#==============================================================================================
# MODULO 1: DETERMINACION DE LA LOCALIDAD DE RESIDENCIA
#==============================================================================================
# Referencia: lineamiento operativo, numeral 5.4.2.1 (Fuentes de verificacion), Nota 2.
#
# La localidad define tanto la habilitacion (requisito d) como el Fondo de Desarrollo
# Local que financiara el cupo, por lo que se establece cruzando TRES fuentes:
#
#   DUE      Direccion unica declarada por el aspirante en SICORE
#   SISBEN4  Localidad registrada en la encuesta SISBEN IV
#   RECIBOS  Localidad derivada del recibo de servicios publicos, resuelta asi:
#              - recibo validado y IDECA coincide con SICORE      -> localidad IDECA
#              - no coinciden y la direccion la asigno Catastro   -> localidad IDECA
#              - no coinciden y la direccion NO la asigno Catastro-> localidad API Catastro
#              - sin cruce IDECA                                  -> localidad API Catastro
#            (documento "Reglas Localidad FDL JE5 Privadas.xlsx")
#
# La LOCALIDAD definitiva es aquella en la que COINCIDEN al menos dos fuentes, con
# la prelacion RECIBOS_DUE > RECIBOS_SISBEN4 > DUE_SISBEN4. Si ninguna pareja
# coincide, el aspirante queda sin localidad (NULL) y se inhabilita por el requisito d.
#----------------------------------------------------------------------------------------------

#===============================================================================
# CALCULO LOCALIDAD 
# Con Fuente RECIBO e IDECA - GEO
#===============================================================================

# Calcular variable cuando Localidad SICORE  = Localidad Recibo con Geo IDECA
INS_RECIBOS_ANALISIS$DIF_LOCALIDAD <- INS_RECIBOS_ANALISIS$IDECA_RECIBO_codloc == INS_RECIBOS_ANALISIS$SICORE_CODLOC
cro(INS_RECIBOS_ANALISIS$DIF_LOCALIDAD)

#-------------------------------------------------------------------------------
# ANALISIS DE LOCALIDAD A UTILIZAR
# Documento Reglas Localidad FDL JE5 Privadas.xlsx
#-------------------------------------------------------------------------------
INS_RECIBOS_ANALISIS$RECIBOS_CODLOC <- NA

#ESTADO FINAL RESIDENCIA = RECIBO NO VALIDADO Y Dif Localidad = TRUE, entonces Tomar Localidad  IDECA
INS_RECIBOS_ANALISIS[INS_RECIBOS_ANALISIS$ESTADO_FINAL_RESIDENCIA =="RECIBO VALIDADO" & !is.na(INS_RECIBOS_ANALISIS$DIF_LOCALIDAD) & INS_RECIBOS_ANALISIS$DIF_LOCALIDAD=="TRUE" ,"RECIBOS_CODLOC" ] <- INS_RECIBOS_ANALISIS[INS_RECIBOS_ANALISIS$ESTADO_FINAL_RESIDENCIA =="RECIBO VALIDADO" & !is.na(INS_RECIBOS_ANALISIS$DIF_LOCALIDAD) & INS_RECIBOS_ANALISIS$DIF_LOCALIDAD=="TRUE" ,"IDECA_RECIBO_codloc" ]

#Dif Localidad = FALSE y tipo_direccion = Asignada por Catastro, entonces Tomar Localidad  IDECA
INS_RECIBOS_ANALISIS[is.na(INS_RECIBOS_ANALISIS$RECIBOS_CODLOC)& INS_RECIBOS_ANALISIS$ESTADO_FINAL_RESIDENCIA =="RECIBO VALIDADO" & !is.na(INS_RECIBOS_ANALISIS$DIF_LOCALIDAD) & INS_RECIBOS_ANALISIS$DIF_LOCALIDAD=="FALSE" & INS_RECIBOS_ANALISIS$IDECA_RECIBO_tipo_direccion=="Asignada por Catastro","RECIBOS_CODLOC" ] <- 
  INS_RECIBOS_ANALISIS[is.na(INS_RECIBOS_ANALISIS$RECIBOS_CODLOC)& INS_RECIBOS_ANALISIS$ESTADO_FINAL_RESIDENCIA =="RECIBO VALIDADO" & !is.na(INS_RECIBOS_ANALISIS$DIF_LOCALIDAD) & INS_RECIBOS_ANALISIS$DIF_LOCALIDAD=="FALSE" & INS_RECIBOS_ANALISIS$IDECA_RECIBO_tipo_direccion=="Asignada por Catastro" ,"IDECA_RECIBO_codloc" ]

#Dif Localidad = FALSE y tipo_direccion != Asignada por Catastro, entonces Tomar Localidad  API CATASTRO
INS_RECIBOS_ANALISIS[is.na(INS_RECIBOS_ANALISIS$RECIBOS_CODLOC)& INS_RECIBOS_ANALISIS$ESTADO_FINAL_RESIDENCIA =="RECIBO VALIDADO" & !is.na(INS_RECIBOS_ANALISIS$DIF_LOCALIDAD) & INS_RECIBOS_ANALISIS$DIF_LOCALIDAD=="FALSE" & INS_RECIBOS_ANALISIS$IDECA_RECIBO_tipo_direccion!="Asignada por Catastro","RECIBOS_CODLOC" ] <- 
  INS_RECIBOS_ANALISIS[is.na(INS_RECIBOS_ANALISIS$RECIBOS_CODLOC)& INS_RECIBOS_ANALISIS$ESTADO_FINAL_RESIDENCIA =="RECIBO VALIDADO" & !is.na(INS_RECIBOS_ANALISIS$DIF_LOCALIDAD) & INS_RECIBOS_ANALISIS$DIF_LOCALIDAD=="FALSE" & INS_RECIBOS_ANALISIS$IDECA_RECIBO_tipo_direccion!="Asignada por Catastro" ,"API_CATASTRO_CODLOC" ]

#Dif Localidad = vacia por sin cruce ideca  API CATASTRO
INS_RECIBOS_ANALISIS[is.na(INS_RECIBOS_ANALISIS$RECIBOS_CODLOC)& INS_RECIBOS_ANALISIS$ESTADO_FINAL_RESIDENCIA =="RECIBO VALIDADO" & is.na(INS_RECIBOS_ANALISIS$DIF_LOCALIDAD),"RECIBOS_CODLOC" ] <- 
  INS_RECIBOS_ANALISIS[is.na(INS_RECIBOS_ANALISIS$RECIBOS_CODLOC)& INS_RECIBOS_ANALISIS$ESTADO_FINAL_RESIDENCIA =="RECIBO VALIDADO" & is.na(INS_RECIBOS_ANALISIS$DIF_LOCALIDAD) ,"API_CATASTRO_CODLOC" ]

cro(INS_RECIBOS_ANALISIS$RECIBOS_CODLOC)

#CONSTRUIR DESCRIPCION LOCALIDAD PARA RECIBOS_CODLOC
LOC_DESCRIP<- unique(JE5[!is.na(JE5$DUE_CODLOC),c("DUE_CODLOC","DUE_LOCALIDAD")])
colnames(LOC_DESCRIP) <- c("RECIBOS_CODLOC","RECIBOS_LOCALIDAD")
INS_RECIBOS_ANALISIS<- merge(x=INS_RECIBOS_ANALISIS, y = LOC_DESCRIP, by="RECIBOS_CODLOC", all.x = TRUE)
rm(LOC_DESCRIP)
names(INS_RECIBOS_ANALISIS)
#ORDENAR VARIABLES
INS_RECIBOS_ANALISIS <- INS_RECIBOS_ANALISIS[,c(2:23,1,24)]

# PEGAR EL CALCULO
JE5 <- merge(x=JE5,y=INS_RECIBOS_ANALISIS,by.x="ID_PERSONA",by.y = "ID_PERSONA",  all.x = TRUE)

#-------------------------------------------------------------------------------
# ANALISIS LOCALIDAD DEFINITIVA
# 5.4.2.1. Fuentes de verificación de los requisitos de participación y criterios de puntuación
# NOTA 2 (VERIFICACION CON LOCALIDAD DUE, LOCALIDAD SISBEN Y LOCALIDAD RECIBO)
#-------------------------------------------------------------------------------
ANALISIS_LOCALIDAD <- JE5[,c("ID_PERSONA","DUE_CODLOC","DUE_LOCALIDAD", "SISBEN4_CODLOC","SISBEN4_LOCALIDAD", "RECIBOS_CODLOC", "RECIBOS_LOCALIDAD" )]
ANALISIS_LOCALIDAD <- sqldf("select *,
             case when DUE_CODLOC == RECIBOS_CODLOC then RECIBOS_CODLOC
                  when SISBEN4_CODLOC == RECIBOS_CODLOC then RECIBOS_CODLOC 
                  when DUE_CODLOC == SISBEN4_CODLOC then SISBEN4_CODLOC
                  else null end CODLOC,
              
              case when DUE_CODLOC == RECIBOS_CODLOC then RECIBOS_LOCALIDAD
                  when SISBEN4_CODLOC == RECIBOS_CODLOC then RECIBOS_LOCALIDAD 
                  when DUE_CODLOC == SISBEN4_CODLOC then SISBEN4_LOCALIDAD
                  else null end LOCALIDAD,
              
              case when DUE_CODLOC == RECIBOS_CODLOC then 'RECIBOS_DUE'
                  when SISBEN4_CODLOC == RECIBOS_CODLOC then 'RECIBOS_SISBEN4' 
                  when DUE_CODLOC == SISBEN4_CODLOC then 'DUE_SISBEN4'
                  else null end ANALISIS_LOCALIDAD 
             
             from ANALISIS_LOCALIDAD")
cro(ANALISIS_LOCALIDAD$ANALISIS_LOCALIDAD)

# PEGAR RESULTADO A DATAFRAME PERSONA UNICA
JE5 <- merge(x=JE5,y=ANALISIS_LOCALIDAD[,c("ID_PERSONA","CODLOC","LOCALIDAD","ANALISIS_LOCALIDAD")],by.x="ID_PERSONA",by.y = "ID_PERSONA",  all.x = TRUE)
rm(ANALISIS_LOCALIDAD)
