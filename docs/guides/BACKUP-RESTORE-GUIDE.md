# Guía de Backup y Restauración - PostgreSQL

## 📋 Información General

### Sistema de Backup Implementado

El sistema de backup automático para PostgreSQL incluye:

- **CronJob**: Backups automáticos diarios a las 2:00 AM UTC
- **PVC**: 20GB de almacenamiento dedicado para backups
- **Retención**: Últimos 7 días de backups
- **Formato**: SQL comprimido con gzip
- **Alcance**: Todas las bases de datos (pg_dumpall)

### Bases de Datos

El sistema incluye las siguientes bases de datos:

1. `ecommerce_db` - Base de datos principal
2. `user_db` - Datos de usuarios
3. `product_db` - Catálogo de productos
4. `order_db` - Órdenes de compra
5. `payment_db` - Transacciones de pago
6. `shipping_db` - Envíos
7. `favourite_db` - Productos favoritos

## 🔄 Backups Automáticos

### CronJob Configurado

```yaml
Schedule: "0 2 * * *"  # Diariamente a las 2:00 AM UTC
Retention: 7 días
Location: /backups (PVC postgres-backup-pvc)
```

### Verificar Estado del CronJob

```bash
# Ver CronJob
kubectl get cronjob postgres-backup-cronjob -n dev

# Ver historial de ejecuciones
kubectl get jobs -n dev | grep postgres-backup

# Ver logs de la última ejecución
LAST_JOB=$(kubectl get jobs -n dev -l app=postgres,component=backup --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}')
kubectl logs job/$LAST_JOB -n dev
```

### Desactivar Backups Automáticos (Temporalmente)

```bash
# Suspender el CronJob
kubectl patch cronjob postgres-backup-cronjob -n dev -p '{"spec":{"suspend":true}}'

# Reactivar el CronJob
kubectl patch cronjob postgres-backup-cronjob -n dev -p '{"spec":{"suspend":false}}'
```

## 💾 Backup Manual (On-Demand)

### Ejecutar Backup Manual

```bash
# Método 1: Usar el Job predefinido
kubectl apply -f k8s/backup/postgres-manual-backup.yaml

# Método 2: Crear un Job desde el CronJob
kubectl create job --from=cronjob/postgres-backup-cronjob postgres-manual-backup-$(date +%Y%m%d-%H%M%S) -n dev
```

### Monitorear Backup Manual

```bash
# Ver estado del job
kubectl get jobs -n dev | grep manual

# Ver logs en tiempo real
kubectl logs -f job/postgres-manual-backup -n dev

# Esperar a que complete
kubectl wait --for=condition=complete --timeout=300s job/postgres-manual-backup -n dev
```

## 📂 Gestión de Backups

### Listar Backups Disponibles

```bash
# Opción 1: Ejecutar comando en el pod de backup
kubectl run -it --rm backup-list --image=postgres:13-alpine --restart=Never -n dev \
  --overrides='
{
  "spec": {
    "containers": [{
      "name": "backup-list",
      "image": "postgres:13-alpine",
      "command": ["ls", "-lh", "/backups"],
      "volumeMounts": [{
        "name": "backup-volume",
        "mountPath": "/backups"
      }]
    }],
    "volumes": [{
      "name": "backup-volume",
      "persistentVolumeClaim": {
        "claimName": "postgres-backup-pvc"
      }
    }]
  }
}'

# Opción 2: Crear pod temporal
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: backup-browser
  namespace: dev
spec:
  containers:
  - name: browser
    image: busybox
    command: ['sh', '-c', 'ls -lh /backups && sleep 3600']
    volumeMounts:
    - name: backup-volume
      mountPath: /backups
  volumes:
  - name: backup-volume
    persistentVolumeClaim:
      claimName: postgres-backup-pvc
EOF

# Ver backups
kubectl exec backup-browser -n dev -- ls -lh /backups

# Limpiar
kubectl delete pod backup-browser -n dev
```

### Descargar un Backup

```bash
# Crear pod temporal para acceder al backup
kubectl run -it --rm backup-download --image=busybox --restart=Never -n dev \
  --overrides='
{
  "spec": {
    "containers": [{
      "name": "backup-download",
      "image": "busybox",
      "command": ["sleep", "300"],
      "volumeMounts": [{
        "name": "backup-volume",
        "mountPath": "/backups"
      }]
    }],
    "volumes": [{
      "name": "backup-volume",
      "persistentVolumeClaim": {
        "claimName": "postgres-backup-pvc"
      }
    }]
  }
}'

# En otra terminal, copiar el backup
BACKUP_FILE="postgres_backup_20251125_043545.sql.gz"  # Reemplazar con el nombre real
kubectl cp dev/backup-download:/backups/$BACKUP_FILE ./$BACKUP_FILE
```

### Eliminar Backups Antiguos Manualmente

