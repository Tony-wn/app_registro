# Métricas DORA — App Registro

> **DORA State of DevOps Report 2024:** dora.dev  
> Referencia: Kim, Humble, Debois & Willis — The DevOps Handbook, 2016.

---

## ¿Qué son las métricas DORA?

Las 4 métricas DORA miden el rendimiento de equipos de software:

| Métrica | Elite | High | Medium | Low |
|---|---|---|---|---|
| **Deployment Frequency** | Múltiples/día | Semanal | Mensual | < 6 meses |
| **Lead Time for Changes** | < 1 hora | < 1 día | < 1 mes | > 6 meses |
| **Change Failure Rate** | < 5% | < 10% | < 15% | > 15% |
| **Time to Restore Service** | < 1 hora | < 1 día | < 1 semana | > 6 meses |

---

## Registro del equipo durante el proyecto

### Período de medición
- **Inicio:** YYYY-MM-DD
- **Fin:** YYYY-MM-DD
- **Duración:** 1 semana

---

### 1. Deployment Frequency (Frecuencia de despliegues)

> Cuántas veces se desplegó a producción durante el período.

| Fecha | Commit SHA | Entorno | Exitoso | Tiempo |
|---|---|---|---|---|
| YYYY-MM-DD | abc123 | staging | ✅ | 4m 32s |
| YYYY-MM-DD | def456 | production | ✅ | 6m 18s |
| YYYY-MM-DD | ghi789 | staging | ❌ | 3m (rollback) |
| | | | | |

**Total deploys:** N  
**Deploys/día:** N/7  
**Clasificación DORA:** [ ] Elite [ ] High [ ] Medium [ ] Low

---

### 2. Lead Time for Changes (Tiempo desde commit hasta producción)

> Tiempo desde el primer commit de un cambio hasta que está en producción.

| PR / Feature | Primer commit | Merge a main | Deploy prod | Lead Time |
|---|---|---|---|---|
| feat/login-fix | YYYY-MM-DD HH:MM | YYYY-MM-DD HH:MM | YYYY-MM-DD HH:MM | X horas |
| feat/qr-update | | | | |
| fix/auth-bug | | | | |

**Lead time promedio:** X horas  
**Clasificación DORA:** [ ] Elite [ ] High [ ] Medium [ ] Low

**Cómo calcularlo con GitHub Actions:**
```bash
# Tiempo del pipeline CI completo (ver Actions logs)
# Lead Time = (timestamp deploy prod) - (timestamp primer commit)
git log --format="%H %ai" | head -5
```

---

### 3. Change Failure Rate (Tasa de fallos en cambios)

> % de deploys que causaron un incidente o requirieron rollback.

| Deploy | Resultado | Acción |
|---|---|---|
| abc123 | ✅ Exitoso | — |
| def456 | ❌ Rollback | Timeout en BD |
| ghi789 | ✅ Exitoso | — |

**Total deploys:** N  
**Deploys fallidos:** M  
**Change Failure Rate:** M/N × 100 = X%  
**Clasificación DORA:** [ ] Elite (<5%) [ ] High (<10%) [ ] Medium [ ] Low

---

### 4. Time to Restore Service (Tiempo de restauración)

> Tiempo desde que se detecta un incidente hasta que el servicio se restaura.

| Incidente | Detectado | Restaurado | MTTR |
|---|---|---|---|
| Auth service down | YYYY-MM-DD HH:MM | YYYY-MM-DD HH:MM | X min |
| High latency | | | |

**MTTR promedio:** X minutos  
**Clasificación DORA:** [ ] Elite (<1h) [ ] High (<1d) [ ] Medium [ ] Low

---

## Comparación con benchmarks DORA 2024

```
                    Nuestro equipo    Elite
─────────────────────────────────────────────────
Deploy Frequency    X/semana          Múltiples/día
Lead Time           X horas           < 1 hora
Change Failure Rate X%                < 5%
MTTR                X minutos         < 1 hora
─────────────────────────────────────────────────
```

## Propuestas de mejora

Basado en los datos recolectados:

1. **Para mejorar Deployment Frequency:** Automatizar más el pipeline de staging → reducir aprobaciones manuales en entornos no críticos.
2. **Para reducir Lead Time:** Optimizar el job de Trivy (actualmente es el más lento: ~4 min).
3. **Para reducir Change Failure Rate:** Agregar más tests de integración al CI; los fallos fueron principalmente por configuración de BD.
4. **Para mejorar MTTR:** Mejorar los runbooks y las alertas de Prometheus para detectar antes.
