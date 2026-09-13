# ARCHITECTURE_AUDIT.md

**Proyecto:** GALÁPAGOS: THE ORIGIN — Volume I: San Cristóbal
**Tarea:** C-001 — Architecture Audit
**Auditor:** Claude — Lead Architecture Agent
**Audita:** Architecture Baseline v1.0 / Canon Baseline v1.0
**Fecha:** 2026-09-12
**Estado:** **ACCEPTED** — aprobado por Luisma, 2026-09-12. Las decisiones derivadas viven en ADR-001…ADR-008, `ARCHITECTURE.md`, `CONVENTIONS.md`, `STATE_OWNERSHIP.md` y `CANON_CONFLICT_RESOLUTION.md`. Este documento es ahora **registro histórico de la auditoría**, no autoridad de implementación.
**Idioma del documento:** español (ver AUD-037; el idioma oficial de documentación y código aún no está fijado — si lo prefieres en inglés para consistencia con los 4 documentos maestros, lo regenero)

---

## 0. Alcance y método

### 0.1 Documentos leídos como autoridad

| # | Documento | Autoridad aplicada |
|---|---|---|
| 1 | `01_GALAPAGOS_THE_ORIGIN_MASTER_CANON.md` | Nivel 2 — Master Canon |
| 2 | `02_CLAUDE_MASTER_ARCHITECT.md` | Nivel 5 — Arquitectura aprobada |
| 3 | `03_CODEX_MASTER_IMPLEMENTATION.md` | Nivel 5 — Arquitectura aprobada |
| 4 | `04_CLAUDE_CODEX_WORKFLOW_MASTER.md` | Nivel 5 — Proceso aprobado |
| 5 | `GALAPAGOS_THE_ORIGIN_GDD_v1.0.md` | Nivel 8/9 — documento archivado, **en conflicto** (ver AUD-004 y Anexo I) |

### 0.2 Estado real del repositorio

Hecho verificado, no supuesto: **el proyecto no tiene repositorio.** El directorio de trabajo contiene los 4 documentos maestros, el GDD v1.0 y 13 imágenes de referencia visual. No hay `git`, no hay `project.godot`, no hay código, no hay `ARCHITECTURE.md`, no hay ADRs aceptados.

Esto tiene una consecuencia metodológica importante y debe quedar explícita:

> **La "Architecture Baseline v1" no es una arquitectura. Es un conjunto de principios y prohibiciones en prosa, distribuidos dentro de dos documentos de rol de agente.**

Auditar principios es posible. Pero un principio no es un contrato: no tiene firma, no tiene dirección de dependencia, no tiene formato, no se puede testear y no se puede hacer cumplir automáticamente. Buena parte de los hallazgos de esta auditoría no son "la arquitectura está mal", sino **"la arquitectura todavía no existe con suficiente resolución para que Codex no la invente"** — que es exactamente el riesgo que pediste evaluar.

### 0.3 Definición de severidad usada

| Severidad | Significado operativo |
|---|---|
| **BLOCKER** | Impide el primer commit de implementación (X-001) o impide completar VS0 sin que Codex invente arquitectura. |
| **HIGH** | No bloquea VS0, pero bloquea el milestone indicado en el propio hallazgo. Resolverlo después cuesta reescritura, no edición. |
| **MEDIUM** | Debe resolverse dentro del milestone indicado. Coste de corrección tardía: moderado y contenido. |
| **LOW** | Higiene, deuda conocida o decisión diferible. Se registra para que no se pierda. |

### 0.4 Qué NO hice

- No cambié canon.
- No rediseñé arquitectura. Todo cambio estructural va como propuesta ADR en la Sección C, sin aplicar.
- No generé código de producción ni estructura de carpetas.
- No generé `VS0_FOUNDATION_SPEC.md` (C-002), según tu instrucción.
- No simplifiqué ningún sistema del juego. Donde un sistema es caro, lo digo y propongo cómo pagarlo, no cómo evitarlo.

---

## 1. Resumen ejecutivo

**Veredicto: NOT READY — BLOCKERS MUST BE RESOLVED.**

Matiz importante, porque el veredicto suena peor de lo que es: **los 8 BLOCKERs son decisiones, no ingeniería.** Ninguno requiere trabajo de desarrollo. Siete de los ocho se resuelven eligiendo una opción de una lista corta; el octavo (archivar el GDD) es mover un archivo y ponerle una cabecera. Estimación realista para pasar a `READY FOR VS0`: **una sesión de trabajo tuya conmigo, más un ADR batch.**

El motivo de que existan es estructural y vale la pena decirlo claro: **VS0 consiste literalmente en materializar decisiones que nadie ha tomado todavía.** El scope de VS0 según `02_CLAUDE_MASTER_ARCHITECT.md` es "bootstrap de proyecto Godot, versión de engine bloqueada, estructura de carpetas, carpetas de datos source/generated, framework mínimo de validación, framework mínimo de test, CI skeleton, export Windows". Cada una de esas ocho cosas es una decisión arquitectónica no tomada. Si Codex empieza hoy, Codex las toma. Y una vez tomadas en código, revertirlas cuesta entre un rename global y una migración de saves.

**Lo que está bien:** el canon es de una calidad estructural inusual. Es internamente consistente (verifiqué la aritmética completa de las 150 entradas y cuadra exactamente), está expresado en enumeraciones cerradas, y contiene una cantidad notable de prohibiciones defensivas correctas (Compás no-GPS, Bond no-probabilidad, capacidades no-especies, lógica no-nombres). La separación Claude/Codex/Luisma con niveles de cambio 0–3 es un buen mecanismo de control. La separación de 4 capas de Tikawi y la separación Battle Logic / Battle Presentation son decisiones acertadas que **no hay que tocar**.

**Los tres riesgos reales del proyecto**, por encima de los hallazgos individuales:

1. **El contrato de resultado de combate.** El canon convierte la animación visible en una regla protegida. Si `BattleActionResult` se diseña como un struct de números finales, la presentación no puede escenificar una actuación y Codex terminará poniendo verdad de juego dentro de callbacks de animación — que es exactamente lo que `03_CODEX_MASTER_IMPLEMENTATION.md` prohíbe. Ese contrato hay que fijarlo antes de VS3, y su forma correcta es una línea de tiempo ordenada de eventos, no un resultado. (AUD-012)

2. **La secuencia de persistencia.** El roadmap pone `VS9 Save & QoL` después de Tikawi, combate, vínculo, Codex, quests y economía. Eso significa construir seis sistemas sin persistencia y añadírsela al final. Es la causa raíz directa del riesgo "save breaking changes" que listaste. (AUD-006)

3. **La producción de contenido, no el runtime.** 150 Tikawi no es un problema de rendimiento — son ~600 KB de datos. Es un problema de autoría: 49 líneas evolutivas × 3 estadios, ~98 transiciones de evolución con 7 tipos de disparador, del orden de 200–300 movimientos que por canon deben tener actuación visible, y del orden de 3.000–5.000 claves de localización ES/EN antes siquiera de contar diálogo. Sin un sistema composable de actuaciones y un pipeline de assets con manifiesto validado, la regla de animación visible deja de ser una regla de calidad y se convierte en el cuello de botella del proyecto. (AUD-015, AUD-016)

**Totales:** 8 BLOCKER · 30 HIGH · 14 MEDIUM · 6 LOW · 58 hallazgos.
**Requieren ADR:** 26 hallazgos, consolidables en **8 ADRs** (Sección C).
**Requieren decisión de Luisma:** 17 hallazgos (checklist consolidado en Anexo II).

---

## 2. Índice de hallazgos

| ID | Sev | Área | Problema (resumen) | ADR | Luisma |
|---|---|---|---|---|---|
| AUD-001 | BLOCKER | Infra / Proceso | No existe repositorio, política de ramas ni host de CI | YES | YES |
| AUD-002 | BLOCKER | Gobernanza arq. | La baseline es prosa; no existe `ARCHITECTURE.md` ejecutable | YES | NO |
| AUD-003 | BLOCKER | Engine | Versión de Godot, renderer y export templates sin fijar | YES | YES |
| AUD-004 | BLOCKER | Canon | GDD v1.0 se autotitula canon y contradice el Master Canon | NO | YES |
| AUD-005 | BLOCKER | Presentación / Arte | Contrato de píxel sin definir (resolución base, tile, escalas) | YES | YES |
| AUD-006 | BLOCKER | Persistencia / Roadmap | Save en VS9: seis milestones se construyen sin persistencia | YES | YES |
| AUD-007 | BLOCKER | Testing / Dependencias | VS0 exige test y validator framework; la dependencia no está decidida | YES | YES |
| AUD-008 | BLOCKER | Datos | Formato source, esquema de IDs y política de generated sin definir | YES | YES |
| AUD-009 | HIGH | Módulos | Dirección de dependencia entre capas indefinida e inaplicable | YES | NO |
| AUD-010 | HIGH | Estado / Persistencia | GameState confundido con payload de guardado | YES | NO |
| AUD-011 | HIGH | Estado | No existe matriz de propiedad de mutaciones | NO | NO |
| AUD-012 | HIGH | Combate | `BattleActionResult` no puede sostener la regla de animación visible | YES | NO |
| AUD-013 | HIGH | Combate | La categoría "Reacción" implica resolución fuera de turno | NO | YES |
| AUD-014 | HIGH | Combate | Energía sin regla de suelo → riesgo de soft-lock | NO | YES |
| AUD-015 | HIGH | Animación | Sin sistema composable de actuaciones, la regla no escala | YES | YES |
| AUD-016 | HIGH | Pipeline arte | Contrato de sprite, anchors y manifiesto inexistente | NO | YES |
| AUD-017 | HIGH | Acoplamiento | EventBus es un espacio de nombres global sin tipar ni registro | YES | NO |
| AUD-018 | HIGH | Compás | El contrato puede filtrar posición exacta; canon frágil por convención | YES | NO |
| AUD-019 | HIGH | Bond | El escalar de vínculo no debe cruzar el borde hacia UI | YES | NO |
| AUD-020 | HIGH | Tikawi runtime | La Evolución no tiene hogar arquitectónico | NO | NO |
| AUD-021 | HIGH | Tikawi runtime | Legendarios/Especiales rompen la regla "sin scripts por especie" | YES | NO |
| AUD-022 | HIGH | Field abilities | Capacidades de Tikawi y objetos solapan sin modelo unificado | NO | YES |
| AUD-023 | HIGH | Mundo / Field | Sin validador de alcanzabilidad pese al canon anti-soft-lock | NO | NO |
| AUD-024 | HIGH | Mundo | Modelo de carga de regiones (discreto vs contiguo) sin decidir | YES | YES |
| AUD-025 | HIGH | Entorno | Time/Weather/Tide es el sistema de mayor fan-out y no tiene contrato | NO | YES |
| AUD-026 | HIGH | Mundo | Selección de encuentros multidimensional sin servicio ni determinismo | NO | NO |
| AUD-027 | HIGH | Quest / Diálogo | Runtime de diálogo es una decisión de dependencia sin evaluar | YES | YES |
| AUD-028 | HIGH | Localización | Sin convención de claves, gate de faltantes ni política de nombres propios | NO | YES |
| AUD-029 | HIGH | Canon / Datos | Los enums canónicos viven en prosa; no hay fuente única generada | YES | NO |
| AUD-030 | HIGH | IDs | Usar el número de Codex como identidad convierte renumerar en migración | NO | NO |
| AUD-031 | HIGH | Roadmap | Evolución, Maestros, Fenómenos Ancestrales y Marine sin milestone | NO | YES |
| AUD-032 | HIGH | Mundo / Marítimo | Sin abstracción de locomoción, el aplazamiento marino fuerza reescritura | NO | NO |
| AUD-033 | HIGH | Determinismo | Servicio de RNG con semilla ausente de arquitectura y de save | NO | NO |
| AUD-034 | HIGH | Save / Windows | Escritura atómica y `user://` sin tratamiento específico de Windows | NO | NO |
| AUD-035 | HIGH | Save | Sin disciplina de fixtures dorados ni de tests de migración | NO | NO |
| AUD-036 | HIGH | Datos / Roadmap | El esquema solo se estresa en VS10, con las 150 entradas de golpe | NO | NO |
| AUD-037 | HIGH | Convenciones | Tipado estático, idioma de identificadores y naming sin fijar | NO | YES |
| AUD-038 | HIGH | Input / UI | El modelo de foco para mando debe ser regla desde el primer menú | NO | NO |
| AUD-039 | MEDIUM | Autoloads | Set de autoloads sin tope duro ni disparador de ADR; uno redundante | NO | NO |
| AUD-040 | MEDIUM | Arquitectura | Commands/Events/Queries sin modelo; riesgo de CQRS innecesario | YES | NO |
| AUD-041 | MEDIUM | Combate / Mundo | Los 8 estados de terreno no tienen contrato mundo→combate | NO | NO |
| AUD-042 | MEDIUM | Combate | Modelo de estados alterados ausente | NO | NO |
| AUD-043 | MEDIUM | Combate | El contrato 1v1 debe nacer con slots para soportar 2v2 | NO | NO |
| AUD-044 | MEDIUM | Codex / Research | El progreso debe ser por condición, no por contador | NO | YES |
| AUD-045 | MEDIUM | Equipo / Save | Capacidad de Reserva indefinida; crecimiento de save no acotado | NO | YES |
| AUD-046 | MEDIUM | Mundo / Save | Modelo de cambios persistentes del mundo sin definir | NO | NO |
| AUD-047 | MEDIUM | Datos / Balance | Tabla de tipos 13×13 inexistente y sin validación | NO | YES |
| AUD-048 | MEDIUM | Datos | La rareza no debe alimentar la generación de estadísticas | NO | NO |
| AUD-049 | MEDIUM | Audio | Buses, ducking y transiciones musicales sin arquitectura | NO | NO |
| AUD-050 | MEDIUM | Accesibilidad | Tensión real entre animación obligatoria y reducción de movimiento | NO | YES |
| AUD-051 | MEDIUM | QA / Proceso | El "evidence/screenshots" exigido a Codex no tiene método definido | NO | NO |
| AUD-052 | MEDIUM | Proceso | Task packets de 19 campos para trabajo Nivel 0 ahogan el flujo | NO | NO |
| AUD-053 | MEDIUM | Runtime | Política de fallo ante datos inválidos en build de release | NO | NO |
| AUD-054 | LOW | Save | El checksum es detección de corrupción, no anti-tamper | NO | NO |
| AUD-055 | LOW | Canon | Punta Pitt aparece como región y como destino marítimo | NO | YES |
| AUD-056 | LOW | Rendimiento | Sin presupuesto de rendimiento ni especificación mínima | NO | NO |
| AUD-057 | LOW | Diagnóstico | Sin servicio de logging ni política de niveles | NO | NO |
| AUD-058 | LOW | Alcance | Modding y telemetría no declarados explícitamente fuera de alcance | NO | YES |

---

## 3. Hallazgos BLOCKER

### AUD-001 — No existe repositorio, política de ramas ni host de CI

1. **ID:** AUD-001
2. **Severidad:** BLOCKER
3. **Área afectada:** Infraestructura / Proceso de agentes / CI
4. **Problema:** El directorio de trabajo no es un repositorio git. No hay decisión sobre dónde vive el repo (local, GitHub privado, otro), ni sobre protección de `main`, ni sobre dónde corre CI. Sin embargo `04_CLAUDE_CODEX_WORKFLOW_MASTER.md` asume `main` protegida, ramas `feature/<task-id>`, worktrees separados para agentes paralelos, y CI como gate de milestone; y X-001 incluye "CI skeleton" como entregable.
5. **Por qué importa:** Todo el modelo de control sobre Codex — ramas aisladas, revisión antes de merge, `ALLOWED_PATHS`, gates de CI, evidencia reproducible — depende de que exista un repositorio con esas propiedades. Sin él, Codex trabaja directamente sobre el directorio, sin historia, sin diff revisable y sin posibilidad de revertir. El primer error arquitectónico sería irrecuperable salvo a mano.
6. **Arquitectura actual:** Ninguna. El workflow describe un repositorio que no existe.
7. **Recomendación:**
   - Inicializar repositorio antes de X-001, con `main` protegida y merge solo vía PR/revisión.
   - Decidir host: recomiendo **GitHub privado con GitHub Actions y runner `windows-latest`**, por ser la vía estándar para Godot headless + export Windows y la única que da a Codex un gate objetivo no auto-reportado. Alternativa aceptable si prefieres cero servicios externos: **solo local, con `pre-commit` + un script `scripts/ci_local.ps1`**; el coste es que Codex se autocertifica, lo que debilita "Never fabricate PASS".
   - Definir `.gitignore` de Godot (`.godot/`, `*.tmp`, exports) y **commitear** los `*.import`.
   - Definir política de LFS para PNG de referencia y assets (las 13 imágenes actuales ya suman ~36 MB).
   - Definir la estrategia de worktrees que exige el workflow para agentes paralelos.
8. **Impacto:** Bajo en esfuerzo (una sesión), muy alto en efecto. Habilita simultáneamente AUD-002, AUD-007, AUD-023, AUD-029, AUD-035 y AUD-051, que dependen todos de "hay un CI donde colgar el gate".
9. **¿Requiere ADR?** **YES** — ADR-002 (decisión de plataforma y política de dependencias/infra).
10. **¿Requiere aprobación de Luisma?** **YES** — implica una cuenta externa, coste potencial y dónde reside el código del proyecto.

---

### AUD-002 — La Architecture Baseline es prosa; no existe un `ARCHITECTURE.md` ejecutable

1. **ID:** AUD-002
2. **Severidad:** BLOCKER
3. **Área afectada:** Gobernanza arquitectónica / Límites de módulos / Libertad de Codex
4. **Problema:** La "Architecture Baseline v1" existe únicamente como listas de principios dentro de `02_CLAUDE_MASTER_ARCHITECT.md` y `03_CODEX_MASTER_IMPLEMENTATION.md`. No hay árbol de carpetas, ni firmas de contratos públicos, ni convenciones de nombres, ni reglas de dependencia, ni política de errores, ni ejemplos canónicos de "así se escribe un sistema en este proyecto".
5. **Por qué importa:** Este es el hallazgo raíz del riesgo que listaste como *"Codex tiene demasiada libertad arquitectónica"*. Codex no puede violar una arquitectura que no está escrita; lo que hará es **completarla**, decisión a decisión, mientras implementa. Cada hueco que rellene se convierte en arquitectura de facto, defendida por el código existente. En un proyecto data-driven de 150 criaturas, los huecos son cientos. El coste de revertir no es lineal: crece con cada milestone que se apoya encima.

   Hay un agravante específico de GDScript: el lenguaje **no tiene módulos, ni visibilidad, ni interfaces**. Cualquier script puede `preload()` cualquier ruta y cualquier autoload es global. La separación de capas en Godot no es una propiedad del lenguaje: es una convención que solo existe si se verifica. Escribirla en prosa y confiar en la disciplina de un agente es la forma menos fiable de mantenerla.
6. **Arquitectura actual:** Nueve aforismos correctos ("Content is data. Systems interpret data. Scenes present systems.", etc.) sin traducción operativa.
7. **Recomendación:** Producir, como entregable mío previo a C-002, un `docs/ARCHITECTURE.md` que sea **normativo y concreto**, conteniendo como mínimo:
   - Árbol de carpetas completo con la capa a la que pertenece cada raíz.
   - Regla de dependencia direccional explícita y su lista de excepciones (AUD-009).
   - Lista cerrada de autoloads con su responsabilidad en una frase y un tope numérico (AUD-039).
   - Estilo de contrato público: qué es una "fachada de sistema", qué puede exponer, qué no.
   - Reglas de ID, de datos source/generated y de recursos generados (AUD-008).
   - Política de errores, aserciones y logging (AUD-053, AUD-057).
   - Un **módulo de referencia completo y comentado** — un sistema pequeño real implementado end-to-end como plantilla obligatoria. Para un agente implementador, un ejemplo canónico vale más que veinte reglas.
   - Y un `docs/CONVENTIONS.md` complementario (AUD-037).
   - Todo lo que se pueda pasar de prosa a verificación automática, se pasa (AUD-009 lint, AUD-021 grep, AUD-023 validador, AUD-028 claves, AUD-029 registro canónico, AUD-035 fixtures).
8. **Impacto:** Es trabajo mío, no de Codex, y es la inversión de mayor retorno de toda la auditoría. Sin esto, el resto de controles son recomendaciones; con esto, son especificaciones.
9. **¿Requiere ADR?** **YES** — ADR-003 (capas, dirección de dependencia y presupuesto de autoloads es la parte que necesita decisión formal; el resto del documento es derivado).
10. **¿Requiere aprobación de Luisma?** **NO** — cae dentro de mi rol declarado. Sí requiere tu aprobación el ADR-003 asociado, por ser cambio de límites de módulo.

---

### AUD-003 — Versión de Godot, renderer y export templates sin fijar

1. **ID:** AUD-003
2. **Severidad:** BLOCKER
3. **Área afectada:** Engine / Base técnica
4. **Problema:** El canon fija "Engine: Godot" y "Language: GDScript", sin versión. VS0 exige explícitamente "engine version lock", pero no dice cuál. Tampoco está decidido el renderer (Forward+, Mobile, Compatibility) ni si se usa la build estándar o .NET.
5. **Por qué importa:** No es un detalle de configuración; es una decisión con efectos en cascada:
   - **Godot 3.x vs 4.x** son lenguajes prácticamente distintos en GDScript. No hay ruta barata entre ellos.
   - Dentro de 4.x, la API de tilemaps cambió: `TileMap` quedó deprecado en favor de `TileMapLayer` (4.3+). Elegir mal obliga a migrar todo el mundo autorado más adelante (AUD-024 y MEDIUM de TileMap).
   - Las **export templates deben coincidir exactamente** con la versión del editor. Si no se fija ahora, el CI y la máquina de Luisma pueden producir builds distintos.
   - El **renderer** decide el mínimo de GPU en Windows, el tamaño del export y qué shaders están disponibles para efectos de impacto/clima. Para 2D pixel art offline-first, `Compatibility` (GL Compatibility) maximiza el parque de máquinas soportadas y arranca más rápido; `Forward+` da mejores herramientas de luz 2D e iluminación por canal, relevante si Cavernas de Lava, el Farol y el ciclo día/noche quieren iluminación real en vez de tintado.
