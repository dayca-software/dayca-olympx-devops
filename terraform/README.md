# Terraform

El entorno `staging` crea el primer stack remoto de API:

- Repositorio ECR para la imagen Docker.
- Roles IAM de ejecución de tareas ECS, infraestructura ECS Express y lectura de secrets.
- Servicio ECS Express Mode sobre Fargate con health check `/api/health`.
- Grupo de CloudWatch Logs para las tareas ECS.
- Role GitHub OIDC opcional, limitado al repositorio y environment `staging`.
- Auto scaling limitado para mantener el costo del MVP controlado.

## Requisitos

- Terraform `>= 1.10`.
- AWS CLI configurado localmente para `plan` y `apply`.
- Un repositorio ECR con la imagen `staging` antes del primer `apply` completo.
- Secrets Manager con `DATABASE_URL` y `JWT_SECRET`.

## Comandos

```bash
cd olympx-devops/terraform/environments/staging
cp terraform.tfvars.example terraform.tfvars
cp backend.hcl.example backend.hcl
terraform init -backend-config=backend.hcl
terraform fmt -recursive
terraform validate
```

La primera activación requiere un bootstrap porque ECS Express necesita que exista una imagen en ECR:

```bash
terraform apply -target=module.ecr
docker build -f ../../../../olympx-api/Dockerfile -t "<ecr-repository-url>:staging" ../../../../
docker push "<ecr-repository-url>:staging"
terraform plan
terraform apply
```

`-target=module.ecr` se usa solo una vez para crear el repositorio inicial. Los siguientes cambios deben usar `plan` y `apply` completos.

El bootstrap y el primer push necesitan una identidad AWS local temporal. Después de obtener el output
`github_actions_role_arn`, los deploys deben ejecutarse mediante OIDC desde el environment `staging` de GitHub.

## Prerequisitos Pendientes

- Region AWS confirmada.
- Bucket S3 de state con cifrado, versionado y bloqueo.
- `DATABASE_URL` y `JWT_SECRET` creados en Secrets Manager.
- ARNs de esos secrets cargados en `terraform.tfvars` local.
- `github_repository` configurado y `github_oidc_enabled = true` para crear el role OIDC.
- Imagen `staging` publicada antes del primer `terraform apply` completo.

Después del apply, consultar:

```bash
terraform output ecs_express_service_url
terraform output ecs_express_service_arn
```

El backend remoto es intencionalmente un archivo `.example`: el bucket y su estado deben definirse por ambiente y nunca se deben inventar en este repositorio.
