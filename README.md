# Guía de Despliegue - Kubernetes + ArgoCD

## Tabla de Contenidos
- [Fase 1: Preparación del Entorno](#fase-1-preparación-del-entorno)
- [Fase 2: Desplegar la Aplicación](#fase-2-desplegar-la-aplicación)
- [Fase 3: Probar la Aplicación](#fase-3-probar-la-aplicación)
- [Fase 4: Instalar ArgoCD](#fase-4-instalar-argocd)
- [Fase 5: Configurar ArgoCD](#fase-5-configurar-argocd-opción-cli)
- [Fase 6: Crear Aplicación en ArgoCD](#fase-6-crear-aplicación-en-argocd)
- [Fase 7: Verificación Final](#fase-7-verificación-final)
- [Comandos Útiles de Mantenimiento](#comandos-útiles-de-mantenimiento)

---

## **FASE 1: Preparación del Entorno**

### 1. Iniciar Minikube
```bash
minikube start
```

### 2. Verificar que el cluster esté funcionando
```bash
kubectl cluster-info
kubectl get nodes
```

---

## **FASE 2: Desplegar la Aplicación**

### 3. Aplicar el ConfigMap
```bash
kubectl apply -f williams-rosas-configmap.yml
```

### 4. Aplicar el Secret
```bash
kubectl apply -f williams-rosas-secret.yml
```

### 5. Desplegar el Backend
```bash
kubectl apply -f williams-rosas-back-deployment.yml
kubectl apply -f williams-rosas-back-service.yml
```

### 6. Desplegar el Frontend
```bash
kubectl apply -f williams-rosas-front-deployment.yml
kubectl apply -f williams-rosas-front-service.yml
```

### 7. Verificar que todos los recursos estén creados
```bash
kubectl get all
```

### 8. Verificar que los pods estén ejecutándose
```bash
kubectl get pods
```

### 9. Verificar los servicios
```bash
kubectl get svc
```

---

## **FASE 3: Probar la Aplicación**

### 10. Obtener la URL del backend
```bash
minikube service williams-rosas-back-service --url
```

### 11. Probar el health check del backend
```bash
curl $(minikube service williams-rosas-back-service --url)/actuator/health
```

**Respuesta esperada:**
```json
{"status":"UP","groups":["liveness","readiness"]}
```

### 12. Obtener la URL del frontend
```bash
minikube service williams-rosas-front-service --url
```

### 13. Abrir el frontend en el navegador
```bash
minikube service williams-rosas-front-service
```

**URLs de acceso:**
- Frontend: `http://192.168.49.2:32000`
- Backend: `http://192.168.49.2:32090`

---

## **FASE 4: Instalar ArgoCD**

### 14. Crear el namespace para ArgoCD
```bash
kubectl create namespace argocd
```

### 15. Instalar ArgoCD
```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 16. Esperar a que todos los pods de ArgoCD estén ejecutándose
```bash
kubectl wait --for=condition=ready pod --all -n argocd --timeout=300s
```

### 17. Verificar que ArgoCD esté ejecutándose
```bash
kubectl get pods -n argocd
```

**Pods esperados:**
- argocd-application-controller
- argocd-dex-server
- argocd-redis
- argocd-repo-server
- argocd-server

### 18. Cambiar el servicio de ArgoCD a NodePort
```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
```

### 19. Obtener la URL del servidor de ArgoCD
```bash
minikube service argocd-server -n argocd --url
```

### 20. Obtener la contraseña inicial de ArgoCD
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

**Credenciales:**
- Usuario: `admin`
- Contraseña: (la que aparece en el comando anterior)

---

## **FASE 5: Configurar ArgoCD (Opción CLI)**

### 21. Instalar ArgoCD CLI
```bash
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```

### 22. Login en ArgoCD
```bash
ARGOCD_SERVER=$(minikube service argocd-server -n argocd --url | head -n1 | sed 's|http://||')
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
argocd login $ARGOCD_SERVER --username admin --password $ARGOCD_PASSWORD --insecure
```

---

## **FASE 6: Crear Aplicación en ArgoCD**

### **Opción A: Crear desde la UI Web**

1. Accede a la URL de ArgoCD (del paso 19)
2. Login con las credenciales del paso 20
3. Click en **"+ NEW APP"**
4. Configuración:
   - **Application Name:** `williams-rosas-app`
   - **Project:** `default`
   - **Sync Policy:** `Automatic`
   - **Self Heal:** ✅ Enabled
   - **Auto Prune:** ✅ Enabled
   - **Repository URL:** `<TU_REPOSITORIO_GIT>`
   - **Revision:** `HEAD` o `main`
   - **Path:** `.` (o la ruta donde están los manifiestos)
   - **Cluster URL:** `https://kubernetes.default.svc`
   - **Namespace:** `default`
5. Click en **"CREATE"**
6. Click en **"SYNC"** para sincronizar

### **Opción B: Crear desde CLI**

**Nota:** Debes tener tus manifiestos en un repositorio Git.

```bash
# 23. Crear la aplicación en ArgoCD
argocd app create williams-rosas-app \
  --repo <TU_REPOSITORIO_GIT> \
  --path . \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --sync-policy automated \
  --auto-prune \
  --self-heal
```

### 24. Sincronizar la aplicación
```bash
argocd app sync williams-rosas-app
```

### 25. Ver el estado de la aplicación
```bash
argocd app get williams-rosas-app
```

---

## **FASE 7: Verificación Final**

### 26. Ver todas las aplicaciones en ArgoCD
```bash
argocd app list
```

### 27. Ver los recursos desplegados
```bash
kubectl get all
```

**Recursos esperados:**
- 8 pods de backend (williams-rosas-back-deployment)
- 8 pods de frontend (williams-rosas-front-deployment)
- 2 servicios (williams-rosas-back-service, williams-rosas-front-service)
- 1 configmap (williams-rosas-configmap)
- 1 secret (williams-rosas-secret)

### 28. Ver los logs de ArgoCD
```bash
kubectl logs -n argocd deployment/argocd-server
```

### 29. Resumen de URLs de acceso
```bash
echo "Frontend: $(minikube service williams-rosas-front-service --url)"
echo "Backend: $(minikube service williams-rosas-back-service --url)"
echo "ArgoCD: $(minikube service argocd-server -n argocd --url)"
```

---

## **Comandos Útiles de Mantenimiento**

### Ver logs de un pod
```bash
kubectl logs <nombre-pod>
kubectl logs -f <nombre-pod>  # Seguir logs en tiempo real
```

### Ver logs de un deployment
```bash
kubectl logs deployment/<nombre-deployment>
```

### Ejecutar comandos dentro de un pod
```bash
kubectl exec -it <nombre-pod> -- /bin/sh
```

### Reiniciar un deployment
```bash
kubectl rollout restart deployment/<nombre-deployment>
```

### Ver el estado de un rollout
```bash
kubectl rollout status deployment/<nombre-deployment>
```

### Ver el historial de un deployment
```bash
kubectl rollout history deployment/<nombre-deployment>
```

### Escalar un deployment
```bash
kubectl scale deployment/<nombre-deployment> --replicas=<numero>
```

### Ver detalles de un recurso
```bash
kubectl describe pod <nombre-pod>
kubectl describe deployment <nombre-deployment>
kubectl describe service <nombre-service>
```

### Ver eventos del cluster
```bash
kubectl get events --sort-by='.lastTimestamp'
```

### ArgoCD - Ver detalles de una aplicación
```bash
argocd app get <nombre-app>
argocd app logs <nombre-app>
argocd app history <nombre-app>
```

### ArgoCD - Sincronizar manualmente
```bash
argocd app sync <nombre-app>
```

### ArgoCD - Eliminar una aplicación
```bash
argocd app delete <nombre-app>
```

---

## **Limpieza de Recursos**

### Eliminar todos los recursos de la aplicación
```bash
kubectl delete -f williams-rosas-front-service.yml
kubectl delete -f williams-rosas-front-deployment.yml
kubectl delete -f williams-rosas-back-service.yml
kubectl delete -f williams-rosas-back-deployment.yml
kubectl delete -f williams-rosas-secret.yml
kubectl delete -f williams-rosas-configmap.yml
```

### Eliminar ArgoCD
```bash
kubectl delete namespace argocd
```

### Detener Minikube
```bash
minikube stop
```

### Eliminar Minikube
```bash
minikube delete
```

---

## **Arquitectura de la Aplicación**

```
┌─────────────────────────────────────────────────────────────┐
│                        Minikube Cluster                      │
│                                                              │
│  ┌────────────────────┐         ┌────────────────────┐     │
│  │   Frontend Pods    │         │   Backend Pods     │     │
│  │  (8 réplicas)      │────────▶│  (8 réplicas)      │     │
│  │  Port: 80          │         │  Port: 9090        │     │
│  └────────────────────┘         └────────────────────┘     │
│           │                              │                  │
│           ▼                              ▼                  │
│  ┌────────────────────┐         ┌────────────────────┐     │
│  │  Front Service     │         │  Back Service      │     │
│  │  NodePort: 32000   │         │  NodePort: 32090   │     │
│  └────────────────────┘         └────────────────────┘     │
│           │                              │                  │
│           └──────────────┬───────────────┘                  │
│                          ▼                                  │
│                 ┌─────────────────┐                         │
│                 │   ConfigMap     │                         │
│                 │     Secret      │                         │
│                 └─────────────────┘                         │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │              ArgoCD (namespace: argocd)             │    │
│  │  - Application Controller                           │    │
│  │  - Repo Server                                      │    │
│  │  - API Server (NodePort)                            │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
                   Git Repository
```

---

## **Troubleshooting**

### Los pods no inician
```bash
kubectl describe pod <nombre-pod>
kubectl logs <nombre-pod>
```

### El servicio no es accesible
```bash
kubectl get endpoints
kubectl describe service <nombre-service>
```

### ArgoCD no sincroniza
```bash
argocd app get <nombre-app>
kubectl logs -n argocd deployment/argocd-application-controller
```

### Problemas con health checks
```bash
kubectl exec -it <nombre-pod> -- wget -qO- http://localhost:<puerto>/<ruta-health>
```

---

## **Notas Importantes**

1. **Repositorio Git:** Para usar ArgoCD, tus manifiestos deben estar en un repositorio Git (GitHub, GitLab, Bitbucket, etc.).

2. **Secrets:** El archivo `williams-rosas-secret.yml` contiene datos sensibles. En producción, considera usar soluciones como:
   - Sealed Secrets
   - External Secrets Operator
   - HashiCorp Vault

3. **ConfigMap:** Si cambias el ConfigMap, debes reiniciar los deployments para que tomen los nuevos valores:
   ```bash
   kubectl rollout restart deployment/<nombre-deployment>
   ```

4. **Imágenes Docker:** Asegúrate de que las imágenes en Docker Hub estén actualizadas:
   - `williams31/ia-assistant-backend:latest`
   - `williams31/frontend-action:latest`

5. **Health Checks:** El backend requiere Spring Boot Actuator configurado correctamente para que los health checks funcionen.

---

## **Recursos Adicionales**

- [Documentación de Kubernetes](https://kubernetes.io/docs/)
- [Documentación de ArgoCD](https://argo-cd.readthedocs.io/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [Spring Boot Actuator](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)
