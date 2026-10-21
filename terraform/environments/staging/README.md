# conquest Staging

Este stack crea únicamente el entorno remoto de staging de la API:

- ECR `conquest-api-staging`.
- App Runner `conquest-api-staging`.
- IAM separado para pull de ECR, lectura de Secrets Manager y despliegue OIDC.
- PostgreSQL Neon externo, conectado mediante los secretos de Secrets Manager.

No contiene credenciales ni ejecuta `terraform apply` automáticamente.

## Requisitos

- Terraform `>= 1.10`.
- AWS CLI autenticado en la cuenta y región correctas.
- Bucket S3 de state ya creado.
- Secretos `DATABASE_URL` y `JWT_SECRET` creados en Secrets Manager.
- Imagen `staging` disponible en ECR antes del primer `apply` completo.

## Bootstrap

Desde `conquest-devops/terraform/environments/staging`:

```bash
cp terraform.tfvars.example terraform.tfvars
cp backend.hcl.example backend.hcl
terraform init -backend-config=backend.hcl
terraform fmt -recursive
terraform validate
terraform apply -target=module.ecr
```

Después de crear ECR, publicar la imagen desde la raíz del workspace:

```bash
docker build -f conquest-api/Dockerfile -t "<ecr-repository-url>:staging" .
docker push "<ecr-repository-url>:staging"
```

Finalmente:

```bash
terraform plan
terraform apply
terraform output app_runner_service_url
```

Las migraciones Prisma se ejecutan en el arranque del contenedor mediante
`conquest-api/deploy/start.sh`. Validar la conexión Neon y el estado de migraciones antes de entregar la
URL al equipo mobile.