```bash
# Ejecutar comando de limpieza
kubectl run -it --rm backup-cleanup --image=busybox --restart=Never -n dev \
  --overrides='
{
  "spec": {
    "containers": [{
      "name": "backup-cleanup",
      "image": "busybox",
      "command": ["sh", "-c", "find /backups -name \"postgres_backup_*.sql.gz\" -type f -mtime +7 -delete && ls -lh /backups"],
      "volumeMounts": [{
        "name": "backup-volume",
        "mountPath": "/backups"
      }]
    }],
    "volumes": [{
      "name": "backup-volume",
      "persistentVolumeClaim": {
        "claimName": "postgres-backup-pvc"
      }
    }]
  }
}'
```

## 🔧 Restauración de Backup

### ⚠️ ADVERTENCIA

La restauración sobrescribirá **TODOS** los datos actuales en la base de datos. Asegúrate de:

1. Crear un backup actual antes de restaurar
2. Verificar que el backup a restaurar esté íntegro
3. Notificar a todos los usuarios del downtime
4. Detener servicios que escriben a la BD durante la restauración

### Procedimiento de Restauración

#### 1. Crear Backup de Seguridad

```bash
# Ejecutar backup actual
kubectl create job --from=cronjob/postgres-backup-cronjob postgres-pre-restore-backup -n dev

# Esperar a que complete
kubectl wait --for=condition=complete --timeout=300s job/postgres-pre-restore-backup -n dev
```

#### 2. Detener Servicios (Opcional pero Recomendado)

```bash
# Escalar servicios a 0 réplicas
kubectl scale deployment user-service product-service order-service payment-service shipping-service favourite-service -n dev --replicas=0

# Verificar que no haya pods activos
kubectl get pods -n dev | grep -E '(user|product|order|payment|shipping|favourite)'
```

#### 3. Ejecutar Restauración

```bash
# Crear Job de restauración
BACKUP_FILE="postgres_backup_20251125_043545.sql.gz"  # Nombre del backup a restaurar

cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: postgres-restore-$(date +%Y%m%d%H%M%S)
  namespace: dev
spec:
  ttlSecondsAfterFinished: 3600
  template:
    spec:
      serviceAccountName: postgres-backup-sa
      restartPolicy: Never
      containers:
      - name: postgres-restore
        image: postgres:13-alpine
        command:
        - /bin/sh
        - -c
        - |
          echo "🔄 Starting restore from: ${BACKUP_FILE}"
          gunzip -c /backups/${BACKUP_FILE} | psql -h postgres.dev.svc.cluster.local -p 5432 -U \${POSTGRES_USER}
          if [ \$? -eq 0 ]; then
            echo "✅ Restore completed successfully"
          else
            echo "❌ Restore failed!"
            exit 1
          fi
        env:
        - name: POSTGRES_USER
          valueFrom:
            configMapKeyRef:
              name: postgres-config
              key: POSTGRES_USER
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: POSTGRES_PASSWORD
        - name: BACKUP_FILE
          value: "${BACKUP_FILE}"
        volumeMounts:
        - name: backup-volume
          mountPath: /backups
      volumes:
      - name: backup-volume
        persistentVolumeClaim:
          claimName: postgres-backup-pvc
EOF
```

#### 4. Monitorear Restauración

```bash
# Ver progreso
RESTORE_JOB=$(kubectl get jobs -n dev -l component=restore --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}')
kubectl logs -f job/$RESTORE_JOB -n dev
```

#### 5. Reiniciar Servicios

```bash
# Restaurar réplicas originales
kubectl scale deployment user-service -n dev --replicas=3
kubectl scale deployment product-service -n dev --replicas=1
kubectl scale deployment order-service -n dev --replicas=1
kubectl scale deployment payment-service -n dev --replicas=1
kubectl scale deployment shipping-service -n dev --replicas=1
kubectl scale deployment favourite-service -n dev --replicas=1

# O usar HPA (si está configurado)
kubectl get hpa -n dev
```

#### 6. Verificar Integridad

```bash
# Verificar que los servicios estén funcionando
./test.sh

# Verificar logs de los servicios
kubectl logs -n dev deployment/user-service --tail=50
kubectl logs -n dev deployment/product-service --tail=50
```

## 🛠️ Troubleshooting

### Problema: Backup Falla con Error de Conexión

```bash
# Verificar que PostgreSQL esté corriendo
kubectl get pods -n dev | grep postgres

# Verificar conectividad
kubectl exec -it postgres-0 -n dev -- psql -U ecommerce -c "SELECT version();"

# Revisar logs de PostgreSQL
kubectl logs postgres-0 -n dev
```

### Problema: PVC Lleno

```bash
# Verificar espacio usado
kubectl exec backup-browser -n dev -- du -sh /backups/*

# Limpiar backups antiguos manualmente
kubectl exec backup-browser -n dev -- find /backups -name "postgres_backup_*.sql.gz" -mtime +7 -delete

# Aumentar tamaño del PVC (si es necesario)
kubectl patch pvc postgres-backup-pvc -n dev -p '{"spec":{"resources":{"requests":{"storage":"50Gi"}}}}'
```

