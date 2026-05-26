# Diccionario de Datos - Sistema SIAC

## Sistema de Información para Atención Comunitaria (SIAC)

**Versión:** Avance 2 - Modelo Relacional Normalizado (3FN)  
**Base de Datos:** Oracle  
**Fecha:** Mayo 2026

---

## Descripción General

El SIAC es un sistema integral diseñado para gestionar información comunitaria, incluyendo aspectos geográficos, vivienda, familias, personas, salud y programas sociales. El modelo está normalizado en Tercera Forma Normal (3FN) para garantizar la integridad y evitar redundancias.

### Estadísticas del Sistema

- **Total de tablas:** 16
- **Total de vistas:** 3
- **Total de secuencias:** 16
- **Módulos principales:** 7 (Geográfico, Viviendas, Personas, Familias, Contactos, Salud, Programas, Seguridad)

---

## Módulo 1: Gestión Geográfica

Este módulo establece la jerarquía territorial del sistema: Región → Distrito → Comunidad.

### 1.1 SIAC_REGION

**Descripción:** Regiones geográficas principales del sistema.

| Columna | Tipo | Nulo | Default | Descripción | Restricciones |
|---------|------|------|---------|-------------|---------------|
| `id_region` | NUMBER | NO | - | Identificador único de la región | **PK** |
| `nombre` | VARCHAR2(100) | NO | - | Nombre de la región | - |
| `descripcion` | VARCHAR2(500) | SÍ | - | Descripción detallada | - |
| `estado` | VARCHAR2(1) | NO | 'A' | Estado de la región | CHECK ('A','I') |
| `fecha_registro` | DATE | SÍ | SYSDATE | Fecha de creación del registro | - |

**Secuencia:** `siac_seq_region`  
**Trigger:** `trg_siac_region_bi` (autoincremental)

**Estados válidos:**
- `A` = Activo
- `I` = Inactivo

---

### 1.2 SIAC_DISTRITO

**Descripción:** Distritos que pertenecen a una región específica.

| Columna | Tipo | Nulo | Default | Descripción | Restricciones |
|---------|------|------|---------|-------------|---------------|
| `id_distrito` | NUMBER | NO | - | Identificador único del distrito | **PK** |
| `nombre` | VARCHAR2(100) | NO | - | Nombre del distrito | - |
| `descripcion` | VARCHAR2(500) | SÍ | - | Descripción detallada | - |
| `id_region` | NUMBER | NO | - | Región a la que pertenece | **FK** → siac_region |
| `estado` | VARCHAR2(1) | NO | 'A' | Estado del distrito | CHECK ('A','I') |
| `fecha_registro` | DATE | SÍ | SYSDATE | Fecha de creación del registro | - |

**Secuencia:** `siac_seq_distrito`  
**Trigger:** `trg_siac_distrito_bi`  
**Índice:** `idx_distrito_region` (id_region)

---

### 1.3 SIAC_COMUNIDAD

**Descripción:** Comunidades dentro de cada distrito.

| Columna | Tipo | Nulo | Default | Descripción | Restricciones |
|---------|------|------|---------|-------------|---------------|
| `id_comunidad` | NUMBER | NO | - | Identificador único de la comunidad | **PK** |
| `nombre` | VARCHAR2(100) | NO | - | Nombre de la comunidad | - |
| `descripcion` | VARCHAR2(500) | SÍ | - | Descripción detallada | - |
| `id_distrito` | NUMBER | NO | - | Distrito al que pertenece | **FK** → siac_distrito |
| `estado` | VARCHAR2(1) | NO | 'A' | Estado de la comunidad | CHECK ('A','I') |
| `fecha_registro` | DATE | SÍ | SYSDATE | Fecha de creación del registro | - |

**Secuencia:** `siac_seq_comunidad`  
**Trigger:** `trg_siac_comunidad_bi`  
**Índice:** `idx_comunidad_distrito` (id_distrito)

---

## Módulo 2: Viviendas

Gestión de información detallada de viviendas, incluyendo condiciones estructurales y servicios básicos.

### 2.1 SIAC_VIVIENDA

**Descripción:** Registro completo de viviendas con sus características físicas y de servicios.

