#==============================================================================================
# MODULO 2: HABILITACION DE ASPIRANTES
#==============================================================================================
# Referencia: lineamiento operativo, numeral 5.3.3 (Requisitos de participacion).
#
# Comienza derivando RA_ICFES_VALIDACION, que distingue a quien obtuvo el titulo de
# bachiller por validacion del ICFES (registro SNP 'VG%' sin grado medio en SIMAT/MEN,
# o con grado medio fuera de Bogota) de quien lo obtuvo por grado medio ordinario.
# Esa marca cambia como se evalua el requisito a).
#
# Luego evalua cada requisito de forma independiente y resuelve la habilitacion final
# (HABILITADO) de forma SECUENCIAL: el primer requisito incumplido determina la causal.
#
#   HABILITADO_A  a) Bachiller de colegio de Bogota o validante ICFES en Bogota (>= 30 pts)
#   HABILITADO_B  b) Prueba Saber 11 presentada y publicada en Bogota
#   HABILITADO_C  c) Hasta 28 anos al cierre de inscripcion (2026-06-10)
#   HABILITADO_D  d) Residir en una localidad con cupos en la convocatoria
#   HABILITADO_E  e) Estado "Graduado" en SNIES si estuvo matriculado en TyT 2025-2 / 2026-1
#   HABILITADO_F  f) No matriculado en programa universitario en 2025-2 / 2026-1
#   HABILITADO_G  g) No graduado de programa universitario
#   HABILITADO_H  h) No beneficiario previo de programas ATENEA / SED
#   HABILITADO_I  -  Identidad valida en RNEC / Migracion
#
# NOTA sobre HABILITADO_D: tiene TRES estados, no dos. Las localidades con cupos
# generales quedan 'HABILITADO'; las localidades sin cupos de la convocatoria pero
# elegibles por recomposicion quedan 'HABILITADO_RECOMPOSICION' (siguen habilitadas,
# pero en el Modulo 5 solo pueden acceder a cupos de recomposicion); y las localidades
# expresamente excluidas quedan 'NO_HABILITADO'.
#----------------------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# ANALISIS VARIABLE RA_ICFES_VALIDACION
# Regla1: ES VALIDACION CUANDO TIENE INFO EN VALIDACION Y NO EN GRADO MEDIA
# Regla2: ES VALIDACION CUANDO TIENE INFO EN VALIDACION Y GRADO MEDIA ES DIF BOGOTA
#-------------------------------------------------------------------------------

