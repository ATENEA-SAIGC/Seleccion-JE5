# Mecanismo de Seleccion de Aspirantes: Quinta Convocatoria Jovenes a la E - IES Privadas (JE5)

<div align="center">

![R Version](https://img.shields.io/badge/R-4.5.1%2B-blue?style=for-the-badge&logo=r)
![License](https://img.shields.io/badge/Licencia-CC%20BY-green?style=for-the-badge)
![Status](https://img.shields.io/badge/Estado-Producci%C3%B3n%20Auditada-success?style=for-the-badge)
![Reproducibilidad](https://img.shields.io/badge/Reproducibilidad-renv%20%7C%20Seed-orange?style=for-the-badge)

**Agencia Distrital para la Educacion Superior, la Ciencia y la Tecnologia (ATENEA)**
*Subgerencia de Analisis de Informacion y Gestion del Conocimiento*

</div>

> **Este repositorio es la segunda mitad de JE5.** El algoritmo de **oferta**
> ([`JE5_oferta_algoritmo`](../JE5_oferta_algoritmo/)) decide *cuantos cupos financiar en cada
> programa*. Este algoritmo de **seleccion** decide *que persona ocupa cada uno de esos cupos*.
> Se ejecutan en ese orden y comparten el mismo presupuesto general de $17.753.034.702 COP.

---

## Tabla de Contenidos

1. [Ficha de Transparencia Algoritmica](#1-ficha-de-transparencia-algoritmica)
2. [Arquitectura del Proyecto](#2-arquitectura-del-proyecto)
3. [Requisitos Tecnicos](#3-requisitos-tecnicos)
4. [Logica Detallada del Algoritmo](#4-logica-detallada-del-algoritmo)
    * [Fase 1: Determinacion de la Localidad](#fase-1-determinacion-de-la-localidad-modulo-1)
    * [Fase 2: Habilitacion de Aspirantes](#fase-2-habilitacion-de-aspirantes-modulo-2)
    * [Fase 3: Criterios de Puntuacion](#fase-3-criterios-de-puntuacion-modulo-3)
    * [Fase 4: Ordenamiento](#fase-4-ordenamiento-modulo-4)
    * [Fase 5: Asignacion de Cupos](#fase-5-asignacion-de-cupos-modulo-5)
    * [Fase 6: Lista de Espera](#fase-6-lista-de-espera-modulo-6)
    * [Fase 7: Consolidacion y Exportacion](#fase-7-consolidacion-y-exportacion-modulo-7)
5. [Diferencias frente al algoritmo JE-EFT4](#5-diferencias-frente-al-algoritmo-je-eft4)
6. [Diccionario de Datos](#6-diccionario-de-datos)
    * [Obtencion del insumo](#obtencion-del-insumo)
7. [Instrucciones de Ejecucion](#7-instrucciones-de-ejecucion)
8. [Garantia de Reproducibilidad](#8-garantia-de-reproducibilidad)
9. [Preguntas Frecuentes y Glosario](#9-preguntas-frecuentes-y-glosario)
10. [Uso del Codigo](#10-uso-del-codigo)

---

## 1. Ficha de Transparencia Algoritmica

| Campo | Contenido |
|---|---|
| **Tipo de algoritmo** | Procesamiento de datos (regla de negocio deterministica). No usa aprendizaje automatico ni inferencia estadistica. |
| **Nombre** | Habilitacion, puntuacion, ordenamiento y asignacion de cupos - quinta convocatoria "Jovenes a la E", oferta de IES privadas (JE5). |
| **Objetivo** | Aplicar los criterios del lineamiento operativo para determinar quien queda **elegible** y quien queda en **lista de espera** en los programas de educacion superior ofrecidos por IES privadas. |
| **Funcion institucional** | Financiar el acceso y la permanencia en educacion superior de bachilleres de Bogota, en programas tecnicos, tecnologicos y universitarios, con cargo a los Fondos de Desarrollo Local. |
| **Estado** | En implementacion (vigente para la quinta convocatoria - junio 2026). |
| **Datos personales** | **Si procesa datos personales, en version anonimizada.** Este repositorio contiene unicamente el codigo: el insumo **no se versiona aqui** y se distribuye por separado (ver [Obtencion del insumo](#obtencion-del-insumo)). Ese insumo sustituye el documento de identidad por un `ID_PERSONA` seudonimizado; las direcciones de residencia estan anonimizadas tanto en el analisis de recibos como en la georreferenciacion IDECA. No contiene nombres ni datos de contacto. |
| **Tipo de datos** | Identificador seudonimizado, fecha de nacimiento, sexo e identidad de genero, grupo y nivel SISBEN IV, condiciones de vulnerabilidad, colegio de grado medio, resultados de la prueba Saber 11 (percentil o puesto), matricula y graduacion en educacion superior (SNIES, SENA), historico de beneficiarios ATENEA/SED y localidad de residencia verificada. Ver [Diccionario de Datos](#6-diccionario-de-datos). |
| **Desarrollador** | Agencia Distrital para la Educacion Superior, la Ciencia y la Tecnologia (ATENEA) - Subgerencia de Analisis de Informacion y Gestion del Conocimiento (SAIGC). |
| **Insumo normativo** | Lineamiento operativo JE convocatoria 5 (IES privadas), numerales 5.3.3, 5.3.3.1, 5.4.2.1 y 5.4.4. |
| **Universo procesado** | 9.169 inscritos y 24.703 registros persona-oferta sobre 144 ofertas de 38 IES privadas. |
| **Cupos a asignar** | 602 cupos: 434 generales (financiados por FDL) y 168 de recomposicion. |
| **Presupuesto** | $17.753.034.702 COP distribuidos en 7 Fondos de Desarrollo Local: Ciudad Bolivar, Kennedy, Bosa, Usme, Usaquen, Los Martires y Teusaquillo. |

**Principios de diseno:**

* **Transparencia:** reglas de negocio codificadas explicitamente, sin "cajas negras".
* **Auditabilidad:** cada requisito y cada componente de puntaje deja su propia variable (`HABILITADO_*`, `C1_*`, `C2_*`), y los criterios con escalas llevan ademas una variable `DTLL_*` con la etiqueta legible del tramo aplicado. El libro Excel incluye hojas de auditoria del ordenamiento, del presupuesto por localidad y del detalle de recomposicion.
* **Reproducibilidad:** semilla fija `set.seed(20260610)` y dependencias congeladas con `renv`.

**Como funciona (resumen):** el algoritmo (1) **establece la localidad** de residencia por coincidencia entre tres fuentes, (2) **habilita** a los aspirantes verificando nueve requisitos, (3) **puntua** por cuatro criterios, (4) **ordena** en una lista unica, (5) **asigna cupos** evaluando primero la bolsa de recomposicion y luego la general contra el presupuesto del FDL, (6) conforma la **lista de espera** con un tope proporcional a los elegibles logrados y (7) exporta los resultados. El detalle paso a paso esta en la [Seccion 4](#4-logica-detallada-del-algoritmo).

---

## 2. Arquitectura del Proyecto

El codigo esta organizado en una arquitectura modular secuencial. Cada modulo aborda una fase del lineamiento operativo y puede auditarse por separado.

```text
JE5_seleccion_algoritmo/
|
|-- JE5_Main.R                # ORQUESTADOR PRINCIPAL (Entry Point)
|-- README.md                 # Documentacion (este archivo)
|-- LICENSE                   # CC BY - Obra institucional ATENEA
|-- renv.lock                 # Manifiesto de dependencias exactas
|
|-- data/                     # Insumos (no versionados)
|   +-- JE5_Insumos.RData     # NO INCLUIDO - solicitar a ATENEA (ver README 6)
|
|-- output/                   # Resultados generados
|   +-- JE5_VF_YYYYMMDD.xlsx
|
|-- docs/                     # Lineamiento operativo y soporte
|
+-- modules/                  # Logica de negocio
    |-- 1_localidad.R         # Localidad por coincidencia entre DUE, SISBEN4 y recibo
    |-- 2_habilitacion.R      # Requisitos de participacion a) - i) (5.3.3)
    |-- 3_puntuacion.R        # Criterios de puntuacion -> PUNTAJE_GLOBAL
    |-- 4_ordenamiento.R      # Criterios de desempate -> JE5_LLAVE_PER
    |-- 5_asignacion_cupos.R  # Recorrido recomposicion / general -> elegibles
    |-- 6_lista_espera.R      # Conformacion de la lista de espera
    +-- 7_exportacion.R       # Consolidacion y exportacion XLSX
```

---

## 3. Requisitos Tecnicos

* **R** 4.5.1 o superior y **renv** 1.1.5+.
* Dependencias declaradas en `renv.lock` y restauradas con `renv::restore()`.

Librerias principales: `sqldf`, `expss`, `dplyr`, `tidyr`, `readr`, `readxl`, `eeptools`, `openxlsx`, `descriptr`.

---

## 4. Logica Detallada del Algoritmo

### Fase 1: Determinacion de la Localidad (Modulo 1)

**Archivo:** `modules/1_localidad.R` - **Referencia:** Lineamiento operativo, numeral 5.4.2.1, Nota 2.

La localidad tiene doble consecuencia en JE5: es **requisito de habilitacion** (criterio d) y define **que FDL financia** el cupo. Por eso se establece con una regla de **doble confirmacion**: no basta una fuente, tienen que coincidir dos.

**Paso 1 - resolver la localidad del recibo (`RECIBOS_CODLOC`).** Solo para recibos validados, en cascada:

| Condicion | Localidad que se toma |
|---|---|
| IDECA coincide con SICORE | IDECA |
| No coinciden, pero la direccion la asigno Catastro | IDECA |
| No coinciden y la direccion NO la asigno Catastro | API Catastro |
| Sin cruce IDECA | API Catastro |

**Paso 2 - localidad definitiva por coincidencia de dos fuentes.** Se comparan tres fuentes con esta prelacion:

```text
SI  DUE_CODLOC     == RECIBOS_CODLOC  -> localidad RECIBOS   (ANALISIS_LOCALIDAD = 'RECIBOS_DUE')
SI  SISBEN4_CODLOC == RECIBOS_CODLOC  -> localidad RECIBOS   (ANALISIS_LOCALIDAD = 'RECIBOS_SISBEN4')
SI  DUE_CODLOC     == SISBEN4_CODLOC  -> localidad SISBEN4   (ANALISIS_LOCALIDAD = 'DUE_SISBEN4')
EN OTRO CASO                          -> NULL
```

Quien no logra que dos fuentes coincidan queda **sin localidad**, y el criterio d) lo inhabilita.

---

### Fase 2: Habilitacion de Aspirantes (Modulo 2)

**Archivo:** `modules/2_habilitacion.R` - **Referencia:** Lineamiento operativo, numeral 5.3.3.

**Paso previo - `RA_ICFES_VALIDACION`.** Antes de evaluar los requisitos se distingue a quien obtuvo el titulo de bachiller **por validacion del ICFES** de quien lo obtuvo por grado medio ordinario. La marca es `'S'` cuando el registro SNP empieza por `VG` y (a) no hay registro de grado medio en SIMAT ni MEN, o (b) el grado medio del MEN esta fuera de Bogota. Esta marca cambia como se evalua el criterio a).

| Variable | Requisito | Regla resumida |
|---|---|---|
| `HABILITADO_A` | a) Bachiller de colegio de Bogota o validante ICFES en Bogota | Municipio SIMAT/MEN = `11001`; o validante con puntaje >= 30 y aplicacion en Bogota |
| `HABILITADO_B` | b) Saber 11 presentada en Bogota | Prueba con periodo, estado `PUBLICADO` y municipio `BOGOTÁ D.C.` |
| `HABILITADO_C` | c) Hasta 28 anos | `CORTE_EDAD <= 28`, calculado al **2026-06-10** (cierre de inscripcion) |
| `HABILITADO_D` | d) Residir en localidad con cupos | Ver nota abajo - **tiene tres estados** |
| `HABILITADO_E` | e) Graduado en SNIES si estuvo matriculado en TyT 2025-2 / 2026-1 | Excepcion para estudiantes SENA en etapa practica |
| `HABILITADO_F` | f) No matriculado en programa universitario en 2025-2 / 2026-1 | Sin `MEN_ULTIMA_MATRICULA_SUPERIOR` |
| `HABILITADO_G` | g) No graduado de programa universitario | Sin graduacion universitaria ni de especializacion |
| `HABILITADO_H` | h) No beneficiario previo | Sin marca de JE, UTC, FEST, EFT o fondos ATENEA |
| `HABILITADO_I` | Identidad valida RNEC | `RA_INHABILITADO_RENEC` en estado habilitado |

> **`HABILITADO_D` tiene TRES estados, no dos** - es la particularidad central de JE5:
>
> | Estado | Localidades | Consecuencia |
> |---|---|---|
> | `HABILITADO` | Usaquen, Usme, Bosa, Kennedy, Teusaquillo, Los Martires, Ciudad Bolivar | Accede a cupos **generales** (financiados por su FDL) **y** a recomposicion |
> | `HABILITADO_RECOMPOSICION` | Resto de localidades con cupos de recomposicion | **Sigue habilitado**, pero solo puede acceder a cupos de **recomposicion** |
> | `NO_HABILITADO` | La Candelaria, Sumapaz, Barrios Unidos, Engativa, Santa Fe, o sin localidad | Queda fuera de la convocatoria |
>
> En la habilitacion secuencial, **solo `NO_HABILITADO` corta**. `HABILITADO_RECOMPOSICION` pasa el filtro y su restriccion se aplica despues, en el Modulo 5.

**Habilitacion final (`HABILITADO`) - resolucion secuencial.** El primer requisito incumplido determina la causal, de `INHABILITA_REQUISITO_A` a `INHABILITA_REQUISITO_I`.

---

### Fase 3: Criterios de Puntuacion (Modulo 3)

**Archivo:** `modules/3_puntuacion.R` - **Referencia:** Lineamiento operativo, numeral 5.4.4.

$$PUNTAJE\_GLOBAL = CRITERIO_1 + CRITERIO_2 + CRITERIO_3 + CRITERIO_4$$

**Criterio 1 - Vulnerabilidad estructural (ACUMULABLE, tope 15 puntos).**

| Componente | Condicion | Puntos |
|---|---|---:|
| `C1_1` | Mujer | 7 |
| `C1_2` | Mujer con hijos | 5 |
| `C1_3` | Persona transgenero | 10 |
| `C1_4` | Pertenencia etnica | 15 |
| `C1_5` | Victima del conflicto armado | 10 |
| `C1_6` | Violencia de genero | 10 |
| `C1_7` | Reincorporado / reinsertado | 10 |
| `C1_8` | Discapacidad (MinSalud) | 10 |
| `C1_9` | Ley 1699 (fuerza publica) | 10 |
| `C1_10` | Egresado de colegio oficial de Sumapaz o rural a mas de 3 km | 15 |

**Criterio 2 - Vulnerabilidad economica (NO ACUMULABLE, hasta 40 puntos).**

*Con SISBEN IV* (`C2_1`), solo para encuestas de hogares de Bogota-Region: grupo **A** = 40, **B** = 30, **C** = 20.

*Sin SISBEN* (`C2_2`), en cascada, solo si `C2_1 == 0`: colegio oficial **rural** = 40; etnia **indigena** = 30; colegio oficial (urbano) = 15.

**Criterio 3 - Merito academico (hasta 40 puntos).** La escala depende del periodo de la Saber 11, porque el ICFES no reportaba percentil antes de 2016-1:

| Desde 2016-1 (percentil nacional) | Puntos | | Antes de 2016-1 (puesto) | Puntos |
|---|---:|---|---|---:|
| 100 | 40 | | 1 a 10 | 40 |
| 95 a 99 | 35 | | 11 a 50 | 35 |
| 90 a 94 | 30 | | 51 a 100 | 30 |
| 85 a 89 | 25 | | 101 a 150 | 25 |
| 75 a 84 | 20 | | 151 a 250 | 20 |
| 65 a 74 | 10 | | 251 a 350 | 15 |
| 50 a 64 | 5 | | 351 a 450 | 10 |
| menor a 50 | 0 | | 451 a 499 | 5 |
| | | | mayor a 499 | 0 |

**Criterio 4 - Fomento a trayectorias (NO ACUMULABLE, hasta 5 puntos).** 5 puntos si cumple **cualquiera** de: graduado UTC, consejero de juventud electo, deportista IDRD o Jovenes con Oportunidades.

---

### Fase 4: Ordenamiento (Modulo 4)

**Archivo:** `modules/4_ordenamiento.R` - **Referencia:** Lineamiento operativo, numerales 5.4.4 y 5.1.4.2.

A diferencia de JE-EFT4, JE5 **no conforma grupos**: todos los aspirantes entran a un unico ordenamiento encabezado por el `PUNTAJE_GLOBAL`.

**Semilla de desempate:** `set.seed(20260610)` - fecha de cierre de la convocatoria. Se materializa como una permutacion aleatoria de los `ID_PERSONA` y se verifica que no haya semillas repetidas.

**Criterios de desempate, en orden estricto:**

```text
1. desc(PUNTAJE_GLOBAL)              mayor puntaje primero
2. desc(SABER11_PUNTAJE_GLOBAL)      mayor puntaje Saber 11 primero
3. SISBEN4_Grupo, SISBEN4_Nivel      mayor vulnerabilidad economica primero (A1 < A2 < ...)
4. desc(CRITERIO_1_VUL_ESTRUCTURAL)  mayor vulnerabilidad estructural primero
5. ORDENAMIENTO_D                    1=colegio oficial, 2=no oficial, 3=sin dato
6. desc(VOTO)                        haber votado
7. SEMILLA                           desempate aleatorio reproducible
```

> **Nota tecnica sobre el criterio 2.** Un `SABER11_PUNTAJE_GLOBAL` igual a 0 se convierte a `NA` antes de ordenar. Un cero en esa variable significa "sin puntaje real", no "puntaje bajo"; al llevarlo a `NA` con `na.last = TRUE` queda al final de su bloque empatado en lugar de competir como si fuera un puntaje valido muy bajo.

El resultado es **`JE5_LLAVE_PER`** (1..n), la llave que gobierna el recorrido de asignacion.

---

### Fase 5: Asignacion de Cupos (Modulo 5)

**Archivo:** `modules/5_asignacion_cupos.R` - **Referencia:** Lineamiento operativo, numerales 5.3.3.1 y 5.4.4 (Paso 3).

**Paso previo - requisitos de las IES (numeral 5.3.3.1).** Algunas IES fijan requisitos adicionales. En esta convocatoria, la **Universidad de los Andes (SNIES 1813)** exige `SABER11_PUNTAJE_GLOBAL >= 370`. Quien no lo cumple queda `2-INHABILITA_CRITERIO_IES` **en esa oferta**, no en la convocatoria: sigue compitiendo por sus demas opciones.

**Dos bolsas de cupos por oferta**, evaluadas siempre en este orden:

| Bolsa | Variable | Restriccion | Quien accede |
|---|---|---|---|
| **1. Recomposicion** | `CUPOS_CONTROL_RECOMP` | Solo cupos, **sin presupuesto** | Todos los habilitados |
| **2. General** | `CUPOS_CONTROL` | Cupos **y** presupuesto del FDL | Solo `HABILITADO_D == 'HABILITADO'` |

**Como se elige el cupo de recomposicion.** El detalle (`BASE_OFERTA_RECOMP`) puede traer cupos **sin localidad** (bolsa ATENEA) o cupos **atados a una localidad**. Se prefiere el cupo sin localidad; solo si ese se agoto se intenta el cupo de la localidad del aspirante:

```text
SI existe registro sin localidad Y tiene cupos  -> usar ese  ("DETALLE_ATENEA")
SINO SI existe registro de la localidad del aspirante Y tiene cupos
                                                -> usar ese  ("DETALLE_LOC")
```

**Pseudocodigo del recorrido:**

```text
PARA CADA aspirante EN ORDEN DE JE5_LLAVE_PER:
    PARA CADA oferta DEL aspirante EN ORDEN DE PRIORIDAD:

        # --- BOLSA 1: RECOMPOSICION (se evalua siempre primero) ---
        SI CUPOS_CONTROL_RECOMP > 0 Y hay detalle aplicable:
            -> ELEGIBLE por RECOMPOSICION
               descontar cupo en BASE_OFERTA y en BASE_OFERTA_RECOMP
               (no consume presupuesto)

        # --- BOLSA 2: GENERAL (solo si no hubo recomposicion) ---
        SINO SI HABILITADO_D == 'HABILITADO':
            SI CUPOS_CONTROL > 0:
                SI PRESUPUESTO_FDL(localidad) / TOTAL_VALOR_COHORTE_ATENEA >= 1:
                    -> ELEGIBLE por GENERAL
                       CUPOS_CONTROL   -= 1
                       PRESUPUESTO_FDL -= TOTAL_VALOR_COHORTE_ATENEA
                SINO:
                    -> 'FDL_SIN_PRESUPUESTO'
            SINO:
                -> 'SIN_CUPOS_GENERAL'
        SINO SI CUPOS_CONTROL_RECOMP < 1:
            -> 'SIN_CUPOS_RECOMPOSICION'
```

Al asignarse un cupo, las demas ofertas del aspirante quedan `INACTIVO` (`"-"`).

**Cierre del modulo - `ESTADO_ELEGIBLE`:**

| Estado | Significado |
|---|---|
| `ELEGIBLE` | Obtuvo cupo (general o recomposicion) |
| `INACTIVO` | La persona obtuvo cupo en otra de sus ofertas |
| `DISPONIBLE` | Habilitado, sin cupo -> candidato a lista de espera (Modulo 6) |
| `NO_ELEGIBLE` | No habilitado, prioridad > 3, o inhabilitado por criterio de la IES |

---

### Fase 6: Lista de Espera (Modulo 6)

**Archivo:** `modules/6_lista_espera.R` - **Referencia:** Lineamiento operativo, numeral 5.4.4.

**Tamano de la lista.** Depende de cuantos elegibles logro cada oferta, con un refuerzo para las ofertas pequenas:

```text
SI elegibles >= 4  ->  lista de espera = elegibles
SI elegibles <  4  ->  lista de espera = elegibles * 2
```

Asi una oferta que solo logro dos elegibles no queda sin respaldo ante una sola renuncia.

**Dos pasadas, y el orden importa:**

1. **Ofertas de recomposicion con bolsa ATENEA** (sin localidad), recorridas en orden ascendente de `ULTIMO_ELEGIBLE`.
2. **Ofertas financiadas por FDL**, particionadas por localidad, tambien en orden ascendente de `ULTIMO_ELEGIBLE`.

Recorrer primero la oferta que "cerro" antes (menor `ULTIMO_ELEGIBLE`) da prelacion a las listas donde la competencia fue mas alta.

Una persona solo puede quedar en lista de espera en **una** oferta: al marcarla, sus demas registros pasan a `INACTIVO_LISTA_ESPERA`.

---

### Fase 7: Consolidacion y Exportacion (Modulo 7)

**Archivo:** `modules/7_exportacion.R`

1. **`RESULTADO`** - marcacion publicable en SICORE: `ELEGIBLE`, `LISTA_ESPERA` o `NO_ELEGIBLE`.
2. **`PUESTO` y `PUESTO_LOC`** - posicion del aspirante dentro de cada oferta, general y por localidad, priorizando 1=elegibles, 2=lista de espera, 3=resto.
3. Exportacion a `output/JE5_VF_YYYYMMDD.xlsx` con siete hojas:

| Hoja | Contenido |
|---|---|
| `JE5_PER` | Persona unica ordenada por `JE5_LLAVE_PER`, con habilitacion, puntajes y localidad. |
| `JE5_PER_OFERTA` | Detalle persona-oferta con estado, asignacion y puesto. |
| `JE5_TOTAL` | Cruce de las dos anteriores (archivo total). |
| `ORDENAMIENTO` | Auditoria del ordenamiento con todos sus criterios de desempate. |
| `BASE_FDL` | Presupuesto por localidad y **remanente al cierre**. |
| `BASE_OFERTA` | Cupos general y recomposicion, y **disponibles al cierre**. |
| `DETALLE_OFERTA_RECOMP` | Detalle de cupos de recomposicion por localidad y su remanente. |

---

## 5. Diferencias frente al algoritmo JE-EFT4

Ambos algoritmos comparten la arquitectura de siete modulos, pero atienden poblaciones y niveles de formacion distintos:

| Aspecto | JE5 (educacion superior privada) | JE-EFT4 (formacion para el trabajo) |
|---|---|---|
| Nivel de formacion | Tecnico, tecnologico y universitario | ETDH de ciclo corto |
| Requisito de edad | Hasta 28 anos | Entre 14 y 28 anos |
| Prueba Saber 11 | Obligatoria en Bogota; vale hasta 40 puntos | No se exige ni se puntua |
| Criterios de puntuacion | 4 (estructural 15, economica 40, merito 40, trayectoria 5) | 3 (estructural 45, economica 45, trayectoria 10) |
| Grupos de aspirantes | 1 (ordenamiento unico) | 2 (focalizados SDIS / resto) |
| Determinacion de localidad | Coincidencia entre DUE, SISBEN IV y recibo | `REGLA_LOCALIDAD` CASO_1..CASO_5 |
| Bolsas de financiacion | General (con presupuesto FDL) / Recomposicion (solo cupos) | FDL (con presupuesto) / ATENEA (solo cupos) |
| Estados de habilitacion territorial | 3 (`HABILITADO`, `HABILITADO_RECOMPOSICION`, `NO_HABILITADO`) | 2, mas la restriccion del numeral 5.2 |
| Requisitos de las IES | Si (Uniandes exige Saber 11 >= 370) | No aplica |
| Tope de lista de espera | Proporcional a los elegibles (x2 si son menos de 4) | Una oferta por persona, sin tope numerico |
| Semilla | `set.seed(20260610)` | `set.seed(20260708)` |

---

## 6. Diccionario de Datos

### Obtencion del insumo

> **Este repositorio contiene unicamente el codigo.** El archivo `JE5_Insumos.RData`
> **no se versiona** y debe solicitarse a ATENEA. Se distribuye dentro del paquete
> de replicacion `JE5_Calculos.zip`, junto con el codigo fuente original y el
> libro de resultados de referencia.
>
> | Archivo | Hash MD5 |
> |---|---|
> | `JE5_Calculos.zip` | `63e4e6402c7db54754b9d804128716ed` |
> | `JE5_Insumos.RData` | `dcd9a0a0161ac73eb42b9ce52bcac0e7` |
>
> Verifique la integridad antes de ejecutar:
>
> ```bash
> md5 data/JE5_Insumos.RData      # macOS
> md5sum data/JE5_Insumos.RData   # Linux
> ```
>
> El archivo va en `data/`. El `.gitignore` del proyecto excluye `data/*.RData`
> para evitar que se versione por accidente.

### Input: `data/JE5_Insumos.RData`

| Objeto | Dimensiones | Descripcion |
|---|---|---|
| `JE5` | 9.169 x 231 | Informacion de persona unica (anonima), con los cruces ya resueltos contra fuentes externas. |
| `JE5_PER_OFERTA` | 24.703 x 26 | Detalle persona-oferta (anonimo). Una fila por cada oferta a la que se inscribio la persona. |
| `INS_RECIBOS_ANALISIS` | 9.169 x 21 | Analisis del recibo de servicios publicos por API Catastro y georreferenciacion IDECA (direccion anonimizada). |
| `BASE_OFERTA` | 144 x 20 | Ofertas de la convocatoria: convenio, costo del programa, cupos generales y de recomposicion. |
| `BASE_OFERTA_RECOMP` | 131 x 5 | Detalle del cupo de recomposicion, por oferta y localidad (o sin localidad = bolsa ATENEA). |
| `BASE_FDL` | 8 x 7 | Presupuesto por localidad (7 localidades + fila de total). |

**Campos clave de `JE5`:**

| Campo | Descripcion |
|---|---|
| `ID_PERSONA` | Identificador seudonimizado (llave de todos los cruces) |
| `FECHA_NACIMIENTO` | Insumo de `CORTE_EDAD` |
| `SEXO`, `IDENTIDAD_GENERO`, `INFO_HIJOS` | Insumos del Criterio 1 |
| `ETNIA`, `ATENEA_PUNTUA_ETNIA` | Pertenencia etnica y su validacion |
| `RA_VICTIMAS`, `RA_VIOLENCIA_GENERO`, `RA_REINCORPORADOS_REINSERTADOS`, `RA_DISCAPACIDAD_MINSALUD`, `RA_MINDEFENSA_LEY1699` | Condiciones de vulnerabilidad (Criterio 1) |
| `SISBEN4_Grupo`, `SISBEN4_Nivel`, `SISBEN4_Cod_mpio` | Clasificacion SISBEN IV y municipio de la encuesta (Criterio 2) |
| `SABER11_PERIODO`, `SABER11_PERCENTIL_NACIONAL_GLOBAL`, `SABER11_PUESTO`, `SABER11_PUNTAJE_GLOBAL`, `SABER11_MUNICIPIO_APLICACION`, `SABER11_ESTADO_PUBLICACION` | Prueba Saber 11 (Criterio 3 y requisito b) |
| `VALIDACION_ICFES_*` | Titulo de bachiller por validacion del ICFES |
| `SIMAT_GM_*`, `MEN_GM_*` | Colegio de grado medio: sector, zona, codigo DANE de sede y municipio |
| `TYT_MATRICULA_*`, `TYT_GRADUACION_*`, `MEN_ULTIMA_MATRICULA_SUPERIOR`, `GRADUADO_*`, `SENA_*` | Matricula y graduacion en educacion superior y SENA |
| `RESTRICCION_JE`, `RESTRICCION_UTC`, `RESTRICCION_FEST`, `RESTRICCION_EFT`, `RA_FONDOS_ATENEA` | Historico de beneficiarios de programas ATENEA / SED |
| `UTC_GRADUADO`, `RA_CONSEJERO_JUVENTUD_ELECTO`, `RA_DEPORTISTA_IDRD`, `RA_JOVENES_OPORTUNIDADES` | Insumos del Criterio 4 |
| `DUE_CODLOC`, `SISBEN4_CODLOC` | Localidades declarada y de la encuesta SISBEN (Modulo 1) |
| `VOTO` | Participacion electoral (criterio de desempate) |
| `RA_INHABILITADO_RENEC` | Estado de identidad RNEC |

**Campos clave de `BASE_OFERTA`:**

| Campo | Descripcion |
|---|---|
| `ID_OFERTA_PROGRAMA` | Identificador unico de la oferta |
| `CODIGO_SNIES_PROGRAMA`, `NOMBRE_PROGRAMA` | Programa academico |
| `CÓDIGO_INSTITUCIÓN`, `NOMBRE_INSTITUCION_SUPERIOR` | IES que oferta |
| `NIVEL_DE_FORMACIÓN`, `MODALIDAD` | Nivel y modalidad del programa |
| `CONVENIO` | Convenio con que se financia |
| `TOTAL_VALOR_COHORTE_ATENEA` | Costo que asume ATENEA por cupo (se descuenta del FDL) |
| `CUPOS_GENERAL` | Cupos de la bolsa general |
| `CUPOS_RECOMPOSICION` | Cupos de la bolsa de recomposicion |

### Variables calculadas por el algoritmo

| Variable | Modulo | Descripcion |
|---|:---:|---|
| `RECIBOS_CODLOC`, `RECIBOS_LOCALIDAD` | 1 | Localidad resuelta a partir del recibo |
| `CODLOC`, `LOCALIDAD`, `ANALISIS_LOCALIDAD` | 1 | Localidad definitiva y par de fuentes que la confirmo |
| `RA_ICFES_VALIDACION` | 2 | Marca de titulo por validacion del ICFES |
| `CORTE_EDAD` | 2 | Edad cumplida al 2026-06-10 |
| `HABILITADO_A`..`HABILITADO_I`, `HABILITADO` | 2 | Resultado de cada requisito y habilitacion final secuencial |
| `C1_1`..`C1_10`, `C2_1`, `C2_2` | 3 | Componentes individuales de puntaje |
| `CRITERIO_1_VUL_ESTRUCTURAL`, `CRITERIO_2_VUL_ECONOMICA`, `CRITERIO_3_MERITO_ACADEMICO`, `CRITERIO_4_TRAYECTORIA` | 3 | Criterios consolidados |
| `DTLL_CRITERIO_2_VUL_ECONOMICA`, `DTLL_CRITERIO_3_MERITO_ACADEMICO` | 3 | Etiqueta legible del tramo aplicado |
| `PUNTAJE_GLOBAL` | 3 | Suma de los cuatro criterios |
| `ORDENAMIENTO_D`, `SEMILLA` | 4 | Criterio de colegio oficial y desempate aleatorio |
| `JE5_LLAVE_PER` | 4 | **Posicion definitiva en el ordenamiento unico (1..n)** |
| `HABILITADO_IES` | 5 | Requisito adicional de la IES sobre esa oferta |
| `ASIGNACION`, `ASIGNACION_DETALLE`, `VALOR_PROGRAMA` | 5 | Bolsa, localidad de la bolsa y costo con que se financio el cupo |
| `ESTADO_ELEGIBLE` | 5-6 | Estado interno del registro persona-oferta |
| `ORDEN_OFERTA`, `ORDEN_OFERTA_LOCALIDAD`, `MEJOR_OPCION` | 6 | Ordenamientos para la lista de espera |
| `RESULTADO` | 7 | Marcacion publicable: `ELEGIBLE`, `LISTA_ESPERA`, `NO_ELEGIBLE` |
| `PUESTO`, `PUESTO_LOC` | 7 | Puesto dentro de la oferta, general y por localidad |

---

## 7. Instrucciones de Ejecucion

1. Instale R (4.5+) y RStudio. Clone este repositorio.
2. Instale dependencias:
   ```r
   if (!require("renv")) install.packages("renv")
   renv::restore()
   ```
3. **Obtenga el insumo** `JE5_Insumos.RData` y colóquelo en `data/`.
   El archivo **no se distribuye en este repositorio**; ver
   [Obtencion del insumo](#obtencion-del-insumo).
4. Ejecute `source("JE5_Main.R")` desde RStudio. El script activa `renv`, carga librerias y corre los 7 modulos en secuencia. Los modulos **no se ejecutan de forma independiente**: cada uno depende de los objetos que dejo el anterior en el entorno global.
5. Resultado: `output/JE5_VF_YYYYMMDD.xlsx`.

> A diferencia del script original, **no hay que editar ninguna ruta**. El proyecto usa rutas relativas.
>
> El Modulo 5 recorre 9.169 aspirantes uno por uno e imprime su avance en consola; la ejecucion completa toma varios minutos.

---

## 8. Garantia de Reproducibilidad

El algoritmo es deterministico bajo las mismas entradas:

* **Semilla fija:** `set.seed(20260610)` (cierre de la convocatoria) para el desempate aleatorio.
* **Cortes documentados:** edad al 2026-06-10; corte de informacion 2026-06-17; contratos SENA al 2026-06-03.
* **Presupuesto explicito:** `BASE_FDL$JE5_Privadas` = $17.753.034.702 COP y su remanente se exporta en la hoja `BASE_FDL`.
* **Entorno controlado:** `renv.lock` congela versiones de dependencias.
* **Sin rutas absolutas:** el `setwd()` del script original se elimino en favor de rutas relativas al proyecto.
* **Versionamiento:** codigo bajo git.

---

## 9. Preguntas Frecuentes y Glosario

**Por que un aspirante con puntaje alto no recibio cupo?**
Porque el puntaje define el **orden**, no el derecho al cupo. Si cuando llega su turno las ofertas que eligio ya agotaron sus cupos, o el FDL de su localidad ya no alcanza a cubrir el costo del programa, no hay cupo que asignar. En ese caso pasa a lista de espera si su posicion lo permite.

**Vivo en una localidad que no aparece en la lista de cupos. Quede fuera?**
No necesariamente. Si su localidad tiene cupos de **recomposicion**, queda `HABILITADO_RECOMPOSICION`: sigue habilitado y compite por esos cupos, aunque no por los generales. Solo las localidades expresamente excluidas (La Candelaria, Sumapaz, Barrios Unidos, Engativa y Santa Fe) quedan fuera.

**Por que quede sin localidad si declare mi direccion?**
Porque JE5 exige **doble confirmacion**: la localidad declarada (DUE) tiene que coincidir con la del recibo de servicios publicos o con la de la encuesta SISBEN IV. Si las tres fuentes discrepan entre si, no se puede establecer la localidad y el criterio d) inhabilita.

**Por que mi puntaje de merito academico es 0 si presente la Saber 11?**
Porque las escalas empiezan en el percentil 50 (para pruebas desde 2016-1) o en el puesto 499 (para pruebas anteriores). Un resultado por debajo de esos umbrales puntua 0 en el Criterio 3, pero el aspirante sigue habilitado y conserva sus demas criterios.

**Que es la bolsa de recomposicion?**
Son cupos que se liberan o redistribuyen y que no consumen presupuesto de FDL en este algoritmo. Se evaluan **antes** que los cupos generales, y pueden estar atados a una localidad especifica o disponibles para cualquiera (bolsa ATENEA).

**Por que la Universidad de los Andes tiene un requisito extra?**
Porque el numeral 5.3.3.1 permite a las IES fijar requisitos adicionales de admision. Uniandes exige un puntaje Saber 11 de al menos 370. Ese requisito excluye al aspirante **de esa oferta unicamente**; sus demas opciones siguen vigentes.

**Que relacion tiene este algoritmo con `JE5_oferta_algoritmo`?**
Son dos etapas del mismo proceso. El algoritmo de oferta decide cuantos cupos financiar en cada programa (y produce los `CUPOS_GENERAL` que aqui se consumen); este algoritmo decide que persona ocupa cada cupo.

**Es posible replicar los resultados fuera de ATENEA?**
Si. Con este repositorio, el insumo `JE5_Insumos.RData` y `renv::restore()` cualquier
persona reproduce los resultados paso a paso. El insumo se distribuye por
separado y se verifica con el hash MD5 publicado en la
[Seccion 6](#obtencion-del-insumo); el codigo no lo incluye.

### Glosario

| Termino | Definicion |
|---|---|
| **JE** | Jovenes a la E (antes Jovenes a la U). Programa de acceso y permanencia de ATENEA. |
| **IES** | Institucion de Educacion Superior. |
| **FDL** | Fondo de Desarrollo Local. Financia los cupos generales de los residentes de su localidad. |
| **Cupo general** | Cupo financiado con presupuesto del FDL de la localidad del aspirante. |
| **Cupo de recomposicion** | Cupo redistribuido que no consume presupuesto de FDL en este algoritmo; puede estar atado a una localidad o ser de bolsa ATENEA. |
| **Elegible** | Aspirante habilitado que obtuvo cupo. |
| **Lista de espera** | Aspirante habilitado sin cupo, en orden para reemplazar renuncias. |
| **DUE** | Direccion unica declarada por el aspirante en la inscripcion. |
| **IDECA** | Infraestructura de Datos Espaciales para el Distrito Capital. Georreferencia direcciones. |
| **API Catastro** | Servicio de consulta de Catastro Distrital, con nivel de confianza asociado. |
| **SICORE** | Sistema de inscripciones de la Agencia ATENEA. |
| **Saber 11** | Prueba de Estado del ICFES para el ingreso a la educacion superior. |
| **Percentil nacional** | Posicion relativa del puntaje frente a todos los evaluados del pais. Disponible desde 2016-1. |
| **SISBEN IV** | Sistema de Identificacion de Potenciales Beneficiarios de Programas Sociales, version IV. |
| **SNIES** | Sistema Nacional de Informacion de la Educacion Superior (MEN). |
| **SIMAT** | Sistema Integrado de Matricula del sector educativo oficial. |
| **TyT** | Tecnico profesional y tecnologico. |
| **UTC** | La U en Tu Colegio. Estrategia de educacion superior en la media. |
| **RNEC** | Registraduria Nacional del Estado Civil. |
| **Semilla** | Permutacion aleatoria fijada con `set.seed()` que hace reproducible el desempate final. |

---

## 10. Uso del Codigo

Obra institucional de ATENEA (articulo 91 de la Ley 23 de 1982) publicada bajo **Creative Commons Attribution 4.0 (CC BY 4.0)**, en cumplimiento de los principios de transparencia y acceso a la informacion publica.

Cualquier persona puede reproducir, distribuir, comunicar publicamente y transformar esta obra, citando a ATENEA como autora institucional. Las modificaciones o versiones derivadas son responsabilidad exclusiva de quien las realice. Esta autorizacion no implica cesion de derechos patrimoniales ni afecta los derechos morales sobre la obra original.

(c) 2026 ATENEA - Agencia Distrital para la Educacion Superior, la Ciencia y la Tecnologia.

**Desarrollado por:** SAIGC - ATENEA · **Publicacion:** Agosto 2026