| Columna | Tipo | Nulo | Default | Descripción | Restricciones |
|---------|------|------|---------|-------------|---------------|
| `id_vivienda` | NUMBER | NO | - | Identificador único de la vivienda | **PK** |
| `direccion_exacta` | VARCHAR2(400) | NO | - | Dirección completa de la vivienda | - |
| `id_comunidad` | NUMBER | NO | - | Comunidad donde se ubica | **FK** → siac_comunidad |
| `condicion_general` | VARCHAR2(1) | NO | 'R' | Estado general de la vivienda | CHECK ('B','R','M') |
| `tipo_vivienda` | VARCHAR2(1) | SÍ | - | Tipo de tenencia | CHECK ('P','A','R','O') |
| `material_paredes` | VARCHAR2(50) | SÍ | - | Material de construcción de paredes | - |
| `material_techo` | VARCHAR2(50) | SÍ | - | Material de construcción del techo | - |
| `acceso_agua` | VARCHAR2(1) | SÍ | 'N' | Disponibilidad de agua potable | CHECK ('S','N') |
| `acceso_electricidad` | VARCHAR2(1) | SÍ | 'N' | Disponibilidad de electricidad | CHECK ('S','N') |
| `acceso_alcantarillado` | VARCHAR2(1) | SÍ | 'N' | Disponibilidad de alcantarillado | CHECK ('S','N') |
| `acceso_internet` | VARCHAR2(1) | SÍ | 'N' | Disponibilidad de internet | CHECK ('S','N') |
| `estado_sanitario` | VARCHAR2(1) | SÍ | 'A' | Condición sanitaria general | CHECK ('A','I','R') |
| `observaciones` | VARCHAR2(1000) | SÍ | - | Notas adicionales | - |
| `fecha_registro` | DATE | SÍ | SYSDATE | Fecha de creación del registro | - |

**Secuencia:** `siac_seq_vivienda`  
**Trigger:** `trg_siac_vivienda_bi`  
**Índice:** `idx_vivienda_comunidad` (id_comunidad)

**Valores de catálogos:**

**Condición general:**
- `B` = Buena
- `R` = Regular
- `M` = Mala

**Tipo de vivienda:**
- `P` = Propia
- `A` = Alquilada
- `R` = Prestada
- `O` = Otro

**Servicios (agua, electricidad, alcantarillado, internet):**
- `S` = Sí tiene
- `N` = No tiene

**Estado sanitario:**
- `A` = Adecuado
- `I` = Inadecuado
- `R` = En revisión

---

## Módulo 3: Personas

Registro individual de personas con información demográfica, educativa y familiar.

### 3.1 SIAC_PERSONA

**Descripción:** Información detallada de cada persona registrada en el sistema.

| Columna | Tipo | Nulo | Default | Descripción | Restricciones |
|---------|------|------|---------|-------------|---------------|
| `id_persona` | NUMBER | NO | - | Identificador único de la persona | **PK** |
| `cedula` | VARCHAR2(30) | NO | - | Número de identificación | UNIQUE |
| `nombre` | VARCHAR2(100) | NO | - | Nombre(s) de la persona | - |
| `primer_apellido` | VARCHAR2(100) | NO | - | Primer apellido | - |
| `segundo_apellido` | VARCHAR2(100) | SÍ | - | Segundo apellido | - |
| `fecha_nacimiento` | DATE | NO | - | Fecha de nacimiento | - |
| `genero` | VARCHAR2(1) | NO | - | Género de la persona | CHECK ('M','F','O') |
| `estado_civil` | VARCHAR2(1) | SÍ | - | Estado civil | CHECK ('S','C','D','V','U') |
| `nivel_educativo` | VARCHAR2(1) | SÍ | - | Nivel de educación alcanzado | CHECK ('N','P','S','T','U','G') |
| `ocupacion` | VARCHAR2(150) | SÍ | - | Ocupación o profesión | - |
| `relacion_familia` | VARCHAR2(1) | SÍ | - | Rol dentro de la familia | CHECK ('J','C','H','P','M','A','R','O') |
| `estado` | VARCHAR2(1) | NO | 'A' | Estado de la persona | CHECK ('A','I','F') |
| `fecha_registro` | DATE | SÍ | SYSDATE | Fecha de creación del registro | - |
| `id_familia` | NUMBER | SÍ | - | Familia a la que pertenece | **FK** → siac_familia |

