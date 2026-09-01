#==============================================================================================
# MODULO 4: ORDENAMIENTO DE ASPIRANTES
#==============================================================================================
# Referencia: lineamiento operativo, numerales 5.4.4 (Actividad 2) y 5.1.4.2
#             (Aplicacion de criterios de desempate).
#
# A diferencia de JE-EFT4, JE5 privadas NO conforma grupos: todos los aspirantes
# entran a un unico ordenamiento, encabezado por el PUNTAJE_GLOBAL del Modulo 3.
#
# Criterios de desempate, en orden estricto:
#   1. desc(PUNTAJE_GLOBAL)             mayor puntaje primero
#   2. desc(SABER11_PUNTAJE_GLOBAL)     mayor puntaje Saber 11 primero
#   3. SISBEN4_Grupo, SISBEN4_Nivel     mayor vulnerabilidad economica primero (A1 < A2 < ...)
#   4. desc(CRITERIO_1_VUL_ESTRUCTURAL) mayor vulnerabilidad estructural primero
#   5. ORDENAMIENTO_D                   1=colegio oficial, 2=no oficial, 3=sin dato
#   6. desc(VOTO)                       haber votado
#   7. SEMILLA                          desempate aleatorio reproducible
#
# Nota: SABER11_PUNTAJE_GLOBAL == 0 se convierte a NA para homogenizar el criterio 2,
# de modo que un cero (sin puntaje real) no compita como si fuera un puntaje bajo
# valido; con na.last=TRUE queda al final del bloque empatado.
#
# La SEMILLA usa set.seed(20260610), fecha de cierre de la convocatoria.
# El resultado es JE5_LLAVE_PER (1..n), la llave que gobierna todo el recorrido
# de asignacion del Modulo 5.
#----------------------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# ORDENAMIENTO
# Criterios de desempate.
# 5.4.4.Actividad 2: Aplicación mecanismo de asignación de cupos
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# f) Cuando no se logre el desempate por los criterios anteriores, se asignará el cupo de forma aleatoria.
# SEMILLA 2026-06-10 (Cierre de convocatoria)
#-------------------------------------------------------------------------------
set.seed(20260610)
JE5$SEMILLA <-  JE5$ID_PERSONA[sample(length(JE5$ID_PERSONA))]
sqldf("select SEMILLA FROM JE5 GROUP BY SEMILLA HAVING COUNT(1)>1")

#-------------------------------------------------------------------------------
#d)Se privilegiará el ingreso de egresados de colegios oficiales.
#-------------------------------------------------------------------------------
JE5$ORDENAMIENTO_D <-3
JE5[!is.na(JE5$SIMAT_GM_SECTOR) & JE5$SIMAT_GM_SECTOR=="OFICIAL", "ORDENAMIENTO_D" ] <- 1 
JE5[!is.na(JE5$SIMAT_GM_SECTOR) & JE5$SIMAT_GM_SECTOR!="OFICIAL", "ORDENAMIENTO_D" ] <- 2 
JE5[!is.na(JE5$MEN_GM_SECTOR) & JE5$MEN_GM_SECTOR=="OFICIAL", "ORDENAMIENTO_D" ] <- 1 
JE5[!is.na(JE5$MEN_GM_SECTOR) & JE5$MEN_GM_SECTOR!="OFICIAL", "ORDENAMIENTO_D" ] <- 2 
cro(JE5$ORDENAMIENTO_D)

#-------------------------------------------------------------------------------
# VARIABLES PARA ORDENAMIENTO
# 5.1.4.2. Aplicación de criterios de desempate
#-------------------------------------------------------------------------------
TMP <- JE5[,c("ID_PERSONA","PUNTAJE_GLOBAL","SABER11_REGISTRO_SNP","SABER11_ESTADO_PUBLICACION", "SABER11_PUNTAJE_GLOBAL","SISBEN4_Grupo","SISBEN4_Nivel","CRITERIO_1_VUL_ESTRUCTURAL","ORDENAMIENTO_D","VOTO","SEMILLA")] 
# Cuando SABER11_PUNTAJE_GLOBAL es 0, entonces se deja vacia para homogenizar el calculo del ordenamiento 
TMP[!is.na(TMP$SABER11_PUNTAJE_GLOBAL) & TMP$SABER11_PUNTAJE_GLOBAL==0, "SABER11_PUNTAJE_GLOBAL" ] <- NA

#-------------------------------------------------------------------------------
# ORDENAMIENTO
#-------------------------------------------------------------------------------
ORDENAMIENTO <-TMP %>%  arrange(desc(PUNTAJE_GLOBAL),
                                desc(SABER11_PUNTAJE_GLOBAL),
                                SISBEN4_Grupo, SISBEN4_Nivel, 
                                desc(CRITERIO_1_VUL_ESTRUCTURAL),
                                ORDENAMIENTO_D,
                                desc(VOTO),
                                SEMILLA, na.last=TRUE)

ORDENAMIENTO$JE5_LLAVE_PER <- as.double(row.names(ORDENAMIENTO))
rm(TMP)

#PEGAR RESULTADO A DATAFRAME PERSONA UNICA
JE5<- merge(x=JE5, y=ORDENAMIENTO[,c("ID_PERSONA","JE5_LLAVE_PER")], by="ID_PERSONA", all = FALSE)

# Estadistica descriptiva variable de ordenamiento JE5_LLAVE_PER 
ds_summary_stats(JE5$JE5_LLAVE_PER)
