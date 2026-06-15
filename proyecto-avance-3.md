UNIVERSIDAD NACIONAL SEDE REGIONAL BRUNCA CAMPOS PZ - COTO PROF. HAIROL ROMERO – JEREMY ELIZONDO CURSO: DISEÑO E IMPL. DE BASES DE DATOS 

I CICLO 2026 

## **RUBRICAS DEL PROYECTO #2 “Sistema Integral de Atención Comunitaria – SIAC”** 

## Avance #3 

**Paquete:** PckAtencionComunitaria Procedimientos: 

- Ø pcRegistrarFamiliaCompleta: Registrar **una familia completa en una sola transacción** , incluyendo: 

   - Vivienda 

   - Familia 

   - Jefe de familia 

   - Miembros iniciales 

- Ø pcCambiarClasificacionRiesgoFamilia; Actualizar la **clasificación de riesgo** de una familia en función de: 

   - Cantidad de enfermedades activas 

   - Condiciones crónicas 

   - Controles de salud pendientes 

- Ø pcAsignarPersonaAProgramaComunitario: Inscribir a **una persona en un programa comunitario** : 

   - No permitir duplicados activos 

   - Verificar vigencia del programa 

   - Validar estado de la persona 

- Ø pcCerrarProgramaComunitario: Cerrar un **programa comunitario** . Actualizar automáticamente todos los registros asociados: 

   - Cambiar estado del programa 

   - Actualizar estado de los beneficiarios 

   - Registrar fecha de cierre 

## Funciones: 

- Ø fcIndiceRiesgoFamiliar: Retorna un **índice numérico de riesgo** para una familia. Cálculo basado en: 

   - Número de miembros 

   - Enfermedades crónicas 

   - Controles de salud vencidos 

   - Participación en programas 

1 

UNIVERSIDAD NACIONAL SEDE REGIONAL BRUNCA CAMPOS PZ - COTO PROF. HAIROL ROMERO – JEREMY ELIZONDO CURSO: DISEÑO E IMPL. DE BASES DE DATOS 

I CICLO 2026 

## Todos deben: 

- Ø Validar existencia de datos 

- Ø Manejar excepciones 

- Ø Retornar mensajes claros de éxito o error 

## **Entregables** 

Script completo 2,5% Paquete de BD (procedimientos y funciones) 10.0% Validaciones y manejo de excepciones 2,5% Defensa técnica 5,0% **Total 20,0%** 

**Fecha de Entrega Campus Coto** Avance #3: 20% Viernes 19 de junio del 2026. **Fecha de Entrega Campus PZ** Avance #3: 20% Martes 16 de junio del 2026. 

2 

UNIVERSIDAD NACIONAL SEDE REGIONAL BRUNCA CAMPOS PZ - COTO PROF. HAIROL ROMERO – JEREMY ELIZONDO CURSO: DISEÑO E IMPL. DE BASES DE DATOS 

I CICLO 2026 

## **Rúbrica - Avance 3** 

Porcentaje 20% Fecha Entrega: 16 de junio del 2026 

Total: 40 puntos 

## 1. Script  (10 puntos) 

**0 – 4 5 – 7 8 – 10** No se entrega el script de Se entrega el script, pero Script completo y funcional. exportación o no es funcional. presenta errores al ejecutarse Permite recrear toda la base No permite recrear la base de o está incompleto. Falta de datos con sus 4 colecciones datos. alguna colección o datos. y documentos correctamente. 

## 2. Defensa Técnica (5 puntos) 

**0 – 1 2 – 3 4 – 5** Explica claramente la Se presenta, pero no logra integración del sistema explicar la integración entre completo, demuestra módulos o no responde dominio de las relaciones correctamente sobre las entre colecciones y responde nuevas colecciones. correctamente las preguntas. 

Se presenta, pero no logra No se presenta a la defensa. explicar la integración entre Se pierde el 100% del módulos o no responde porcentaje del avance (10%). correctamente sobre las nuevas colecciones. 

## 3. Paquete de BD (20 puntos) 

**0 – 6 7 – 13 14 – 20** No se entrega el paquete de Se entrega el paquete de Se presenta completo el bases de datos o está muy base de datos, pero presenta paquete de base de datos, el incompleto. No se pueden errores al ejecutarse o está cual presenta todos los ejecutar los procedimientos y incompleto. Faltan procedimientos y funciones funciones. procedimientos y/o funciones con funcionalidad correcta. 

3 

UNIVERSIDAD NACIONAL SEDE REGIONAL BRUNCA CAMPOS PZ - COTO PROF. HAIROL ROMERO – JEREMY ELIZONDO CURSO: DISEÑO E IMPL. DE BASES DE DATOS 

I CICLO 2026 

almacenadas. 

## 4. Validaciones y manejo de excepciones  (5 puntos) 

**0 – 1** 

**2 – 3** 

No se presentan ni Se presentan validaciones y validaciones ni manejo de manejo de excepciones pero excepciones en los incompletos, faltan definir procedimientos y funciones excepciones para los del paquete de base de procedimientos y funciones. datos. 

**4 – 5** 

Se presenta completo el paquete de base de datos con todas las validaciones necesarias y manejo de excepciones correcto. 

4 

