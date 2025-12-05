#!/bin/bash

# ====================================
# Script de despliegue - CRUD Kubernetes
# Autor: Williams
# ====================================

echo "🚀 Desplegando aplicación CRUD en Kubernetes..."
echo ""

# 1. Crear namespace
echo "📦 Creando namespace williams-namespace..."
kubectl apply -f 01-williams-namespace.yml

echo ""
sleep 2

# 2. Crear deployment
echo "🔧 Creando deployment con 3 réplicas..."
kubectl apply -f 02-williams-deployment.yml

echo ""
sleep 2

# 3. Crear service NodePort
echo "🌐 Creando service NodePort (puerto 30093)..."
kubectl apply -f 03-williams-service.yml

echo ""
sleep 2

# 4. Crear service para port-forward
echo "🔌 Creando service para port-forward (puerto 8094)..."
kubectl apply -f 04-williams-portforward.yml

echo ""
echo "✅ Despliegue completado!"
echo ""

# Esperar a que los pods estén listos
echo "⏳ Esperando a que los pods estén listos..."
kubectl wait --for=condition=ready pod -l app=crud-app -n williams-namespace --timeout=120s

echo ""
echo "📊 Estado de los recursos:"
echo ""
kubectl get all -n williams-namespace

echo ""
echo "🌐 Para acceder a la aplicación:"
echo ""
echo "Opción 1 - NodePort:"
echo "  URL: http://localhost:30093/v1/api/student"
echo "  (Si usas Minikube ejecuta: minikube service williams-service -n williams-namespace)"
echo ""
echo "Opción 2 - Port-Forward:"
echo "  Ejecuta: kubectl port-forward -n williams-namespace service/williams-service-portforward 8094:8094"
echo "  URL: http://localhost:8094/v1/api/student"
echo ""
