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

## Estado Actual

Staging ya está provisionado y validado en AWS:

- [x] Región `us-east-1`, state remoto y Secrets Manager configurados.
- [x] ECR `conquest-api-staging` y App Runner `conquest-api-staging` activos.
- [x] OIDC de GitHub y rol `conquest-github-actions-staging` creados.
- [x] Imagen actual publicada con tag SHA y `staging`.
- [x] Migraciones Prisma aplicadas y `/api/health` validado.
- [x] CORS limitado temporalmente al dominio HTTPS de App Runner.

El workflow de staging está preparado localmente en `olympx-api/.github/workflows/deploy-staging.yml` y es
manual-only. La rama local `staging` queda destinada a QA; `main` se reserva para producción.

Cuando el workflow se publique en GitHub, configurar en el environment `staging`:

- Secret `AWS_ROLE_TO_ASSUME`: output `github_actions_role_arn` del stack staging.
- Variable `AWS_REGION`: valor de `aws_region`.
- Variable `ECR_REPOSITORY`: valor de `ecr_repository_name`.
- Variable `APP_RUNNER_SERVICE_ARN`: output `app_runner_service_arn` del stack staging.

No se activan despliegues automáticos hasta publicar el workflow y configurar explícitamente ese environment.