**Secuencia:** `siac_seq_persona`  
**Trigger:** `trg_siac_persona_bi`  
**Índices:** 
- `idx_persona_cedula` (cedula)
- `idx_persona_familia` (id_familia)

**Valores de catálogos:**

**Género:**
- `M` = Masculino
- `F` = Femenino
- `O` = Otro

**Estado civil:**
- `S` = Soltero/a
- `C` = Casado/a
- `D` = Divorciado/a
- `V` = Viudo/a
- `U` = Unión libre

**Nivel educativo:**
- `N` = Ninguno
- `P` = Primaria
- `S` = Secundaria
- `T` = Técnico
- `U` = Universitario
- `G` = Posgrado

**Relación familiar:**
- `J` = Jefe de familia
- `C` = Cónyuge
- `H` = Hijo/a
- `P` = Padre
- `M` = Madre
- `A` = Abuelo/a
- `R` = Hermano/a
- `O` = Otro

**Estado:**
- `A` = Activo
- `I` = Inactivo
- `F` = Fallecido

---

## Módulo 4: Familias

Gestión de núcleos familiares y su clasificación de riesgo.

### 4.1 SIAC_FAMILIA

**Descripción:** Grupos familiares registrados con su clasificación de vulnerabilidad.

| Columna | Tipo | Nulo | Default | Descripción | Restricciones |
|---------|------|------|---------|-------------|---------------|
| `id_familia` | NUMBER | NO | - | Identificador único de la familia | **PK** |
| `nombre_familia` | VARCHAR2(200) | NO | - | Nombre identificador de la familia | - |
| `id_jefe_familia` | NUMBER | SÍ | - | Persona jefe del hogar | **FK** → siac_persona (DEFERRABLE) |
| `clasificacion_riesgo` | VARCHAR2(1) | NO | 'B' | Nivel de vulnerabilidad | CHECK ('A','M','B') |
| `id_vivienda` | NUMBER | NO | - | Vivienda donde residen | **FK** → siac_vivienda |
| `observaciones` | VARCHAR2(1000) | SÍ | - | Notas adicionales | - |
| `estado` | VARCHAR2(1) | NO | 'A' | Estado de la familia | CHECK ('A','I') |
| `fecha_registro` | DATE | SÍ | SYSDATE | Fecha de creación del registro | - |

**Secuencia:** `siac_seq_familia`  
**Trigger:** `trg_siac_familia_bi`  
**Índices:**
- `idx_familia_vivienda` (id_vivienda)
- `idx_familia_jefe` (id_jefe_familia)

**Clasificación de riesgo:**
- `A` = Alto riesgo
- `M` = Riesgo medio
- `B` = Bajo riesgo

**Nota importante:** La relación con la comunidad se obtiene de forma transitiva a través de la vivienda (ver vista `siac_vw_familia_comunidad`).

---

## Módulo 5: Contactos

Gestión de medios de contacto para personas y familias.

### 5.1 SIAC_TIPO_CONTACTO

**Descripción:** Catálogo de tipos de contacto disponibles.

| Columna | Tipo | Nulo | Default | Descripción | Restricciones |
|---------|------|------|---------|-------------|---------------|
| `id_tipo_contacto` | NUMBER | NO | - | Identificador único | **PK** |
| `descripcion` | VARCHAR2(60) | NO | - | Nombre del tipo de contacto | UNIQUE |
| `estado` | VARCHAR2(1) | NO | 'A' | Estado del tipo | CHECK ('A','I') |

**Secuencia:** `siac_seq_tipo_contacto`  
**Trigger:** `trg_siac_tipo_cont_bi`

**Valores iniciales:** TELEFONO_FIJO, CELULAR, EMAIL, WHATSAPP, FAX

---

### 5.2 SIAC_CONTACTO

**Descripción:** Medios de contacto específicos de personas o familias.

| Columna | Tipo | Nulo | Default | Descripción | Restricciones |
|---------|------|------|---------|-------------|---------------|
| `id_contacto` | NUMBER | NO | - | Identificador único del contacto | **PK** |
| `id_tipo_contacto` | NUMBER | NO | - | Tipo de contacto | **FK** → siac_tipo_contacto |
| `valor` | VARCHAR2(200) | NO | - | Valor del contacto (teléfono, email, etc.) | - |
| `id_persona` | NUMBER | SÍ | - | Persona asociada | **FK** → siac_persona |
| `id_familia` | NUMBER | SÍ | - | Familia asociada | **FK** → siac_familia |
| `es_principal` | VARCHAR2(1) | SÍ | 'N' | Indica si es el contacto preferido | CHECK ('S','N') |
| `estado` | VARCHAR2(1) | NO | 'A' | Estado del contacto | CHECK ('A','I') |
| `fecha_registro` | DATE | SÍ | SYSDATE | Fecha de creación del registro | - |

