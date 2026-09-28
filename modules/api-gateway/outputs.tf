output "invoke_url" {
  description = "Public HTTPS entry point for TeamOps"
  value       = aws_apigatewayv2_api.web.api_endpoint
}

output "api_id" {
  description = "HTTP API identifier"
  value       = aws_apigatewayv2_api.web.id
}
