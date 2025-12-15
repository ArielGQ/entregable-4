# Despliegue en Kubernetes

Este directorio contiene los manifiestos de Kubernetes necesarios para desplegar la aplicación segura en un cluster de Kubernetes.

## Orden de Despliegue

Los archivos están numerados (01-, 02-, 03-, etc.) para indicar el orden correcto de aplicación. El orden es importante porque algunos recursos dependen de otros:

1. **Namespace** → Debe crearse primero
2. **MongoDB** → Base de datos (Secret → PVC → Deployment → Service)
3. **API** → Depende de MongoDB (ConfigMap → Secret → Deployment → Service)
4. **Frontend** → Depende de la API (ConfigMap → Deployment → Service)

**Importante**: Siempre despliega MongoDB antes que la API, y la API antes que el Frontend.

## Estructura de Archivos

Los manifiestos están organizados por componente en carpetas separadas, con números al inicio de cada archivo que indican el orden correcto de despliegue:

```
k8s/
├── namespace.yaml                 # Namespace para la aplicación
├── mongodb/                       # Recursos de MongoDB
│   ├── 01-secret.yaml            # Secret con credenciales de MongoDB
│   ├── 02-pvc.yaml               # PersistentVolumeClaim para datos
│   ├── 03-deployment.yaml        # Deployment de MongoDB
│   └── 04-service.yaml           # Service de MongoDB
├── api/                           # Recursos de la API
│   ├── 01-configmap.yaml         # ConfigMap con configuración de la API
│   ├── 02-secret.yaml            # Secret con JWT_SECRET
│   ├── 03-deployment.yaml        # Deployment de la API
│   └── 04-service.yaml           # Service de la API
├── frontend/                      # Recursos del Frontend
│   ├── 01-configmap.yaml         # ConfigMap con configuración del Frontend
│   ├── 02-deployment.yaml        # Deployment del Frontend
│   └── 03-service.yaml           # Service del Frontend (LoadBalancer)
└── README.md                      # Este archivo
```

**Orden de despliegue**: Los números al inicio de cada archivo (01-, 02-, etc.) indican el orden correcto de aplicación. Los recursos deben desplegarse en este orden para evitar dependencias faltantes.

## Prerrequisitos

1. **Cluster de Kubernetes** funcionando (minikube, kind, GKE, EKS, AKS, OCI, etc.)
2. **kubectl** instalado y configurado para conectarse al cluster
3. **Permisos** para crear recursos en el cluster (namespaces, deployments, services, etc.)

## Configuración Inicial

### 1. Actualizar Secrets

**IMPORTANTE**: Antes de desplegar, debes actualizar los valores en los archivos de Secret con valores seguros:

#### `mongodb/01-secret.yaml`
```yaml
data:
  MONGO_INITDB_ROOT_USERNAME: username
  MONGO_INITDB_ROOT_PASSWORD: password
  MONGO_INITDB_DATABASE: dbname
  MONGODB_URI:  mongodb://username:password@mongodb:27017/dbname?authSource=admin
```

#### `api/02-secret.yaml`
```yaml
data:
  JWT_SECRET: SecretoSuperLargoYUnico  # Cambiar por uno seguro
```

**Nota**:
- Todos los valores de `data` están en **base64**. Debes codificar tus propios valores antes de usarlos.
- Actualiza `MONGODB_URI` para que use las mismas credenciales que definas en `MONGO_INITDB_ROOT_USERNAME` y `MONGO_INITDB_ROOT_PASSWORD`.

### 2. Actualizar ConfigMaps (Opcional)

Si necesitas cambiar la configuración de la aplicación, edita los archivos:

- `api/01-configmap.yaml`: Variables de entorno de la API (NODE_ENV, PORT, FRONTEND_URL)
- `frontend/01-configmap.yaml`: Variables de entorno del Frontend (FRONTEND_URL)

### 3. Verificar StorageClass

El `PersistentVolumeClaim` de MongoDB usa `storageClassName: oci-bv` (para Oracle Cloud). Si tu cluster usa un StorageClass diferente, actualiza `mongodb/02-pvc.yaml`:

```yaml
storageClassName: tu-storage-class
```

Si necesitas verificar los StorageClasses disponibles:
```bash
kubectl get storageclass
```

## Despliegue

### Despliegue Completo por Componente

Despliega todos los recursos en orden, siguiendo la numeración de los archivos:

```bash
# 1. Crear el namespace
kubectl apply -f namespace.yaml

# 2. Desplegar MongoDB (en orden numérico)
kubectl apply -f mongodb/01-secret.yaml
kubectl apply -f mongodb/02-pvc.yaml
kubectl apply -f mongodb/03-deployment.yaml
kubectl apply -f mongodb/04-service.yaml

# 3. Desplegar API (en orden numérico)
kubectl apply -f api/01-configmap.yaml
kubectl apply -f api/02-secret.yaml
kubectl apply -f api/03-deployment.yaml
kubectl apply -f api/04-service.yaml

# 4. Desplegar Frontend (en orden numérico)
kubectl apply -f frontend/01-configmap.yaml
kubectl apply -f frontend/02-deployment.yaml
kubectl apply -f frontend/03-service.yaml
```

### Opción 2: Despliegue por Carpeta