**Secuencia:** `siac_seq_contacto`  
**Trigger:** `trg_siac_contacto_bi`  
**Índices:**
- `idx_cont_persona` (id_persona)
- `idx_cont_familia` (id_familia)

**Restricción especial:** Un contacto debe pertenecer a una persona O a una familia (o ambos), pero no puede estar huérfano.

---

## Módulo 6: Controles de Salud

Seguimiento de controles preventivos y estado de salud de las personas.

### 6.1 SIAC_TIPO_CONTROL

**Descripción:** Catálogo de tipos de controles preventivos de salud.

| Columna | Tipo | Nulo | Default | Descripción | Restricciones |
|---------|------|------|---------|-------------|---------------|
| `id_tipo_control` | NUMBER | NO | - | Identificador único | **PK** |
| `descripcion` | VARCHAR2(120) | NO | - | Nombre del tipo de control | UNIQUE |
| `periodicidad_dias` | NUMBER(5) | SÍ | - | Frecuencia recomendada en días | - |
| `estado` | VARCHAR2(1) | NO | 'A' | Estado del tipo | CHECK ('A','I') |

**Secuencia:** `siac_seq_tipo_control`  
**Trigger:** `trg_siac_tipo_ctrl_bi`

**Valores iniciales:** CONTROL PRENATAL (30 días), CONTROL NIÑO SANO (90 días), CONTROL ADULTO MAYOR (60 días), CONTROL CRÓNICOS (90 días), VACUNACIÓN (365 días), ODONTOLOGÍA (180 días)

---

### 6.2 SIAC_CONTROL_SALUD

**Descripción:** Registro de controles preventivos realizados a personas.

| Columna | Tipo | Nulo | Default | Descripción | Restricciones |
|---------|------|------|---------|-------------|---------------|
| `id_control` | NUMBER | NO | - | Identificador único del control | **PK** |
| `id_persona` | NUMBER | NO | - | Persona que recibe el control | **FK** → siac_persona |
| `id_tipo_control` | NUMBER | NO | - | Tipo de control realizado | **FK** → siac_tipo_control |
| `fecha_control` | DATE | NO | - | Fecha de realización | - |
| `fecha_proxima_cita` | DATE | SÍ | - | Fecha sugerida para próximo control | - |
| `peso_kg` | NUMBER(5,2) | SÍ | - | Peso en kilogramos | - |
| `talla_cm` | NUMBER(5,2) | SÍ | - | Talla en centímetros | - |
| `tension_arterial` | VARCHAR2(15) | SÍ | - | Lectura de presión arterial | - |
| `resultado` | VARCHAR2(1) | NO | - | Resultado general del control | CHECK ('N','A','C','P') |
| `profesional_resp` | VARCHAR2(200) | NO | - | Profesional responsable | - |
| `numero_expediente` | VARCHAR2(50) | SÍ | - | Número de expediente médico | - |
| `observaciones` | VARCHAR2(2000) | SÍ | - | Notas del profesional | - |
| `fecha_registro` | DATE | SÍ | SYSDATE | Fecha de creación del registro | - |

**Secuencia:** `siac_seq_control_salud`  
**Trigger:** `trg_siac_ctrl_salud_bi`  
**Índices:**
- `idx_ctrl_persona` (id_persona)
- `idx_ctrl_tipo` (id_tipo_control)
- `idx_ctrl_fecha` (fecha_control)

**Resultados:**
- `N` = Normal
- `A` = Alterado
- `C` = Crítico
- `P` = Pendiente

---

## Módulo 7: Enfermedades y Condiciones

Gestión de diagnósticos médicos y seguimiento de enfermedades.

### 7.1 SIAC_ENFERMEDAD

**Descripción:** Catálogo de enfermedades y condiciones médicas con codificación CIE-10.

