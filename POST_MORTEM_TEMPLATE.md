# Post-Mortem: [Título del Incidente]

> **Formato:** Google SRE Blameless Post-Mortem  
> **Proyecto:** App Registro  
> **Equipo:** [Nombres]  
> **Fecha del incidente:** YYYY-MM-DD  
> **Fecha del post-mortem:** YYYY-MM-DD  

---

## Estado

- [ ] Borrador
- [ ] En revisión
- [ ] Finalizado

**Severity:** SEV-1 / SEV-2 / SEV-3  
**Duración:** X horas Y minutos  
**Impacto:** Descripción breve del impacto en usuarios/sistema

---

## Resumen Ejecutivo

> Descripción en 2-3 oraciones de qué pasó, por qué pasó y cómo se resolvió.

**Ejemplo:**  
El 2025-01-15 a las 14:30 UTC, el servicio de autenticación (`/api/v1/auth/login`) dejó de responder durante 45 minutos debido a un agotamiento de conexiones en el pool de PostgreSQL. Esto afectó al 100% de los usuarios intentando iniciar sesión. El incidente fue resuelto al reiniciar el pool de conexiones y aplicar un límite de conexiones máximas en la configuración de TypeORM.

---

## Impacto

| Métrica | Valor |
|---|---|
| Duración total | X min |
| Usuarios afectados | ~N |
| Requests fallidas | N (X%) |
| Entornos afectados | Producción / Staging |
| SLO afectado | Disponibilidad 99.9% → X% durante el incidente |

---

## Timeline

> Usar hora UTC. Ser específico y blameless.

| Hora (UTC) | Evento |
|---|---|
| 14:30 | Primeras alertas de Prometheus: `HighErrorRate` firing |
| 14:32 | Alerta recibida en canal #alerts |
| 14:35 | Oncall investiga logs en Grafana |
| 14:45 | Identificada causa raíz: pool de conexiones agotado |
| 14:50 | Aplicado workaround: reinicio del deployment |
| 15:00 | Servicio restaurado al 100% |
| 15:15 | Postmortem iniciado |

---

## Root Cause Analysis

### Causa raíz

> Descripción técnica precisa de qué causó el incidente.

**Ejemplo:**  
La configuración de TypeORM tenía `connectionLimit: 10` pero el HPA escaló a 4 réplicas. Con 4 pods × 10 conexiones = 40 conexiones, excediendo el límite de 25 conexiones del plan gratuito de Supabase.

### Causas contribuyentes

1. No había alertas configuradas para `pg_active_connections`
2. El HPA no consideraba el impacto en la base de datos al escalar
3. La documentación del plan de Supabase no fue revisada durante el diseño

---

## Qué salió bien

1. Las alertas de Prometheus detectaron el problema en menos de 2 minutos
2. El dashboard de Grafana permitió identificar rápidamente la ruta afectada
3. El rollback fue ejecutado en menos de 5 minutos

---

## Qué salió mal

1. No había límite de conexiones documentado en el runbook
2. El smoke test de staging no reproduce la carga de producción
3. No había alerta específica para conexiones de base de datos

---

## 5 Whys

| # | Pregunta | Respuesta |
|---|---|---|
| 1 | ¿Por qué falló el servicio? | El pool de conexiones se agotó |
| 2 | ¿Por qué se agotó? | El HPA escaló pods sin considerar el límite de BD |
| 3 | ¿Por qué el HPA no lo consideró? | El límite de conexiones no estaba documentado como restricción de escalado |
| 4 | ¿Por qué no estaba documentado? | No había un proceso de "capacity review" antes del deploy |
| 5 | ¿Por qué no había ese proceso? | El equipo priorizó features sobre documentación de restricciones |

---

## Action Items

| Acción | Responsable | Prioridad | Deadline |
|---|---|---|---|
| Agregar alerta `HighDBConnections` en Prometheus | [Nombre] | P1 | 3 días |
| Configurar `connection_limit` por pod en TypeORM | [Nombre] | P1 | 2 días |
| Agregar `pg_active_connections` al dashboard de Grafana | [Nombre] | P2 | 1 semana |
| Documentar restricciones de Supabase en el runbook | [Nombre] | P2 | 1 semana |
| Implementar load test en staging pipeline | [Nombre] | P3 | 2 semanas |

---

## Lecciones aprendidas

> Sin culpar a personas. Enfocarse en sistemas y procesos.

1. **Observabilidad de BD:** Prometheus debe monitorear métricas de PostgreSQL, no solo HTTP.
2. **Capacidad:** El límite de conexiones de la BD debe ser parte del checklist de escalado.
3. **Runbooks:** Cada alerta debe tener un runbook asociado con pasos de resolución.

---

## SLO Impact Report

```
Período: 2025-01-15 14:30 → 15:00 UTC (30 min)
Disponibilidad en el período: ~33% (10 min up / 30 min total)
Error budget consumido: 30 min de 43.8 min/mes (99.9% SLO)
Error budget restante: ~31% del mes
```

---

*Este documento es blameless: describe fallas del sistema, no de las personas.*