### Problema: CronJob No Se Ejecuta

```bash
# Verificar que no esté suspendido
kubectl get cronjob postgres-backup-cronjob -n dev -o jsonpath='{.spec.suspend}'

# Ver eventos
kubectl get events -n dev --sort-by='.lastTimestamp' | grep cronjob

# Verificar schedule
kubectl get cronjob postgres-backup-cronjob -n dev -o jsonpath='{.spec.schedule}'
```

### Problema: Restauración Falla

```bash
# Verificar que el archivo de backup existe
kubectl exec backup-browser -n dev -- ls -lh /backups/

# Verificar integridad del backup
kubectl exec backup-browser -n dev -- gzip -t /backups/postgres_backup_*.sql.gz

# Verificar credenciales
kubectl get secret postgres-secret -n dev -o yaml
kubectl get configmap postgres-config -n dev -o yaml
```

## 📊 Monitoreo de Backups

### Métricas a Monitorear

1. **Éxito de Backups**: Jobs completados vs fallidos
2. **Tamaño de Backups**: Crecimiento en el tiempo
3. **Duración**: Tiempo que toma cada backup
4. **Espacio Disponible**: En el PVC de backups

### Dashboard de Prometheus (Queries Útiles)

```promql
# Jobs de backup exitosos (últimas 24 horas)
kube_job_status_succeeded{job_name=~"postgres-backup.*", namespace="dev"}

# Jobs de backup fallidos
kube_job_status_failed{job_name=~"postgres-backup.*", namespace="dev"}

# Espacio usado en PVC
kubelet_volume_stats_used_bytes{persistentvolumeclaim="postgres-backup-pvc"}

# Espacio disponible en PVC
kubelet_volume_stats_available_bytes{persistentvolumeclaim="postgres-backup-pvc"}
```

### Alertas Recomendadas

```yaml
# Alert cuando el backup falla
- alert: PostgreSQLBackupFailed
  expr: kube_job_status_failed{job_name=~"postgres-backup.*"} > 0
  for: 5m
  annotations:
    summary: "PostgreSQL backup failed"
    description: "Backup job {{ $labels.job_name }} has failed"

# Alert cuando el PVC está casi lleno
- alert: PostgreSQLBackupStorageFull
  expr: (kubelet_volume_stats_used_bytes{persistentvolumeclaim="postgres-backup-pvc"} / kubelet_volume_stats_capacity_bytes{persistentvolumeclaim="postgres-backup-pvc"}) > 0.85
  for: 15m
  annotations:
    summary: "PostgreSQL backup storage almost full"
    description: "Backup PVC is {{ $value | humanizePercentage }} full"
```

## 🔐 Mejores Prácticas

### Seguridad

1. **Encriptar Backups**: Considerar encriptar backups en reposo
2. **Control de Acceso**: Solo Service Accounts autorizados
3. **Secrets**: Nunca exponer credenciales en logs
4. **Auditoría**: Registrar quién accede a backups

### Operaciones

1. **Probar Restauración**: Probar restauración regularmente (mensualmente)
2. **Backups Offsite**: Copiar backups críticos fuera del cluster
3. **Documentación**: Mantener procedimientos actualizados
4. **Automatización**: Scripts para tareas comunes
5. **Monitoreo**: Alertas para fallos de backup

### Performance

1. **Ventana de Mantenimiento**: Backups en horarios de baja carga
2. **Recursos Adecuados**: CPU/memoria suficiente para jobs
3. **Compresión**: Siempre comprimir backups (gzip)
4. **Retención**: Balance entre espacio y historial necesario

## 📋 Checklist de Disaster Recovery

### Antes del Desastre

- [ ] Backups automáticos configurados y ejecutándose
- [ ] Últimos 7 backups verificados e íntegros
- [ ] Procedimiento de restauración documentado y probado
- [ ] Equipo entrenado en procedimientos de recuperación
- [ ] Alertas configuradas para fallos de backup

### Durante el Desastre

- [ ] Evaluar magnitud del problema
- [ ] Notificar a stakeholders
- [ ] Identificar último backup íntegro
- [ ] Crear backup actual (si es posible)
- [ ] Detener servicios afectados
- [ ] Ejecutar restauración
- [ ] Verificar integridad de datos restaurados

### Después del Desastre

- [ ] Documentar incidente (postmortem)
- [ ] Verificar funcionamiento de servicios
- [ ] Revisar y mejorar procedimientos
- [ ] Actualizar runbooks
- [ ] Comunicar resultados a equipo

---

**Última actualización**: 25 de noviembre de 2025  
**Responsable**: DevOps Team  
**Contacto de Emergencia**: Check MANUAL-OPERACIONES.md
