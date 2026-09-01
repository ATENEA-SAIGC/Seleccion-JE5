#==============================================================================================
# MODULO 3: CRITERIOS DE PUNTUACION
#==============================================================================================
# Referencia: lineamiento operativo, numeral 5.4.4 (Actividad 2).
#
# El PUNTAJE_GLOBAL es la suma de cuatro criterios:
#
#   CRITERIO_1_VUL_ESTRUCTURAL  Vulnerabilidad estructural - ACUMULABLE, tope 15 puntos.
#                               Suma C1_1..C1_10 (mujer, mujer con hijos, transgenero,
#                               etnia, victima, violencia de genero, reincorporado,
#                               discapacidad, Ley 1699, colegio oficial de Sumapaz o
#                               rural a mas de 3 km) y se trunca en 15.
#
#   CRITERIO_2_VUL_ECONOMICA    Vulnerabilidad economica - NO ACUMULABLE, hasta 40 puntos.
#                               C2_1 por grupo SISBEN IV (solo hogares de Bogota-Region);
#                               C2_2 aplica unicamente a quien NO tiene SISBEN.
#
#   CRITERIO_3_MERITO_ACADEMICO Merito academico - hasta 40 puntos. Desde 2016-1 se usa
#                               el percentil nacional global de la Saber 11; antes de
#                               2016-1 la escala de puesto (el ICFES no reportaba percentil).
#
#   CRITERIO_4_TRAYECTORIA      Fomento a trayectorias - NO ACUMULABLE, hasta 5 puntos.
#                               Graduado UTC, consejero de juventud electo, deportista
#                               IDRD o Jovenes con Oportunidades.
#
# Cada criterio con escalas lleva ademas una variable DTLL_* con la etiqueta legible
# del tramo aplicado, para trazabilidad en la publicacion de resultados.
#----------------------------------------------------------------------------------------------

#===============================================================================
# CALCULO CRITERIOS DE PUNTUACION 
# 5.4.4.	Actividad 2: Aplicación mecanismo de asignación de cupos
#===============================================================================

