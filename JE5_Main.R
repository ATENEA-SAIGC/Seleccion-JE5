#==============================================================================================
# JE5 - Quinta convocatoria Jovenes a la E (IES privadas)
# Calculo de habilitacion, puntuacion, ordenamiento y asignacion de cupos
# (elegibles y lista de espera)
# Corte: 2026-06-17
#==============================================================================================
# ORQUESTADOR PRINCIPAL (Entry Point)
#==============================================================================================

#-----------------------------------------
# ACTIVAR RENV (Gestion de dependencias)
#-----------------------------------------
source("renv/activate.R")

#-----------------------------------------
# CONFIGURACION DEL ENTORNO
#-----------------------------------------
library(sqldf)
library(expss)
library(readr)
library(readxl)
library(dplyr)
library(tidyr)
library(eeptools)
library(openxlsx)
library(descriptr)
options(scipen=999)

#-----------------------------------------
# CARGAR INSUMOS PARA LOS CALCULOS
#-----------------------------------------
load("data/JE5_Insumos.RData")

#-----------------------------------------
# EJECUTAR MODULOS
#-----------------------------------------

# Modulo 1: Localidad definitiva por coincidencia entre DUE, SISBEN4 y recibo
source("modules/1_localidad.R")

# Modulo 2: Habilitacion de aspirantes (requisitos a - i)
source("modules/2_habilitacion.R")

# Modulo 3: Criterios de puntuacion -> PUNTAJE_GLOBAL
source("modules/3_puntuacion.R")

# Modulo 4: Ordenamiento y criterios de desempate -> JE5_LLAVE_PER
source("modules/4_ordenamiento.R")

# Modulo 5: Asignacion de cupos (recomposicion y general) -> elegibles
source("modules/5_asignacion_cupos.R")

# Modulo 6: Conformacion de la lista de espera
source("modules/6_lista_espera.R")

# Modulo 7: Consolidacion y exportacion de resultados a Excel
source("modules/7_exportacion.R")
