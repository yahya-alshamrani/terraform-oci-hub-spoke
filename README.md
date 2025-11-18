# Environment Setup Guide

This project uses Oracle Cloud Infrastructure (OCI) and Terraform.  
You must create an `env.sh` file before running any Terraform commands.  
This file holds the environment variables Terraform needs to authenticate to OCI and store the Terraform state in Object Storage.

## 1. Create the env.sh File

Create a new file named `env.sh` in the project root and add the required environment variables:

- **OCI_TENANCY_OCID**: The OCID of your OCI tenancy.

- **OCI_USER_OCID**: The OCID of the OCI user Terraform should authenticate as.

- **OCI_FINGERPRINT**: The fingerprint of the public API key linked to your user.

- **OCI_PRIVATE_KEY_PATH**: The path to your private API key (pem file).

- **OCI_BUCKET_NAMESPACE**: Your Object Storage namespace.

- **OCI_TF_BUCKET**: The Object Storage bucket where Terraform state will be stored.

- **OCI_REGION**: The region where your resources and bucket exist.

Also add the `tinit` alias to make Terraform initialization easier.

## 2. Example env.sh Content

Below is an example of what your env.sh file should look like.  
Replace all values with your real OCI details:

```bash
export OCI_TENANCY_OCID="your-tenancy-ocid"
export OCI_USER_OCID="your-user-ocid"
export OCI_FINGERPRINT="your-api-key-fingerprint"
export OCI_PRIVATE_KEY_PATH="/path/to/oci_api_key.pem"
export OCI_BUCKET_NAMESPACE="your-namespace"
export OCI_TF_BUCKET="your-terraform-bucket"
export OCI_REGION="your-region"
alias tinit='terraform init \
  -backend-config="namespace=${OCI_NAMESPACE}" \
  -backend-config="bucket=${OCI_TF_BUCKET}" \
  -backend-config="region=${OCI_REGION}" \
  -backend-config="key=terraform/state.tfstate"'
```
## 3. Load the Environment

After creating and updating the file, load it by running:

source env.sh

This will export all variables and register the `tinit` alias.

## 4. Initialize Terraform

Run the Terraform init command using the alias:

tinit

This initializes Terraform using the backend settings you defined in `env.sh`.

---

If you modify the file later, run `source env.sh` again to reload the updated values.
