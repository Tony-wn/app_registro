# App Registro — Estrategia DevOps

![CI Pipeline](https://github.com/DepresslyJuice/app_registro/actions/workflows/ci.yml/badge.svg)
![CD Pipeline](https://github.com/DepresslyJuice/app_registro/actions/workflows/cd.yml/badge.svg)
![License](https://img.shields.io/badge/license-ISC-blue)
![NestJS](https://img.shields.io/badge/NestJS-11-red)
![Node](https://img.shields.io/badge/Node-22-green)

API REST de autenticación y registro desarrollada con **NestJS + TypeScript + PostgreSQL**, con estrategia DevOps completa que incluye CI/CD, IaC, Kubernetes, observabilidad y seguridad.

---

## Arquitectura

```
┌─────────────────────────────────────────────────────────┐
│                     GitHub Actions                       │
│  push → CI (test+scan+build) → CD staging → CD prod     │
└──────────────────────┬──────────────────────────────────┘
                       │
          ┌────────────▼────────────┐
          │      GHCR (Registry)    │
          │  ghcr.io/depresslyjuice │
          └────────────┬────────────┘
                       │
    ┌──────────────────▼──────────────────────┐
    │              Kubernetes (EKS)            │
    │                                          │
    │  ┌──────────┐    ┌──────────┐           │
    │  │ Pod (1)  │    │ Pod (2)  │  ← HPA    │
    │  │NestJS:3k │    │NestJS:3k │  min:2    │
    │  └──────────┘    └──────────┘  max:10   │
    │         │               │               │
    │         └───────┬───────┘               │
    │                 │                       │
    │         ┌───────▼──────┐                │
    │         │   Service    │                │
    │         │  ClusterIP   │                │
    │         └───────┬──────┘                │
    │                 │                       │
    │         ┌───────▼──────┐                │
    │         │   Ingress    │ ← TLS/HTTPS    │
    │         └──────────────┘                │
    └─────────────────────────────────────────┘
                       │
    ┌──────────────────▼──────────────────────┐
    │            Observabilidad                │
    │  Prometheus (scrape /metrics cada 15s)  │
    │  Grafana (dashboards + alertas SLO)     │
    └─────────────────────────────────────────┘
                       │
    ┌──────────────────▼──────────────────────┐
    │     PostgreSQL (Supabase)                │
    │  prod: aws-1-us-east-1.pooler            │
    └─────────────────────────────────────────┘
```

---

## Stack tecnológico

| Capa | Tecnología |
|---|---|
| Backend | NestJS 11, TypeScript 5, Node.js 22 |
| Base de datos | PostgreSQL (Supabase), TypeORM |
| Autenticación | JWT (access + refresh tokens en cookies HttpOnly) |
| Contenedor | Docker multi-stage (Alpine, ~120MB) |
| Orquestación | Kubernetes (EKS / minikube local) |
| CI/CD | GitHub Actions |
| IaC | Terraform (AWS: EKS + S3 + DynamoDB) |
| Observabilidad | Prometheus + Grafana + prom-client |
| Seguridad | Trivy (SAST+SCA), gitleaks, OWASP ZAP |

---

## Estructura del repositorio

```
proyecto-devops/
├── README.md                    ← arquitectura + badge CI
├── Dockerfile                   ← multi-stage obligatorio
├── .dockerignore
├── .env.example                 ← NUNCA committear .env real
├── src/                         ← código de la aplicación NestJS
│   ├── app.module.ts
│   ├── main.ts
│   └── modules/
│       ├── auth/                ← JWT, login, register
│       ├── usuarios/            ← CRUD usuarios
│       ├── roles/               ← gestión de roles
│       ├── qr/                  ← QR codes
│       └── metrics/             ← Prometheus metrics endpoint
├── .github/
│   └── workflows/
│       ├── ci.yml               ← build, test, scan, push
│       └── cd.yml               ← deploy staging + prod
├── k8s/
│   ├── deployment.yaml          ← con probes + resources + anti-affinity
│   ├── service.yaml
│   ├── hpa.yaml                 ← min:2 max:10 réplicas
│   ├── configmap.yaml           ← variables no sensibles
│   └── ingress.yaml             ← TLS
├── terraform/
│   ├── main.tf                  ← EKS + VPC
│   ├── variables.tf
│   ├── outputs.tf
│   └── backend.tf               ← estado remoto en S3 + DynamoDB lock
├── monitoring/
│   ├── prometheus/
│   │   ├── prometheus.yml       ← scrape config
│   │   └── alert_rules.yml      ← SLO 99.9% alerts
│   ├── grafana/
│   │   └── dashboards/
│   │       └── app-registro.json
│   └── docker-compose.monitoring.yml
├── POST_MORTEM_TEMPLATE.md      ← formato Google SRE
└── DORA_METRICS.md              ← las 4 métricas + benchmarks 2024
```

---

## Requisitos previos

- Node.js 22+ y pnpm 10+
- Docker Desktop
- kubectl
- minikube o kind (para Kubernetes local)
- Terraform 1.6+

---

## Inicio rápido (desarrollo local)

```bash
# 1. Clonar el repositorio
git clone https://github.com/DepresslyJuice/app_registro.git
cd app_registro

# 2. Copiar variables de entorno
cp .env.example .env
# → Editar .env con tus valores reales

# 3. Instalar dependencias
pnpm install

# 4. Ejecutar migraciones y seed
pnpm run db:setup

# 5. Iniciar en modo desarrollo
pnpm run start:dev

# API disponible en: http://localhost:3000/api/v1
# Swagger: http://localhost:3000/api/docs
# Métricas: http://localhost:3000/metrics
```

---

## Ejecutar con Docker

```bash
# Build
docker build -t app-registro:local .

# Run (con variables de entorno)
docker run -p 3000:3000 --env-file .env app-registro:local
```

---

## Kubernetes local (minikube)

```bash
# Iniciar minikube
minikube start --cpus=2 --memory=4g

# Aplicar manifests
kubectl create namespace production
kubectl apply -f k8s/configmap.yaml -n production
kubectl create secret generic app-secrets \
  --from-literal=JWT_SECRET=tu-secret \
  --from-literal=SEGURIDAD_DB_PASS=tu-pass \
  -n production
kubectl apply -f k8s/ -n production

# Ver pods
kubectl get pods -n production -w

# Port-forward para testing local
kubectl port-forward svc/app-registro-svc 3000:80 -n production
```

---

## Observabilidad local

```bash
# Levantar Prometheus + Grafana
docker compose -f monitoring/docker-compose.monitoring.yml up -d

# Acceder a:
# Prometheus: http://localhost:9090
# Grafana:    http://localhost:3001  (admin / devops2024)
```

---

## Pipeline CI/CD

```
Push a develop/main
       │
       ▼
  🧪 Test + Coverage (≥85%)
       │
       ▼
  🔍 SAST (Trivy fs + gitleaks)
       │
       ▼
  🐳 Docker build + push GHCR
       │
       ▼
  🔍 SCA (Trivy image)
       │
       ▼
  🟡 Deploy Staging (automático)
       │
       ▼
  ✋ Aprobación manual
       │
       ▼
  🟢 Deploy Production
```

---

## Seguridad (DevSecOps)

- **Trivy:** Scan de filesystem (SAST) e imagen Docker (SCA) — falla en CRITICAL
- **gitleaks:** Detección de secretos en commits
- **OWASP ZAP:** Baseline scan automático en CI
- **Secrets management:** Variables sensibles en GitHub Secrets → K8s Secrets
- **No root:** El contenedor corre como usuario `appuser` (UID 1001)
- **Read-only:** Filesystem del contenedor en modo lectura
- **Capacidades dropped:** `ALL` capabilities eliminadas

---

## SLO definidos

| SLI | SLO |
|---|---|
| Disponibilidad | 99.9% (43.8 min/mes downtime máximo) |
| Latencia P95 | < 1 segundo |
| Latencia P99 | < 3 segundos |
| Error rate | < 0.1% |

---

## Métricas DORA

Ver [`DORA_METRICS.md`](./DORA_METRICS.md) para el registro completo del equipo y comparación con benchmarks 2024.

---

## Entrega

- **Repositorio:** https://github.com/DepresslyJuice/app_registro
- **Informe PDF:** `/informe/informe-devops.pdf` (IEEE, 10-15 págs.)
- **Demo:** 10 minutos en vivo

---

## Bibliografía

- Kim, Humble, Debois & Willis. *The DevOps Handbook*. 2016.
- Beyer et al. *Site Reliability Engineering*. Google/O'Reilly, 2016.
- DORA *State of DevOps Report 2024* — dora.dev
- Kubernetes docs — kubernetes.io/docs
