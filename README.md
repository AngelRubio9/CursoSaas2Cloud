# CursoSaas2Cloud

Guia de clase para construir, desplegar y automatizar una aplicacion ASP.NET Core en Azure usando IA como copiloto tecnico.

La idea del curso no es que la IA haga magia. La idea es aprender un ciclo profesional:

```text
Prompt -> Plan -> Ejecucion -> Validacion -> Explicacion -> Commit
```

Cada paso debe terminar con una validacion real: un comando, una URL funcionando, un log visible, un deployment exitoso o un cambio versionado en GitHub.

## Objetivo Del Curso

Al final del curso tendremos:

- Una app ASP.NET Core MVC en .NET 10.
- Autenticacion con ASP.NET Core Identity.
- Deploy en Azure App Service.
- Application Insights conectado.
- Infraestructura definida con Bicep.
- Repositorio GitHub.
- Pipeline de GitHub Actions con OIDC.
- Deploy automatico al hacer push a `main`.

## Arquitectura Final

```text
GitHub Repo
  |
  | push a main
  v
GitHub Actions
  |
  | OIDC login
  v
Azure
  |
  +-- Resource Group: CursoAZ2
      |
      +-- App Service Plan: plan-cursoaz-free-mx2
      +-- Web App: saasia-cursoaz2
      +-- Application Insights: appi-saasia-cursoaz2
```

URL de la app:

```text
https://saasia-cursoaz2.azurewebsites.net
```

## Requisitos

En la maquina local:

```text
.NET 10 SDK
Azure CLI
Git
GitHub CLI
Homebrew, si estas en macOS
Cuenta de Azure
Cuenta de GitHub
Codex / ChatGPT conectado al workspace
```

Comandos utiles para validar:

```bash
dotnet --version
az --version
git --version
gh --version
az account show --output table
gh auth status
```

## Modulo 1: Preparar El Entorno Con IA

Objetivo: validar herramientas, cuentas y acceso.

Prompt sugerido:

```text
Actua como arquitecto cloud y mentor. Quiero crear una app ASP.NET Core .NET 10 y desplegarla en Azure para un curso. Guiame paso a paso, usando comandos concretos, validaciones y explicando que hace cada recurso.
```

Prompt de validacion:

```text
Revisa mi entorno local. Confirma si tengo dotnet, az, git y gh instalados. Si falta algo, dame el comando exacto para instalarlo en macOS con Homebrew.
```

Login en Azure:

```bash
az login
az account list --output table
az account set --subscription "<NOMBRE_O_ID_DE_LA_SUSCRIPCION>"
```

Login en GitHub:

```bash
gh auth login
gh auth status
```

## Modulo 2: Crear La App .NET 10

Objetivo: crear una aplicacion web base con autenticacion.

Comando base:

```bash
dotnet new mvc --auth Individual -n SaaSIAMVC
```

Ejecutar local:

```bash
cd SaaSIAMVC
dotnet run
```

Prompt sugerido:

```text
Crea una app ASP.NET Core MVC en .NET 10 con autenticacion individual. Usa una estructura simple para curso. Luego dime como correrla localmente y que archivos importantes se generaron.
```

Prompt de explicacion:

```text
Explicame la estructura de esta app ASP.NET Core MVC: Program.cs, Controllers, Views, appsettings.json, Identity y Entity Framework.
```

Validacion:

```text
Abrir la URL local
Registrar un usuario
Iniciar sesion
Confirmar que no hay errores
```

## Modulo 3: Primer Deploy Manual A Azure

Objetivo: crear recursos con Azure CLI y desplegar manualmente.

Recursos:

```text
Resource Group
App Service Plan
Web App
```

Prompt de plan:

```text
Conectate a Azure CLI y ayudame a crear un resource group para curso, un App Service Plan Free en Mexico Central y una Web App Windows con runtime .NET 10. No ejecutes nada sin mostrarme primero el plan.
```

Crear resource group:

```bash
az group create \
  --name CursoAZ2 \
  --location eastus
```

Crear App Service Plan:

```bash
az appservice plan create \
  --name plan-cursoaz-free-mx2 \
  --resource-group CursoAZ2 \
  --location mexicocentral \
  --sku F1
```

Crear Web App:

```bash
az webapp create \
  --name saasia-cursoaz2 \
  --resource-group CursoAZ2 \
  --plan plan-cursoaz-free-mx2 \
  --runtime "dotnet:10"
```

Publicar localmente:

```bash
dotnet publish SaaSIAMVC/SaaSIAMVC.csproj \
  -c Release \
  -o /private/tmp/saasia-publish
```