```bash
# 1. Crear el namespace
kubectl apply -f namespace.yaml

# 2. Desplegar MongoDB (todos los archivos en orden)
kubectl apply -f mongodb/

# 3. Desplegar API (todos los archivos en orden)
kubectl apply -f api/

# 4. Desplegar Frontend (todos los archivos en orden)
kubectl apply -f frontend/
```

### Opción 3: Script de Despliegue Automático

Puedes usar el script `deploy.sh` para automatizar el despliegue.

Dar permisos de ejecución
```bash
chmod +x deploy.sh
```
Ejecutar el script
```bash
./deploy.sh
```

**Nota**: Asegúrate de haber actualizado los Secrets antes de ejecutar estos comandos. Los archivos se aplican en orden alfabético, por lo que la numeración (01-, 02-, etc.) garantiza el orden correcto dentro de cada carpeta.

## Verificación del Despliegue

### 1. Verificar que los Pods estén corriendo

```bash
kubectl get pods -n secure-app
```

Deberías ver algo como:
```
NAME                        READY   STATUS    RESTARTS   AGE
mongodb-xxxxxxxxxx-xxxxx    1/1     Running   0          2m
api-xxxxxxxxxx-xxxxx        1/1     Running   0          1m
api-xxxxxxxxxx-xxxxx        1/1     Running   0          1m
frontend-xxxxxxxxxx-xxxxx   1/1     Running   0          1m
frontend-xxxxxxxxxx-xxxxx   1/1     Running   0          1m
```

### 2. Verificar los Services

```bash
kubectl get services -n secure-app
```

### 3. Verificar los Secrets y ConfigMaps

```bash
kubectl get secrets -n secure-app
kubectl get configmaps -n secure-app
```

### 4. Ver logs de los Pods

```bash
# Logs de MongoDB
kubectl logs -n secure-app -l app=mongodb

# Logs de la API
kubectl logs -n secure-app -l app=api

# Logs del Frontend
kubectl logs -n secure-app -l app=frontend
```

## Acceso a la Aplicación

### Frontend

El servicio Frontend está configurado como `LoadBalancer`. Para acceder:

1. **Si estás usando un LoadBalancer real:**
   ```bash
   kubectl get service frontend -n secure-app
   ```
   Usa la IP externa mostrada en `EXTERNAL-IP`. Acceder http://EXTERNAL-IP/

2. **Si estás usando minikube**:
   ```bash
   minikube service frontend -n secure-app
   ```

3. **Si estás usando kind o un cluster local**:
   Cambia el tipo de servicio a `NodePort` en `frontend/03-service.yaml`:
   ```yaml
   spec:
     type: NodePort
   ```
   Luego tienes dos opciones para acceder desde el navegador:

   - **Acceso directo por NodePort**
     ```bash
     kubectl get svc frontend -n secure-app
     ```
     Usa `http://<NODE_IP>:<NODE_PORT>` (suele ser `http://localhost:<NODE_PORT>`).

   - **Acceso usando port-forward sobre el Service**
     ```bash
     kubectl port-forward -n secure-app svc/frontend 8080:80
     ```
     Luego accede a `http://localhost:8080`

### API

La API está expuesta internamente en el cluster. Para acceder desde fuera:

1. **Port-forward**
   ```bash
   kubectl port-forward -n secure-app service/api 3000:3000
   ```
   Luego accede a `http://localhost:3000`


### MongoDB

MongoDB está expuesto solo dentro del cluster. Para acceder desde fuera:

```bash
kubectl port-forward -n secure-app service/mongodb 27017:27017
```

Luego conecta usando: `mongodb://localhost:27017`

## Características de Seguridad Implementadas

Los manifiestos incluyen las siguientes características de seguridad:

1. **Security Contexts**:
   - `runAsNonRoot: true` - Los contenedores no se ejecutan como root
   - `readOnlyRootFilesystem: true` - Sistema de archivos raíz de solo lectura
   - `allowPrivilegeEscalation: false` - Sin escalación de privilegios
   - `capabilities.drop: ALL` - Eliminación de todas las capacidades

2. **Separación de Secrets y ConfigMaps**:
   - Credenciales sensibles en Secrets (base64)
   - Configuración no sensible en ConfigMaps

3. **Persistent Volumes**:
   - Datos de MongoDB en un PersistentVolumeClaim

4. **Health Checks**:
   - Liveness y Readiness probes configurados

5. **Resource Limits**:
   - `resources.requests` y `resources.limits` configurados en los deployments de MongoDB, API y Frontend

## Escalado

### Escalar la API

```bash
kubectl scale deployment api -n secure-app --replicas=3
```

### Escalar el Frontend

```bash
kubectl scale deployment frontend -n secure-app --replicas=3
```

**Nota**: MongoDB está configurado con 1 réplica. En producción debemos usar StatefulSet con MongoDB Replica Set.


## Eliminación

Para eliminar todos los recursos:

```bash
# Opción 1: Eliminar por componente (orden inverso a deploy)
kubectl delete -f frontend/
kubectl delete -f api/
kubectl delete -f mongodb/
kubectl delete -f namespace.yaml

# Opción 2: Eliminar el namespace completo (eliminamos todo!)
kubectl delete namespace secure-app
```

**Nota**: Si eliminas el namespace directamente, todos los recursos se eliminarán automáticamente.

**ADVERTENCIA**: Eliminar el namespace eliminará todos los datos, incluyendo el PersistentVolumeClaim de MongoDB. Asegúrate de hacer backup antes.