| Columna | Tipo | Nulo | Default | Descripción | Restricciones |
|---------|------|------|---------|-------------|---------------|
| `id_enfermedad` | NUMBER | NO | - | Identificador único | **PK** |
| `nombre` | VARCHAR2(200) | NO | - | Nombre de la enfermedad | UNIQUE |
| `codigo_cie10` | VARCHAR2(10) | SÍ | - | Código CIE-10 internacional | - |
| `tipo` | VARCHAR2(1) | NO | 'C' | Tipo de enfermedad | CHECK ('C','T','I','M','O') |
| `descripcion` | VARCHAR2(1000) | SÍ | - | Descripción detallada | - |
| `estado` | VARCHAR2(1) | NO | 'A' | Estado en el catálogo | CHECK ('A','I') |

**Secuencia:** `siac_seq_enfermedad`  
**Trigger:** `trg_siac_enfermedad_bi`

**Tipos de enfermedad:**
- `C` = Crónica
- `T` = Temporal
- `I` = Infecciosa
- `M` = Mental
- `O` = Otra

**Valores iniciales:** Diabetes Mellitus Tipo 2 (E11), Hipertensión Arterial (I10), Asma Bronquial (J45), Depresión (F32), Dengue (A90), COVID-19 (U07.1)

---

### 7.2 SIAC_PERSONA_ENFERMEDAD

**Descripción:** Relación muchos-a-muchos entre personas y sus diagnósticos médicos.

| Columna | Tipo | Nulo | Default | Descripción | Restricciones |
|---------|------|------|---------|-------------|---------------|
| `id_persona_enf` | NUMBER | NO | - | Identificador único de la relación | **PK** |
| `id_persona` | NUMBER | NO | - | Persona diagnosticada | **FK** → siac_persona |
| `id_enfermedad` | NUMBER | NO | - | Enfermedad diagnosticada | **FK** → siac_enfermedad |
| `fecha_diagnostico` | DATE | NO | - | Fecha del diagnóstico | - |
| `estado_condicion` | VARCHAR2(1) | NO | 'A' | Estado actual de la condición | CHECK ('A','C','R','S') |
| `medico_diagnostico` | VARCHAR2(200) | SÍ | - | Médico que realizó el diagnóstico | - |
| `tratamiento` | VARCHAR2(1000) | SÍ | - | Descripción del tratamiento | - |
| `seguimiento` | VARCHAR2(2000) | SÍ | - | Notas de seguimiento | - |
| `fecha_resolucion` | DATE | SÍ | - | Fecha de resolución (si aplica) | - |
| `fecha_registro` | DATE | SÍ | SYSDATE | Fecha de creación del registro | - |

**Secuencia:** `siac_seq_persona_enf`  
**Trigger:** `trg_siac_pers_enf_bi`  
**Índices:**
- `idx_penf_persona` (id_persona)
- `idx_penf_enfer` (id_enfermedad)

**Restricción única:** Una persona no puede tener la misma enfermedad registrada dos veces (UNIQUE en id_persona + id_enfermedad).

**Estados de condición:**
- `A` = Activa
- `C` = Controlada
- `R` = Resuelta
- `S` = En seguimiento

---

## Módulo 8: Programas Comunitarios

Gestión de programas sociales y de salud disponibles para la comunidad.

### 8.1 SIAC_PROGRAMA

**Descripción:** Programas comunitarios de apoyo, prevención y desarrollo.

| Columna | Tipo | Nulo | Default | Descripción | Restricciones |
|---------|------|------|---------|-------------|---------------|
| `id_programa` | NUMBER | NO | - | Identificador único del programa | **PK** |
| `nombre` | VARCHAR2(250) | NO | - | Nombre del programa | UNIQUE |
| `descripcion` | VARCHAR2(1000) | SÍ | - | Descripción detallada | - |
| `tipo` | VARCHAR2(1) | NO | - | Tipo de programa | CHECK ('S','A','E','N','O') |
| `institucion` | VARCHAR2(200) | SÍ | - | Institución responsable | - |
| `fecha_inicio` | DATE | SÍ | - | Fecha de inicio del programa | - |
| `fecha_fin` | DATE | SÍ | - | Fecha de finalización | - |
| `estado` | VARCHAR2(1) | NO | 'A' | Estado del programa | CHECK ('A','F','S','I') |