JE5<- sqldf("SELECT *, 
            case 
            
           -- 1. SABER11 y no tiene registro en graduación o matricula
            when VALIDACION_ICFES_REGISTRO_SNP is not null AND  VALIDACION_ICFES_REGISTRO_SNP like 'VG%'  
                                                       AND SIMAT_GM_Divipola_MUNICIPIO is null
                                                       AND MEN_GM_Divipola_MUNICIPIO is null THEN 'S'
            
            --2. SABER11 ES VG y el divipola de grado MEN es diferente a Bogota
            when VALIDACION_ICFES_REGISTRO_SNP is not null AND VALIDACION_ICFES_REGISTRO_SNP like 'VG%'  
                                                       AND MEN_GM_Divipola_MUNICIPIO is not null 
                                                       AND MEN_GM_Divipola_MUNICIPIO != 11001 THEN 'S'
            
            -- 4.ES registro en graduación o matricula
            when    SIMAT_GM_Divipola_MUNICIPIO is not null
                  OR MEN_GM_Divipola_MUNICIPIO is not null THEN 'N'
                                                        
            else 'SD' end RA_ICFES_VALIDACION from JE5")
cro(JE5$RA_ICFES_VALIDACION)

#===============================================================================
# CALCULO HABILITADOS 
# 5.3.3.	Requisitos de participación
#===============================================================================

JE5$CORTE_EDAD <- as.integer(age_calc(as.Date(JE5$FECHA_NACIMIENTO, format = "%Y-%m-%d"), enddate = as.Date("2026-06-10"), units = "years", precise = TRUE))
cro(JE5$CORTE_EDAD)

#-------------------------------------------------------------------------------
# CRITERIO A
# a) Ser bachiller egresado de un colegio ubicado en Bogotá y autorizado por la 
# Secretaría de Educación del Distrito al cierre de la inscripción en la convocatoria, 
# o haber obtenido el título de Bachiller mediante la prueba de validación del 
# ICFES presentada en Bogotá.
#-------------------------------------------------------------------------------
JE5 <- sqldf("SELECT *,
                     CASE 
                     WHEN     SIMAT_GM_Divipola_MUNICIPIO is null 
                          AND MEN_GM_Divipola_MUNICIPIO is null 
                          AND VALIDACION_ICFES_PERIODO is null THEN '01_SIN_GM_SIN_VALIDACION_ICFES'

                     WHEN  RA_ICFES_VALIDACION=='N' AND SIMAT_GM_Divipola_MUNICIPIO is not null AND SIMAT_GM_Divipola_MUNICIPIO!='11001' THEN '02_SIMAT_GM_NOBOGOTA'
                     WHEN  RA_ICFES_VALIDACION=='N' AND MEN_GM_Divipola_MUNICIPIO  is not null AND MEN_GM_Divipola_MUNICIPIO!='11001' THEN '02_MEN_GM_NOBOGOTA' 
                     
                     WHEN  RA_ICFES_VALIDACION=='S' AND VALIDACION_ICFES_REGISTRO_SNP like 'VG%' AND (VALIDACION_ICFES_PUNTAJE_GLOBAL < 30 OR VALIDACION_ICFES_PUNTAJE_GLOBAL is null) THEN '04_VALIDANTE_MENOR30_PUNTOS'
                     WHEN  RA_ICFES_VALIDACION=='S' AND VALIDACION_ICFES_REGISTRO_SNP like 'VG%' AND VALIDACION_ICFES_MUNICIPIO_APLICACION !='BOGOTÁ D.C.'  THEN '05_VALIDANTE_NO_BOGOTA'
                     
                     ELSE 'HABILITADO' END HABILITADO_A
                     FROM JE5")

cro(JE5$HABILITADO_A)

#-------------------------------------------------------------------------------
# CRITERIO B
# b) Haber presentado la prueba Saber 11° del ICFES en la ciudad de Bogotá.
#-------------------------------------------------------------------------------
JE5 <- sqldf("SELECT *,
                     CASE 
                     WHEN SABER11_PERIODO is null THEN 'NO_HABILITADO'
                     WHEN SABER11_ESTADO_PUBLICACION is null OR SABER11_ESTADO_PUBLICACION != 'PUBLICADO'  THEN 'NO_PUBLICADO'
                     WHEN SABER11_MUNICIPIO_APLICACION is null OR SABER11_MUNICIPIO_APLICACION != 'BOGOTÁ D.C.'  THEN 'NO_HABILITADO'
                     ELSE 'HABILITADO' END HABILITADO_B
                     FROM JE5")
cro(JE5$HABILITADO_B)

#-------------------------------------------------------------------------------
# CRITERIO C
# c) Tener hasta 28 años al cierre de la inscripción de la convocatoria de acuerdo 
# con el cronograma definido.
#-------------------------------------------------------------------------------
JE5 <- sqldf("SELECT *,
                     CASE 
                     WHEN CORTE_EDAD > 28 THEN 'NO_HABILITADO' ELSE 'HABILITADO' END HABILITADO_C
                     FROM JE5")
cro(JE5$HABILITADO_C)

#-------------------------------------------------------------------------------
# CRITERIO D 
# d) Residir en la ciudad de Bogotá D.C. en las localidades con cupos de la presente 
# convocatoria, estipuladas en la nota 6 del presente numeral.
#-------------------------------------------------------------------------------
JE5 <- sqldf("SELECT *,
                     CASE 
                     WHEN LOCALIDAD is null THEN 'NO_HABILITADO'
                     WHEN LOCALIDAD in ('LA CANDELARIA','SUMAPAZ','BARRIOS UNIDOS','ENGATIVA','SANTA FE') THEN 'NO_HABILITADO'
                     WHEN LOCALIDAD in ( 'USAQUEN','USME','BOSA','KENNEDY','TEUSAQUILLO','LOS MARTIRES','CIUDAD BOLIVAR') THEN 'HABILITADO' ELSE 'HABILITADO_RECOMPOSICION' END HABILITADO_D
                     FROM JE5")
cro(JE5$HABILITADO_D)

#-------------------------------------------------------------------------------
# CRITERIO E
# e) Contar con estado “Graduado” en el sistema de información SNIES si estuvo 
# matriculado en un programa técnico profesional o tecnológico en los semestres 
# 2025-II y/o 2026-I. Este requisito no aplica para estudiantes del SENA que 
# estén cursando un programa tecnológico y que hayan finalizado su etapa lectiva 
# y se encuentren en la etapa práctica.
#-------------------------------------------------------------------------------
JE5 <- sqldf("SELECT *,
                     CASE 
                     
                     -- MATRICULA TYT 2026_1 (SIN SENA)
                     WHEN TYT_MATRICULA_2026_1 IS NOT NULL 
                          AND TYT_GRADUACION_MATRICULA_2026_1 like '%NO_GRADUADO%' 
                          AND SENA_Registra_Certificado is null AND UTC_GRADUADO=='N'
                          THEN '1_TYT_20261_SINGRADO'
                     
                     -- MATRICULA TYT 2025_2(SIN SENA)
                     WHEN TYT_MATRICULA_2025_2 IS NOT NULL 
                          AND TYT_GRADUACION_MATRICULA_2025_2 like '%NO_GRADUADO%'  
                          AND SENA_Registra_Certificado is null AND UTC_GRADUADO=='N'
                          THEN '2_TYT_20252_SINGRADO'
                     
                    -- MATRICULA TYT 2026_1 Y CONTRATO SENA MENOR AL INICIO DE LA CONVOCATORIA
                     WHEN TYT_MATRICULA_2026_1 IS NOT NULL 
                          AND TYT_GRADUACION_MATRICULA_2026_1 like '%NO_GRADUADO%'
                          AND UTC_GRADUADO=='N'
                          AND SENA_Registra_Certificado =='NO' 
                          AND (SENA_Fecha_Fin_Contrato < '2026-06-03' OR SENA_Fecha_Fin_Contrato is null) THEN '3_TYT_20261_SINGRADO_SENA_EXP'
                     
                    -- MATRICULA TYT 2025_2 Y CONTRATO SENA MENOR AL INICIO DE LA CONVOCATORIA
                     WHEN TYT_MATRICULA_2025_2 IS NOT NULL 
                          AND TYT_GRADUACION_MATRICULA_2025_2 like '%NO_GRADUADO%'
                          AND UTC_GRADUADO=='N'
                          AND SENA_Registra_Certificado =='NO'
                          AND (SENA_Fecha_Fin_Contrato < '2026-06-03' OR SENA_Fecha_Fin_Contrato is null) THEN '4_TYT_20252_SINGRADO_SENA_EXP'
    
                    ELSE 'HABILITADO' END HABILITADO_E 
             FROM JE5")
cro(JE5$HABILITADO_E)

#-------------------------------------------------------------------------------
# CRITERIO F
# f) No haber estado matriculado en un programa de nivel universitario en los 
# semestres 2025-II y/o 2026-I.
#-------------------------------------------------------------------------------
JE5 <- sqldf("SELECT *,
                     CASE 
                    -- EGRESADO SUPERIOR
                    WHEN MEN_ULTIMA_MATRICULA_SUPERIOR IS NOT NULL THEN 'NO_HABILITADO'
                     
                     ELSE 'HABILITADO' END HABILITADO_F 
             FROM JE5")
cro(JE5$HABILITADO_F)

#-------------------------------------------------------------------------------
# CRITERIO G
# g) No ser graduado(a) de un programa de educación superior en el nivel 
# profesional universitario.
#-------------------------------------------------------------------------------
JE5 <- sqldf("SELECT *,
                     CASE 
                    -- EGRESADO SUPERIOR
                    WHEN GRADUADO_Universitario IS NOT NULL OR GRADUADO_EspecializacionUniversitaria IS NOT NULL THEN 'NO_HABILITADO'
                     
                     ELSE 'HABILITADO' END HABILITADO_G 
             FROM JE5")
cro(JE5$HABILITADO_G)

#-------------------------------------------------------------------------------
# CRITERIO H
# h) No haber sido beneficiario(a) del Programa “Jóvenes a la E” (antes Jóvenes 
# a la U) en sus convocatorias previas y en cualquiera de sus líneas o de otras 
# estrategias que adelanten Atenea o la Secretaría de Educación del Distrito para 
# el acceso y la permanencia en educación superior, a saber: FEST Atenea, Fondo 
# Educación Superior para Todos (FEST), Fondo Alianza Ciudad Educadora, Fondo para 
# la Reparación de las Víctimas del Conflicto Armado, Fondo Ciudad Bolívar, Fondo 
# Técnica y Tecnológica, Fondo Universidades Públicas (Universidad Nacional de 
# Colombia, Universidad Nacional Abierta y a Distancia- UNAD, Universidad Distrital 
# Francisco José de Caldas, Universidad Pedagógica Nacional y Escuela Tecnológica 
# Instituto Técnico Central) y becas Universidad Libre y América.
#-------------------------------------------------------------------------------
JE5 <- sqldf("SELECT *,
                     CASE 
                    -- JE
                    WHEN RESTRICCION_JE =='S' THEN '1_ES_BENEF_JE'
                    -- UTC
                    WHEN RESTRICCION_UTC =='S' THEN '2_ES_BENEF_UTC'
                    --FEST_ATENEA
                    WHEN RESTRICCION_FEST =='S' THEN '3_ES_BENEF_FEST'
                    --EFT
                    WHEN RESTRICCION_EFT =='S' THEN '4_ES_BENEF_EFT'
                    -- FONDOS
                    WHEN RA_FONDOS_ATENEA =='S' THEN '4_ES_FONDOS'
                    
                    ELSE 'HABILITADO' END HABILITADO_H
             FROM JE5")
cro(JE5$HABILITADO_H)

#-------------------------------------------------------------------------------
# i) Registrarse en la plataforma de inscripciones de la Agencia Atenea -SICORE-, 
# a través de la página web de la Agencia y dentro de las fechas establecidas en 
# el cronograma publicado en la página web de la Agencia.
#-------------------------------------------------------------------------------

# TODOS LOS REGISTROS PROVIENEN DEL SICORE, NO APLICA PARA EL CALCULO

#-------------------------------------------------------------------------------
# CRITERIO I - RNEC
# Requisito Identidad RNEC y Migración
#-------------------------------------------------------------------------------
JE5 <- sqldf("SELECT *,
                     CASE 
                    -- RNEC
                    WHEN RA_INHABILITADO_RENEC is not null AND RA_INHABILITADO_RENEC NOT IN ('HABILITADO') THEN 'NO_HABILITADO'
                    
                     ELSE 'HABILITADO' END HABILITADO_I
             FROM JE5")
cro(JE5$RA_INHABILITADO_RENEC, JE5$HABILITADO_I)

#-------------------------------------------------------------------------------
# CALCULO HABILITACION SECUENCIAS
#-------------------------------------------------------------------------------
JE5 <- sqldf("SELECT *,
         CASE 
                     WHEN HABILITADO_A !='HABILITADO'  THEN 'INHABILITA_REQUISITO_A'
                     WHEN HABILITADO_B !='HABILITADO'  THEN 'INHABILITA_REQUISITO_B'
                     WHEN HABILITADO_C !='HABILITADO'  THEN 'INHABILITA_REQUISITO_C'
                     WHEN HABILITADO_D =='NO_HABILITADO'  THEN 'INHABILITA_REQUISITO_D'
                     WHEN HABILITADO_E !='HABILITADO'  THEN 'INHABILITA_REQUISITO_E'
                     WHEN HABILITADO_F !='HABILITADO'  THEN 'INHABILITA_REQUISITO_F'
                     WHEN HABILITADO_G !='HABILITADO'  THEN 'INHABILITA_REQUISITO_G'
                     WHEN HABILITADO_H !='HABILITADO'  THEN 'INHABILITA_REQUISITO_H'
                     WHEN HABILITADO_I !='HABILITADO'  THEN 'INHABILITA_REQUISITO_I'
              ELSE 'HABILITADO' END HABILITADO
             
             FROM JE5")
cro(JE5$HABILITADO)