6. **Arquitectura actual:** "Godot" y "GDScript", sin más precisión.
7. **Recomendación:**
   - Fijar **Godot 4.x estándar (no .NET)** — GDScript es canon, y .NET añade runtime, tamaño de export y fricción de CI sin beneficio aquí.
   - Fijar una versión **estable y concreta** (recomiendo la última 4.x estable con la que verifiquemos el arranque en tu máquina, verificada por nosotros, no asumida), registrarla en `docs/ENGINE.md`, en `project.godot` y en el workflow de CI, y **prohibir a Codex actualizarla sin ADR**.
   - Recomiendo **Forward+** si quieres luz 2D real en cuevas/noche/Farol; **Compatibility** si priorizas compatibilidad máxima y arranque. Es una decisión con consecuencia visual, por eso es tuya. Necesito que respondas a: *"¿la oscuridad de las Cavernas de Lava y la noche son iluminación real o tintado artístico?"*.
   - Fijar `TileMapLayer` y prohibir `TileMap` deprecado.
   - Guardar las export templates como artefacto versionado o pin explícito en CI.
8. **Impacto:** Decisión de minutos, reversión de meses. Bloquea X-001 de forma literal: `project.godot` no se puede escribir sin ella.
9. **¿Requiere ADR?** **YES** — ADR-001 (la política ADR lista "engine" y "platform assumptions" como materia de ADR obligatoria).
10. **¿Requiere aprobación de Luisma?** **YES** — la elección de renderer tiene consecuencia visual directa y el canon te reserva la autoridad visual.

---

### AUD-004 — El GDD v1.0 se autotitula canon y contradice el Master Canon en puntos protegidos