**Secuencia:** `siac_seq_programa`  
**Trigger:** `trg_siac_programa_bi`

**Tipos de programa:**
- `S` = Social
- `A` = Sanitario
- `E` = Educativo
- `N` = Nutricional
- `O` = Otro

**Estados:**
- `A` = Activo
- `F` = Finalizado
- `S` = Suspendido
- `I` = Inactivo

**Valores iniciales:** Programa Crecimiento y Desarrollo (CCSS), Avancemos (IMAS), Control de Crónicos Comunitario (CCSS)

---

### 8.2 SIAC_BENEFICIARIO

**Descripción:** Relación muchos-a-muchos entre personas y programas en los que participan.

| Columna | Tipo | Nulo | Default | Descripción | Restricciones |
|---------|------|------|---------|-------------|---------------|
| `id_beneficiario` | NUMBER | NO | - | Identificador único de la relación | **PK** |
| `id_programa` | NUMBER | NO | - | Programa en el que participa | **FK** → siac_programa |
| `id_persona` | NUMBER | NO | - | Persona beneficiaria | **FK** → siac_persona |
| `fecha_inicio_part` | DATE | NO | - | Fecha de inicio de participación | - |
| `fecha_fin_part` | DATE | SÍ | - | Fecha de fin de participación | - |
| `estado_part` | VARCHAR2(1) | NO | 'A' | Estado de la participación | CHECK ('A','C','R','S') |
| `observaciones` | VARCHAR2(1000) | SÍ | - | Notas sobre la participación | - |
| `fecha_registro` | DATE | SÍ | SYSDATE | Fecha de creación del registro | - |

**Secuencia:** `siac_seq_beneficiario`  
**Trigger:** `trg_siac_benef_bi`  
**Índices:**
- `idx_benef_programa` (id_programa)
- `idx_benef_persona` (id_persona)

**Restricción única:** Una persona no puede estar registrada dos veces en el mismo programa (UNIQUE en id_programa + id_persona).

**Estados de participación:**
- `A` = Activo
- `C` = Completado
- `R` = Retirado
- `S` = Suspendido

---

## Módulo 9: Seguridad

Control de acceso y autenticación de usuarios del sistema.

### 9.1 SIAC_ROL

**Descripción:** Roles de acceso disponibles en el sistema.

| Columna | Tipo | Nulo | Default | Descripción | Restricciones |
|---------|------|------|---------|-------------|---------------|
| `id_rol` | NUMBER | NO | - | Identificador único del rol | **PK** |
| `nombre` | VARCHAR2(60) | NO | - | Nombre del rol | UNIQUE |
| `descripcion` | VARCHAR2(500) | SÍ | - | Descripción del rol | - |
| `estado` | VARCHAR2(1) | NO | 'A' | Estado del rol | CHECK ('A','I') |

**Secuencia:** `siac_seq_rol`  
**Trigger:** `trg_siac_rol_bi`

**Valores iniciales:**
- ADMINISTRADOR (Acceso total al sistema)
- MEDICO (Gestión de controles y enfermedades)
- ENFERMERO (Registro de controles preventivos)
- TRABAJADOR_SOCIAL (Gestión de familias y programas)
- CONSULTA (Solo lectura)

---

### 9.2 SIAC_USUARIO

**Descripción:** Usuarios con acceso al sistema SIAC.

| Columna | Tipo | Nulo | Default | Descripción | Restricciones |
|---------|------|------|---------|-------------|---------------|
| `id_usuario` | NUMBER | NO | - | Identificador único del usuario | **PK** |
| `username` | VARCHAR2(60) | NO | - | Nombre de usuario para login | UNIQUE |
| `password_hash` | VARCHAR2(512) | NO | - | Hash de la contraseña (nunca texto plano) | - |
| `id_persona` | NUMBER | SÍ | - | Persona asociada al usuario | **FK** → siac_persona |
| `id_rol` | NUMBER | NO | - | Rol asignado | **FK** → siac_rol |
| `correo` | VARCHAR2(200) | SÍ | - | Correo electrónico | - |
| `estado` | VARCHAR2(1) | NO | 'A' | Estado del usuario | CHECK ('A','B','I','P') |
| `intentos_fallidos` | NUMBER(2) | SÍ | 0 | Contador de intentos de login fallidos | - |
| `fecha_ultimo_acceso` | DATE | SÍ | - | Timestamp del último login exitoso | - |
| `fecha_registro` | DATE | SÍ | SYSDATE | Fecha de creación del usuario | - |

