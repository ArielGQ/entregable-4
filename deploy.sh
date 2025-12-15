#!/bin/bash
# deploy.sh

echo "Desplegando namespace..."
kubectl apply -f namespace.yaml

echo "Desplegando MongoDB..."
kubectl apply -f mongodb/

echo "Esperando a que MongoDB esté listo..."
kubectl wait --for=condition=ready pod -l app=mongodb -n secure-app --timeout=300s

echo "Desplegando API..."
kubectl apply -f api/

echo "Esperando a que la API esté lista..."
kubectl wait --for=condition=ready pod -l app=api -n secure-app --timeout=300s

echo "Desplegando Frontend..."
kubectl apply -f frontend/

echo "Despliegue completado!"
kubectl get pods -n secure-app