1. **ID:** AUD-004
2. **Severidad:** BLOCKER
3. **Área afectada:** Canon / Seguridad documental del workflow
4. **Problema:** `GALAPAGOS_THE_ORIGIN_GDD_v1.0.md` está en la carpeta del proyecto, sin marca de obsolescencia, con el encabezado **"Estado: Biblia canónica de preproducción"**. Contradice el Master Canon en al menos nueve puntos, cinco de ellos en la lista *DO NOT CHANGE WITHOUT LUISMA APPROVAL*. Detalle completo en el **Anexo I — Canon Conflict Report**. Los más graves:

   | Punto | GDD v1.0 | Master Canon v1.0 | ¿Protegido? |
   |---|---|---|---|
   | Edad de Darwin | ~26 años | **20 años** | Sí |
   | Legendarios | 5 Guardianes | **3** (#148/#149/#150) | Sí |
   | Identidad de Legendarios | Incluye Abyssiguana y Scalysia | "Abyssiguana and Scalysia are **not** Volume I Legendarios" | Sí |
   | Terminología | "criaturas / compañeros" | **Tikawi** | Sí |
   | Criaturas vegetales | "antropomórficas… Scalito es una criatura vegetal bípeda" | "**Scalito is not a humanoid plant**"; tortuga + Scalesia | Sí |
   | Compás | "variantes especializadas", vendidas en tienda | Objeto único; no dispositivo de captura/almacenamiento | Sí |
   | Estructura del Codex | 30×3 + 20×2 + 15×1 + 5 leg. | 49 líneas × 3 + 3 legendarios | Sí |
   | Motor / plataforma / guardado | "decisiones pendientes" | Godot / GDScript / Windows, saves versionados | Sí |
   | Prueba final | "San Cristóbal Trial" | "Prueba de San Cristóbal"; *"Do not call this a Liga"* | Parcial |
   | Probabilidad de vínculo | "probabilidades de vínculo" pendiente | Bond **no es** probabilidad de captura | Sí |

5. **Por qué importa:** No es un problema de ambigüedad para un humano — tú sabes cuál manda. Es un problema de **seguridad operativa para agentes**. `03_CODEX_MASTER_IMPLEMENTATION.md` instruye a Codex a "inspeccionar el repositorio real" y `04` establece que "la documentación versionada del repositorio es la fuente de verdad". Un documento llamado *Biblia canónica*, dentro del repositorio, es exactamente lo que un agente tratará como autoridad. El resultado probable no es un error visible: es Scalito modelado como planta bípeda antropomórfica, o cinco Legendarios en el esquema de datos, descubierto tres milestones después.
6. **Arquitectura actual:** Coexistencia sin jerarquía marcada. La jerarquía existe (autoridad 2 vs 8) pero **solo dentro de los documentos de rol**, no dentro del artefacto en conflicto.
7. **Recomendación:**
   - Mover el GDD a `docs/archive/` y añadirle una cabecera inequívoca: `STATUS: SUPERSEDED BY 01_GALAPAGOS_THE_ORIGIN_MASTER_CANON.md — NOT IMPLEMENTATION AUTHORITY`.
   - Renombrarlo para que el nombre lo diga: `GDD_v1.0_SUPERSEDED.md`.
   - Establecer la regla general en `ARCHITECTURE.md`: **ningún documento sin cabecera de estado y nivel de autoridad es autoridad.** Todo documento del repo lleva `STATUS` y `AUTHORITY LEVEL` en las primeras cinco líneas.
   - Antes de archivarlo: confirmarme si alguna parte del GDD sigue siendo diseño vigente **no recogido** en el Master Canon (identifico varias: rutinas de NPC por hora, rumores verdaderos/falsos/exagerados, mercado clandestino con consecuencias sobre vínculo, eventos emergentes, Tomás eligiendo el inicial con ventaja de tipo, progresión/transformación de movimientos, builds divergentes en misma especie y nivel). Si son vigentes, deben **ascender al Master Canon**, no quedarse en un archivo archivado, o se perderán.
8. **Impacto:** Diez minutos de trabajo. Elimina una clase entera de fallos de canon silenciosos. El único trabajo real es el punto de "ascender lo que siga vigente", que requiere tu criterio.
9. **¿Requiere ADR?** **NO** — no cambia arquitectura; aplica la jerarquía de autoridad ya aprobada.
10. **¿Requiere aprobación de Luisma?** **YES** — es canon, y decidir qué del GDD sobrevive es decisión tuya. Yo no puedo promover ni descartar diseño.

---

### AUD-005 — El contrato de píxel no está definido (resolución base, tamaño de tile, clases de tamaño, modo de escalado)

1. **ID:** AUD-005
2. **Severidad:** BLOCKER
3. **Área afectada:** Presentación / Pipeline de arte / Cámara / Mundo
4. **Problema:** El canon fija "2D pixel art", "top-down", "inspiración estructural GBC/GBA con paleta/detalle más rica tipo GBA temprano, no HD-2D" y **"pixel-perfect scaling"**. No fija ninguno de los números que hacen falta para materializarlo: resolución base interna, tamaño de tile, tamaño de sprite del jugador, clases de tamaño de Tikawi, ni el modo de estiramiento de Godot.
5. **Por qué importa:** Dos razones, ambas caras.

   **Técnica:** `project.godot` no se puede escribir sin esto. "Pixel-perfect" en Godot es una combinación concreta de ajustes —`display/window/stretch/mode`, `stretch/aspect`, `scale_mode = integer`, filtro de textura `Nearest`, snap de transformadas y vértices 2D— que solo tiene sentido sobre una resolución base elegida. Codex tendrá que inventarla en la primera hora de X-001.

   **De producción:** es la decisión de mayor alcance irreversible del proyecto artístico. El tamaño de tile y las clases de tamaño de sprite determinan cuánto cuesta **cada uno de los ~150 Tikawi × sus animaciones**. Cambiar de 16 px a 24 px a mitad de producción no es un reescalado: es volver a dibujar. Y el canon pide más detalle que GBC pero menos que HD-2D, un punto intermedio que solo queda definido por números.

   Además interactúa con el canon de combate: si las actuaciones deben mostrar windup, recorrido, impacto y reacción, la resolución base decide cuánto espacio hay para escenificarlas. Una resolución demasiado baja hace físicamente imposible la regla de animación protegida.
6. **Arquitectura actual:** Declaraciones cualitativas de estilo, cero parámetros.
7. **Recomendación:** Fijar y bloquear, con tu aprobación, un **Pixel Contract** en `docs/PIXEL_CONTRACT.md`:
   - Resolución base interna y modo de estiramiento (mi recomendación: `canvas_items` + `keep` + escalado entero, resolución base en el entorno de 384×216 o 320×180 por ser 16:9 limpios y escalar entero a 1080p/1440p; la elección exacta debe hacerse mirando tus PNG de referencia contigo, no a ciegas).
   - Tamaño de tile único para todo el mundo autorado.
   - Clases de tamaño de Tikawi (p. ej. S/M/L/XL/Legendario) con dimensiones fijas de lienzo por clase, en overworld y en combate. Esto es lo que evita que cada especie sea un caso único.
   - Preset de importación obligatorio (filtro Nearest, sin mipmaps, sin compresión con pérdida) y verificación en CI.
   - Reglas de cámara: zoom entero, sin subpíxel, política de sacudida de impacto compatible con pixel-perfect.
8. **Impacto:** Bloquea X-001 y bloquea toda producción de arte, que es la tarea de mayor plazo del proyecto. Cuanto antes se fije, antes puede arrancar arte **en paralelo** al código, que es la única forma de que VS10 no sea un muro.
9. **¿Requiere ADR?** **YES** — ADR-001, junto con engine y renderer, por ser el mismo bloque de decisión de presentación.
10. **¿Requiere aprobación de Luisma?** **YES** — es canon visual. Puedo proponer números y sus implicaciones; la elección es tuya.

---

### AUD-006 — El núcleo de guardado está programado para VS9; seis milestones se construyen sin persistencia

1. **ID:** AUD-006
2. **Severidad:** BLOCKER
3. **Área afectada:** Persistencia / Secuencia del roadmap
4. **Problema:** El roadmap sitúa `VS9 Save & QoL` después de VS2 Tikawi Runtime, VS3 Battle, VS4 Compass & Bond, VS5 Codex & Research, VS6 Quest & Dialogue, VS7 Field & Environmental y VS8 Base & Economy. Es decir: siete sistemas con estado durable se diseñan, implementan y validan **sin contrato de persistencia**, y luego se les añade guardado.
5. **Por qué importa:** Es la causa raíz directa de dos de los riesgos que pediste evaluar —*save breaking changes* y *GameState ownership*— y probablemente el defecto de secuencia más caro del plan.

   La persistencia no es una funcionalidad que se añade: es una **restricción sobre la forma de los datos**. Un sistema construido sin ella tiende a guardar referencias a nodos, closures, `Resource` vivas, índices de array posicionales y estado derivado — todo lo cual es inserializable o frágil. Cuando en VS9 haya que serializar siete sistemas a la vez, la opción barata será "serializar lo que hay", y lo que hay será un esquema accidental, no diseñado. A partir de ese momento, cada cambio en cualquiera de esos siete sistemas es una migración de saves.

   Y hay un agravante de timing: VS9 llega justo antes de VS10 Content Assembly y VS11 Polish. El momento de descubrir que el esquema de guardado es inadecuado sería el peor posible.
6. **Arquitectura actual:** El *contenido* del modelo de guardado está bien pensado (escritura atómica, backup, checksum, migraciones, autosaves rotatorios, slots manuales, versión de save separada de versión de juego, "persistir consecuencias, no presentación"). El problema es **cuándo** entra, no qué contiene.
7. **Recomendación:** Propongo — como cambio de arquitectura formal, no aplicado — **dividir el guardado en dos**:
   - **Save Core, adelantado a VS0/VS1**: sobre gran parte no hay nada que diseñar aún, solo el envoltorio. Concretamente: envoltorio versionado (`save_version`, `game_version`, `created_at`, `checksum`), escritura atómica correcta en Windows (AUD-034), rotación de backups, recuperación, **arnés de migración N→N+1 vacío pero funcional**, y **un fixture dorado** que se congela en VS0 y se verifica en CI para siempre.
   - **Rebanada de persistencia por milestone**: cada milestone posterior que introduzca estado durable entrega, como criterio de aceptación obligatorio, (a) su porción del esquema de guardado, (b) su migración desde la versión anterior, y (c) un fixture dorado nuevo. VS9 deja de ser "construir el guardado" y pasa a ser lo que su nombre dice: **QoL** — slots, autosave, UI de guardado, recuperación de usuario.
   - Regla derivada, ya insinuada en el canon y que conviene hacer explícita: *ningún milestone se cierra con estado durable no persistido y no migrado.*
8. **Impacto:** Adelanta trabajo pequeño (el envoltorio es de los componentes más acotados del proyecto) y elimina un riesgo grande. Cambia el contenido de VS0 y de todos los milestones intermedios, por eso requiere tu aprobación antes de que yo escriba `VS0_FOUNDATION_SPEC.md`.
9. **¿Requiere ADR?** **YES** — ADR-005. Toca persistencia y esquema de guardado, ambos materia obligatoria de ADR.
10. **¿Requiere aprobación de Luisma?** **YES** — modifica el roadmap de Vertical Slice aprobado.

---

### AUD-007 — VS0 exige framework de test y de validación, pero la dependencia no está decidida

1. **ID:** AUD-007
2. **Severidad:** BLOCKER
3. **Área afectada:** Testing / Política de dependencias
4. **Problema:** VS0 incluye "minimal validator framework" y "minimal test framework". Simultáneamente, `03_CODEX_MASTER_IMPLEMENTATION.md` prohíbe a Codex "add random plugins" y `02` exige ADR para "dependency strategy". Codex no puede cumplir VS0 sin tomar una decisión que tiene prohibido tomar.
5. **Por qué importa:** Es un bloqueo lógico literal, no una laguna. Además la elección importa de verdad: el framework de test es la infraestructura sobre la que se apoyan los controles de canon que recomiendo en el resto de esta auditoría (determinismo de combate, fixtures de save, alcanzabilidad, claves de localización, registro canónico). Elegir mal, o cambiar más tarde, obliga a reescribir todos los tests.

   Las opciones tienen perfiles distintos: los addons establecidos (GUT, gdUnit4) dan asertos, runner headless, salida para CI y mocking, a cambio de una dependencia de terceros que hay que fijar por versión y actualizar con el engine. Un runner propio mínimo evita la dependencia pero tendremos que mantener nosotros lo que un addon te da gratis, y tiende a quedarse corto en cuanto se necesita headless + reporting + filtrado.
6. **Arquitectura actual:** Requisito sin decisión, con una prohibición encima.
7. **Recomendación:**
   - Decidir en ADR y **fijar versión exacta**, vendorizada en el repo (no descargada en CI), para preservar offline-first.
   - Mi recomendación: **gdUnit4 o GUT, fijado por versión y vendorizado**, en lugar de runner propio. Razón: la disciplina de testing que propongo en esta auditoría es amplia (determinismo, fixtures, validadores, gates), y quiero que el esfuerzo se gaste en escribir tests de canon, no en mantener un runner.
   - El **validator framework** recomiendo que sea **propio y sin dependencias**: son scripts de validación de datos específicos del dominio, ejecutables en Godot headless y también como script independiente; no hay nada que reutilizar de terceros y sí mucho canon específico que codificar (AUD-029).
   - Declarar explícitamente la política: **toda dependencia se fija por versión, se vendoriza y requiere ADR.** Cero descargas en tiempo de build.
8. **Impacto:** Desbloquea X-001 y habilita toda la estrategia de verificación posterior.
9. **¿Requiere ADR?** **YES** — ADR-002 (infraestructura y dependencias).
10. **¿Requiere aprobación de Luisma?** **YES** — es una dependencia de terceros en el producto, y el canon reserva la aprobación de dependencias.

---

### AUD-008 — Formato de datos source, esquema de IDs y política de recursos generados sin definir

1. **ID:** AUD-008
2. **Severidad:** BLOCKER
3. **Área afectada:** Datos / Pipeline de contenido / Identidad
4. **Problema:** El flujo autoritativo está bien definido conceptualmente — `source data → schema validation → semantic validation → canon validation → generated Godot resources` — pero faltan las tres decisiones que lo hacen ejecutable:
   - **Formato de los datos source**: no está elegido (JSON, YAML, CSV/hoja de cálculo, `.tres` autorado a mano…).
   - **Formato de ID**: no está especificado (cadena `snake_case`, entero, UUID) ni sus reglas de ciclo de vida.
   - **Política de recursos generados**: no está dicho si los `.tres` generados se commitean al repositorio o se construyen al vuelo.
5. **Por qué importa:** VS0 crea las carpetas "source/generated data" — no se pueden crear sin saber qué contienen.

   La tercera decisión es la menos obvia y la más importante. Si los recursos generados **no** se commitean, el editor de Godot no puede abrir escenas que los referencien sin ejecutar antes un paso de build, lo cual rompe el flujo de trabajo de edición y complica a Codex y a ti por igual. Si **sí** se commitean, se vuelven un artefacto duplicado que puede divergir silenciosamente de su fuente — y en ese momento el principio "Source is authoritative" deja de ser cierto en la práctica.

   La segunda decisión es la que protege los saves. Los IDs aparecen dentro de cada partida guardada; el canon ya dice "Game logic must never depend on display names", pero no dice qué **es** un ID ni qué pasa cuando un contenido se borra.
6. **Arquitectura actual:** Flujo correcto, sin formatos ni reglas.
7. **Recomendación:**
   - **Source en JSON**, versionado en git, legible en diff, editable por humanos y por agentes, parseable tanto por Godot como por herramientas externas. Si prefieres autorar contenido masivo en hoja de cálculo (razonable para 150 Tikawi × estadísticas), el CSV se exporta **a** JSON y el JSON es el artefacto autoritativo commiteado; la hoja es una herramienta de autoría, no una fuente.
   - **IDs como cadena `snake_case` estable**, independientes del número de Codex (AUD-030), con registro append-only en `data/source/_registry/ids.json`, y tres reglas duras: un ID nunca se reutiliza; un ID nunca se renombra sin migración; borrar un ID exige moverlo a `deprecated_ids` con motivo.
   - **Recursos generados: commiteados, y verificados por CI.** El gate es: regenerar desde source y comprobar que el resultado es idéntico byte a byte a lo commiteado. Esto da lo mejor de ambos — el editor siempre funciona, y la divergencia entre fuente y artefacto es imposible de mergear.
   - Prohibición explícita, ya presente en `03` y que hay que hacer verificable: **nunca editar a mano un recurso generado**. Cabecera autogenerada en cada archivo + comprobación en CI.
8. **Impacto:** Bloquea VS0 y define la forma de todo el contenido del juego para siempre. Es una decisión barata ahora y carísima en VS10.
9. **¿Requiere ADR?** **YES** — ADR-004 ("source-data authority" es materia obligatoria de ADR).
10. **¿Requiere aprobación de Luisma?** **YES** — afecta a cómo vas a autorar contenido tú mismo durante años; la ergonomía de autoría es tu decisión, no solo la mía.

---
## 4. Hallazgos HIGH

### AUD-009 — Dirección de dependencia entre capas indefinida e inaplicable

1. **ID:** AUD-009
2. **Severidad:** HIGH — bloquea VS1
3. **Área afectada:** Límites de módulos / Presentation · Systems · Core · Data
4. **Problema:** Los documentos nombran cuatro responsabilidades ("Modules own behavior. Data owns content. UI owns presentation. Core owns infrastructure") pero nunca establecen **quién puede depender de quién**. ¿Systems puede leer Data directamente o solo a través de un repositorio? ¿Core puede conocer Systems (no debe)? ¿Presentation puede llamar a Systems o solo emitir intenciones? ¿Data puede contener lógica?
5. **Por qué importa:** Sin dirección declarada, la dependencia se vuelve bidireccional por conveniencia en cuestión de semanas, y a partir de ahí "Battle Logic headless-testable" deja de ser cierto: bastará una referencia desde lógica a un nodo de presentación para que el test headless no pueda instanciarla. La testabilidad headless que el canon exige **es** una consecuencia de la dirección de dependencias; no se puede pedir una sin fijar la otra. Y como ya señalé en AUD-002, GDScript no ofrece ningún mecanismo de lenguaje para impedirlo.
6. **Arquitectura actual:** Cuatro nombres de capa sin grafo.
7. **Recomendación:**
   - Declarar la regla: **`Presentation → Systems → Core → Data`**, dependencias solo hacia abajo, sin excepciones, y la comunicación hacia arriba exclusivamente por eventos/señales.
   - `Data` no contiene lógica, solo definiciones y acceso. `Core` no conoce ningún sistema de juego concreto.
   - **Implementar un lint de dependencias en CI** en VS0: un script que construya el grafo de `preload`/`load`/`class_name` por carpeta raíz y falle si una arista va hacia arriba. Son unas decenas de líneas y es el único control que realmente sostiene la arquitectura en GDScript.
   - Mantener una lista explícita y corta de excepciones aprobadas, cada una justificada por escrito.
8. **Impacto:** Barato en VS0, imposible de recuperar en VS6. Protege directamente la testabilidad headless del combate.
9. **¿Requiere ADR?** **YES** — ADR-003.
10. **¿Requiere aprobación de Luisma?** **NO**.

---

### AUD-010 — GameState confundido con el payload de guardado

1. **ID:** AUD-010
2. **Severidad:** HIGH — bloquea VS1 (y se agrava con cada milestone)
3. **Área afectada:** Estado / Persistencia
4. **Problema:** `02` define GameState con 13 subestados (Meta, Player, Team, Reserve, World, Story, Quest, Codex, Inventory, Economy, Navigation, Map, Statistics) y separadamente define un modelo de guardado. En ningún punto se dice si son la misma estructura. Por defecto, en la práctica, acabarán siéndolo: guardar será "serializar GameState".
5. **Por qué importa:** Si el estado de runtime **es** el esquema de guardado, entonces cada refactor interno de cualquier sistema se convierte en un cambio de esquema persistido, y por tanto en una migración. Es el mecanismo exacto por el que un proyecto acumula migraciones triviales y acaba temiendo tocar su propio estado. También arrastra al save cosas que el canon prohíbe persistir ("persist consequences, not transient presentation state"): cachés, referencias a nodos, estado derivado, índices temporales.
6. **Arquitectura actual:** Dos modelos descritos, relación no especificada — que en la práctica equivale a un solo modelo.
7. **Recomendación:**
   - Separar explícitamente **estado de runtime** y **DTO de guardado**, con una función de mapeo declarada por cada subestado: `to_save_dict()` / `from_save_dict(version)`.
   - El DTO es un contrato versionado y estable; el runtime es libre de refactorizarse mientras el mapeo se mantenga.
   - Regla: **ningún campo entra en el DTO sin justificación de "es una consecuencia durable"**, revisada por mí en cada milestone (el template ya tiene el campo *Persistence Impact*; esto le da contenido).
   - El DTO vive en `Core`/`Data`, no en los sistemas, para que su forma sea visible de un vistazo y revisable.
8. **Impacto:** Poco código, mucha libertad futura. Es la contraparte estructural de AUD-006: adelantar el save no sirve si el save es un espejo del runtime.
9. **¿Requiere ADR?** **YES** — ADR-005.
10. **¿Requiere aprobación de Luisma?** **NO**.

---

### AUD-011 — No existe matriz de propiedad de mutaciones

1. **ID:** AUD-011
2. **Severidad:** HIGH — bloquea VS2
3. **Área afectada:** Estado / Ownership
4. **Problema:** El canon dice "GameState exposes state; domain systems own valid mutations" y "UI must not directly mutate raw GameState". Correcto, pero no existe la tabla que dice **qué sistema posee qué subestado**. Con GameState como autoload y 13 subestados públicos, cualquier script puede escribir en cualquiera, y GDScript no tiene forma de impedirlo.
5. **Por qué importa:** Sin la tabla, la regla es inauditable: no se puede revisar "¿quién mutó ReserveState?" ni en review ni en CI. Y con ~10 sistemas escribiendo sobre 13 subestados, la depuración de estado corrupto pasa de "mirar un sistema" a "mirar todo el proyecto". Afecta especialmente a los subestados de propiedad ambigua: WorldState (¿mundo, quest o evento?), StoryState vs QuestState, StatisticsState (todos quieren escribirlo).
6. **Arquitectura actual:** Principio correcto sin instrumento.
7. **Recomendación:**
   - Producir `docs/STATE_OWNERSHIP.md`: una fila por subestado con **propietario único**, lista de mutadores permitidos, eventos que emite y si es persistido.
   - Patrón de acceso: lectura pública vía consultas; escritura únicamente a través de la fachada del sistema propietario. En GDScript esto se aproxima con `get`-only properties y con `_`-prefijo en mutadores internos; no es garantía, pero sí señal legible.
   - Complementar con verificación: grep en CI de escrituras a `GameState.<subestado>` fuera de la carpeta del sistema propietario. Es tosco pero eficaz.
   - Ampliar `STATE OWNERSHIP` en cada task packet con la fila concreta que la tarea toca.
8. **Impacto:** Un documento y un script. Convierte un principio en algo revisable.
9. **¿Requiere ADR?** **NO** — instrumenta arquitectura ya aprobada.
10. **¿Requiere aprobación de Luisma?** **NO**.

---

### AUD-012 — `BattleActionResult` no puede sostener la regla canónica de animación visible

1. **ID:** AUD-012
2. **Severidad:** HIGH — bloquea VS3 · **Hallazgo de mayor prioridad técnica del proyecto**
3. **Área afectada:** Battle Logic / Battle Presentation / Canon de animación
4. **Problema:** La arquitectura define `Battle Logic → BattleActionResult → Battle Presentation` y exige que la lógica sea headless-testable y que la presentación "lea resultados". Pero **no especifica la forma de `BattleActionResult`**. La lectura natural del nombre —"resultado"— sugiere una estructura de valores finales: daño, crítico, efectividad, energía restante.
5. **Por qué importa:** El canon eleva a regla protegida que *"los movimientos de combate son actuaciones, no notificaciones numéricas"*, con beats explícitos: windup, acción corporal, recorrido/proyectil/contacto, impacto, reacción del objetivo, sonido, recuperación. Y `03` prohíbe expresamente *"poner la verdad del daño dentro de callbacks de animación"*.

   Esas dos reglas juntas son incompatibles con un resultado plano. Si la presentación solo recibe `{damage: 12}`, no sabe **cuándo** ocurre el impacto dentro de la actuación, ni cuántos golpes hubo, ni en qué momento se aplicó el estado, ni qué reacción corresponde. Ante esa carencia, un implementador tiene exactamente dos salidas, y ambas violan canon: (a) inventar el ritmo en la capa de animación y disparar el daño desde un callback — prohibido explícitamente; (b) reducir la actuación a un flash y un número — prohibido explícitamente.

   Es decir: **la regla de animación protegida es hoy indefendible por arquitectura, y solo se sostiene por buena voluntad del implementador.** Eso es exactamente lo que no queremos dejarle a Codex.
6. **Arquitectura actual:** Separación correcta, contrato del medio sin especificar.
7. **Recomendación:** Fijar `BattleActionResult` como una **línea de tiempo ordenada e inmutable de eventos de combate**, no como un resultado:

   ```
   BattleActionResult {
       action_id, actor_slot, target_slots, rng_seed_used,
       steps: Array[BattleStep]   # ordenada, determinista, replayable
   }
   BattleStep = { kind, subject_slot, payload, presentation_hint }
   # kind ∈ { windup, travel, contact, damage_applied, status_applied,
   #          energy_spent, stat_changed, reaction, terrain_changed,
   #          faint, recovery, message }
   ```

   Propiedades que esto compra, todas relevantes aquí:
   - La lógica decide **qué** pasa y **en qué orden**; la presentación decide **cuánto dura** y **cómo se ve**. Ninguna invade a la otra.
   - La regla de animación deja de depender de disciplina: si no hay `windup`/`contact`/`reaction` en los pasos, el validador de canon lo detecta. **La regla protegida pasa a ser verificable en CI.**
   - Los tests headless comparan listas de pasos, no números sueltos — mucho mejor cobertura de reglas de combate.
   - Con `rng_seed_used`, un combate entero es reproducible desde un log; obtienes replay y depuración determinista gratis (AUD-033).
   - Soporta multi-golpe, multi-objetivo (AUD-043), reacciones (AUD-013) y cambios de terreno (AUD-041) sin cambiar el contrato.
   - Y permite la QoL de velocidad de combate sin tocar la lógica (AUD-050).
8. **Impacto:** Decidirlo ahora es gratis; decidirlo en VS11 implica reescribir la lógica de combate, sus tests y su presentación. Es el contrato del que cuelga el pilar de combate entero.
9. **¿Requiere ADR?** **YES** — ADR-006 (contrato público + arquitectura de eventos entre sistemas).
10. **¿Requiere aprobación de Luisma?** **NO** — no cambia diseño de juego; **protege** una regla de canon tuya. Sí te pediría revisar la lista de `kind` para confirmar que cubre las actuaciones que tienes en la cabeza.

---

### AUD-013 — La categoría "Reacción" implica resolución fuera de turno no contemplada en el modelo

1. **ID:** AUD-013
2. **Severidad:** HIGH — bloquea VS3
3. **Área afectada:** Combate / Bucle de turnos
4. **Problema:** El canon fija cinco categorías de movimiento: Físico, Especial, Soporte, Control y **Reacción**. Una categoría "Reacción" implica, semánticamente, resolución disparada por la acción del oponente: contraataque, intercepción, réplica, protección condicional. La arquitectura describe el combate como turnos con resultado de acción, sin ningún mecanismo de interrupción.
5. **Por qué importa:** Un bucle de turnos simple (ordenar por Velocidad → resolver acciones en secuencia) y un bucle con resolución fuera de turno son **arquitecturas distintas**, no una variante de la otra. Añadir reacciones después obliga a reescribir el resolvedor, el orden de turno, el modelo de resultado y todos los tests de combate. Y con `BattleActionResult` como timeline (AUD-012), una reacción debe poder **insertarse dentro** de la línea de tiempo de la acción que la disparó, lo que es natural si se diseña desde el inicio e imposible de encajar después.

   Hay además una cuestión de diseño sin resolver: ¿una Reacción ocupa uno de los seis slots activos y se arma previamente? ¿Se dispara automáticamente o se elige? ¿Consume Energía al armarse o al dispararse? ¿Puede una reacción disparar otra reacción (y cómo se corta la recursión)?
6. **Arquitectura actual:** Categoría canónica sin modelo de ejecución.
7. **Recomendación:**
   - Diseñar el resolvedor de combate desde VS3 como una **cola de resolución con puntos de interrupción declarados** (antes de impacto, tras impacto, al recibir estado, al caer Agotado), aunque VS3 no implemente ninguna reacción todavía. El coste de dejar los ganchos es marginal; el de retrofitearlos es el resolvedor entero.
   - Fijar un límite duro de profundidad de encadenamiento de reacciones (recomiendo 1) y hacerlo test.
   - Necesito de ti la definición de diseño: qué es exactamente una Reacción en GALÁPAGOS, cómo se arma y qué la dispara. Es Nivel 3.
8. **Impacto:** Ganchos baratos ahora; resolvedor reescrito si se ignora.
9. **¿Requiere ADR?** **NO** — se resuelve dentro de la especificación de VS3, una vez exista la definición de diseño.
10. **¿Requiere aprobación de Luisma?** **YES** — es definición de mecánica, Nivel 3.

---

### AUD-014 — Energía sin regla de suelo: riesgo de soft-lock en combate

1. **ID:** AUD-014
2. **Severidad:** HIGH — bloquea VS3
3. **Área afectada:** Combate / Energía / Anti-soft-lock
4. **Problema:** El canon establece Energía como estadística y como mecanismo anti-spam ("Energy system prevents spam"), pero no define regeneración, ni coste mínimo, ni qué ocurre cuando **ningún** movimiento del repertorio activo es pagable. Con 6 movimientos activos de coste libre, ese estado es alcanzable trivialmente.
5. **Por qué importa:** Es un **soft-lock de la ruta principal**, y "main path would soft-lock" está listado como condición de parada obligatoria tanto para mí como para Codex. Un combate en el que el jugador no puede actuar y el rival sí, sin salida, no es una dificultad: es una partida perdida sin agencia. Y como el canon prohíbe dificultad adaptativa oculta, no hay red de seguridad silenciosa disponible.

   Nótese que la solución clásica del género (un movimiento de último recurso tipo "forcejeo") es una **decisión de diseño con implicaciones de canon**: un movimiento genérico no tipado choca con un sistema de exactamente 13 tipos sin "Normal", y un ataque de recurso sigue sujeto a la regla de actuación visible.
6. **Arquitectura actual:** Estadística declarada, reglas ausentes.
7. **Recomendación:**
   - Necesito tu decisión entre (al menos) estas vías: **(a)** regeneración garantizada por turno que asegura que algún movimiento siempre es pagable; **(b)** acción explícita de "Recuperar/Respirar" siempre disponible, fuera de los seis slots, que restaura Energía y cede el turno; **(c)** coste cero para el movimiento de menor coste del repertorio; **(d)** un recurso de último término con identidad propia del mundo de GALÁPAGOS.
   - Mi recomendación arquitectónica, sin invadir tu diseño, es **(b)**: es el único que no toca el sistema de tipos, no falsea costes, es legible para el jugador, encaja con "Energía impide spam" (te castiga con un turno, no te bloquea) y se anima de forma natural — el Tikawi recupera el aliento, que además es una actuación visible barata y reutilizable.
   - Sea cual sea la elección: **test de invariante permanente** — "en cualquier estado de combate alcanzable existe al menos una acción legal para el jugador".
8. **Impacto:** El test de invariante es el entregable importante y es barato. La decisión de diseño es tuya y bloquea VS3.
9. **¿Requiere ADR?** **NO**.
10. **¿Requiere aprobación de Luisma?** **YES** — Nivel 3.

---

### AUD-015 — Sin sistema composable de actuaciones, la regla de animación visible no escala

1. **ID:** AUD-015
2. **Severidad:** HIGH — bloquea VS3 y toda la producción de contenido
3. **Área afectada:** Animación / Presentación de combate / Escalabilidad de contenido
4. **Problema:** El canon exige que **todo** movimiento ofensivo completado muestre windup, acción corporal, recorrido/contacto, impacto, reacción del objetivo, sonido y recuperación. La arquitectura no propone ningún mecanismo para producir eso a escala; implícitamente, cada movimiento sería una animación autorada a mano.
5. **Por qué importa:** Es aritmética, no opinión. Volume I tiene 150 entradas. Si el repertorio aprendible medio ronda la docena y los movimientos se comparten entre especies, hablamos del orden de **200–300 movimientos distintos**, cada uno con siete beats, y cada uno visto sobre Tikawi de morfologías radicalmente distintas — un ave volcánica, una tortuga, un cangrejo, un hongo, un calamar abisal.

   Autorar eso a mano no es caro: es **inviable para un equipo pequeño**, y el fallo no se manifestaría en VS3 (donde hay 3–6 movimientos) sino en VS10, cuando ya no hay forma barata de rectificar. En ese punto la presión sería reducir la regla de animación — es decir, simplificar el juego por conveniencia técnica, que es precisamente lo que el canon prohíbe. La forma de **defender** la regla no es repetirla: es construir el sistema que la hace barata.
6. **Arquitectura actual:** Regla de calidad sin sistema que la sostenga.
7. **Recomendación:** Definir las actuaciones como **datos composables**, no como animaciones únicas:
   - Una `MovePerformance` es una receta de datos que referencia piezas reutilizables: un clip de windup de la biblioteca de la especie (por clase de tamaño/morfología), un arquetipo de proyectil o de desplazamiento, un efecto de impacto por tipo elemental, una reacción por clase de tamaño, un id de sonido, y parámetros de cámara.
   - El **Tikawi aporta el cuerpo** (sus clips de windup/recuperación/reacción, definidos por su clase); el **movimiento aporta el efecto** (proyectil, impacto, terreno). Un movimiento nuevo se crea combinando piezas existentes; una especie nueva hereda toda la biblioteca de efectos.
   - Biblioteca inicial reducida y deliberada: unos pocos arquetipos de windup por morfología, un efecto de impacto por cada uno de los 13 tipos, unas pocas reacciones por clase de tamaño. Eso ya cubre cientos de movimientos con actuaciones distinguibles.
   - **Validador de canon de actuación**: ningún movimiento puede existir en datos sin receta completa; CI falla si falta cualquier beat obligatorio. Así la regla protegida se verifica sola.
   - Movimientos singulares (Legendarios, movimiento insignia de un inicial) siguen pudiendo ser autorados a mano — la excepción es asequible precisamente porque el caso general no lo es.
8. **Impacto:** Es la diferencia entre que la regla de animación sea una fortaleza del juego o su cuello de botella. Debe fijarse antes de VS3 porque VS3 crea la presentación de combate.
9. **¿Requiere ADR?** **YES** — ADR-006 (contrato entre lógica y presentación) o ADR propio de pipeline de actuaciones.
10. **¿Requiere aprobación de Luisma?** **YES** — define cuánta variedad visual es alcanzable por movimiento; es una decisión de calidad visual y te corresponde.

---

### AUD-016 — Contrato de sprite, anchors y manifiesto de assets inexistente

1. **ID:** AUD-016
2. **Severidad:** HIGH — bloquea producción de arte (ruta más larga del proyecto)
3. **Área afectada:** Pipeline de arte / Integración de assets
4. **Problema:** `02` autoriza a Claude a "especificar requisitos de frames, anchors, manifiestos y contratos de presentación", pero nada de eso existe. No hay definición de: dimensiones de lienzo por clase de tamaño, número de direcciones en overworld (4 u 8), conjunto de animaciones obligatorio por Tikawi, puntos de anclaje (origen, pie/suelo, punto de impacto, punto de emisión, sombra), convención de nombres de archivo, formato de manifiesto, ni presets de importación.
5. **Por qué importa:** El arte es la ruta crítica más larga y la menos paralelizable con corrección tardía. Sin anchors definidos, el sistema de actuaciones de AUD-015 no puede colocar impactos ni proyectiles: un ataque saldría del centro del sprite en vez de la boca, el pico o la pinza — y eso invalida la regla de actuación visible por motivos puramente técnicos.

   Sin contrato, además, cada Tikawi se convierte en un caso especial de integración, que es la versión artística del riesgo "scripts específicos por especie" (AUD-021).
6. **Arquitectura actual:** Autorización para especificarlo, sin especificación.
7. **Recomendación:**
   - Producir `docs/ASSET_CONTRACT.md` una vez esté fijado el Pixel Contract (AUD-005), definiendo: conjunto obligatorio de animaciones por Tikawi (idle overworld, caminar × direcciones, idle combate, windup, acción, reacción de golpe, Agotado, retrato de Codex), lienzos por clase de tamaño, anchors obligatorios y convención de nombres.
   - **Manifiesto por especie** en datos (no en la escena), enlazando ids de animación con recursos y anchors, validado en CI: *ninguna especie entra en el juego sin manifiesto completo*.
   - **Sistema de placeholders técnicos**: generación automática de sprites de marcador que cumplen el contrato (silueta por clase de tamaño y tipo), para que el código nunca espere al arte y para que la ausencia de arte final sea visualmente obvia y auditable — nunca confundible con arte definitivo, tal como exige `03`.
   - Reporte de cobertura de assets en CI: cuántas de las 150 tienen manifiesto completo. Es tu panel de producción.
8. **Impacto:** Permite que arte y código avancen en paralelo desde ya, en lugar de colisionar en VS10.
9. **¿Requiere ADR?** **NO** — es especificación dentro de mi rol, derivada de decisiones de AUD-005.
10. **¿Requiere aprobación de Luisma?** **YES** — define el coste por Tikawi de la producción artística; es canon visual.

---

### AUD-017 — EventBus es un espacio de nombres global sin tipar, sin registro y sin política de orden

1. **ID:** AUD-017
2. **Severidad:** HIGH — bloquea VS2
3. **Área afectada:** Acoplamiento / EventBus
4. **Problema:** EventBus figura como autoload en la lista aprobada, sin definición de: qué eventos existen, qué carga lleva cada uno, quién los emite y quién los consume, si el despacho es inmediato o diferido, y qué garantías de orden ofrece.
5. **Por qué importa:** Un EventBus global resuelve acoplamiento directo y a cambio crea tres problemas menos visibles, todos relevantes en este proyecto:

   **Acoplamiento invisible.** La dependencia deja de estar en el código y pasa a estar en el nombre del evento. "Quién reacciona a `tikawi_bonded`" deja de ser respondible leyendo el sistema — hay que buscar en todo el repositorio. Para un revisor arquitectónico y para un agente implementador, eso es peor que el acoplamiento directo, no mejor.

   **Orden indefinido.** Si Research, Codex, Quest y Statistics escuchan el mismo evento, el orden de ejecución es el de conexión. En cuanto una regla de juego dependa de ese orden (y con Codex+Research+Quest escuchando los mismos avistamientos, dependerá), habrá un bug no determinista y no reproducible.

   **Reentrancia.** Emitir un evento dentro de un manejador que muta GameState, en mitad de un paso de combate, produce estados intermedios inconsistentes. Es el fallo clásico y el más difícil de diagnosticar.
6. **Arquitectura actual:** Un autoload en una lista.
7. **Recomendación:**
   - **Registro único y tipado de eventos**: todas las señales declaradas en un archivo, con carga documentada. Ningún evento ad hoc.
   - **Regla semántica dura**: EventBus transporta **hechos del pasado**, en pretérito (`tikawi_bonded`, `region_entered`, `move_resolved`). Nunca órdenes. Una orden es una llamada a la fachada del sistema propietario. Esto mantiene limpia la distinción Commands/Events/Queries del canon (AUD-040).
   - **Despacho diferido para eventos de juego**: encolar y drenar en un punto conocido del frame, en vez de emitir dentro de la mutación. Elimina la reentrancia.
   - **Prohibición explícita**: ninguna verdad de juego puede depender del orden de los oyentes. Si dos sistemas deben ordenarse, no es un evento: es una llamada explícita.
   - **Chequeo en CI**: eventos emitidos y nunca consumidos, y oyentes de eventos que nadie emite. Detecta contratos rotos en refactors.
   - Y una recomendación de contención: no todo debe pasar por el bus. Dentro de un módulo, señales locales. El bus es para **cruces de módulo**.
8. **Impacto:** Define el sistema nervioso del juego. Corregirlo tarde implica tocar todos los sistemas.
9. **¿Requiere ADR?** **YES** — ADR-003 ("cross-system event architecture" es materia obligatoria de ADR).
10. **¿Requiere aprobación de Luisma?** **NO**.

---

### AUD-018 — El contrato del Compás puede filtrar posición exacta; el canon se sostiene solo por convención

1. **ID:** AUD-018
2. **Severidad:** HIGH — bloquea VS4
3. **Área afectada:** Compás / Protección de canon por diseño
4. **Problema:** El canon protege el Compás con prohibiciones: no es GPS, no es dispositivo de captura, no es almacenamiento, no es medidor preciso de distancia, no es rastreador de misiones, y **nunca debe exponer la distancia exacta al objetivo**. Pero no existe ningún contrato que haga imposible lo contrario. La implementación natural —un servicio que consulta posiciones y se las pasa a la UI para que dibuje la aguja— **cumple la prohibición solo mientras alguien recuerde cumplirla**.
5. **Por qué importa:** Este es el patrón que quiero aplicar a las reglas de canon frágiles: **si la UI recibe un `Vector2` hacia el objetivo, el canon ya está roto aunque nadie lo muestre todavía.** Basta un futuro ajuste de "calidad de vida" — un indicador de dirección más preciso, un valor de depuración que se queda, un modo debug visible — para que la información se filtre. Y lo hará precisamente en VS11 Polish, bajo presión de usabilidad.

   La prohibición en prosa es necesaria pero insuficiente. La forma robusta es que el dato prohibido **no cruce el límite**.
6. **Arquitectura actual:** Prohibición fuerte, contrato inexistente.
7. **Recomendación:** Diseñar el Compás de modo que la violación sea arquitectónicamente imposible:
   - El servicio del Compás es el **único** que ve posiciones. Lo que devuelve es una lectura **cuantizada**, sin magnitudes continuas:
     ```
     CompassReading {
         strength_band,      # enum de bandas, no float
         direction_hint,     # enum de 8 sectores o "inestable"
         stability,          # enum
         resonance_type,     # id de tipo/afinidad
         anomaly             # id opcional de anomalía registrable
     }
     ```
   - La capa de UI **nunca** recibe posiciones, distancias ni ángulos continuos. No puede mostrar lo que no tiene.
   - Tests de canon permanentes: la lectura no contiene floats de distancia; el número de bandas es pequeño y fijo; el sector de dirección es discreto.
   - El mismo servicio registra "anomalías significativas" (canon) como entradas durables — ahí sí hay persistencia (AUD-006/AUD-010).
8. **Impacto:** Convierte una regla de canon protegida en una propiedad estructural verificable. Mismo coste de implementación, riesgo mucho menor.
9. **¿Requiere ADR?** **YES** — ADR-007 (contrato público con protección de canon).
10. **¿Requiere aprobación de Luisma?** **NO** — implementa tu canon; no lo cambia. Sí querré validar contigo cuántas bandas de intensidad y cuántos sectores de dirección "se sienten" bien, que es decisión de feel.

---

### AUD-019 — El escalar de vínculo no debe cruzar el borde hacia la UI

1. **ID:** AUD-019
2. **Severidad:** HIGH — bloquea VS4
3. **Área afectada:** Bond / Protección de canon por diseño
4. **Problema:** El canon define Bond como confianza contextual con cinco estados (VÍNCULO IMPOSIBLE, INESTABLE, RESONANCIA, POSIBLE, ESTABLECIDO), afirma que *"un Tikawi no pertenece a Darwin: decide caminar con él"*, que el Tikawi **puede negarse**, y `03` prohíbe explícitamente cualquier porcentaje de captura visible. Cualquier implementación razonable, sin embargo, calculará internamente un valor continuo. La arquitectura no dice qué puede salir de ese cálculo.
5. **Por qué importa:** Es el mismo patrón que AUD-018 y el riesgo es mayor, porque aquí la presión de usabilidad es enorme: es la mecánica central de adquisición, y todo el género entrena al jugador a esperar un porcentaje. Si `BondEvaluation` devuelve un `float`, aparecerá en pantalla — primero en debug, luego "temporalmente", luego para siempre. Y en ese momento Bond deja de ser confianza contextual y se convierte en probabilidad de captura, que es exactamente la transformación que el canon prohíbe.
6. **Arquitectura actual:** Regla de diseño clara, frontera técnica inexistente.
7. **Recomendación:**
   - `BondEvaluation` devuelve **el estado canónico y sus razones cualitativas**, nunca un escalar: `{ state, contributing_factors: Array[id], refusal_reason }`. El score interno no sale del sistema.
   - Modelar explícitamente el rechazo como resultado de primera clase, no como fallo: el canon dice que el Tikawi **puede negarse**, lo cual es distinto de "no tuviste suerte". Debe haber un motivo comunicable (contexto, hábitat, estado del Tikawi, comportamiento previo de Darwin), y eso es lo que hace legible el sistema sin números.
   - Test de canon permanente: ningún campo numérico continuo en el contrato público de Bond; los cinco estados son exhaustivos.
   - Interacción con Control de Blackwood: el estado es **derivable pero distinto** (AUD-021); un Tikawi controlado no entra en el flujo de Bond hasta que el Control se retira, y eso debe ser un estado explícito, no una rama oculta.
   - Confirmado por canon y a preservar en el contrato: un Bond exitoso crea **exactamente una** `TikawiInstance` persistente.
8. **Impacto:** Igual que AUD-018: mismo esfuerzo, canon estructuralmente protegido. Además mejora el juego — obliga a comunicar *por qué*, que es más rico que un porcentaje.
9. **¿Requiere ADR?** **YES** — ADR-007.
10. **¿Requiere aprobación de Luisma?** **NO** — implementa canon. Sí necesitaré de ti el vocabulario de factores y motivos de rechazo, que es contenido de diseño.

---

### AUD-020 — La Evolución no tiene hogar arquitectónico

1. **ID:** AUD-020
2. **Severidad:** HIGH — bloquea VS2
3. **Área afectada:** Tikawi runtime / Sistemas transversales
4. **Problema:** El canon convierte la evolución en un pilar de diseño ("Adaptación / evolución") y define hasta siete disparadores: nivel, objeto raro, hábitat/localización, tiempo, vínculo, desafío e investigación. Exige además que una evolución altere significativamente al menos tres de seis dimensiones ("same animal, only bigger" no pasa revisión). **Ni `02` ni `03` mencionan la evolución una sola vez** en su arquitectura. No aparece en la lista de módulos, ni en los subestados de GameState, ni en ningún milestone del roadmap (AUD-031).
5. **Por qué importa:** La evolución es uno de los sistemas de mayor fan-out del juego: lee nivel (Instance), inventario (objeto), región (World), hora (Time), vínculo (Bond), progreso de investigación (Research) y logros (Statistics); y escribe en Instance, Codex, Team y save. Es exactamente el tipo de sistema que, sin hogar declarado, acaba disperso: un poco en `TikawiInstance`, un poco en la pantalla de nivel, un poco en un manejador de eventos. Una vez disperso, las reglas de evolución dejan de ser datos y pasan a ser código repartido — el camino más corto a los scripts por especie (AUD-021).

   Además hay volumen real: 49 líneas × 2 transiciones = **~98 transiciones de evolución** que autorar y validar.
6. **Arquitectura actual:** Ausente.
7. **Recomendación:**
   - Declarar un `EvolutionSystem` con propiedad única sobre las transiciones, alimentado por datos: cada transición es un registro `{from_species, to_species, conditions: Array[Condition]}` con un **vocabulario cerrado de condiciones** correspondiente a los siete disparadores canónicos, reutilizando el mismo vocabulario que quests (AUD-027) — una sola gramática de condiciones para todo el juego, no tres.
   - Evaluación en puntos declarados (fin de combate, subida de nivel, cambio de región, transición de hora, uso de objeto, avance de investigación), nunca en `_process`.
   - Validadores de canon: toda especie no final tiene exactamente una línea de evolución declarada; ninguna línea excede 3 estadios (AUD-029); ninguna condición referencia ids inexistentes; ninguna transición es inalcanzable con el contenido de Volume I.
   - La comprobación de "altera ≥3 de 6 dimensiones" es creativa, no automatizable: debe ser un ítem de checklist en tu revisión visual, y dejarlo declarado evita que se pierda.
8. **Impacto:** Darle hogar ahora cuesta un módulo; recuperarlo después cuesta desenredarlo de seis sistemas.
9. **¿Requiere ADR?** **NO** — es un módulo nuevo dentro de la arquitectura aprobada; se especifica en VS2.
10. **¿Requiere aprobación de Luisma?** **NO** para la arquitectura. **Sí** más adelante para el contenido de las ~98 transiciones.

---

### AUD-021 — Legendarios y Especiales chocan con la regla "sin scripts específicos por especie"

1. **ID:** AUD-021
2. **Severidad:** HIGH — bloquea VS2
3. **Área afectada:** Tikawi runtime / Extensibilidad
4. **Problema:** La regla "evitar scripts de runtime específicos por especie salvo justificación" es correcta y protege contra un riesgo real. Pero el canon crea simultáneamente contenido que **es** intrínsecamente específico:
   - Los tres Legendarios no evolucionan, no usan equipo/reserva normales, no usan tablas de encuentro normales, no usan el flujo de Bond normal, tienen estados propios (Calmado / Alterado / Fuera de control / Restaurado) e identidades de combate distintas (tanque-control de terreno, cazador-percepción, velocidad-clima), y viven bajo una arquitectura aparte de **Fenómenos Ancestrales**.
   - Los 12 Especiales "dependen de condiciones y misterios, no de tasas mínimas de aparición aleatoria" — es decir, condiciones de adquisición singulares.
   - Y el Control de Blackwood es un estado aplicado a Tikawi concretos, con su propia mecánica de retirada.
5. **Por qué importa:** Una regla absoluta sin válvula de escape no se respeta: se **rodea**. Codex se encontrará ante contenido que la arquitectura declarada no puede expresar, y resolverá con lo que tenga a mano — cadenas de `if` sobre `species_id` repartidas por los sistemas, que es el peor resultado posible y justo el riesgo que querías evitar. La regla necesita una salida sancionada.
6. **Arquitectura actual:** Separación de 4 capas correcta (SpeciesData / Instance / Actor / BattleParticipant) + una prohibición sin alternativa.
7. **Recomendación:**
   - Añadir un mecanismo **declarativo de comportamiento por datos**: cada especie puede declarar `behavior_tags` y `behavior_components` de un **registro cerrado y validado** (p. ej. `no_evolution`, `ancestral_phenomenon`, `terrain_shaper`, `condition_gated_encounter`). Los sistemas consultan capacidades, no identidades. Es el mismo principio que ya aplica el canon a las field abilities — *capacidades, no especies* — extendido al runtime.
   - Reglas duras: ningún sistema puede ramificar sobre `species_id`; ramifica sobre tags/componentes. **Verificación en CI**: grep de `species_id ==` / `species == "` fuera de una allowlist mínima y justificada. Tosco, efectivo, y convierte una regla de prosa en un gate.
   - Excepción sancionada y acotada: Legendarios y Fenómenos Ancestrales pueden tener implementación dedicada **dentro de su propio módulo**, declarada como excepción en `ARCHITECTURE.md`, nunca dispersa por sistemas generales. Tres entidades únicas con código propio en su módulo es correcto; tres entidades únicas con `if` repartidos por el combate, el mundo y el vínculo, no.
   - Consecuencia de alcance: **Fenómenos Ancestrales necesita su propio milestone** (AUD-031).
8. **Impacto:** Hace la regla cumplible. Sin esto, la regla se erosiona en el primer contenido especial que se implemente.
9. **¿Requiere ADR?** **YES** — ADR-003 (límites de módulo y excepciones sancionadas).
10. **¿Requiere aprobación de Luisma?** **NO**.

---

### AUD-022 — Capacidades de Tikawi y objetos de exploración se solapan sin modelo unificado

1. **ID:** AUD-022
2. **Severidad:** HIGH — bloquea VS7 (y condiciona VS1)
3. **Área afectada:** Field abilities / Progresión de exploración / Canon
4. **Problema:** El canon establece **dos** vías de acceso paralelas y no dice cómo se relacionan:
   - Field abilities de Tikawi: Fuerza, Despeje/Corte, **Luz**, **Escalada**, Planeo, Nado, Inmersión, Inmersión Profunda, Rastreo — bajo el principio *"Los Tikawi no son llaves. Son compañeros que cambian la manera en que exploras."*
   - Tríada de objetos y soporte: Mochila = Preparación, **Farol = Profundidad**, **Cuerda = Acceso**, Equipo = Progresión.

   Hay solape directo: **Luz vs Farol**, **Escalada vs Cuerda/Equipo**. Si el Farol resuelve la oscuridad, la capacidad Luz de un Tikawi queda mecánicamente vacía; si no la resuelve, entonces hay dos sistemas de gating paralelos y el jugador tiene que aprender ambos.
5. **Por qué importa:** Determina la arquitectura de gating del mundo entero, y por tanto la de VS7 y buena parte de VS1 (qué puede bloquear el paso y cómo se consulta). Sin decidirlo, Codex implementará obstáculos con la comprobación que tenga más a mano, y acabaremos con obstáculos-objeto y obstáculos-capacidad implementados de dos formas distintas e incompatibles, imposibles de auditar juntas para el análisis anti-soft-lock (AUD-023).

   No lo considero una contradicción de canon —ambas cosas pueden coexistir coherentemente— sino un **hueco de diseño** con consecuencia arquitectónica directa.
6. **Arquitectura actual:** Dos vocabularios de acceso, sin relación declarada.
7. **Recomendación:**
   - Arquitectónicamente, la solución limpia es un **proveedor de capacidades** unificado: un obstáculo declara la *capacidad* que exige (`light`, `climb`, `strength`…), y esa capacidad puede ser suministrada por un Tikawi del equipo **o** por un objeto del inventario. Un único punto de consulta, un único modelo, auditable de una vez.
   - Necesito de ti la decisión de diseño sobre el solape. Tres lecturas posibles, todas compatibles con el canon: **(a)** objeto y Tikawi son intercambiables (el objeto es la ruta de respaldo, el Tikawi la ruta elegante); **(b)** son capacidades distintas con grados distintos (Farol = luz estática básica; Luz de Tikawi = luz móvil superior que abre zonas adicionales); **(c)** el objeto es prerrequisito y el Tikawi es el ejecutor.
   - Mi recomendación es **(b)**: preserva la utilidad de ambos, honra "los Tikawi no son llaves" (el Tikawi no es la única llave, es la mejor forma), y da al Farol un rol de umbral sin volver redundante la capacidad.
   - Recordatorio de canon a preservar: la acción de campo solo está completa cuando el Tikawi **la ejecuta visiblemente** — lo cual reutiliza el sistema de actuaciones de AUD-015.
8. **Impacto:** Define cómo se construye cada obstáculo del juego. Cambiarlo después implica reautorar el mundo.
9. **¿Requiere ADR?** **NO** — ADR-008 lo cubre una vez tú decidas el modelo de diseño.
10. **¿Requiere aprobación de Luisma?** **YES** — Nivel 3.

---

### AUD-023 — No existe validador de alcanzabilidad pese al canon anti-soft-lock

1. **ID:** AUD-023
2. **Severidad:** HIGH — bloquea VS7
3. **Área afectada:** Mundo / Field abilities / QA automatizada
4. **Problema:** El canon establece que **"ningún inicial puede dejar al jugador en soft-lock"**, y los tres iniciales otorgan capacidades **disjuntas**: la línea Mariguín da Nado → Inmersión, la línea Lavalín da Planeo, la línea Scalito da Fuerza / Despeje. Ninguno da Luz, Escalada, Rastreo ni Inmersión Profunda. No existe ningún mecanismo para comprobar que el mundo resultante es superable desde las tres elecciones.
5. **Por qué importa:** Es una propiedad global del mundo, no local de un obstáculo. Nadie la puede verificar leyendo un mapa: emerge de la intersección de obstáculos, capacidades, disponibilidad de Tikawi por región, hora, marea y objetos. Y falla de la peor manera posible — solo para una de las tres elecciones de inicial, en una región intermedia, descubierto por un jugador.

   Es además el ejemplo perfecto de por qué el canon necesita instrumentos y no solo reglas: "no soft-lock" escrito en un documento no detecta nada; un grafo recorrido en CI sí.
6. **Arquitectura actual:** Regla canónica sin verificación.
7. **Recomendación:**
   - Modelar el mundo como un **grafo de alcanzabilidad en datos**: nodos = regiones/puntos de entrada; aristas = transiciones con requisitos de capacidad, objeto, marea, hora o progreso de historia.
   - **Validador en CI** que, para cada uno de los tres iniciales, haga búsqueda en anchura desde el punto de partida y verifique que toda región obligatoria de la ruta principal es alcanzable, contando las capacidades realmente obtenibles en el camino. Falla el build si alguna elección queda bloqueada.
   - Extender a los casos degenerados: equipo con un solo Tikawi, todos Agotados, mareas en su estado adverso, de noche.
   - Este validador es también el sitio natural para comprobar "reserve changes only in safe physical contexts" y la regla de viaje rápido solo entre puntos seguros descubiertos.
   - Coste: modesto, si el mundo está en datos desde el principio — otra razón para AUD-008 y AUD-024.
8. **Impacto:** Convierte una garantía canónica en un gate automático. Es de los controles con mejor relación valor/esfuerzo del proyecto.
9. **¿Requiere ADR?** **NO** — es instrumentación, dentro de mi rol.
10. **¿Requiere aprobación de Luisma?** **NO**.

---
### AUD-024 — El modelo de carga del mundo (regiones discretas vs continuo) no está decidido

1. **ID:** AUD-024
2. **Severidad:** HIGH — bloquea VS1
3. **Área afectada:** Arquitectura de mundo / Carga de regiones
4. **Problema:** El canon pide "region-based loading", "hand-authored world", mundo abierto donde *"las regiones no funcionan como niveles lineales"*, y `02` acota: *"Do not build AAA streaming."* Entre esos dos extremos queda sin decidir la pregunta operativa: ¿las 10 regiones de San Cristóbal son **escenas separadas con transición** (con corte/fundido en los bordes), o **un espacio contiguo** con carga y descarga de sectores por proximidad?
5. **Por qué importa:** Son dos arquitecturas distintas, no un ajuste. Determinan el modelo de cámara, el de colisiones, el de coordenadas (locales por región vs globales), el de spawn de entidades, el de persistencia de cambios del mundo, y la forma de los puntos de entrada. También determinan la sensación del juego: la transición con corte es plenamente coherente con la inspiración estructural GBC/GBA que fija el canon y es mucho más barata; la contigüidad da una sensación de isla real más fuerte, y es el estándar implícito cuando alguien lee "mundo abierto".

   Es el punto donde dos partes del canon tiran en direcciones distintas sin contradecirse: "estructura GBC/GBA" y "mundo abierto, sin paredes invisibles". Ambas son satisfacibles, pero no con la misma arquitectura, y la elección es de feel.
6. **Arquitectura actual:** "Regiones modulares, entry IDs estables, spawns seguros, world-change IDs" — correcto y suficiente para la variante discreta, insuficiente para la contigua.
7. **Recomendación:**
   - Necesito tu decisión. Mi recomendación es **regiones discretas con transiciones sin costura perceptual** (carga rápida tras un fundido corto, puntos de entrada emparejados, continuidad visual y musical a ambos lados del borde). Razones: es coherente con la referencia GBA declarada, es radicalmente más barato, permite validar alcanzabilidad como grafo (AUD-023), simplifica persistencia por región, y no compromete el "mundo abierto" en el sentido que el canon le da — que es **no linealidad y libertad de ruta**, no ausencia de cortes de carga.
   - Sea cual sea la elección: **coordenadas locales por región + ID de entrada estable** en el save, nunca posición global absoluta. Así el save sobrevive a reautorar mapas, que ocurrirá muchas veces.
   - Fijar `TileMapLayer`, tamaño de región máximo y convención de bordes.
   - Dejar declarado explícitamente lo que el canon ya prohíbe: nada de generación procedimental de terreno; los sistemas varían **lo que ocurre dentro** de mapas autorados.
8. **Impacto:** Decide la forma de VS1 entero y de todo el contenido de mundo posterior.
9. **¿Requiere ADR?** **YES** — ADR (materia obligatoria: "major loading architecture"). Lo integro en ADR-003 o como ADR propio según tu respuesta.
10. **¿Requiere aprobación de Luisma?** **YES** — tiene consecuencia directa sobre la sensación de exploración.

---

### AUD-025 — Time / Weather / Tide es el sistema de mayor fan-out y no tiene contrato

1. **ID:** AUD-025
2. **Severidad:** HIGH — bloquea VS7 (y condiciona VS1, VS2, VS3, VS5)
3. **Área afectada:** Entorno / Sistemas transversales
4. **Problema:** El canon establece día/atardecer/noche, lluvia, niebla, viento, sol intenso, marea alta y baja, y declara que esas condiciones modifican especies disponibles, NPC presentes, navegación, recursos, movimientos, eventos y acceso a zonas. La arquitectura solo menciona "maybe TimeManager if justified" y "Navigation/Fishing/Diving share environmental context".
5. **Por qué importa:** Es, por número de consumidores, el sistema más transversal del juego: encuentros (AUD-026), evolución (AUD-020), acceso de campo (AUD-022), terreno de combate (AUD-041), rutinas de NPC, iluminación, audio y marea para navegación. Cuando un sistema con ese fan-out no tiene contrato, cada consumidor se construye su propia lectura del entorno, y aparecen incoherencias del tipo "el spawn cree que es de noche y la iluminación cree que es atardecer" — bugs baratos de crear y carísimos de encontrar.

   Y hay preguntas sin responder que son decisiones de diseño, no de implementación: ¿el tiempo avanza en tiempo real o por eventos? ¿avanza durante el combate y los menús? ¿cuánto dura un día? ¿la marea deriva del tiempo o es independiente? ¿el viaje rápido adelanta el reloj?
6. **Arquitectura actual:** Un autoload condicional y una frase.
7. **Recomendación:**
   - **Confirmar `TimeManager` como autoload** (el canon lo exige de facto; el condicional solo genera indecisión) y que publique un **`EnvironmentContext` inmutable**: `{ time_of_day, minute_of_day, weather, tide, region_modifiers }`. Un snapshot, publicado en cambios discretos.
   - **Regla dura**: nadie recalcula condiciones de entorno; todos consultan el contexto. Nada de "si la hora está entre X e Y" repartido por sistemas.
   - Tiempo persistido como **contador entero de minutos** desde el inicio de partida — simple, migrable, determinista.
   - Marea **derivada** del tiempo mediante función pura y testeable, no como estado independiente (evita desincronización y hace la marea predecible para el jugador, que es bueno para el diseño de exploración).
   - Clima con transiciones a partir de la **RNG con semilla** (AUD-033) y sesgo por región, para que sea reproducible en test.
   - Necesito de ti: duración del día de juego y si el tiempo corre durante combate/menús. Es feel.
8. **Impacto:** Un contrato pequeño que previene una clase entera de incoherencias en siete sistemas.
9. **¿Requiere ADR?** **NO** — se especifica dentro de VS1/VS7; solo el autoload extra roza la política, y cabe en ADR-003.
10. **¿Requiere aprobación de Luisma?** **YES** — duración del día y avance en combate son decisiones de feel.

---

### AUD-026 — La selección de encuentros es multidimensional y no tiene servicio ni determinismo

1. **ID:** AUD-026
2. **Severidad:** HIGH — bloquea VS2
3. **Área afectada:** Mundo / Encuentros / Datos
4. **Problema:** El contenido de encuentros depende, según canon, de región × hora × clima × marea × profundidad × rareza × estado de investigación (los Especiales "dependen de condiciones y misterios, no de tasas mínimas de aparición"). No existe servicio declarado que resuelva esa selección, ni formato de datos para expresarla, ni regla de determinismo.
6. **Por qué importa:** Es un problema de selección de cinco o seis dimensiones. Sin un único servicio autoritativo, la lógica de spawn se reparte entre regiones y sistemas, y el resultado es contenido inencontrable: un Tikawi cuya combinación de condiciones nunca se da, descubierto (o no) meses después. Sin determinismo, además, ningún bug de encuentros es reproducible.

   Nota sobre canon: el mandato "los Especiales no dependen de tasas diminutas de aparición aleatoria" es una restricción de **arquitectura**, no solo de diseño: significa que el sistema de encuentros debe admitir **condiciones de aparición**, no solo pesos probabilísticos. Un sistema construido como tabla de pesos no puede expresarlo y habría que rehacerlo.
7. **Recomendación:**
   - Un `EncounterService` único, alimentado por datos, que recibe `(region, EnvironmentContext, depth, player_context)` y devuelve un candidato usando la **RNG con semilla** (AUD-033).
   - Modelo de datos con dos mecanismos separados: **tabla ponderada** para fauna común, y **condiciones de aparición** para Especiales, Legendarios y eventos raros.
   - **Validador de cobertura en CI**: toda especie de Volume I con encuentro declarado debe ser alcanzable bajo alguna combinación de condiciones realmente producible por el juego. Detecta contenido huérfano antes de VS10.
   - Reporte de distribución: histograma por región y condiciones, como herramienta para tu balance.
8. **Impacto:** Sin esto, "150 Tikawi" no es un problema de datos sino de descubribilidad, y solo se manifiesta al final.
9. **¿Requiere ADR?** **NO** — especificación dentro de VS2.
10. **¿Requiere aprobación de Luisma?** **NO** para arquitectura; sí para las condiciones concretas de los Especiales.

---

### AUD-027 — El runtime de diálogo y quests es una decisión de dependencia sin evaluar

1. **ID:** AUD-027
2. **Severidad:** HIGH — bloquea VS6
3. **Área afectada:** Quest / Diálogo / Dependencias
4. **Problema:** El canon exige quests dirigidas por eventos, condiciones/efectos reutilizables, diálogo mediante claves de localización, y advierte que *"los datos de quest no deben convertirse en un lenguaje de programación"*. No se ha evaluado si el runtime de diálogo se construye (custom) o se adopta (addon del ecosistema Godot). `03` prohíbe a Codex añadir dependencias.
5. **Por qué importa:** Un sistema de diálogo decente —ramificación, condiciones, retratos, localización, autoría, previsualización— es de las piezas más costosas de construir bien, y el volumen de contenido aquí es grande: NPC con rutinas, rumores verdaderos y falsos, favores, cinco Maestros, el arco de Blackwood, Isabela, Tomás, Mama Yara.

   La tensión real es esta: **construirlo a medida** garantiza encaje con el vocabulario cerrado de condiciones que recomiendo compartir con evolución y quests (AUD-020), y con el gate de claves de localización (AUD-028), pero cuesta semanas. **Adoptar un addon** ahorra ese tiempo y a cambio trae su propio modelo de datos y su propia forma de expresar condiciones, que puede empujar precisamente hacia el "lenguaje de programación" que el canon prohíbe, además de acoplar el proyecto a la vida útil del addon.
6. **Arquitectura actual:** Principios correctos, decisión pendiente.
7. **Recomendación:**
   - Evaluar formalmente antes de VS6 y decidir por ADR, con criterio explícito: **el vocabulario de condiciones/efectos debe ser cerrado, validado en build y compartido con evolución y quests.** La opción que no permita eso queda descartada, sea cual sea su comodidad.
   - Mi inclinación, sujeta a tu decisión de coste: **runtime propio y mínimo** (nodos de diálogo en datos, condiciones del registro cerrado, texto solo por claves), precisamente porque el canon impone restricciones poco habituales que un addon generalista no respeta por defecto. Es más trabajo y menos riesgo de deriva de canon.
   - Modelar los rumores explícitamente como información **con valor de verdad separado de su contenido** (`claim` vs `truth`), ya que el canon los quiere correctos, incompletos, exagerados o falsos. Si eso no está en el modelo desde el principio, no se puede añadir sin rehacer la estructura de datos de rumores.
8. **Impacto:** Afecta a la mayor parte del contenido narrativo del juego.
9. **¿Requiere ADR?** **YES** — ADR-002 (dependencias) o ADR propio.
10. **¿Requiere aprobación de Luisma?** **YES** — es una compensación tiempo/riesgo, y una dependencia.

---

### AUD-028 — Sin convención de claves de localización, gate de faltantes ni política de nombres propios

1. **ID:** AUD-028
2. **Severidad:** HIGH — bloquea VS2
3. **Área afectada:** Localización
4. **Problema:** El canon exige ES/EN desde el día uno y `LocalizationManager` figura como autoload, pero no hay convención de claves, ni idioma fuente declarado, ni política sobre nombres propios, ni verificación de claves faltantes. Tampoco hay milestone de localización en el roadmap (AUD-031).
5. **Por qué importa:** El volumen es considerable y llega antes de lo que parece: 150 nombres, 150 descripciones de Codex, **750 textos de estadios de investigación** (150 × 5), del orden de 200–300 movimientos con nombre y descripción, objetos, regiones, UI, y después todo el diálogo. Del orden de **3.000–5.000 claves antes de contar diálogo**, × 2 idiomas.

   Sin convención ni verificación, el modo de fallo típico no es un error: es texto en español apareciendo en la build inglesa, o la clave cruda `tikawi.mariguin.desc` visible en pantalla. Y lo descubres jugando, no compilando.

   Hay además una decisión de canon: **los nombres de los Tikawi no deben traducirse.** "Mariguín", "Lavalín", "Scalito", "Volcápago" son nombres propios canónicos y protegidos. Si el sistema de localización los trata como cadenas traducibles, en algún momento alguien —o algún agente— los "traducirá" al inglés, y eso es una violación directa de contenido bloqueado.
6. **Arquitectura actual:** Un autoload sin contrato.
7. **Recomendación:**
   - Convención de claves jerárquica y estable, derivada de los IDs inmutables (`tikawi.<id>.name`, `move.<id>.desc`, `research.<id>.stage_3`), generada automáticamente desde el contenido source — no escrita a mano.
   - **Registro de nombres propios no traducibles** (nombres de Tikawi, topónimos canónicos, nombres de personajes), validado: esas claves deben tener el mismo valor en todos los idiomas, y CI falla si divergen. Así el canon queda protegido por el pipeline.
   - **Gate de CI**: claves faltantes en cualquier idioma soportado, claves huérfanas, y texto literal (no clave) en escenas y scripts de UI.
   - Reconsiderar `LocalizationManager` como autoload: Godot ya trae `TranslationServer` y `tr()`; un autoload propio probablemente solo aporte cambio de idioma en caliente y formateo. Si es eso, cabe en `Core` sin ocupar plaza de autoload (AUD-039).
8. **Impacto:** Instaurarlo en VS2 es trivial; retrofitearlo en VS10, con miles de claves ya escritas, no.
9. **¿Requiere ADR?** **NO**.
10. **¿Requiere aprobación de Luisma?** **YES** — confirmar idioma fuente de autoría y la regla de nombres propios no traducibles.

---

### AUD-029 — Los enums canónicos viven en prosa; no hay fuente única generada

1. **ID:** AUD-029
2. **Severidad:** HIGH — bloquea VS2
3. **Área afectada:** Canon / Datos / Verificación
4. **Problema:** El Master Canon define un número notable de **enumeraciones cerradas**: 13 tipos, 7 rarezas, 4 etiquetas de origen, 7 bandas de nivel, 5 estados de Bond, 5 estadios de investigación, 5 categorías de movimiento, 8 estados de terreno, 4 niveles de profundidad, 9 field abilities, 4 estados de Legendario, 10 regiones, 5 Maestros, y la estructura exacta de las 150 entradas por rangos. Todo eso existe únicamente como listas en un documento Markdown. El código las duplicará.
5. **Por qué importa:** Duplicar canon es garantizar deriva. En el momento en que el `enum TikawiType` de GDScript es una transcripción manual del documento, la pregunta "¿el código implementa el canon?" deja de ser verificable y pasa a ser una cuestión de confianza. Y la lista de contenido protegido es larga: si alguien añade un decimocuarto tipo, o escribe mal un nombre de familia, o los rangos del Codex se desalinean, nada lo detecta.

   Éste es, junto con AUD-012 y AUD-018/019, el tercer pilar de la misma idea: **el canon debe poder verificarse, no solo leerse.**
6. **Arquitectura actual:** Canon en prosa; código pendiente de existir y de duplicarlo.
7. **Recomendación:**
   - Crear un **Canon Registry** en `data/source/canon/` como datos: tipos, rarezas, estados, capacidades, regiones, y el manifiesto de las 150 entradas con familia, rango y estadio.
   - **Generar desde ahí** las constantes/enums de GDScript, como artefacto generado no editable (AUD-008).
   - **Validador de canon en CI** que comprueba invariantes derivadas directamente del Master Canon: exactamente 13 tipos; exactamente 150 entradas; los rangos por pilar cuadran (9/30/24/24/30/18/12/3); los nombres de familia coinciden literalmente con el canon; ningún tipo prohibido (Normal, Hada, Dragón, Fantasma, Luz, Roca, Viento); Legendarios sin evolución y fuera de tablas normales; Cormorr, Terriguana, Abyssiguana y Scalysia **ausentes** del roster activo de Volume I.
   - **Invariante estructural observada, que requiere tu confirmación antes de aplicarla:** verifiqué la aritmética del Codex y **cada una de las 49 familias no legendarias tiene exactamente 3 estadios** (3 iniciales + 10 aves + 8 reptiles + 8 mamíferos + 10 marinos + 6 plantas/insectos + 4 especiales = 49 líneas × 3 = 147, + 3 Legendarios = 150). Si eso es intencional, es una simplificación estructural excelente: el esquema puede asumir 3 estadios y validarlo. Pero el GDD v1.0 describía líneas de 1, 2 y 3 estadios, así que **no lo doy por canon**: necesito que confirmes si "toda línea tiene exactamente 3 estadios" es regla o coincidencia. No lo aplicaré sin tu respuesta.
8. **Impacto:** Convierte la protección de canon de revisión manual en gate automático. Coste bajo, efecto permanente.
9. **¿Requiere ADR?** **YES** — ADR-004 (autoridad de datos source).
10. **¿Requiere aprobación de Luisma?** **NO** para el mecanismo. **YES** para la pregunta de los 3 estadios.

---

### AUD-030 — Usar el número de Codex como identidad convertiría cualquier renumeración en migración

1. **ID:** AUD-030
2. **Severidad:** HIGH — bloquea VS2
3. **Área afectada:** IDs / Persistencia / Canon
4. **Problema:** El canon fija los números del Codex 001–150 con rangos por pilar, lo cual hace muy tentador usar el número como identificador primario de especie. Nada en la arquitectura lo prohíbe.
5. **Por qué importa:** El número del Codex es un **atributo de presentación y ordenación**, no una identidad. El canon mismo deja la puerta abierta a que crezca (*"No existe una última página del Codex"*, entradas 151+ en futuros volúmenes), y el orden dentro de un pilar es una decisión editorial que querrás poder ajustar. Si el número es la identidad, entonces reordenar dos aves se convierte en una migración de saves y en una reescritura de todos los datos que las referencian.
6. **Arquitectura actual:** No especificado; el riesgo es el camino de menor resistencia.
7. **Recomendación:**
   - Separación explícita: `species_id: "mariguin"` (inmutable, nunca reutilizado, lo que se persiste y referencia) y `codex_number: 1` (metadato de presentación, reordenable libremente).
   - **Nada en un save guarda nunca un `codex_number`.** Test de canon permanente.
   - Validador: los números son únicos, contiguos 1–150 y caen en el rango correcto de su pilar (esto sí verifica el canon), mientras los ids son estables.
   - Regla análoga para todo lo demás: regiones, movimientos, objetos, quests y entradas del mundo usan ids de cadena, nunca índices posicionales ni números de orden.
8. **Impacto:** Una decisión de una línea que evita una clase completa de migraciones.
9. **¿Requiere ADR?** **NO** — se recoge en ADR-004.
10. **¿Requiere aprobación de Luisma?** **NO**.

---

### AUD-031 — El roadmap no tiene hogar para Evolución, Maestros, Fenómenos Ancestrales, Marítimo ni Opciones

1. **ID:** AUD-031
2. **Severidad:** HIGH — bloquea la planificación, no un milestone concreto
3. **Área afectada:** Roadmap de Vertical Slice
4. **Problema:** Comparando el canon de contenido con los milestones VS0–VS12, hay sistemas canónicos sin milestone asignado:
   - **Evolución** (pilar de diseño, 7 disparadores, ~98 transiciones) — sin milestone.
   - **Maestros, Sellos y Prueba de San Cristóbal** (progresión competitiva central de Volume I) — sin milestone.
   - **Fenómenos Ancestrales / Legendarios** (arquitectura explícitamente separada por canon) — sin milestone.
   - **Marine Technical Slice** (On The Hook, navegación, pesca, buceo, 4 profundidades) — mencionado como "posterior", sin posición.
   - **Opciones / accesibilidad / rebinding** — "Opciones" está en el menú principal canónico; no aparece en ningún milestone.
   - **Localización como contenido** (no como infraestructura) — sin milestone.
   - **Audio** — sin milestone (aparece como principio, no como trabajo).
5. **Por qué importa:** Un sistema sin milestone no es un sistema pospuesto: es un sistema que aparecerá **dentro** de otro milestone, comprimiendo su alcance y saltándose su especificación. Es el mecanismo habitual por el que un roadmap ordenado se desborda. Además, dos de ellos (Evolución y Fenómenos Ancestrales) son transversales, y meterlos dentro de VS2 o VS3 por conveniencia acabaría dispersándolos (AUD-020, AUD-021).

   Aparte, VS12 "Architecture Review" como milestone final es discutible: la revisión arquitectónica está definida en el workflow como paso **de cada milestone**. Un VS12 dedicado sugiere que se puede diferir, que es justo lo contrario de lo que el workflow establece.
6. **Arquitectura actual:** 13 milestones que no cubren el canon aprobado.
7. **Recomendación:**
   - Ubicar explícitamente cada sistema huérfano. Mi propuesta, sujeta a tu aprobación: Evolución dentro de VS2 con especificación propia y criterios de aceptación separados; Maestros/Sellos/Prueba como milestone propio entre VS8 y VS9; Fenómenos Ancestrales como milestone propio posterior a VS7; Marine Technical Slice como slice independiente después de VS11; Opciones/accesibilidad/rebinding integrado en VS9 (que ya es "QoL"); audio distribuido con un gate de calidad en VS11.
   - Convertir VS12 en **revisión continua por milestone** (ya definida) más una **auditoría de escalabilidad** previa a producción masiva, que es lo que realmente hace falta antes de VS10.
   - No añadir milestones nuevos por añadir: el objetivo es que ningún sistema canónico quede sin dueño temporal, no inflar el plan.
8. **Impacto:** Evita que milestones acotados se conviertan en cajones de sastre.
9. **¿Requiere ADR?** **NO** — es planificación, no arquitectura.
10. **¿Requiere aprobación de Luisma?** **YES** — modifica el roadmap aprobado.

---

### AUD-032 — Sin abstracción de locomoción, el aplazamiento marítimo forzará una reescritura del movimiento

1. **ID:** AUD-032
2. **Severidad:** HIGH — bloquea VS1
3. **Área afectada:** Mundo / Movimiento / Marítimo
4. **Problema:** El Vertical Slice terrestre es correcto en aplazar la navegación completa a un Marine Technical Slice posterior. El riesgo es que VS1 construya movimiento, cámara, colisión y transiciones asumiendo **caminar en top-down**, y que después haya que encajar navegación de vela, nado, buceo y cuatro niveles de profundidad.
5. **Por qué importa:** El canon marítimo no es un modo separado: *"el océano se atraviesa, no se selecciona de un menú"* y *"bucear extiende la exploración en lugar de lanzar un minijuego aparte"*. Es decir, es explícitamente el **mismo** espacio de exploración con otra locomoción. Y la profundidad (SHALLOW / MID / DEEP / ABYSSAL) introduce un eje vertical en un juego top-down 2D, que es el cambio conceptual más profundo del conjunto: afecta a colisión, orden de dibujado, qué entidades son visibles/interactuables y qué significa "estar en" un punto del mapa.

   Retrofitear eso sobre un `CharacterBody2D` que asume caminar no es una extensión: es una reescritura del movimiento y de todo lo que dependa de él.
6. **Arquitectura actual:** Aplazamiento correcto, sin previsión de contrato.
7. **Recomendación:**
   - VS1 define un `LocomotionMode` y un `TraversalContext` como abstracción, **implementando únicamente `walk`**. Los otros modos existen como concepto en el contrato, no como código.
   - Los obstáculos y transiciones se expresan por capacidad requerida (AUD-022), no por "es tierra o es agua".
   - Reservar un campo de **capa/profundidad** en la posición del jugador desde VS1, aunque su único valor sea `surface`. Añadirlo después es tocar el save (AUD-006) y todo el sistema de colisión.
   - No implementar nada marítimo en VS1 — solo no cerrarle la puerta.
8. **Impacto:** Coste casi nulo ahora; reescritura del movimiento si se ignora.
9. **¿Requiere ADR?** **NO** — se especifica en VS1.
10. **¿Requiere aprobación de Luisma?** **NO**.

---

### AUD-033 — El servicio de RNG con semilla está ausente de la arquitectura y del modelo de guardado

1. **ID:** AUD-033
2. **Severidad:** HIGH — bloquea VS2
3. **Área afectada:** Determinismo / Testing / Persistencia
4. **Problema:** `02` establece el principio *"Use controlled randomness where reproducible testing matters"*, pero no existe ningún servicio de RNG en la lista de autoloads ni en la de subestados de GameState, ni se menciona la semilla en el modelo de guardado.
5. **Por qué importa:** El azar aparece en casi todos los sistemas del juego: encuentros, críticos, precisión, orden de turno en empates, clima, eventos emergentes, generación de estadísticas individuales. Si cada uno usa `randi()` global, entonces: ningún bug de combate es reproducible; los tests de combate no pueden aseverar resultados; la reproducción de un save es imposible; y la línea de tiempo de combate de AUD-012 pierde su propiedad más valiosa, que es ser reproducible.

   Es también un requisito para varios controles que recomiendo: tests deterministas de batalla, validación de encuentros, transiciones de clima testeables.
6. **Arquitectura actual:** Un principio sin implementación declarada.
7. **Recomendación:**
   - Un servicio de RNG con **flujos independientes con nombre** (`battle`, `encounters`, `weather`, `loot`, `cosmetic`), cada uno con su propia semilla y su propio contador. Flujos separados evitan que consumir aleatoriedad en un sistema desplace los resultados de otro — la causa clásica de tests que se rompen "solos".
   - La semilla maestra y los contadores de los flujos que afectan a consecuencias durables **se persisten**, para que cargar una partida no reabra una tirada ya realizada.
   - El flujo `cosmetic` (partículas, variación visual) es explícitamente no determinista y no persistido: no debe contaminar el estado de juego.
   - Cada `BattleActionResult` registra la semilla usada (AUD-012), lo que da reproducción exacta de cualquier combate desde su log.
   - Prohibición: ningún sistema de juego llama a `randi()`/`randf()` globales. Verificable con grep en CI.
8. **Impacto:** Habilita el testing serio de combate y encuentros, que es donde estará la mayor parte del riesgo de regresión.
9. **¿Requiere ADR?** **NO** — se recoge en ADR-005 (persistencia) y en `ARCHITECTURE.md`.
10. **¿Requiere aprobación de Luisma?** **NO**.

---

### AUD-034 — Escritura atómica y `user://` sin tratamiento específico de Windows

1. **ID:** AUD-034
2. **Severidad:** HIGH — bloquea VS0 (dentro del Save Core de AUD-006)
3. **Área afectada:** Guardado / Plataforma Windows
4. **Problema:** El modelo de guardado especifica "temp write, validation/checksum, atomic rename, backup and recovery". El patrón es correcto en POSIX. En Windows, **renombrar sobre un archivo existente no es la misma operación**: la semántica de reemplazo difiere, y la API de `DirAccess` de Godot puede fallar o comportarse de forma distinta según versión al renombrar sobre un destino existente. Además, el bloqueo de archivos de Windows y los antivirus pueden mantener handles abiertos justo después de escribir.
5. **Por qué importa:** El canon fija Windows como plataforma inicial y offline-first. Una implementación de escritura atómica escrita con supuestos POSIX **fallará silenciosamente o intermitentemente en la plataforma objetivo**, y lo hará precisamente en el sistema donde el fallo cuesta la partida del jugador. `04` establece que el progreso del jugador tiene alta prioridad.

   Es además un fallo difícil de detectar en test: solo se manifiesta con archivo destino existente, o bajo bloqueo transitorio.
6. **Arquitectura actual:** Patrón correcto, plataforma no considerada.
7. **Recomendación:**
   - Especificar la secuencia concreta y verificarla en la plataforma real: escribir a temporal → `flush` y cerrar → validar checksum releyendo → rotar el actual a backup → mover el temporal a su sitio → verificar → limpiar. Nunca destruir el backup antes de verificar el nuevo archivo.
   - Tratar el fallo de renombrado como caso esperado, con reintento acotado, no como excepción imposible.
   - Documentar la ruta real de `user://` en Windows para soporte y para que tú puedas encontrar tus saves.
   - **Test de recuperación obligatorio desde VS0**: simular interrupción en cada paso y verificar que siempre queda una partida cargable. Es el test que justifica todo el mecanismo.
   - Cuidado adicional de plataforma: Windows tiene sistema de archivos insensible a mayúsculas; las rutas de recursos de Godot **sí** son sensibles en export. Un error de capitalización funciona en tu máquina y falla en la build (ver MEDIUM AUD-053 y anexo).
8. **Impacto:** Protege directamente el progreso del jugador, que el workflow declara prioridad alta.
9. **¿Requiere ADR?** **NO** — detalle de implementación dentro de ADR-005.
10. **¿Requiere aprobación de Luisma?** **NO**.

---

### AUD-035 — Sin disciplina de fixtures dorados ni tests de migración

1. **ID:** AUD-035
2. **Severidad:** HIGH — bloquea VS0 (dentro del Save Core)
3. **Área afectada:** Guardado / Migraciones / CI
4. **Problema:** El modelo de guardado menciona migraciones pero no define cómo se verifican. No hay concepto de partida de referencia congelada, ni obligación de test de migración, ni gate que impida cambiar un esquema persistido sin migración.
5. **Por qué importa:** Las migraciones son el único mecanismo que protege partidas existentes, y son también el código menos ejercitado del proyecto: se escriben una vez y se ejecutan en máquinas de jugadores, meses después, sobre datos que el desarrollador ya no tiene. Sin fixtures congelados, una migración se "verifica" ejecutándola sobre un save recién creado por la versión actual — que es exactamente el caso que **no** hay que probar.

   Éste es el control concreto que responde a tu riesgo listado *"save breaking changes"*. Es mecánico y barato, pero solo funciona si se instaura desde el primer save que exista.
6. **Arquitectura actual:** Migraciones mencionadas, sin disciplina.
7. **Recomendación:**
   - **Fixtures dorados**: cada vez que cambia `save_version`, se congela en el repositorio un save real de la versión anterior. Nunca se regeneran ni se editan: son evidencia histórica.
   - **Gate de CI**: cargar **todos** los fixtures históricos, migrarlos hasta la versión actual, y aseverar invariantes semánticas (el equipo sobrevive, el progreso del Codex sobrevive, los Tikawi vinculados siguen existiendo, la posición es válida, las quests siguen siendo coherentes). No basta con "no ha petado".
   - **Gate estructural**: un hash del esquema persistido. Si cambia y `save_version` no sube y no hay migración registrada, CI falla. Esto convierte la regla "no cambies persistencia sin migración" en algo imposible de olvidar — incluido por un agente.
   - Tests de degradación: save de versión **futura** cargado por una build antigua debe rechazarse limpiamente, no corromper.
   - Empezar con el fixture v1 en VS0, cuando el save solo contiene el envoltorio. Un fixture trivial que existe vale más que uno perfecto que llega en VS9.
8. **Impacto:** Es el control que hace que la persistencia deje de ser una fuente de miedo.
9. **¿Requiere ADR?** **NO** — se recoge en ADR-005.
10. **¿Requiere aprobación de Luisma?** **NO**.

---

### AUD-036 — El esquema de contenido solo se estresa en VS10, con las 150 entradas de golpe

1. **ID:** AUD-036
2. **Severidad:** HIGH — bloquea VS2
3. **Área afectada:** Datos / Roadmap / Escalabilidad
4. **Problema:** El roadmap concentra la producción de contenido en VS10 Content Assembly, y tanto `03` como `04` advierten correctamente de no crear los 150 Tikawi por adelantado. El efecto colateral es que el esquema de datos solo se somete a la variedad real del canon al final: hasta VS10, el contenido de prueba serán tres iniciales y unos pocos salvajes.
5. **Por qué importa:** Tres iniciales no ejercitan el esquema. No hay planta, ni hongo, ni insecto, ni criatura marina con profundidad, ni Especial con condición de aparición, ni Legendario sin evolución, ni evolución por objeto/hábitat/hora/vínculo/desafío/investigación, ni doble tipo problemático, ni rareza alta. Todos esos son los casos que **rompen** esquemas.

   El riesgo no es teórico: en VS10 se descubriría que el esquema no puede expresar, por ejemplo, la condición de aparición de un Especial, o la evolución por investigación — y a esas alturas hay contenido, saves y presentación construidos encima.

   Hay una tensión aparente con la advertencia del canon de no crear las 150 por adelantado, pero no es contradicción: una cosa es **volumen** y otra **variedad**.
6. **Arquitectura actual:** Advertencia correcta contra el volumen prematuro, sin contrapeso de variedad temprana.
7. **Recomendación:**
   - Mantener contenido de volumen bajo pero **estructuralmente completo** desde VS2: los 9 iniciales (que el canon ya exige), más un conjunto pequeño y deliberado que cubra al menos una especie de cada pilar (ave, reptil, mamífero, marino, planta/hongo/insecto), un Especial con condición, un Legendario, y al menos un ejemplo de **cada uno de los 7 disparadores de evolución**.
   - Marcar ese contenido como **contenido de validación de esquema**, con datos provisionales aprobados por ti, sustituible más tarde por contenido final sin cambiar la forma.
   - Objetivo explícito: que en VS2 el esquema ya haya soportado toda la variedad del canon, aunque no su volumen.
   - Complementar con un **reporte de completitud de contenido** en CI (cuántas de las 150 tienen datos, manifiesto de assets, textos ES/EN, movimientos, evolución), que es tu panel de producción de cara a VS10.
8. **Impacto:** Convierte VS10 en un problema de cantidad —planificable— en lugar de un problema de descubrimiento.
9. **¿Requiere ADR?** **NO**.
10. **¿Requiere aprobación de Luisma?** **NO** para el mecanismo; sí para los datos provisionales que se usen.

---

### AUD-037 — Convenciones de GDScript, tipado e idioma de identificadores sin fijar

1. **ID:** AUD-037
2. **Severidad:** HIGH — bloquea VS0
3. **Área afectada:** Convenciones de código / Mantenibilidad
4. **Problema:** No existe decisión sobre: tipado estático obligatorio u opcional, idioma de identificadores y comentarios, uso de `class_name`, convención de nombres de señales, organización de archivos, ni política de documentación en código.
5. **Por qué importa:** Dos motivos concretos de este proyecto.

   **Tipado**: GDScript permite tipado opcional, y sin tipos no hay análisis estático significativo. En una base de código data-driven, con cientos de ids circulando como cadenas y contratos entre capas, el tipado estático es la única defensa barata contra errores que de otro modo solo aparecen en runtime, en la rama concreta que nadie probó. Además, mucho del valor de los contratos que recomiendo (AUD-012, AUD-018, AUD-019) depende de que los tipos de retorno sean explícitos y verificables.

   **Idioma**: es una decisión pequeña que se vuelve cara. El canon es bilingüe por naturaleza — nombres de Tikawi, regiones, estados de Bond y categorías de movimiento son en español y **son canon**; la documentación maestra está en inglés. Si no se decide, aparecerá código mezclado (`func obtener_vinculo() -> BondState`), y homogeneizarlo después es un rename global sobre todo el repositorio.

   Mi recomendación: **identificadores y comentarios en inglés; términos de canon en español conservados literalmente como ids y valores** (`species_id = "mariguin"`, `BondState.RESONANCIA`, `region_id = "tierras_altas"`). Es la convención que respeta el canon donde importa —los nombres propios y los estados canónicos no se traducen— sin fragmentar el código.
6. **Arquitectura actual:** Sin definir.
7. **Recomendación:**
   - `docs/CONVENTIONS.md` con: **tipado estático obligatorio** en todo el código de producción (y gate en CI); idioma según lo anterior; `class_name` solo para tipos reutilizables, no para todo; señales en pretérito (coherente con AUD-017); nombres de archivo y de carpeta; límite de tamaño de archivo (el proyecto ya fija 500 líneas); y política de comentarios: se comenta el *por qué*, no el *qué*.
   - Decidir también el idioma de la **documentación** del repositorio, que hoy es incoherente (maestros en inglés, esta auditoría en español).
8. **Impacto:** Barato hoy; rename global mañana.
9. **¿Requiere ADR?** **NO** — es convención; va en `ARCHITECTURE.md`/`CONVENTIONS.md`.
10. **¿Requiere aprobación de Luisma?** **YES** — el idioma del código y de la documentación es una preferencia tuya y afecta a cómo vas a leer el proyecto durante años.

---

### AUD-038 — El modelo de foco para mando debe ser regla desde el primer menú

1. **ID:** AUD-038
2. **Severidad:** HIGH — bloquea VS1
3. **Área afectada:** Input / UI
4. **Problema:** El Vertical Slice exige teclado y mando, y VS0 incluye "input abstraction baseline". Pero no hay definición de: mapa de acciones, navegación por foco en UI, rebinding y su persistencia, cambio de dispositivo en caliente, ni glifos de botón por dispositivo.
5. **Por qué importa:** La navegación por foco es el caso claro de coste asimétrico. En Godot, una UI usable con mando requiere vecinos de foco correctos, foco inicial declarado, atrapado de foco en modales y orden de tabulación coherente — **en cada pantalla**. Si se establece como regla desde la primera pantalla, es gratis. Si se retrofitea en VS11 sobre el Codex, el equipo, la mochila, el mapa, las tiendas, el diálogo, la evolución y el combate, es una revisión completa de toda la UI. Y el canon fija un menú principal con nueve entradas, cada una con su propia pantalla.

   Los glifos tienen además impacto de arte: prompts de teclado, Xbox y PlayStation son assets distintos, y eso enlaza con el contrato de assets (AUD-016).

   Detalle de persistencia relevante: los rebindings y las opciones **no son progreso de partida**. Deben vivir en un archivo de configuración separado del save, o cambiar de opciones tocaría la partida.
6. **Arquitectura actual:** "Input abstraction baseline" sin contenido.
7. **Recomendación:**
   - Definir en VS0/VS1 el mapa de acciones completo (incluyendo las acciones que aún no existen: Compás, Codex, compañero, acción de campo), con nombres semánticos, nunca teclas concretas en el código.
   - Regla obligatoria de UI, verificable en revisión: **toda escena de UI declara foco inicial, vecinos de foco y atrapado de foco**; ninguna pantalla es solo navegable con ratón.
   - Detección de dispositivo activo y conmutación de glifos como servicio, con los glifos en el contrato de assets.
   - Configuración y rebinding en archivo aparte del save, versionado independientemente.
   - Un test de humo de navegación por mando por pantalla, aunque sea mínimo.
8. **Impacto:** Coste marginal desde el inicio; auditoría completa de UI si se pospone.
9. **¿Requiere ADR?** **NO**.
10. **¿Requiere aprobación de Luisma?** **NO**.

---
## 5. Hallazgos MEDIUM

> Formato compacto. Los diez campos se mantienen; la argumentación es más breve porque el coste de corrección tardía es contenido.

### AUD-039 — Set de autoloads sin tope duro, con un candidato redundante

1. **ID:** AUD-039 · 2. **MEDIUM** (VS0) · 3. **Autoloads / Acoplamiento**
4. **Problema:** La lista aprobada (EventBus, GameState, SaveManager, SceneManager, AudioManager, LocalizationManager, quizá TimeManager) no tiene tope numérico ni disparador de ADR para añadir uno, y el condicional de TimeManager deja una decisión abierta que el canon ya obliga de facto (AUD-025).
5. **Por qué importa:** "Avoid singleton explosion" es una intención, no un límite. La explosión de singletons nunca ocurre por una decisión: ocurre por siete decisiones razonables. Además, el recuento de autoloads es un mal indicador de acoplamiento — con EventBus y GameState globales, todo alcanza todo igualmente; el control real es el lint de capas (AUD-009).
6. **Arquitectura actual:** Lista orientativa con un condicional.
7. **Recomendación:** Tope duro de **8 autoloads**, con ADR obligatorio para superarlo. Confirmar `TimeManager` y cerrar el condicional. Evaluar retirar `LocalizationManager` (Godot ya trae `TranslationServer`; ver AUD-028). Patrón preferido para todo lo demás: sistemas como objetos normales con propietario explícito, no autoloads. Cada autoload documenta su responsabilidad en una frase en `ARCHITECTURE.md`.
8. **Impacto:** Bajo; preventivo.
9. **ADR:** NO (se recoge en ADR-003) · 10. **Luisma:** NO

---

### AUD-040 — Commands / Events / Queries sin modelo de implementación

1. **ID:** AUD-040 · 2. **MEDIUM** (VS1) · 3. **Arquitectura / Riesgo de overengineering**
4. **Problema:** El principio *"Commands request change. Events report change. Queries ask without changing anything"* se repite en los tres documentos sin decir cómo se materializa: ¿objetos de comando, un despachador, o simplemente llamadas a fachadas de sistema?
5. **Por qué importa:** El vocabulario sugiere CQRS. Implementado literalmente —objetos de comando, bus de comandos, manejadores— añadiría una cantidad considerable de infraestructura para un RPG de un solo jugador con un solo escritor, y encaja de lleno en el riesgo de **overengineering** que pediste evaluar. La ambigüedad favorece la interpretación más pesada, porque parece más "correcta".
6. **Arquitectura actual:** Principio sin modelo.
7. **Recomendación:** Fijar explícitamente **la interpretación ligera**: un *Command* es una llamada a un método público de la fachada del sistema propietario; un *Event* es una señal del EventBus en pretérito (AUD-017); una *Query* es un método de solo lectura, sin efectos. Sin bus de comandos, sin objetos de comando, sin manejadores. El principio se conserva íntegro y la infraestructura es cero. Reevaluar solo si aparece una necesidad real (deshacer, replay de entrada, red — ninguna prevista).
8. **Impacto:** Evita infraestructura innecesaria permanente.
9. **ADR:** YES — ADR-003 (contratos públicos) · 10. **Luisma:** NO

---

### AUD-041 — Los 8 estados de terreno no tienen contrato mundo → combate

1. **ID:** AUD-041 · 2. **MEDIUM** (VS3) · 3. **Combate / Mundo / Entorno**
4. **Problema:** El canon define ocho estados de terreno (Seco, Húmedo, Volcánico, Vegetal, Rocoso, Acuático, Profundo, Ventoso) sin decir quién los determina ni cómo llegan al combate.
5. **Por qué importa:** El terreno es el punto de encuentro entre región, clima, marea y profundidad (AUD-025) y las reglas de combate. Sin contrato, cada combate lo deducirá por su cuenta y habrá incoherencias visibles (llueve en el mundo, terreno Seco en combate). Además el canon da a Volcápago identidad de "control de terreno", así que el combate debe poder **modificarlo** en marcha, no solo leerlo.
6. **Arquitectura actual:** Enumeración canónica sin flujo.
7. **Recomendación:** El terreno inicial de combate se **deriva** de `EnvironmentContext` + región + profundidad mediante función pura testeable; el combate lo recibe como estado inicial y lo posee a partir de ahí. Los cambios de terreno en combate son un `kind` de la línea de tiempo (AUD-012). Validar que las ocho combinaciones son alcanzables.
8. **Impacto:** Contenido; evita incoherencias visibles.
9. **ADR:** NO · 10. **Luisma:** NO

---

### AUD-042 — Modelo de estados alterados ausente

1. **ID:** AUD-042 · 2. **MEDIUM** (VS3) · 3. **Combate**
4. **Problema:** El canon implica estados alterados (categorías Control y Soporte, objetos "para estados alterados", "Agotada/Agotado") pero no hay modelo: duración, acumulación, inmunidades, interacción con tipos, persistencia fuera del combate.
5. **Por qué importa:** Los estados son la fuente habitual de reglas emergentes y de bugs de combate; retrofitear acumulación o prioridad después obliga a revisar todos los movimientos ya autorados. Y hay una pregunta de persistencia: ¿un estado sobrevive al final del combate? Eso decide si el estado entra en el save (AUD-006).
6. **Arquitectura actual:** Implícito.
7. **Recomendación:** Modelo declarativo de estados en datos (duración, apilamiento, exclusión mutua, momento de resolución en el turno, si persiste fuera del combate), integrado en la línea de tiempo como `status_applied`. Decidir explícitamente qué estados persisten; solo esos entran en el save.
8. **Impacto:** Contenido; afecta a todo el autorado de movimientos.
9. **ADR:** NO · 10. **Luisma:** NO (arquitectura); sí para el catálogo de estados

---

### AUD-043 — El contrato 1v1 debe nacer con slots para soportar 2v2

1. **ID:** AUD-043 · 2. **MEDIUM** (VS3) · 3. **Combate**
4. **Problema:** El Vertical Slice especifica combate 1v1 y el canon introduce 2v2 en Isla Lobos. Si el contrato de combate se escribe con "actor" y "objetivo" singulares, el paso a 2v2 cambia la firma de la selección de objetivos, del resultado y de la presentación.
5. **Por qué importa:** Es el mismo patrón que AUD-032: prever sin implementar cuesta casi nada; retrofitear cuesta el módulo.
6. **Arquitectura actual:** 1v1 en el slice, 2v2 en canon, contrato sin definir.
7. **Recomendación:** Modelar posiciones como **slots** desde VS3 (`actor_slot`, `target_slots: Array`), con el campo de batalla como conjunto de slots por bando, implementando solo la configuración 1v1. La línea de tiempo de AUD-012 ya lo soporta de forma natural. Los movimientos declaran su patrón de objetivo en datos (uno, todos los enemigos, aliado, propio, campo) aunque en VS3 solo se use el primero.
8. **Impacto:** Marginal ahora; módulo entero después.
9. **ADR:** NO · 10. **Luisma:** NO

---

### AUD-044 — El progreso de investigación debe ser por condición, no por contador

1. **ID:** AUD-044 · 2. **MEDIUM** (VS5) · 3. **Codex / Research**
4. **Problema:** Los cinco estadios (Avistamiento, Observación, Interacción, Investigación, Vínculo) no tienen mecanismo definido. `03` advierte contra "contadores repetitivos y grindy" sin aprobación explícita.
5. **Por qué importa:** El canon es inusualmente claro aquí —*"El Codex no premia capturar más. Premia comprender más."*— y esa es una afirmación **arquitectónica**: el progreso debe derivar de condiciones cualitativamente distintas, no de repetición. La implementación por defecto (contar avistamientos) contradice el pilar central del juego, y es la que saldrá sola si no se especifica.
6. **Arquitectura actual:** Estadios canónicos sin mecanismo.
7. **Recomendación:** Cada estadio avanza al satisfacerse un conjunto de **condiciones distintas** del vocabulario cerrado compartido (AUD-020, AUD-027): verla en cierto hábitat, de noche, usando cierto movimiento, alimentándose, interactuando, en determinado clima. Nada de "vista N veces". `ResearchSystem` escucha eventos y decide; `CodexSystem` solo almacena conocimiento — separación ya correcta en los documentos. Diseñar el estado de la entrada para admitir **hallazgos futuros** ("NEW ADAPTATION DISCOVERED") sin migración: conjunto abierto de hechos descubiertos, no lista fija de campos.
8. **Impacto:** Contenido; define la sensación del pilar de Descubrimiento.
9. **ADR:** NO · 10. **Luisma:** YES — las condiciones por estadio son diseño

---

### AUD-045 — Capacidad de Reserva indefinida y crecimiento de save no acotado

1. **ID:** AUD-045 · 2. **MEDIUM** (VS2) · 3. **Equipo / Reserva / Persistencia**
4. **Problema:** El canon fija equipo máximo 6 y `ReserveState` como subestado, pero **no fija capacidad de reserva**. Tampoco define si un Tikawi vinculado puede liberarse o marcharse (el canon dice que nunca se venden y que el vínculo es voluntario, pero no habla de salida).
5. **Por qué importa:** Cada Bond crea una `TikawiInstance` persistente. Sin cota, la reserva crece sin límite: crece el save, crece el tiempo de carga, y la UI de reserva deja de ser navegable — todo ello descubierto tarde, con partidas reales. Y la pregunta de la liberación es canon: si el vínculo es una decisión mutua, que un Tikawi pueda dejar de caminar contigo es coherente, pero es diseño tuyo, no una deducción mía.
6. **Arquitectura actual:** Subestado declarado, reglas ausentes.
7. **Recomendación:** Fijar capacidad de reserva (o declarar explícitamente que es ilimitada y asumir el coste con paginación y UI preparada). Definir la semántica de salida del vínculo. Persistir instancias de forma compacta (ids + datos divergentes, nunca copiar `SpeciesData` en cada instancia). Añadir un test de rendimiento con una reserva grande desde VS9.
8. **Impacto:** Contenido si se decide pronto.
9. **ADR:** NO · 10. **Luisma:** YES — capacidad y semántica de salida son diseño

---

### AUD-046 — Modelo de cambios persistentes del mundo sin definir

1. **ID:** AUD-046 · 2. **MEDIUM** (VS1) · 3. **Mundo / Persistencia**
4. **Problema:** "World-change IDs" está enunciado pero sin modelo: ¿banderas booleanas, registros tipados, o estado por entidad? ¿Qué se persiste de un objeto recogido, un obstáculo despejado, un NPC movido, un campamento de Blackwood desmantelado?
5. **Por qué importa:** Es el subestado que más tiende a crecer sin control y el que peor envejece: un mar de banderas booleanas sin significado legible es imposible de migrar y de depurar tres milestones después. Y el canon pide cambios durables del mundo (obstáculos despejados, mapa completado, anomalías registradas).
6. **Arquitectura actual:** Nombre sin estructura.
7. **Recomendación:** Registros **tipados y con espacio de nombres** (`region_id` + `change_id` + tipo), no banderas sueltas; catálogo declarado en datos y validado (ningún cambio referencia ids inexistentes; ningún id duplicado). Regla: solo se persiste lo que altera lo que el jugador puede volver a ver o hacer. Lo recolocable por reglas se **recalcula**, no se guarda.
8. **Impacto:** Contenido; evita deuda de persistencia difusa.
9. **ADR:** NO · 10. **Luisma:** NO

---

### AUD-047 — Tabla de tipos 13×13 inexistente y sin validación

1. **ID:** AUD-047 · 2. **MEDIUM** (VS3) · 3. **Datos / Balance / Canon**
4. **Problema:** Los 13 tipos son canon bloqueado, pero la matriz de 169 relaciones no existe. El GDD solo fija el triángulo inicial (Agua > Fuego > Planta > Agua).
5. **Por qué importa:** Es un dato de contenido con forma de sistema: no se puede implementar combate sin él, no se puede balancear sin verlo completo, y tiene propiedades globales que solo se ven mirando la matriz entera (un tipo sin debilidades es indominable; un tipo sin resistencias es inútil; dobles tipos pueden producir multiplicadores extremos). Con 13 tipos y sin "Normal", no hay tipo neutro de referencia, así que la matriz define enteramente la identidad de cada tipo.
6. **Arquitectura actual:** Tipos canónicos, relaciones inexistentes.
7. **Recomendación:** Matriz en datos source, generada a código (AUD-029). Validadores: dimensión exacta 13×13; ningún tipo sin al menos una debilidad y una resistencia; multiplicador de doble tipo dentro de un rango acordado; simetrías intencionadas declaradas. Herramienta de visualización de la matriz para tu balance. Es contenido tuyo; yo aporto validación y forma.
8. **Impacto:** Contenido; bloquea VS3 en la práctica.
9. **ADR:** NO · 10. **Luisma:** YES — es diseño de juego

---

### AUD-048 — La rareza no debe alimentar la generación de estadísticas

1. **ID:** AUD-048 · 2. **MEDIUM** (VS2) · 3. **Datos / Canon**
4. **Problema:** El canon declara explícitamente *"Rare does not automatically mean stronger"*, pero nada en la arquitectura impide que la rareza acabe siendo una entrada del cálculo de estadísticas o del nivel de encuentro.
5. **Por qué importa:** Es la conexión que se establece sola, porque es el supuesto por defecto del género. Si ocurre, contradice un principio declarado y —peor— desactiva la intención de diseño: la rareza debe premiar el descubrimiento, no el poder.
6. **Arquitectura actual:** Principio declarado, sin frontera.
7. **Recomendación:** La rareza pertenece exclusivamente al dominio de **encuentro y descubrimiento** (AUD-026) y al Codex. Ningún cálculo de estadísticas, crecimiento o nivel la recibe como parámetro: no debe siquiera estar disponible en esa capa. Test de canon: el calculador de estadísticas no depende de rareza.
8. **Impacto:** Bajo; preventivo y protege canon.
9. **ADR:** NO · 10. **Luisma:** NO

---

### AUD-049 — Buses de audio, ducking y transiciones musicales sin arquitectura

1. **ID:** AUD-049 · 2. **MEDIUM** (VS3/VS11) · 3. **Audio**
4. **Problema:** Los principios de audio son correctos y suficientes en lo que dicen (la verdad de juego no depende del audio; ids de audio; toda información crítica tiene respaldo no sonoro). Falta la arquitectura: distribución de buses, mezcla, atenuación durante combate y diálogo, audio posicional 2D, y modelo de transición musical (cambio de región, entrada/salida de combate, día/noche, clima).
5. **Por qué importa:** La transición musical es lo que hace que un mundo se sienta continuo o troceado, y está directamente ligada a la decisión de carga de regiones (AUD-024): con transiciones discretas, la continuidad musical entre regiones es lo que oculta el corte. Retrofitear una arquitectura de mezcla es tedioso pero acotado, por eso es MEDIUM y no HIGH.
6. **Arquitectura actual:** Principios sin estructura.
7. **Recomendación:** Buses fijos (Master / Music / SFX / Ambience / UI) con volúmenes persistidos en configuración, no en el save (AUD-038). Servicio de música con capas y fundidos cruzados, dirigido por eventos, no por lógica de escena. Confirmar explícitamente **sin middleware externo** (coherente con offline-first y con la política de dependencias). Regla ya canónica a instrumentar: ninguna transición de juego espera a que termine un sonido.
8. **Impacto:** Contenido.
9. **ADR:** NO · 10. **Luisma:** NO

---

### AUD-050 — Tensión real entre animación obligatoria y accesibilidad / ritmo

1. **ID:** AUD-050 · 2. **MEDIUM** (VS11) · 3. **Accesibilidad / Canon**
4. **Problema:** El canon convierte la actuación visible en regla protegida. Las expectativas de accesibilidad y de calidad de vida empujan en dirección contraria: reducción de movimiento, saltar animaciones, acelerar el combate en la enésima batalla.
5. **Por qué importa:** No es un conflicto inventado: **aparecerá con seguridad en VS11**, bajo presión de usabilidad, y en ese momento alguien propondrá una opción de "desactivar animaciones" que violaría una regla protegida. Es mejor decidirlo ahora, con calma, que en pulido y con prisa. Y hay un componente de accesibilidad genuino: sacudidas de pantalla y destellos pueden ser un problema real para algunas personas.
6. **Arquitectura actual:** Regla de canon sin política de accesibilidad.
7. **Recomendación:** Con la línea de tiempo de AUD-012, la salida limpia existe y es arquitectónica: la **escala de velocidad** de la actuación es un parámetro de presentación, y los **beats siguen ocurriendo** aunque duren menos. Propongo la política: *se puede acelerar, no se puede eliminar* — la actuación siempre ocurre, y el jugador elige a qué ritmo. Separadamente, opciones de accesibilidad para intensidad de sacudida y de destello, que no eliminan la actuación sino su intensidad. Es coherente con el canon y con el cuidado del jugador.
8. **Impacto:** Bajo si se decide ahora; conflicto de canon si se decide en VS11.
9. **ADR:** NO · 10. **Luisma:** YES — es política de canon, tuya

---

### AUD-051 — La evidencia y las capturas exigidas a Codex no tienen método definido

1. **ID:** AUD-051 · 2. **MEDIUM** (VS0) · 3. **QA / Proceso**
4. **Problema:** El informe de implementación exige "Screenshots/evidence" y "Runtime verification", y `03` prohíbe fabricar un PASS. Pero no hay método definido para que un agente produzca evidencia visual de forma automática, y Godot headless no captura gameplay de forma natural.
5. **Por qué importa:** Un requisito de proceso sin mecanismo se cumple con prosa. En la práctica, "verificación en runtime" acabaría siendo una afirmación de Codex, no un artefacto — exactamente lo que la regla pretende evitar. Y la regla es importante: es el principal control contra el reporte optimista.
6. **Arquitectura actual:** Requisito sin herramienta.
7. **Recomendación:** Definir en VS0 un mecanismo concreto: escenas de verificación scriptadas que arrancan, ejecutan una secuencia determinista y **guardan capturas a disco** en rutas fijas, ejecutables en CI. Complementar con un test de humo que cargue toda escena del proyecto y falle ante errores de script (el gate más barato y de mayor rendimiento en Godot). Definir qué evidencia es obligatoria por tipo de tarea. Para lo que realmente requiere ojo humano —feel de movimiento, calidad de una actuación— la evidencia es un vídeo corto y **la revisión es tuya**, no de un agente: el canon ya lo establece con la puerta creativa humana.
8. **Impacto:** Convierte una regla de honestidad en un artefacto verificable.
9. **ADR:** NO · 10. **Luisma:** NO

---

### AUD-052 — Task packets de 19 campos para trabajo de Nivel 0

1. **ID:** AUD-052 · 2. **MEDIUM** (proceso) · 3. **Workflow / Overhead**
4. **Problema:** El formato de handoff exige 19 campos y el informe de vuelta otros 17, para toda tarea. El sistema de niveles de cambio (0–3) reconoce que existe trabajo trivial, pero el formato no se adapta a él.
5. **Por qué importa:** Es el riesgo de **overengineering aplicado al proceso**, no al código. Un proceso que cuesta más que la tarea se erosiona: primero se rellenan campos con "N/A", luego se omiten, y finalmente la disciplina se pierde también donde sí importaba. Prefiero un proceso proporcionado que se cumpla siempre a uno exhaustivo que se cumpla a ratos.
6. **Arquitectura actual:** Formato único para todo.
7. **Recomendación:** Dos formatos. **Completo** (los 19 campos) obligatorio para Nivel 2 y 3, y para cualquier tarea que toque contratos públicos, persistencia, canon o varios módulos. **Ligero** (objetivo, rutas permitidas, criterios de aceptación, condiciones de parada) para Nivel 0 y 1. Los campos que jamás se omiten, sea cual sea el formato: **rutas permitidas, impacto en persistencia, condiciones de parada**. Y una regla de escalado automática: si durante la ejecución una tarea ligera toca persistencia o contratos, se detiene y se reemite como completa.
8. **Impacto:** Sostiene la disciplina del proceso a largo plazo.
9. **ADR:** NO · 10. **Luisma:** NO

---

### AUD-053 — Política de fallo ante datos inválidos en build de release

1. **ID:** AUD-053 · 2. **MEDIUM** (VS0) · 3. **Runtime / Robustez**
4. **Problema:** El canon establece *"Invalid content must fail before the game runs"*, lo cual es correcto para desarrollo y CI. No dice qué debe ocurrir si, pese a todo, una build de release encuentra datos inválidos o un id desconocido en un save.
5. **Por qué importa:** "Fallar pronto" y "no arruinar la partida del jugador" son objetivos legítimos y opuestos según el contexto. Sin política, cada sistema improvisará: unos lanzarán aserción, otros devolverán un valor por defecto silencioso, y ambos comportamientos son inadecuados en el contexto contrario. El caso más probable y más delicado es un save con un id que ya no existe (contenido retirado, migración incompleta).
6. **Arquitectura actual:** Regla de desarrollo sin contrapartida de runtime.
7. **Recomendación:** Política explícita en dos modos. **Desarrollo/CI**: fallo ruidoso e inmediato ante cualquier dato inválido. **Release**: degradación controlada, registrada y visible para soporte, nunca corrupción del save y nunca fallo silencioso; jamás sobrescribir un save que no se pudo interpretar por completo. Complemento relacionado, por ser Windows-first: chequeo en CI de **consistencia de mayúsculas en rutas de recursos**, porque el sistema de archivos de Windows perdona lo que el export no perdona (AUD-034).
8. **Impacto:** Contenido; protege partidas reales.
9. **ADR:** NO · 10. **Luisma:** NO

---

## 6. Hallazgos LOW

### AUD-054 — El checksum es detección de corrupción, no anti-manipulación

1. **ID:** AUD-054 · 2. **LOW** (VS0) · 3. **Guardado**
4. **Problema:** El modelo de guardado incluye checksum sin declarar su propósito.
5. **Por qué importa:** Si no se dice, alguien lo tratará como protección anti-trampas y construirá encima — en un juego de un solo jugador, offline, sin componente competitivo. Esfuerzo inútil, y potencialmente hostil para un jugador que solo quiere recuperar su partida.
6. **Arquitectura actual:** Mecanismo sin propósito declarado.
7. **Recomendación:** Declarar: el checksum detecta **corrupción**, no manipulación. No se implementa anti-tamper. Un save modificado que valide estructuralmente se carga.
8. **Impacto:** Nulo; evita trabajo equivocado.
9. **ADR:** NO · 10. **Luisma:** NO

---

### AUD-055 — Punta Pitt aparece como región y como destino marítimo

1. **ID:** AUD-055 · 2. **LOW** (VS1) · 3. **Canon / Mundo**
4. **Problema:** Punta Pitt figura como región terrestre nº 9 de San Cristóbal y también en la lista de lo que soporta On The Hook, junto a León Dormido, Isla Lobos e Isla Perdida, que sí son destinos marítimos. El canon aclara que Punta Pitt es el noreste de San Cristóbal y **no** una isla separada.
5. **Por qué importa:** No es contradicción —una región costera puede alcanzarse por tierra y por mar— pero sí ambigüedad de modelado: ¿es un destino de navegación, un punto de desembarco, o ambos? Afecta al grafo de alcanzabilidad (AUD-023) y a los datos de navegación.
6. **Arquitectura actual:** Doble aparición sin distinción de rol.
7. **Recomendación:** Modelar explícitamente dos conceptos distintos: **región** y **punto de desembarco/atraque**. Punta Pitt es una región con punto de atraque; León Dormido e Isla Lobos son destinos marítimos. Una confirmación tuya de una línea cierra el tema.
8. **Impacto:** Nulo si se aclara pronto.
9. **ADR:** NO · 10. **Luisma:** YES — aclaración de canon, una frase

---

### AUD-056 — Sin presupuesto de rendimiento ni especificación mínima

1. **ID:** AUD-056 · 2. **LOW** (VS11) · 3. **Rendimiento / Plataforma**
4. **Problema:** No hay objetivo de fotogramas, resolución de salida objetivo, especificación mínima de máquina, ni presupuesto de memoria o de tiempo de carga.
5. **Por qué importa:** Para un 2D pixel art offline en Windows, el riesgo de rendimiento es bajo, por eso es LOW. Pero sin objetivo declarado no hay criterio de aceptación para VS11, y el tiempo de carga entre regiones es una métrica de **feel** que sí importa si la decisión de AUD-024 es transiciones discretas.
6. **Arquitectura actual:** Sin definir.
7. **Recomendación:** Fijar objetivos modestos y verificables antes de VS11 (fotogramas estables al objetivo elegido en la especificación mínima, tiempo máximo de transición entre regiones, tiempo máximo de carga de partida) y medirlos en CI donde sea posible. Interactúa con la elección de renderer (AUD-003).
8. **Impacto:** Bajo.
9. **ADR:** NO · 10. **Luisma:** NO

---

### AUD-057 — Sin servicio de diagnóstico ni política de logging

1. **ID:** AUD-057 · 2. **LOW** (VS0) · 3. **Diagnóstico**
4. **Problema:** No hay servicio de logging, niveles, ni política sobre qué se registra en desarrollo frente a release.
5. **Por qué importa:** Afecta principalmente a la capacidad de depurar reportes tuyos y de Codex. Sin niveles, el registro se llena de ruido y deja de leerse; sin archivo en release, un fallo reportado por ti no es diagnosticable.
6. **Arquitectura actual:** Ausente.
7. **Recomendación:** Servicio de logging ligero en `Core` (no autoload) con niveles y categorías por módulo, archivo rotatorio en `user://logs/` también en release, y regla de que ningún log contenga rutas de tu máquina ni datos personales. Enlaza con la política de degradación de AUD-053.
8. **Impacto:** Bajo; alto valor de soporte.
9. **ADR:** NO · 10. **Luisma:** NO

---

### AUD-058 — Modding y telemetría no declarados explícitamente fuera de alcance

1. **ID:** AUD-058 · 2. **LOW** (VS0) · 3. **Alcance / Privacidad**
4. **Problema:** Nada dice si el juego admitirá contenido de usuario o recogerá telemetría. El canon fija offline-first, lo que implica ausencia de telemetría, pero no lo declara.
5. **Por qué importa:** El modding tiene consecuencias arquitectónicas profundas (carga dinámica de datos, ids de terceros, saves con contenido no oficial, validación en runtime). Si no se declara fuera de alcance, alguien podría "dejar la puerta abierta" añadiendo complejidad permanente por una funcionalidad que quizá nunca quieras. La telemetría, además, es una decisión de privacidad que no debe tomarse por omisión ni por un agente.
6. **Arquitectura actual:** No declarado.
7. **Recomendación:** Declarar explícitamente en `ARCHITECTURE.md`: **sin telemetría, sin red, sin analítica** en Volume I; **modding fuera de alcance**, sin infraestructura preparatoria. Si más adelante lo quisieras, sería un ADR y una decisión tuya, no una consecuencia acumulada.
8. **Impacto:** Nulo; previene complejidad especulativa.
9. **ADR:** NO · 10. **Luisma:** YES — confirmación de alcance, una frase

---
## A. ARCHITECTURE STRENGTHS

Lo que está bien diseñado y **no debemos tocar**. Lo enumero con el mismo rigor que los problemas, porque en una auditoría el mayor daño no lo hace pasar por alto un fallo: lo hace "mejorar" algo que ya estaba bien.

**A1 — El canon es internamente consistente, y eso es raro.**
Verifiqué la aritmética completa del Codex de Volume I: 9 iniciales + 30 aves + 24 reptiles + 24 mamíferos + 30 marinos/invertebrados + 18 plantas/hongos/insectos + 12 especiales + 3 legendarios = **exactamente 150**. Contrasté además el número de familias listadas por pilar contra su rango: 3, 10, 8, 8, 10, 6 y 4 familias respectivamente, todas de tres estadios, más 3 Legendarios sin evolución. Cuadra sin excepciones. Un canon de este tamaño que cuadra a la primera es una base de contenido excepcionalmente sólida, y hace que la validación automática (AUD-029) sea trivial de escribir.

**A2 — El canon está expresado en enumeraciones cerradas, no en descripciones abiertas.**
13 tipos, 7 rarezas, 5 estados de Bond, 5 estadios de investigación, 5 categorías de movimiento, 8 terrenos, 4 profundidades, 9 capacidades de campo, 4 estados de Legendario. Esto es, sin que el documento lo diga, una decisión **arquitectónica** de primer orden: un canon enumerado se puede convertir en código generado y en validadores; un canon en prosa, no. Es lo que hace posible casi todo el sistema de protección que propongo.

**A3 — Las prohibiciones defensivas están dirigidas a los riesgos correctos.**
"El Compás no es GPS." "El Bond no es probabilidad de captura." "Los Tikawi no son llaves." "La lógica de juego no depende de nombres visibles." "Un empujón de sprite no es un ataque terminado." Cada una de esas frases ataca un modo de fallo real y concreto del género, anticipado antes de que ocurra. No es documentación defensiva genérica: es alguien que sabe exactamente dónde se degrada este tipo de juego. Mi trabajo aquí no ha sido cuestionarlas sino **convertirlas en estructura** (AUD-012, AUD-018, AUD-019, AUD-021, AUD-023), porque son demasiado valiosas para dejarlas dependiendo de la disciplina de quien implementa.

**A4 — La separación de cuatro capas de Tikawi es correcta y debe mantenerse literalmente.**
`TikawiSpeciesData` (definición inmutable compartida) / `TikawiInstance` (estado persistente del individuo) / `TikawiActor` (presencia en el mundo) / `BattleParticipant` (rol efímero en combate) es exactamente la descomposición que este juego necesita, y es la que hace posible el combate headless, los saves compactos y el compañero visible. No la toques. Lo único que falta es aclarar el alcance de `TikawiActor` (AUD-020) y añadir la vía declarativa de comportamiento (AUD-021).

**A5 — La separación Battle Logic / Battle Presentation con exigencia headless.**
Es la decisión técnica más importante del proyecto y está bien tomada. Es lo que permite testear reglas de combate sin renderizar, y lo que hace que la regla de animación visible sea un problema de presentación y no un riesgo de corrección. AUD-012 no la corrige: la **completa**, definiendo el contrato que va en medio.

**A6 — `source → validación → recursos generados`, con la fuente como autoridad.**
El flujo es el correcto para un juego data-driven, y la regla de no editar artefactos generados está explícitamente enunciada. Solo faltan formatos y política de commit (AUD-008), no el concepto.

**A7 — El modelo de guardado, en contenido, es maduro.**
Escritura atómica, backup, checksum, migraciones, autosaves rotatorios, slots manuales, recuperación segura, y —especialmente— **versión de save separada de versión de juego** y "persistir consecuencias, no estado de presentación". Esa última pareja de decisiones es la que distingue un sistema de guardado que envejece bien de uno que no. El problema es de secuencia (AUD-006), no de diseño.

**A8 — La separación de roles con niveles de cambio 0–3 y condiciones de parada.**
Es un mecanismo de control bien pensado sobre agentes: define quién decide qué, obliga a parar en vez de improvisar, y —crucialmente— lista *"main path would soft-lock"* y *"canon is contradictory"* como paradas obligatorias. La lista de comportamientos prohibidos para Codex es específica y accionable, no genérica. Mantenerlo. Mi única objeción es de proporción, no de fondo (AUD-052).

**A9 — "La documentación versionada es la fuente de verdad, no la memoria de la conversación."**
Para un proyecto llevado con agentes a lo largo de meses, ésta es probablemente la regla individual más valiosa de los cuatro documentos. Es también la que hace que AUD-004 sea un BLOCKER y no una molestia: si la documentación manda, entonces la documentación obsoleta es peligrosa.

**A10 — El principio final, y que la auditoría confirma como correcto:**
> *"La arquitectura debe adaptarse al juego aprobado. El juego aprobado no debe simplificarse solo porque la implementación sería más fácil."*

Ningún hallazgo de esta auditoría propone simplificar el juego. Varios (AUD-012, AUD-015, AUD-023) proponen **construir la estructura que hace asequible lo que el canon exige**, que es la forma correcta de honrar ese principio.

---

## B. RISKS BEFORE CODEX STARTS

Qué debe resolverse antes del primer commit de implementación, ordenado por lo que realmente ocurriría si no se resuelve.

**B1 — Codex completaría la arquitectura en vez de seguirla.**
Riesgo raíz. VS0 exige materializar ocho decisiones que no están tomadas (versión de engine, resolución base, estructura de carpetas, formato de datos, framework de test, política de CI, convenciones, envoltorio de save). Un agente competente no se detiene ante un hueco: lo rellena razonablemente. Cada hueco rellenado pasa a ser arquitectura de facto, y a partir de ahí cada corrección compite contra código que funciona. *Mitigación:* AUD-002 (`ARCHITECTURE.md` normativo con módulo de referencia), AUD-037 (`CONVENTIONS.md`), y el paquete de ADRs de la Sección C, todo antes de X-001.

**B2 — Un canon en conflicto dentro del repositorio.**
El GDD v1.0 se presenta como Biblia canónica y contradice cinco elementos protegidos. Los documentos instruyen a Codex a inspeccionar el repositorio y tratar su documentación como verdad. El fallo no sería visible: sería Scalito como planta bípeda antropomórfica, o cinco Legendarios en el esquema. *Mitigación:* AUD-004, más tu decisión sobre qué diseño del GDD sigue vigente y debe ascender al Master Canon.

**B3 — La regla de animación visible es hoy indefendible por arquitectura.**
Es una regla protegida sin contrato que la sostenga (AUD-012) y sin sistema que la haga asequible a escala (AUD-015). Las dos salidas que un implementador tiene ante esa carencia violan canon explícitamente. Y el momento del fallo sería VS10–VS11, cuando la única "solución" barata sería debilitar la regla. *Mitigación:* fijar el contrato de línea de tiempo y el sistema composable de actuaciones antes de VS3.

**B4 — Persistencia construida por acumulación en vez de por diseño.**
Siete sistemas con estado durable antes de que exista guardado (AUD-006), sin separación runtime/DTO (AUD-010), sin matriz de propiedad (AUD-011), sin fixtures (AUD-035). La consecuencia no es un bug: es que a partir de VS9 cada cambio de estado da miedo. *Mitigación:* Save Core en VS0 y rebanada de persistencia obligatoria por milestone.

**B5 — Reglas de canon que solo sobreviven mientras alguien las recuerde.**
Compás sin distancia exacta, Bond sin porcentaje, capacidades en lugar de especies, sin soft-lock, enums canónicos exactos. Todas están escritas; ninguna está verificada. En un proyecto de varios años con agentes rotando y contexto que se pierde, "está escrito en el documento" no es un control. *Mitigación:* AUD-018, AUD-019, AUD-021, AUD-023, AUD-029 — todas convierten prosa en gate de CI.

**B6 — Decisiones de arte no tomadas, en la ruta más larga del proyecto.**
Sin contrato de píxel (AUD-005) ni contrato de assets (AUD-016), la producción artística no puede empezar. Y el arte es lo que no se puede acelerar al final. Mientras el código avanza por milestones, el arte debería estar avanzando en paralelo desde ya; hoy no puede. *Mitigación:* fijar ambos contratos cuanto antes, incluso antes que parte de lo técnico.

**B7 — Sistemas canónicos sin dueño temporal.**
Evolución, Maestros, Fenómenos Ancestrales, marítimo, opciones y audio no tienen milestone (AUD-031). Un sistema sin milestone no se pospone: se cuela dentro de otro, sin especificación y comprimiendo su alcance. *Mitigación:* reubicación explícita con tu aprobación.

**B8 — Un proceso más pesado que el trabajo que gobierna.**
19 campos por tarea, 17 por informe, ADRs, revisiones por milestone, para un equipo de una persona y dos agentes (AUD-052). El riesgo no es la burocracia en sí: es que se erosione y arrastre consigo la disciplina en los casos donde sí era necesaria. *Mitigación:* dos formatos, con los campos críticos siempre presentes.

---

## C. RECOMMENDED ADR PROPOSALS

Solo los que hacen falta. He consolidado 26 hallazgos que requieren ADR en **ocho** propuestas, agrupadas por decisión real y no por tema, para que puedas aprobarlas en un solo bloque. **Ninguna está aplicada.** Todas son propuestas en estado DRAFT a la espera de tu decisión.

| ADR | Título | Decide | Hallazgos | Estado |
|---|---|---|---|---|
| **ADR-001** | Engine, renderer y contrato de píxel | Versión exacta de Godot, build estándar sin .NET, renderer, resolución base, modo de escalado, tamaño de tile, clases de tamaño de sprite, `TileMapLayer` | AUD-003, AUD-005 | DRAFT |
| **ADR-002** | Infraestructura de repositorio, CI y dependencias | Host del repo, protección de `main`, worktrees, runner de CI, framework de test, política de dependencias (fijadas por versión, vendorizadas, ADR obligatorio), runtime de diálogo | AUD-001, AUD-007, AUD-027, AUD-051 | DRAFT |
| **ADR-003** | Capas, dirección de dependencia, eventos y presupuesto de autoloads | `Presentation → Systems → Core → Data` con lint en CI, registro tipado de eventos con despacho diferido, interpretación ligera de Commands/Events/Queries, tope de 8 autoloads, excepción sancionada para comportamiento declarativo por datos | AUD-002, AUD-009, AUD-017, AUD-021, AUD-039, AUD-040 | DRAFT |
| **ADR-004** | Pipeline de datos, IDs y registro canónico | JSON como fuente autoritativa, ids de cadena inmutables separados del número de Codex, recursos generados commiteados y verificados byte a byte, Canon Registry generado a código con validadores | AUD-008, AUD-029, AUD-030 | DRAFT |
| **ADR-005** | Arquitectura de persistencia y secuenciación save-first | Formato de serialización, envoltorio versionado, separación runtime/DTO, arnés de migración, fixtures dorados, RNG con semilla persistida, y **adelanto del Save Core a VS0/VS1** con rebanada de persistencia por milestone | AUD-006, AUD-010, AUD-033, AUD-034, AUD-035 | DRAFT |
| **ADR-006** | Contrato de combate como línea de tiempo de eventos | `BattleActionResult` como secuencia ordenada e inmutable de pasos con semilla registrada; sistema composable de actuaciones (`MovePerformance`) con validación de beats obligatorios | AUD-012, AUD-015, AUD-043 | DRAFT |
| **ADR-007** | Fronteras de canon para Compás y Bond | Lecturas cuantizadas sin magnitudes continuas; Bond devuelve estado y factores cualitativos, nunca escalar; tests de canon permanentes sobre ambos contratos | AUD-018, AUD-019 | DRAFT |
| **ADR-008** | Travesía por capacidades y validación de alcanzabilidad | Proveedor unificado de capacidades (Tikawi y objetos), abstracción de locomoción con eje de profundidad reservado, grafo de alcanzabilidad y validador anti-soft-lock por inicial | AUD-022, AUD-023, AUD-024, AUD-032 | DRAFT |

Tres notas sobre este paquete:

- **ADR-001, ADR-002 y ADR-004 son los que bloquean X-001.** Si solo puedes revisar tres ahora, son esos.
- **ADR-005 y ADR-006 son los que más ahorran a largo plazo**, y ambos deben decidirse antes de VS3.
- **ADR-007 y ADR-008 no cambian tu diseño; lo blindan.** Deben decidirse antes de VS4 y VS7 respectivamente.

Si apruebas la dirección, redacto los ocho en formato ADR completo (contexto, decisión, alternativas consideradas, consecuencias, hallazgos que cierra) para que los aceptes o rechaces uno a uno. Puedes aceptar unos y rechazar otros: están escritos para ser independientes.

---

## D. VERTICAL SLICE READINESS

### D1 — ¿Puede empezar VS0 después de esta auditoría?

**No todavía. Pero está cerca, y lo que falta son decisiones, no trabajo.**

El motivo es directo: VS0 no es una fase de preparación neutra. Su contenido declarado —bootstrap de Godot, bloqueo de versión de engine, estructura de carpetas, carpetas de datos source/generated, framework mínimo de validación, framework mínimo de test, CI skeleton, export Windows— **es precisamente la materialización en código de las decisiones que ningún documento ha tomado**. VS0 no puede empezar sin ellas, no porque falte permiso, sino porque no hay nada que escribir.

Concretamente, esto es lo que Codex tendría que inventar hoy en la primera hora de X-001:

| Archivo de X-001 | Decisión no tomada que exige |
|---|---|
| `project.godot` | versión de engine, renderer, resolución base, modo de escalado, filtro de textura (AUD-003, AUD-005) |
| Estructura de carpetas | capas, dirección de dependencia, nombres (AUD-002, AUD-009, AUD-037) |
| `data/source/` y `data/generated/` | formato de datos, esquema de IDs, política de commit de generados (AUD-008) |
| Esqueleto de validador | qué valida, y contra qué registro canónico (AUD-029) |
| Primer test | framework de test (dependencia prohibida a Codex) (AUD-007) |
| CI skeleton | dónde vive el repo y dónde corre CI (AUD-001) |
| Export Windows | versión de export templates, coincidente con el engine (AUD-003) |
| Metadatos de versión | relación entre versión de juego y versión de save (AUD-006) |

Ocho de ocho entregables bloqueados por decisiones. Ésa es la razón del veredicto, y es reparable en una sesión.

### D2 — Qué hace falta exactamente para pasar a READY

Ruta mínima, en orden:

1. **Tú decides** los puntos del Anexo II marcados como bloqueantes de VS0 (son nueve preguntas concretas).
2. **Yo redacto** ADR-001, ADR-002, ADR-004 y la parte de secuenciación de ADR-005; tú los aceptas o rechazas.
3. **Yo produzco** `ARCHITECTURE.md` y `CONVENTIONS.md` con el módulo de referencia.
4. **Tú archivas** el GDD v1.0 y me dices qué diseño suyo asciende al Master Canon.
5. **Yo escribo** `VS0_FOUNDATION_SPEC.md` (C-002) y los task packets de VS0.
6. **Codex empieza** X-001.

Los pasos 2 y 3 son trabajo mío y no te cuestan tiempo más allá de la revisión. El camino crítico real eres tú en los pasos 1 y 4.

### D3 — Evaluación del alcance del Vertical Slice

Aparte de la disponibilidad para empezar, evalúo el tamaño del slice terrestre aprobado, porque me lo pediste como área de auditoría.

**El alcance es ambicioso pero correcto, y no recomiendo reducirlo.** Bahía del Desembarco + parte de Tierras Secas + costa rocosa, tres iniciales, salvajes representativos, combate 1v1 con animaciones reales, Energía, Compás, Bond, compañero visible, al menos una field ability, Codex/Research, un rumor, un favor, economía pequeña, tiempo/clima/marea básicos, guardado, ES/EN y teclado/mando. Eso toca **los seis pilares de diseño**, que es exactamente lo que un vertical slice debe hacer: probar que el núcleo es divertido, no que es grande.

Dos observaciones sobre el alcance, ninguna de ellas una propuesta de recorte:

- **Lo más caro del slice, con diferencia, es "combate 1v1 con animaciones reales".** No por la lógica, sino porque obliga a existir al pipeline de actuaciones (AUD-015) y al contrato de assets (AUD-016) antes de VS3. Es correcto que esté en el slice —es la regla de canon que más hay que demostrar pronto— pero conviene reconocer que arrastra consigo dos sistemas que no aparecen en la lista del slice.
- **Aplazar la navegación marítima completa a un Marine Technical Slice posterior es la decisión correcta**, siempre que VS1 no cierre la puerta (AUD-032). Con esa precaución, el aplazamiento es sano.

### D4 — Estado de preparación por milestone

| Milestone | Estado | Bloqueado por |
|---|---|---|
| **VS0 Foundation** | 🔴 Bloqueado | AUD-001, 002, 003, 005, 006, 007, 008 |
| **VS1 Movement & World** | 🔴 Bloqueado | AUD-024 (decisión de carga), 009, 032, 038 |
| **VS2 Tikawi Runtime** | 🟠 Decisiones pendientes | AUD-020, 021, 026, 029, 030, 036 |
| **VS3 Battle** | 🔴 Bloqueado | AUD-012, 013, 014, 015, 047 |
| **VS4 Compass & Bond** | 🟠 Decisiones pendientes | AUD-018, 019 |
| **VS5 Codex & Research** | 🟡 Preparable | AUD-044 |
| **VS6 Quest & Dialogue** | 🟠 Decisiones pendientes | AUD-027 |
| **VS7 Field & Environmental** | 🔴 Bloqueado | AUD-022 (decisión tuya), 023, 025 |
| **VS8 Base & Economy** | 🟡 Preparable | — |
| **VS9 Save & QoL** | 🟠 Redefinido | AUD-006 (cambia de alcance) |
| **VS10 Content Assembly** | 🟡 Preparable | AUD-036 (variedad temprana) |
| **VS11 Polish** | 🟡 Preparable | AUD-050 |
| **VS12 Architecture Review** | 🟠 Redefinido | AUD-031 (pasa a revisión continua) |

🔴 tiene al menos un bloqueante duro · 🟠 requiere decisiones antes de especificar · 🟡 especificable cuando llegue

---

## E. FINAL VERDICT

# **NOT READY — BLOCKERS MUST BE RESOLVED**

**Los ocho BLOCKERs son decisiones, no ingeniería.** Ninguno requiere escribir código. Siete se resuelven eligiendo entre opciones que he acotado en cada hallazgo; el octavo consiste en archivar un documento y decidir qué parte de su contenido asciende. Estimación realista para pasar a `READY FOR VS0`: **una sesión de decisiones contigo, más el paquete de ADRs y los dos documentos de arquitectura que produzco yo.**

Este veredicto no es una crítica al proyecto. El canon de GALÁPAGOS: THE ORIGIN es la base de contenido mejor construida con la que puedo trabajar: cuadra aritméticamente, está enumerado en lugar de descrito, y sus prohibiciones apuntan a riesgos reales anticipados con precisión. Los principios arquitectónicos son, uno por uno, correctos.

Lo que falta no son mejores principios. Es **resolución**: la distancia entre *"la lógica de combate debe ser testeable sin renderizar"* y la firma concreta del contrato que lo hace cierto. Esa distancia es exactamente donde un agente implementador decide por su cuenta, y es donde se pierde el canon — no de golpe, sino en decisiones pequeñas y razonables, cada una defendible, que tres milestones después han producido un juego distinto del aprobado.

El hilo que atraviesa toda esta auditoría es uno solo:

> **Toda regla de canon que dependa de que alguien la recuerde acabará rota. Toda regla de canon expresada como contrato o como test de CI sobrevivirá al proyecto.**

Los documentos maestros ya hicieron el trabajo difícil: decidir qué debe protegerse. Lo que propongo es construir los mecanismos para que esa protección no dependa de la memoria de nadie — ni de la tuya, ni de la mía, ni de la de Codex.

**C-001 completado. Detengo el trabajo aquí y espero tu aprobación, rechazo o corrección antes de producir `VS0_FOUNDATION_SPEC.md` (C-002) o cualquier ADR.**

---

## Anexo I — CANON CONFLICT REPORT

**Documento en conflicto:** `GALAPAGOS_THE_ORIGIN_GDD_v1.0.md`
**Ubicación:** raíz del directorio de trabajo, sin marca de estado
**Se autodescribe como:** *"Estado: Biblia canónica de preproducción"*
**Nivel de autoridad real:** 8 (documento archivado / borrador antiguo)
**Resolución aplicada:** el Master Canon v1.0 prevalece en todos los puntos. **No he cambiado nada.**

### Conflictos detectados

| # | Punto | GDD v1.0 (§) | Master Canon v1.0 | Protegido | Resolución |
|---|---|---|---|---|---|
| 1 | Edad de Darwin | ~26 años (§7, §1) | **20 años** | Sí | Canon |
| 2 | Número de Legendarios | 5 "Guardianes" (§25) | **3** (#148, #149, #150) | Sí | Canon |
| 3 | Identidad de Legendarios | Incluye **Abyssiguana** y **Scalysia** (§25) | *"Abyssiguana and Scalysia are **not** Volume I Legendarios"* | Sí | Canon |
| 4 | Terminología de criatura | "criaturas", "compañeros" (todo el doc) | **Tikawi** (sing. *un Tikawi*, pl. *los Tikawi*) | Sí | Canon |
| 5 | Regla de criaturas vegetales | *"antropomórficas… Scalito es una pequeña criatura vegetal bípeda"* (§12) | *"**Scalito is not a humanoid plant**"*; tortuga + Scalesia | Sí | Canon |
| 6 | Compás | *"variantes especializadas por hábitat o tipo"*, vendidas en Casa del Explorador (§17, §20) | Objeto único; no captura, no almacenamiento, no medidor preciso | Sí | Canon |
| 7 | Estructura del Codex | 30 familias × 3 + 20 × 2 + 15 × 1 + 5 legendarios (§10) | 49 familias × 3 + 3 Legendarios = 150 | Sí | Canon |
| 8 | Motor / plataforma / guardado | listados como *"decisiones pendientes"* (§31) | Godot / GDScript / Windows / saves versionados | Sí | Canon |
| 9 | Probabilidad de vínculo | *"probabilidades de vínculo"* como pendiente (§31) | Bond **no es** probabilidad de captura; es confianza contextual | Sí | Canon |
| 10 | Prueba final | *"SAN CRISTÓBAL TRIAL"* (§24) | *"Prueba de San Cristóbal"*; *"Do not call this a Liga"* | Parcial | Canon |
| 11 | Nombre de Maestro | *"Maestro de las Tierras Altas"* (§24) | *"Maestro de Alturas"* | Parcial | Canon |
| 12 | Nombre de región | *"Campamento Blackwood"* (§22) | *"Blackwood Camp"* | Parcial | Canon (y ver AUD-037: idioma) |

### Contenido del GDD que **no** está en el Master Canon y que podría perderse

Esto no es conflicto; es diseño que el Master Canon no recoge y que, si sigue vigente, debería **ascender** a canon antes de archivar el GDD. No puedo decidirlo yo. Necesito que marques cada uno como *vigente* o *descartado*:

- Rutinas horarias de NPC (pescadores por la mañana, barcos al atardecer, contrabandistas de noche) — §5.2
- Rumores con valor de verdad: correctos, incompletos, exagerados o falsos — §5.1 *(relevante para AUD-027)*
- Mercado clandestino con productos Blackwood de consecuencias negativas sobre agotamiento o vínculo — §20
- Eventos emergentes no-misión (criatura herida, combate entre salvajes, colono en peligro, tormenta, aparición fugaz) — §26
- Tomás elige el inicial con ventaja de tipo sobre el de Darwin — §8
- Progresión y transformación de movimientos (Chispa de Lava → Garra Magma → Torrente Magma → Erupción Salvaje) — §15.2
- Dos Tikawi de misma especie y nivel pueden tener builds completamente distintas — §21
- Niveles concretos de evolución de los iniciales (18/36, 16/34, 17/35) — §11
- Mapa que se completa con la exploración y registra senderos, cuevas, fuentes, hábitats, desembarcaderos — §4.2
- Estructura de la saga en tres volúmenes: San Cristóbal → Santa Cruz → Isabela — §3
- Continuidad postcampaña: San Cristóbal sigue jugable, rematches, desafíos — §29
- Filosofía de gating natural: *"Puedo verlo ahora, pero todavía no sé cómo llegar"* — §4.1 *(relevante para AUD-022)*

### Acción requerida

1. Confirmar que el Master Canon prevalece (creo que es obvio, pero debe quedar registrado).
2. Marcar cada punto de la lista anterior como vigente o descartado.
3. Mover el GDD a `docs/archive/GDD_v1.0_SUPERSEDED.md` con cabecera de estado.
4. Adoptar la regla: **ningún documento sin cabecera `STATUS` y `AUTHORITY LEVEL` es autoridad.**

---

## Anexo II — DECISIONES QUE REQUIEREN A LUISMA

Diecisiete decisiones, ordenadas por urgencia. Las marcadas **[VS0]** bloquean el primer commit.

### Bloquean VS0 — necesarias antes de que Codex escriba una línea

1. **[VS0] Repositorio y CI** (AUD-001) — ¿GitHub privado con Actions, o todo local con scripts? ¿Aceptas una cuenta externa para el código del proyecto?
2. **[VS0] Renderer** (AUD-003) — ¿La oscuridad de las Cavernas de Lava, la noche y el Farol son **iluminación real** (Forward+) o **tintado artístico** (Compatibility)?
3. **[VS0] Contrato de píxel** (AUD-005) — resolución base, tamaño de tile y clases de tamaño de Tikawi. Te propongo opciones concretas mirando tus PNG de referencia; no quiero elegirlo a ciegas.
4. **[VS0] Framework de test** (AUD-007) — ¿Aceptas una dependencia de terceros fijada y vendorizada (gdUnit4 o GUT), o prefieres runner propio asumiendo mantenerlo?
5. **[VS0] Autoría de datos** (AUD-008) — ¿Vas a autorar las 150 Tikawi en hoja de cálculo o directamente en JSON? Determina la ergonomía del pipeline durante años.
6. **[VS0] Secuencia de guardado** (AUD-006) — ¿Apruebas adelantar el Save Core a VS0/VS1 y exigir una rebanada de persistencia por milestone?
7. **[VS0] Idioma de código y documentación** (AUD-037) — mi propuesta: identificadores en inglés, términos de canon en español conservados literalmente. ¿Lo confirmas? ¿Y el idioma de la documentación del repo?
8. **[VS0] GDD v1.0** (AUD-004, Anexo I) — confirmar el archivado y marcar qué diseño asciende al Master Canon.
9. **[VS0] Alcance declarado** (AUD-058) — confirmar sin telemetría, sin red, sin modding en Volume I.

### Bloquean VS1–VS3

10. **Carga del mundo** (AUD-024) — ¿regiones discretas con transición, o espacio contiguo? Recomiendo discretas; es una decisión de feel.
11. **Energía y suelo anti-soft-lock** (AUD-014) — ¿acción de "Recuperar" siempre disponible fuera de los seis slots, u otra vía?
12. **Categoría Reacción** (AUD-013) — ¿qué es exactamente, cómo se arma, qué la dispara?
13. **Tabla de tipos 13×13** (AUD-047) — es contenido de diseño tuyo; yo aporto forma y validación.
14. **Tiempo de juego** (AUD-025) — duración del día, y si el reloj corre durante combate y menús.
15. **Coste visual por movimiento** (AUD-015) — cuánta variedad de actuación quieres por movimiento; define el tamaño de la biblioteca de piezas.

### Bloquean VS4–VS7

16. **Capacidades vs objetos** (AUD-022) — Luz vs Farol, Escalada vs Cuerda/Equipo. Recomiendo la opción (b): capacidades distintas con grados distintos.
17. **Estructura de líneas evolutivas** (AUD-029) — ¿es regla que **toda** línea tenga exactamente 3 estadios, o es coincidencia del roster actual? No lo aplicaré como validación sin tu respuesta.

### También necesitaré de ti, más adelante (no urgente)

Capacidad de reserva y semántica de salida del vínculo (AUD-045) · condiciones por estadio de investigación (AUD-044) · política de velocidad de combate y accesibilidad (AUD-050) · reubicación de milestones huérfanos (AUD-031) · aclaración de Punta Pitt (AUD-055) · runtime de diálogo: construir o adoptar (AUD-027) · idioma fuente y regla de nombres propios no traducibles (AUD-028).

---

**FIN DE C-001 — ARCHITECTURE AUDIT**

*Preparado por Claude, Lead Architecture Agent. Ningún cambio aplicado. Ninguna propuesta arquitectónica ejecutada. Esperando decisión de Luisma.*
