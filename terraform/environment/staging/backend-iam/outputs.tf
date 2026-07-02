output "backend_role_arn" {
  description = "Pod Identity role ARN (unused while IRSA is active)"
  value       = aws_iam_role.backend.arn
}

output "irsa_role_arn" {
  description = "IRSA role ARN - put this in the backend ServiceAccount annotation"
  value       = aws_iam_role.irsa_iam_role.arn
}