**Secuencia:** `siac_seq_usuario`  
**Trigger:** `trg_siac_usuario_bi`  
**Índices:**
- `idx_usr_rol` (id_rol)
- `idx_usr_persona` (id_persona)

**Trigger especial:** `trg_siac_usr_bloqueo` - Bloquea automáticamente el usuario después de 5 intentos fallidos.

**Estados:**
- `A` = Activo
- `B` = Bloqueado
- `I` = Inactivo
- `P` = Pendiente de activación

---

## Vistas Compensatorias

Estas vistas reemplazan atributos que fueron eliminados durante la normalización para mantener la 3FN.

### V1. SIAC_VW_FAMILIA_COMUNIDAD

**Propósito:** Resuelve la comunidad y jerarquía geográfica de cada familia (relación transitiva vía vivienda).

**Columnas:**
- id_familia, nombre_familia, clasificacion_riesgo, id_vivienda
- id_comunidad, nombre_comunidad
- id_distrito, nombre_distrito
- id_region, nombre_region
- estado, fecha_registro

**Uso:** Permite consultar directamente la ubicación geográfica completa de una familia sin necesidad de joins manuales.

---

### V2. SIAC_VW_FAMILIA_MIEMBROS

**Propósito:** Calcula la cantidad de miembros por familia (atributo derivado).

**Columnas:**
- id_familia, nombre_familia, clasificacion_riesgo, estado
- cantidad_miembros_activos (solo personas con estado 'A')
- cantidad_miembros_total (todas las personas)

**Uso:** Proporciona el conteo de miembros sin almacenar datos redundantes.

---

### V3. SIAC_VW_FAMILIA_RESUMEN

**Propósito:** Vista combinada que integra comunidad y cantidad de miembros.

**Columnas:** Todas las columnas de `siac_vw_familia_comunidad` más cantidad_miembros_activos y cantidad_miembros_total.

**Uso:** Ideal para reportes completos de familias con toda su información contextual.

---

## Secuencias del Sistema

Todas las secuencias están configuradas con `START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE`.

| Secuencia | Tabla asociada |
|-----------|----------------|
| `siac_seq_region` | siac_region |
| `siac_seq_distrito` | siac_distrito |
| `siac_seq_comunidad` | siac_comunidad |
| `siac_seq_vivienda` | siac_vivienda |
| `siac_seq_familia` | siac_familia |
| `siac_seq_persona` | siac_persona |
| `siac_seq_tipo_contacto` | siac_tipo_contacto |
| `siac_seq_contacto` | siac_contacto |
| `siac_seq_tipo_control` | siac_tipo_control |
| `siac_seq_control_salud` | siac_control_salud |
| `siac_seq_enfermedad` | siac_enfermedad |
| `siac_seq_persona_enf` | siac_persona_enfermedad |
| `siac_seq_programa` | siac_programa |
| `siac_seq_beneficiario` | siac_beneficiario |
| `siac_seq_rol` | siac_rol |
| `siac_seq_usuario` | siac_usuario |

---

## Notas de Implementación

### Decisiones de Diseño

1. **Normalización estricta (3FN):** Se eliminaron atributos derivados (cantidad_miembros) y transitivos (id_comunidad en familia) para evitar redundancias.

2. **FK diferida:** La relación familia → jefe_familia usa `DEFERRABLE INITIALLY DEFERRED` para permitir inserciones en cualquier orden.

3. **Estados estandarizados:** La mayoría de tablas usan 'A' (Activo) e 'I' (Inactivo) para soft-delete.

4. **Seguridad:** Las contraseñas se almacenan como hash (VARCHAR2(512)), nunca en texto plano.

5. **Auditoría:** Todas las tablas incluyen `fecha_registro` con default SYSDATE.

### Recomendaciones de Uso

- Usar las vistas compensatorias para reportes en lugar de joins manuales
- Implementar bloqueo automático de usuarios tras intentos fallidos (ya configurado)
- Mantener catálogos actualizados (tipos de contacto, enfermedades, programas)
- Validar integridad referencial antes de eliminar registros (usar soft-delete con estado 'I')

---

**Fin del Diccionario de Datos**
