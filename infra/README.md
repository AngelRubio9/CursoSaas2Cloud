# Infraestructura con Bicep

Este folder define la infraestructura Azure de la app del curso.

Recursos incluidos:

- App Service Plan Free en Windows
- Web App con runtime .NET 10
- Application Insights
- App settings para conectar Application Insights con la Web App

El Resource Group se crea fuera de este template:

```bash
az group create --name CursoAZ --location eastus
```

Validar cambios sin aplicar:

```bash
az deployment group what-if \
  --resource-group CursoAZ \
  --template-file infra/main.bicep \
  --parameters infra/dev.bicepparam
```

Aplicar infraestructura:

```bash
az deployment group create \
  --resource-group CursoAZ \
  --template-file infra/main.bicep \
  --parameters infra/dev.bicepparam
```