Empaquetar:

```bash
cd /private/tmp/saasia-publish
zip -r /private/tmp/saasia.zip .
```

Desplegar:

```bash
az webapp deploy \
  --resource-group CursoAZ2 \
  --name saasia-cursoaz2 \
  --src-path /private/tmp/saasia.zip \
  --type zip
```

Validar:

```bash
curl -I https://saasia-cursoaz2.azurewebsites.net
```

Resultado esperado:

```text
HTTP/1.1 200 OK
```

## Modulo 4: Observabilidad Con Application Insights

Objetivo: conectar monitoreo y logs.

Prompt sugerido:

```text
Crea Application Insights en el mismo resource group y conectalo a mi Web App. Usa App Settings de Azure, no guardes connection strings en el codigo. Despues reinicia la app y valida que siga respondiendo.
```

Crear Application Insights:

```bash
az monitor app-insights component create \
  --app appi-saasia-cursoaz2 \
  --resource-group CursoAZ2 \
  --location mexicocentral \
  --application-type web \
  --kind web
```

Conectar a Web App:

```bash
az monitor app-insights component connect-webapp \
  --resource-group CursoAZ2 \
  --app appi-saasia-cursoaz2 \
  --web-app saasia-cursoaz2 \
  --enable-profiler false \
  --enable-snapshot-debugger false
```

Agregar log en `HomeController`:

```csharp
_logger.LogInformation("Home page loaded.");
```

Query Kusto para validar:

```kusto
traces
| where message contains "Home page loaded"
| order by timestamp desc
```

## Modulo 5: GitHub Y Buenas Practicas Del Repo

Objetivo: versionar el proyecto sin subir artefactos locales.

Prompt sugerido:

```text
Prepara este proyecto para GitHub. Asegurate de no subir bin, obj, publish, ZIPs ni app.db. Crea un commit inicial y subelo a un repo privado llamado CursoSaas2Cloud.
```

Reglas importantes en `.gitignore`:

```text
bin/
obj/
publish/
*.zip
app.db
```

Crear repo y push:

```bash
gh repo create CursoSaas2Cloud \
  --private \
  --source=. \
  --remote=origin \
  --push
```

## Modulo 6: Infraestructura Como Codigo Con Bicep

Objetivo: representar Azure como codigo.

Estructura:

```text
infra/
  main.bicep
  dev.bicepparam
  README.md
```

Prompt sugerido:

```text
Crea una version simple en Bicep de mi infraestructura actual para curso. Incluye App Service Plan Free Windows, Web App .NET 10, Application Insights, App Settings y HTTPS only. Usa un solo main.bicep y un dev.bicepparam.
```

Compilar:

```bash
az bicep build --file infra/main.bicep
```

Previsualizar cambios:

```bash
az deployment group what-if \
  --resource-group CursoAZ2 \
  --template-file infra/main.bicep \
  --parameters infra/dev.bicepparam
```

Aplicar:

```bash
az deployment group create \
  --resource-group CursoAZ2 \
  --template-file infra/main.bicep \
  --parameters infra/dev.bicepparam
```

## Modulo 7: Recrear Un Ambiente Desde Bicep

Objetivo: demostrar el valor real de IaC.

Prompt sugerido:

```text
Sin tocar el ambiente actual, crea un segundo resource group y despliega toda la infraestructura desde Bicep usando nombres con sufijo 2. Despues publica la app y valida HTTP 200.
```

Validacion:

```bash
az resource list \
  --resource-group CursoAZ2 \
  --output table

curl -I https://saasia-cursoaz2.azurewebsites.net
```

## Modulo 8: GitHub Actions Para CI/CD

Objetivo: desplegar automaticamente al hacer push a `main`.

Archivo:

```text
.github/workflows/deploy-azure.yml
```

El pipeline hace:

```text
checkout
setup .NET 10
restore
publish
azure login con OIDC
deploy a Azure App Service
```

Prompt sugerido:

```text
Crea un workflow de GitHub Actions para desplegar esta app .NET 10 a Azure App Service cuando haga push a main. Usa OIDC, no publish profile ni client secret.
```

Prompt para revisar identidad:

```text
Busca si ya tengo un Service Principal que pueda reutilizar para GitHub Actions OIDC. Verifica si tiene permisos sobre CursoAZ2 y si tiene federated credential para este repo y branch main.
```

Variables necesarias en GitHub:

```text
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
```

## Modulo 9: OIDC Entre GitHub Y Azure

Objetivo: autenticar GitHub Actions sin secretos.

