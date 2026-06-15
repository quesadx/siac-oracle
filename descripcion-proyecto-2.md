UNIVERSIDAD NACIONAL SEDE REGIONAL BRUNCA CAMPOS PZ - COTO PROF. HAIROL ROMERO – JEREMY ELIZONDO CURSO: DISEÑO E IMPL. DE BASES DE DATOS 

I CICLO 2026 

## **DESCRIPCIÓN DEL PROYECTO #2 “Sistema Integral de Atención Comunitaria – SIAC”** 

## Objetivo 

Realizar el diseño de una base de datos para un nuevo sistema orientado a la web sobre la gestión integral de atención comunitaria. 

## Descripción del Sistema 

El **Sistema Integral de Atención Comunitaria (SIAC)** tiene como objetivo diseñar e implementar una **base de datos relacional en Oracle 21c XE** que permita gestionar de forma centralizada, segura y consistente la información asociada a la atención comunitaria en salud y bienestar social. 

El sistema estará orientado a instituciones públicas o comunitarias encargadas del **seguimiento integral de comunidades** , considerando aspectos demográficos, familiares, sanitarios y sociales, permitiendo: 

- Ø Caracterizar comunidades y sectores geográficos. 

- Ø Gestionar viviendas y grupos familiares. 

- Ø Administrar información personal y contactos. 

- Ø Registrar eventos de salud, controles preventivos y condiciones de riesgo. 

- Ø Generar información estructurada para análisis y toma de decisiones. 

- Ø Aplicar reglas de negocio directamente desde la base de datos mediante **procedimientos y funciones almacenadas** . 

## Módulos 

El **Sistema Integral de Atención Comunitaria (SIAC)** tiene los siguientes módulos como mínimo: 

## Gestión Geográfica 

Permite administrar la división territorial utilizada por el sistema. Incluye: 

- Ø Regiones 

- Ø Distritos 

- Ø Comunidades 

1 

UNIVERSIDAD NACIONAL SEDE REGIONAL BRUNCA CAMPOS PZ - COTO PROF. HAIROL ROMERO – JEREMY ELIZONDO CURSO: DISEÑO E IMPL. DE BASES DE DATOS 

I CICLO 2026 

## Viviendas 

Gestiona la información física y social de las viviendas. Incluye: 

- Ø Ubicación 

- Ø Condiciones generales 

- Ø Acceso a servicios básicos 

- Ø Estado sanitario 

## Familias 

Administra los grupos familiares que habitan las viviendas. Incluye: 

- Ø Identificación de la familia 

- Ø Jefe de familia 

- Ø Clasificación de riesgo 

- Ø Relación con vivienda y comunidad 

## Personas 

Gestiona la información personal de los individuos asociados a una familia. Incluye: 

- Ø Datos demográficos 

- Ø Estado civil y educativo 

- Ø Relación con la familia 

- Ø Estado general 

## Contactos 

Permite almacenar distintos medios de contacto para personas y familias. Incluye: 

- Ø Tipos de contacto 

- Ø Información de contacto 

- Ø Relación con personas o familias 

## Controles de Salud 

Registra controles preventivos y seguimientos generales. Incluye: 

- Ø Tipo de control 

- Ø Fecha 

- Ø Observaciones 

- Ø Profesional responsable 

## Enfermedades y Condiciones 

Permite el registro de condiciones médicas relevantes. Incluye: 

- Ø Enfermedades crónicas 

- Ø Condiciones temporales 

- Ø Estados y seguimientos 

2 

UNIVERSIDAD NACIONAL SEDE REGIONAL BRUNCA CAMPOS PZ - COTO PROF. HAIROL ROMERO – JEREMY ELIZONDO CURSO: DISEÑO E IMPL. DE BASES DE DATOS 

I CICLO 2026 

## Programas Comunitarios 

Gestiona programas de apoyo, prevención y acompañamiento. Incluye: 

- Ø Programas sociales o sanitarios 

- Ø Beneficiarios 

- Ø Fechas de participación 

## Seguridad 

Permite controlar el acceso al sistema. Incluye: 

- Ø Usuarios 

- Ø Roles 

- Ø Estados de cuenta 

## Especificaciones 

De la información que precede, se debe realizar lo siguiente: 

1. Instalar Oracle 21c XE en Docker. 

2. Herramienta para manejo de la base de datos: PLSQL Developer, SQLDeveloper, Toad. 

3. Crear un usuario formado por la primera letra del nombre y el primer apellido (Ej.  Hairol Romero – HROMERO). A este usuario se le deben asignar los privilegios del sistema necesarios para poder conectarse a la Base de Datos, crear tablas y otros objetos, exportar datos, etc. 

4. Crear o utilizar el “tablespace” llamado UNA. 

5. Crear las tablas. Las tablas deben contener las restricciones (“constraints”) necesarios: llaves primarias, referencias, no nulos y posibles valores. Los nombres de estas deben iniciar con SIAC_nombre. 

6. Crear secuencias para los consecutivos que lo requieran. 

## **Fecha de Entrega Campus Coto** 

Entrega Enunciado: Viernes 17 de abril del 2026. Avance #1: 5% Viernes 30 de abril del 2026. Avance #2: 5% Viernes 22 de mayo del 2026. Entrega Final: 20% Viernes 19 de junio del 2026. 

## **Fecha de Entrega Campus PZ** 

Entrega Enunciado: Martes 14 de abril del 2026. Avance #1: 5% Martes 28 de abril del 2026. Avance #2: 5% Martes 19 de mayo del 2026. Entrega Final: 20% Martes 16 de junio del 2026. 

3 

