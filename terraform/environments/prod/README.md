# Production

Production debe usar un state remoto, secrets, cuenta o role y aprobación separados de `staging`.

Después de validar el entorno `staging`, duplicar su configuración con nombres `olympx-api-prod`, un backend `olympx/prod/terraform.tfstate` y un environment protegido en GitHub Actions.