Service Principal usado:

```text
GitHubActionsOIDC
```

Permiso recomendado:

```text
Contributor solo sobre el resource group CursoAZ2
```

Crear federated credential:

```bash
az ad app federated-credential create \
  --id <AZURE_CLIENT_ID> \
  --parameters '{
    "name": "CursoSaas2Cloud-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:AngelRubio9/CursoSaas2Cloud:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

Nota: en algunos tenants GitHub puede enviar un subject con IDs internos. Si el login falla con `AADSTS700213`, copiar el subject exacto del error y agregar una segunda federated credential.

Asignar rol:

```bash
az role assignment create \
  --assignee <AZURE_CLIENT_ID> \
  --role Contributor \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/CursoAZ2
```

Configurar variables en GitHub:

```bash
gh variable set AZURE_CLIENT_ID --repo AngelRubio9/CursoSaas2Cloud --body "<AZURE_CLIENT_ID>"
gh variable set AZURE_TENANT_ID --repo AngelRubio9/CursoSaas2Cloud --body "<AZURE_TENANT_ID>"
gh variable set AZURE_SUBSCRIPTION_ID --repo AngelRubio9/CursoSaas2Cloud --body "<AZURE_SUBSCRIPTION_ID>"
```

## Modulo 10: Probar El Ciclo Completo

Objetivo: cambiar codigo, hacer push y ver Azure actualizarse solo.

Prompt sugerido:

```text
En la Home agrega un modal Bootstrap que diga "Hoy es 15 de julio de 2026". Compila, haz commit, push, espera el pipeline, y valida que el texto aparezca en la URL de Azure.
```

Validar pipeline:

```bash
gh run list \
  --repo AngelRubio9/CursoSaas2Cloud \
  --workflow deploy-azure.yml \
  --limit 3
```

Validar app:

```bash
curl -s https://saasia-cursoaz2.azurewebsites.net | rg "Hoy es 15 de julio de 2026"
```

## Prompts Transversales

Usar estos prompts durante todo el curso.

### Plan Antes De Actuar

```text
Antes de ejecutar comandos, dame un plan corto, los recursos que se van a crear o modificar y los riesgos.
```

### Validar Despues De Actuar

```text
Despues de ejecutar, valida el resultado con Azure CLI, GitHub CLI o curl. No asumas que funciono.
```

### Explicar Como Instructor

```text
Explicame esto como si fuera para alumnos que conocen .NET pero estan aprendiendo Azure. Usa una analogia simple y luego los comandos reales.
```

### Debug

```text
Este comando fallo. Lee el error, identifica la causa probable, dame dos posibles soluciones y ejecuta la mas segura.
```

### Seguridad

```text
Revisa si este paso guarda secretos en codigo, GitHub o logs. Si hay una alternativa sin secretos, recomiendala.
```

### IaC

```text
Convierte este recurso creado manualmente a Bicep simple y explicame cada bloque.
```

### CI/CD

```text
Revisa este workflow de GitHub Actions. Dime que hace cada step y que variables o secrets necesita.
```

## Validaciones Finales

Estado de Azure:

```bash
az webapp show \
  --resource-group CursoAZ2 \
  --name saasia-cursoaz2 \
  --query "{state:state,host:defaultHostName,httpsOnly:httpsOnly}" \
  --output table
```

HTTP:

```bash
curl -I https://saasia-cursoaz2.azurewebsites.net
```

GitHub Actions:

```bash
gh run list \
  --repo AngelRubio9/CursoSaas2Cloud \
  --workflow deploy-azure.yml \
  --limit 5
```

Application Insights:

```kusto
requests
| order by timestamp desc
| take 20
```

```kusto
traces
| order by timestamp desc
| take 20
```

## Limpieza De Recursos

Para evitar costos, eliminar el resource group del curso:

```bash
az group delete \
  --name CursoAZ2 \
  --yes
```

Antes de borrar, validar que no sea un resource group compartido:

```bash
az resource list \
  --resource-group CursoAZ2 \
  --output table
```

## Cierre Del Curso

La historia completa:

```text
1. Crear app .NET 10
2. Ejecutarla localmente
3. Desplegar manualmente con Azure CLI
4. Agregar Application Insights
5. Subir el codigo a GitHub
6. Convertir infraestructura a Bicep
7. Crear un ambiente desde IaC
8. Configurar GitHub Actions con OIDC
9. Hacer push y desplegar automaticamente
10. Validar Azure, logs y pipeline
```

Idea central:

```text
La IA acelera, pero el ingeniero valida.
```
