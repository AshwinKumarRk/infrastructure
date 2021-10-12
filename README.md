# infrastructure

## Dependencies
1. AWS CLI
2. User profiles
3. Terraform
## How to Setup and Run
1. cd into the directory of the cloned repository
2. Initialize Terraform with AWS provider plugins
   ```
   terraform init
   ```
3. View the configuration plan before applying changes to resources
   ```
   terraform plan
   ```
4. Apply changes as given in the Terraform configuration files to create or modify resources
   ```
   terraform apply
   ```
5. Destroy the resources created by the Terraform configuration files
   ```
   terraform destroy
   ```