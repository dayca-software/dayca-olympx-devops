# OlympX DevOps

Infraestructura y automatizacion del proyecto OlympX.

## Responsabilidades

- Terraform para AWS, ECR, App Runner e IAM; los valores sensibles se referencian desde Secrets Manager.
- GitHub Actions para CI/CD mediante OIDC, sin access keys permanentes.
- Neon como PostgreSQL administrado.
- App Runner como runtime administrado de la API.
- El contenedor ejecuta `prisma migrate deploy` antes de iniciar NestJS, por lo que las migraciones pendientes se aplican durante el despliegue.

## Estructura

```text
olympx-devops/
├── terraform/
│   ├── modules/ecr/
│   ├── modules/app-runner/
│   ├── modules/github-oidc/
│   └── environments/staging/
└── workflows/
    ├── ci.yml.example
    └── deploy-staging.yml.example
```

## Orden De Uso

1. Crear el bucket remoto de state y su bloqueo.
2. Configurar `terraform.tfvars` desde `terraform.tfvars.example` en `terraform/environments/staging`.
3. Ejecutar una vez `terraform apply -target=module.ecr` para crear el repositorio inicial de staging.
4. Publicar una imagen inicial con el tag `staging` en ECR.
5. Ejecutar `terraform init`, `terraform plan` y `terraform apply` completos desde `terraform/environments/staging`.
6. Copiar los workflows a `.github/workflows/` cuando el rol OIDC esté creado.

No se guardan valores de Secrets Manager, credenciales AWS, URLs privadas de Neon ni archivos `.tfvars` reales en el repositorio.

## Punto De Reanudacion

La activacion queda pausada hasta completar estos prerequisitos:

- [ ] Confirmar la region AWS.
- [ ] Crear el bucket S3 remoto de Terraform con cifrado, versionado y bloqueo.
- [ ] Crear los secrets de `DATABASE_URL` y `JWT_SECRET` de staging en Secrets Manager y registrar sus ARNs.
- [ ] Configurar `github_repository` y activar `github_oidc_enabled` para que Terraform cree el role IAM OIDC.
- [ ] Crear la imagen inicial `staging` en ECR.

Orden de continuacion:

1. Copiar `terraform.tfvars.example` y `backend.hcl.example` dentro de `terraform/environments/staging`.
2. Ejecutar `terraform init -backend-config=backend.hcl`.
3. Ejecutar una sola vez `terraform apply -target=module.ecr` para crear el repositorio inicial.
4. Construir y publicar `olympx-api:staging` usando `olympx-api/Dockerfile` desde la raiz del proyecto.
5. Ejecutar `terraform plan` y `terraform apply` completos para crear App Runner y sus roles de staging.
6. Obtener `github_actions_role_arn` y configurarlo como `AWS_ROLE_TO_ASSUME` en GitHub.
7. Copiar los workflows `.example` a `.github/workflows/` y configurar sus variables protegidas.
8. Ejecutar el primer deploy por GitHub Actions, esperar la aplicación de migraciones y validar `/api/health`.

El bootstrap de ECR y la primera publicación requieren una identidad AWS local temporal con permisos suficientes.
Las credenciales no deben guardarse en el repositorio ni en GitHub; los deploys posteriores deben usar OIDC.

En el environment `staging` de GitHub configurar:

- Secret `AWS_ROLE_TO_ASSUME`: output `github_actions_role_arn` del stack staging.
- Variable `AWS_REGION`: valor de `aws_region`.
- Variable `ECR_REPOSITORY`: valor de `ecr_repository_name`.
- Variable `APP_RUNNER_SERVICE_ARN`: output `app_runner_service_arn` del stack staging.

No ejecutar `terraform apply` ni publicar infraestructura hasta que los cinco prerequisitos estén marcados.
