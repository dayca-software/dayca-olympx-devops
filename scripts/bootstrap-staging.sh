#!/usr/bin/env bash

set -euo pipefail

AWS_PROFILE="${AWS_PROFILE:-conquest-staging}"
AWS_REGION="${AWS_REGION:-us-east-1}"
EXPECTED_ACCOUNT_ID="${STAGING_ACCOUNT_ID:-932383039890}"
STATE_BUCKET="${STATE_BUCKET:-conquest-staging-tfstate-${EXPECTED_ACCOUNT_ID}}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEVOPS_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
ENV_DIR="${DEVOPS_DIR}/terraform/environments/staging"

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "No se encontró el comando: $1"
}

require_command aws
require_command terraform

[[ -d "$ENV_DIR" ]] || fail "No existe el entorno Terraform: $ENV_DIR"

printf 'Perfil AWS: %s\n' "$AWS_PROFILE"
printf 'Región: %s\n' "$AWS_REGION"
printf 'Cuenta esperada: %s\n' "$EXPECTED_ACCOUNT_ID"
printf 'Bucket de state: %s\n\n' "$STATE_BUCKET"

CALLER_ACCOUNT="$(aws sts get-caller-identity \
  --profile "$AWS_PROFILE" \
  --query 'Account' \
  --output text)"
CALLER_ARN="$(aws sts get-caller-identity \
  --profile "$AWS_PROFILE" \
  --query 'Arn' \
  --output text)"

[[ "$CALLER_ACCOUNT" == "$EXPECTED_ACCOUNT_ID" ]] || fail \
  "El perfil apunta a la cuenta $CALLER_ACCOUNT, no a $EXPECTED_ACCOUNT_ID."
[[ "$CALLER_ARN" != *":root" ]] || fail \
  "El perfil está autenticado como root. Usa IAM Identity Center."

printf 'Identidad validada: %s\n\n' "$CALLER_ARN"

if aws s3api head-bucket \
  --bucket "$STATE_BUCKET" \
  --expected-bucket-owner "$EXPECTED_ACCOUNT_ID" \
  --profile "$AWS_PROFILE" >/dev/null 2>&1; then
  printf 'El bucket de state ya existe.\n'
else
  printf 'Creando bucket de state...\n'
  if [[ "$AWS_REGION" == "us-east-1" ]]; then
    aws s3api create-bucket \
      --bucket "$STATE_BUCKET" \
      --region "$AWS_REGION" \
      --profile "$AWS_PROFILE" >/dev/null
  else
    aws s3api create-bucket \
      --bucket "$STATE_BUCKET" \
      --region "$AWS_REGION" \
      --create-bucket-configuration "LocationConstraint=$AWS_REGION" \
      --profile "$AWS_PROFILE" >/dev/null
  fi
fi

aws s3api put-bucket-versioning \
  --bucket "$STATE_BUCKET" \
  --versioning-configuration Status=Enabled \
  --profile "$AWS_PROFILE"

aws s3api put-bucket-encryption \
  --bucket "$STATE_BUCKET" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' \
  --profile "$AWS_PROFILE"

aws s3api put-public-access-block \
  --bucket "$STATE_BUCKET" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true \
  --profile "$AWS_PROFILE"

BACKEND_FILE="$ENV_DIR/backend.hcl"
if [[ ! -f "$BACKEND_FILE" ]]; then
  cat > "$BACKEND_FILE" <<EOF
bucket       = "$STATE_BUCKET"
key          = "olympx/staging/terraform.tfstate"
region       = "$AWS_REGION"
encrypt      = true
use_lockfile = true
EOF
  printf 'Creado: %s\n' "$BACKEND_FILE"
else
  printf 'Conservado: %s\n' "$BACKEND_FILE"
fi

TFVARS_FILE="$ENV_DIR/terraform.tfvars"
if [[ ! -f "$TFVARS_FILE" ]]; then
  cp "$ENV_DIR/terraform.tfvars.example" "$TFVARS_FILE"
  printf 'Creado desde ejemplo: %s\n' "$TFVARS_FILE"
else
  printf 'Conservado: %s\n' "$TFVARS_FILE"
fi

export AWS_PROFILE
export AWS_REGION

printf '\nInicializando Terraform...\n'
terraform -chdir="$ENV_DIR" init -backend-config="$BACKEND_FILE"
terraform -chdir="$ENV_DIR" validate

cat <<EOF

Bootstrap local terminado.

Antes de aplicar infraestructura:
1. Crea Neon staging.
2. Crea DATABASE_URL y JWT_SECRET en Secrets Manager.
3. Reemplaza los ARNs de esos secretos en:
   $TFVARS_FILE
4. Revisa el plan:
   terraform -chdir="$ENV_DIR" plan

Este script no ejecuta terraform apply, no crea secretos y no publica imágenes.
EOF
