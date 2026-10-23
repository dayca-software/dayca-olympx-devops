# conquest Staging

Este stack crea únicamente el entorno remoto de staging de la API:

- ECR `conquest-api-staging`.
- ECS Express Mode `conquest-api-staging` sobre Fargate.
- IAM separado para ejecución ECS, infraestructura Express, lectura de Secrets Manager y despliegue OIDC.
- CloudWatch Logs `/aws/ecs/conquest-api-staging`.
- PostgreSQL Neon externo, conectado mediante los secretos de Secrets Manager.

No contiene credenciales ni ejecuta `terraform apply` automáticamente.

## Requisitos

- Terraform `>= 1.10`.
- AWS CLI autenticado en la cuenta y región correctas.
- Bucket S3 de state ya creado.
- Secretos `DATABASE_URL` y `JWT_SECRET` creados en Secrets Manager.
- Imagen `staging` disponible en ECR antes del primer `apply` completo.

## Bootstrap

Desde `olympx-devops/terraform/environments/staging`:

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
docker build -f olympx-api/Dockerfile -t "<ecr-repository-url>:staging" .
docker push "<ecr-repository-url>:staging"
```

Finalmente:

```bash
terraform plan
terraform apply
terraform output ecs_express_service_url
```

Las migraciones Prisma se ejecutan en el arranque del contenedor mediante
`olympx-api/deploy/start.sh`. Validar la conexión Neon y el estado de migraciones en
`/aws/ecs/conquest-api-staging` antes de entregar la URL al equipo mobile.

El workflow `olympx-api/.github/workflows/deploy-staging.yml` es manual-only y está restringido a la rama
`staging`. Requiere configurar en el environment `staging` las variables `AWS_REGION`, `ECR_REPOSITORY` y
`ECS_EXPRESS_SERVICE_ARN`, además del secret `AWS_ROLE_TO_ASSUME`.