#-------------------------------------------------------------------------------
# CRITERIO 1 : Vulnerabilidad estructural (Acumulable hasta 15 puntos)
#-------------------------------------------------------------------------------
JE5 <- sqldf("SELECT *,
                     CASE WHEN SEXO IN ('MUJER') THEN 7 else 0 END C1_1, 
                     CASE WHEN SEXO IN ('MUJER') AND INFO_HIJOS IS NOT NULL AND INFO_HIJOS !='SINHIJOS' AND ATENEA_PUNTUA_HIJOS == 'S'  THEN 5 else 0 END C1_2,
                     CASE WHEN IDENTIDAD_GENERO IN ('HOMBRE TRANSGENERO', 'MUJER TRANSGENERO') THEN 10 else 0 END C1_3,
                     CASE WHEN ETNIA != 'NINGUNO' AND ATENEA_PUNTUA_ETNIA =='S' THEN 15 else 0 END C1_4,
                     CASE WHEN RA_VICTIMAS =='S'                        THEN 10 ELSE 0 END C1_5,  
                     CASE WHEN RA_VIOLENCIA_GENERO =='S'                THEN 10 ELSE 0 END C1_6,
                     CASE WHEN RA_REINCORPORADOS_REINSERTADOS =='S'     THEN 10 ELSE 0 END C1_7,  
                     CASE WHEN RA_DISCAPACIDAD_MINSALUD =='S'           THEN 10 ELSE 0 END C1_8,
                     CASE WHEN RA_MINDEFENSA_LEY1699 =='S'              THEN 10 ELSE 0 END C1_9,
                     
                     --Egresados colegios oficiales Localidad Sumapaz o en zonas rurales a más de 3 km
                     CASE WHEN SIMAT_GM_CODIGO_DANE_SEDE is not null AND  SIMAT_GM_CODIGO_DANE_SEDE in (211850000876,211001027485,211850001121,211850001171) THEN 15
                          WHEN MEN_GM_CODIGO_DANE_SEDE is not null AND  MEN_GM_CODIGO_DANE_SEDE in (211850000876,211001027485,211850001121,211850001171) THEN 15
                                                                                                        
                           ELSE 0 END C1_10
                     FROM JE5")

# SE TOTALIZAN EL CALCULO DE LAS VARIABLES QUE CONFORMAN EL CRITERIO
JE5$C1_TOTAL <- JE5$C1_1 + JE5$C1_2 + JE5$C1_3 + JE5$C1_4 +  JE5$C1_5 + JE5$C1_6 + JE5$C1_7 + JE5$C1_8 + JE5$C1_9 + JE5$C1_10 

# Se calcula el criterio teniendo en cuenta que es Acumulable hasta 15 puntos
JE5 <- sqldf("SELECT *,
                   CASE 
                        WHEN C1_TOTAL > 15 THEN 15 ELSE C1_TOTAL END CRITERIO_1_VUL_ESTRUCTURAL
                   FROM JE5")

cro(JE5$CRITERIO_1_VUL_ESTRUCTURAL)
cro(JE5$C1_TOTAL,JE5$CRITERIO_1_VUL_ESTRUCTURAL)

#-------------------------------------------------------------------------------
# CRITERIO 2 : Vulnerabilidad económica- No acumulable - Hasta 40 puntos
#-------------------------------------------------------------------------------

# CALCULO PERSONA CON SISBEN (Nota 4. únicamente las encuestas realizadas en hogares de Bogotá- Región)
# Los municipios de Bogotá Región válidos para el otorgamiento del puntaje son: Soacha, Cajicá, Chía, Cota, Facatativá, Funza, La Calera, Madrid, Mosquera, Sesquilé, Sibaté, Sopó, Tenjo, Tocancipá, Ubaté y Zipaquirá.
JE5 <- sqldf("SELECT *,
                     CASE WHEN SISBEN4_Grupo  =='A' and SISBEN4_Cod_mpio in ('11001','25754','25126','25175','25214','25269','25286','25377','25430','25473','25736','25740','25758','25799','25817','25843','25899')  THEN 40  
                          WHEN SISBEN4_Grupo  =='B' and SISBEN4_Cod_mpio in ('11001','25754','25126','25175','25214','25269','25286','25377','25430','25473','25736','25740','25758','25799','25817','25843','25899') THEN 30
                          WHEN SISBEN4_Grupo  =='C' and SISBEN4_Cod_mpio in ('11001','25754','25126','25175','25214','25269','25286','25377','25430','25473','25736','25740','25758','25799','25817','25843','25899') THEN 20
                          ELSE 0 END C2_1
                     FROM JE5")
cro(JE5$SISBEN4_Grupo, JE5$C2_1)

# CALCULO PERSONA SIN SISBEN
JE5 <- sqldf("SELECT *,
                     CASE 
                          --GRADUADOS SIMAT (OFICIAL-RURAL)
                          WHEN C2_1==0 AND SISBEN4_Grupo =='NA' AND SIMAT_GM_SECTOR =='OFICIAL' AND SIMAT_GM_ZONA == 'RURAL'  THEN 40
                          --GRADUADOS MEN (OFICIAL-RURAL)
                          WHEN C2_1==0 AND SISBEN4_Grupo =='NA' AND MEN_GM_SECTOR =='OFICIAL' AND MEN_GM_ZONA_SEDE == 'RURAL'  THEN 40
                          
                          -- ETNIA INDIGENA
                          WHEN C2_1==0 AND SISBEN4_Grupo =='NA' AND ETNIA =='INDIGENA' AND ATENEA_PUNTUA_ETNIA =='S'  THEN 30
                          
                          --GRADUADOS SIMAT
                          WHEN C2_1==0 AND SISBEN4_Grupo =='NA' AND SIMAT_GM_SECTOR =='OFICIAL' THEN 15
                          --GRADUADOS MEN
                          WHEN C2_1==0 AND SISBEN4_Grupo =='NA' AND MEN_GM_SECTOR =='OFICIAL' THEN 15
                          
                          ELSE 0 END C2_2
                     FROM JE5")
cro(JE5$C2_2)

# LA SUMATORIA DE LOS CALCULOS DEFINE EL CRITERIO 2
JE5$CRITERIO_2_VUL_ECONOMICA <- JE5$C2_1 + JE5$C2_2
cro(JE5$CRITERIO_2_VUL_ECONOMICA)
#DETALLE DE PUNTUACION 
JE5 <- sqldf("SELECT *,
                     CASE WHEN SISBEN4_Grupo  =='A' and SISBEN4_Cod_mpio in ('11001','25754','25126','25175','25214','25269','25286','25377','25430','25473','25736','25740','25758','25799','25817','25843','25899')  THEN 'SISBEN A'  
                          WHEN SISBEN4_Grupo  =='B' and SISBEN4_Cod_mpio in ('11001','25754','25126','25175','25214','25269','25286','25377','25430','25473','25736','25740','25758','25799','25817','25843','25899')  THEN 'SISBEN B'
                          WHEN SISBEN4_Grupo  =='C' and SISBEN4_Cod_mpio in ('11001','25754','25126','25175','25214','25269','25286','25377','25430','25473','25736','25740','25758','25799','25817','25843','25899')  THEN 'SISBEN C'
                          ELSE '0' END DTLL_CRITERIO_2_VUL_ECONOMICA
                     FROM JE5")
JE5[JE5$DTLL_CRITERIO_2_VUL_ECONOMICA=="0" & JE5$C2_2==40, "DTLL_CRITERIO_2_VUL_ECONOMICA"] <-"Personas sin SISBEN egresadas de colegio oficial rural"
JE5[JE5$DTLL_CRITERIO_2_VUL_ECONOMICA=="0" & JE5$C2_2==15, "DTLL_CRITERIO_2_VUL_ECONOMICA"] <-"Personas sin SISBEN egresadas de colegio oficial urbano"
JE5[JE5$DTLL_CRITERIO_2_VUL_ECONOMICA=="0" & JE5$C2_2==30, "DTLL_CRITERIO_2_VUL_ECONOMICA"] <-"Aspirantes con pertenencia étnica indígena sin SISBEN"
JE5[JE5$DTLL_CRITERIO_2_VUL_ECONOMICA=="0", "DTLL_CRITERIO_2_VUL_ECONOMICA"] <-NA
cro(JE5$DTLL_CRITERIO_2_VUL_ECONOMICA,JE5$CRITERIO_2_VUL_ECONOMICA )

#-------------------------------------------------------------------------------
# CRITERIO 3 : Mérito académico
#-------------------------------------------------------------------------------
JE5 <- sqldf("SELECT *,
                     CASE 
                     
                     --POR PERCENTIL
                     WHEN SABER11_PERIODO >= 20161 AND SABER11_PERCENTIL_NACIONAL_GLOBAL == 100 THEN 40
                     WHEN SABER11_PERIODO >= 20161 AND SABER11_PERCENTIL_NACIONAL_GLOBAL between 95 and 99 THEN 35
                     WHEN SABER11_PERIODO >= 20161 AND SABER11_PERCENTIL_NACIONAL_GLOBAL between 90 and 94 THEN 30
                     WHEN SABER11_PERIODO >= 20161 AND SABER11_PERCENTIL_NACIONAL_GLOBAL between 85 and 89 THEN 25
                     WHEN SABER11_PERIODO >= 20161 AND SABER11_PERCENTIL_NACIONAL_GLOBAL between 75 and 84 THEN 20
                     WHEN SABER11_PERIODO >= 20161 AND SABER11_PERCENTIL_NACIONAL_GLOBAL between 65 and 74 THEN 10
                     WHEN SABER11_PERIODO >= 20161 AND SABER11_PERCENTIL_NACIONAL_GLOBAL between 50 and 64 THEN 5
                     
                     --POR PUESTO
                     WHEN SABER11_PERIODO < 20161 AND SABER11_PUESTO between 1 and 10 THEN 40
                     WHEN SABER11_PERIODO < 20161 AND SABER11_PUESTO between 11 and 50 THEN 35
                     WHEN SABER11_PERIODO < 20161 AND SABER11_PUESTO between 51 and 100 THEN 30
                     WHEN SABER11_PERIODO < 20161 AND SABER11_PUESTO between 101 and 150 THEN 25
                     WHEN SABER11_PERIODO < 20161 AND SABER11_PUESTO between 151 and 250 THEN 20
                     WHEN SABER11_PERIODO < 20161 AND SABER11_PUESTO between 251 and 350 THEN 15
                     WHEN SABER11_PERIODO < 20161 AND SABER11_PUESTO between 351 and 450 THEN 10
                     WHEN SABER11_PERIODO < 20161 AND SABER11_PUESTO between 451 and 499 THEN 5
                   
                     ELSE 0 END CRITERIO_3_MERITO_ACADEMICO
                     FROM JE5")
cro(JE5$CRITERIO_3_MERITO_ACADEMICO)

JE5 <- sqldf("SELECT *,
                     CASE 
                     
                     --POR PERCENTIL
                     WHEN SABER11_PERIODO >= 20161 AND SABER11_PERCENTIL_NACIONAL_GLOBAL == 100 THEN 'Percentil 100'
                     WHEN SABER11_PERIODO >= 20161 AND SABER11_PERCENTIL_NACIONAL_GLOBAL between 95 and 99 THEN 'Percentil 95 a 99'
                     WHEN SABER11_PERIODO >= 20161 AND SABER11_PERCENTIL_NACIONAL_GLOBAL between 90 and 94 THEN 'Percentil 90 a 94'
                     WHEN SABER11_PERIODO >= 20161 AND SABER11_PERCENTIL_NACIONAL_GLOBAL between 85 and 89 THEN 'Percentil 85 a 89'
                     WHEN SABER11_PERIODO >= 20161 AND SABER11_PERCENTIL_NACIONAL_GLOBAL between 75 and 84 THEN 'Percentil 75 a 84'
                     WHEN SABER11_PERIODO >= 20161 AND SABER11_PERCENTIL_NACIONAL_GLOBAL between 65 and 74 THEN 'Percentil 65 a 74'
                     WHEN SABER11_PERIODO >= 20161 AND SABER11_PERCENTIL_NACIONAL_GLOBAL between 50 and 64 THEN 'Percentil 50 a 64'
                     WHEN SABER11_PERIODO >= 20161 THEN 'Percentil Menor a 50'
                     
                     --POR PUESTO
                     WHEN SABER11_PERIODO < 20161 AND SABER11_PUESTO between 1 and 10 THEN 'Puesto 1 a 10'
                     WHEN SABER11_PERIODO < 20161 AND SABER11_PUESTO between 11 and 50 THEN 'Puesto 11 a 50'
                     WHEN SABER11_PERIODO < 20161 AND SABER11_PUESTO between 51 and 100 THEN 'Puesto 51 a 100'
                     WHEN SABER11_PERIODO < 20161 AND SABER11_PUESTO between 101 and 150 THEN 'Puesto 101 a 150'
                     WHEN SABER11_PERIODO < 20161 AND SABER11_PUESTO between 151 and 250 THEN 'Puesto 151 a 250'
                     WHEN SABER11_PERIODO < 20161 AND SABER11_PUESTO between 251 and 350 THEN 'Puesto 251 a 350'
                     WHEN SABER11_PERIODO < 20161 AND SABER11_PUESTO between 351 and 450 THEN 'Puesto 351 a 450'
                     WHEN SABER11_PERIODO < 20161 AND SABER11_PUESTO between 451 and 499 THEN 'Puesto 451 a 499'
                     WHEN SABER11_PERIODO < 20161 THEN 'Puesto Mayor a 499'
                   
                     ELSE 'Sin Prueba Saber 11' END DTLL_CRITERIO_3_MERITO_ACADEMICO
                     FROM JE5")

cro(JE5$DTLL_CRITERIO_3_MERITO_ACADEMICO)
cro(JE5$DTLL_CRITERIO_3_MERITO_ACADEMICO, JE5$CRITERIO_3_MERITO_ACADEMICO )

#-------------------------------------------------------------------------------
# CRITERIO 4 : Fomento a trayectorias- No acumulable Hasta 5 puntos
#-------------------------------------------------------------------------------
JE5 <- sqldf("SELECT *,
                     CASE WHEN UTC_GRADUADO =='S'  THEN 5
                          WHEN RA_CONSEJERO_JUVENTUD_ELECTO =='S'  THEN 5
                          WHEN RA_DEPORTISTA_IDRD  =='S'  THEN 5
                          WHEN RA_JOVENES_OPORTUNIDADES  =='S'  THEN 5
                          
                          ELSE 0 END CRITERIO_4_TRAYECTORIA
                     FROM JE5")
cro(JE5$CRITERIO_4_TRAYECTORIA)

#-------------------------------------------------------------------------------
# SUMATORIA CRITERIOS PARA PUNTAJE_GLOBAL
#-------------------------------------------------------------------------------
JE5$CRITERIO_1_VUL_ESTRUCTURAL <- as.double(JE5$CRITERIO_1_VUL_ESTRUCTURAL)
JE5$CRITERIO_2_VUL_ECONOMICA <- as.double(JE5$CRITERIO_2_VUL_ECONOMICA)
JE5$CRITERIO_3_MERITO_ACADEMICO <- as.double(JE5$CRITERIO_3_MERITO_ACADEMICO)
JE5$CRITERIO_4_TRAYECTORIA <- as.double(JE5$CRITERIO_4_TRAYECTORIA)

JE5$PUNTAJE_GLOBAL <- JE5$CRITERIO_1_VUL_ESTRUCTURAL + JE5$CRITERIO_2_VUL_ECONOMICA + JE5$CRITERIO_3_MERITO_ACADEMICO + JE5$CRITERIO_4_TRAYECTORIA
