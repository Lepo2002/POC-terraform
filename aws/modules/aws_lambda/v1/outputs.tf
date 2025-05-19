
output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.function.arn
}

output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.function.function_name
}

output "function_role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.lambda_role.arn
}

output "function_invoke_arn" {
  description = "ARN to be used for invoking Lambda function from API Gateway"
  value       = aws_lambda_function.function.invoke_arn
}
