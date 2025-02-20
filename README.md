# Grist-Pack: an all-in-one packaging of Grist for cloud providers

This is a [Packer](https://developer.hashicorp.com/packer/docs/intro) build of Grist that generates virtual machine images for cloud providers. Currently Amazon Web Services and DigitalOcean are supported. The generated images will have a `grist` user that is mostly setup to run Grist via [Docker Compose](https://docs.docker.com/compose/).

## Building the virtual machine images

Follow these steps to build AMIs for AWS and Snapshots for DigitalOcean (DO).

1. [Install Packer](https://developer.hashicorp.com/packer/install)
2. Clone this repository: `git clone https://github.com/gristlabs/grist-pack.git`
3. Initialise packer: `cd grist-pack && packer init .`

You now need to obtain credentials for AWS, DO, and/or Azure.

1. For AWS, you need to [obtain an access key with its corresponding secret](https://developer.hashicorp.com/packer/integrations/hashicorp/amazon#authentication).
    * [Using IAM](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)
    * [Using the root account](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_root-user_manage_add-key.html)
2. For DO, you will need [a token](https://docs.digitalocean.com/reference/api/create-personal-access-token/)
3. For Azure, you need to create [a tenant](https://learn.microsoft.com/en-us/entra/fundamentals/create-new-tenant), add [a subscription](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/considerations/fundamental-concepts#azure-subscription-purposes) to it, and then create [a client application](https://learn.microsoft.com/en-us/azure/healthcare-apis/register-application) with sufficient permissions to create virtual machine images (usually, the Contributor role is sufficient).

Create a file called `grist.auto.pkrvars.hcl` and add those secrets. Only cloud providers for which all of the secrets are provided will have a virtual machine image built. For example:

```sh
echo '
aws_access_key = "XXXXXXXXXXXXXXXXXXXX"
aws_secret_key = "YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY"

do_token = "dop_v1_zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"

azure_tenant_id       = "00000000-0000-0000-0000-000000000000"
azure_subscription_id = "11111111-1111-1111-1111-111111111111"
azure_client_id       = "22222222-2222-2220-2222-222222222222"
azure_client_secret   = "AAAAA~AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
' > grist.auto.pkrvars.hcl
```

You are now ready to build the images:

```sh
packer build .
```

This should take a few minutes and generate in parallel two images, one for AWS and one for DO. Both images will be named `grist-marketplace-${timestamp}`. If it completes successfully, it will write the resulting IDs of each image to a `manifest.json` file in the local directory. You can now go into your AWS console to inspect the resulting AMI or to your DO dashboard and see the new snapshot. You may further launch virtual machines as normal via the usual means for each cloud provider.

## Updating the images

The Packer configuration can be found in the `grist.pkr.hcl` file. Two variables are defined there for choosing the base image and for generating the AMI or snapshot: `aws_image_filter` and `do_image` – for AWS and DO, respectively. These variables can be overridden [via the usual method for Packer variables](https://developer.hashicorp.com/packer/docs/templates/hcl_templates/variables#assigning-values-to-input-variables) in order to pick different base images to build from.

For DO, note that `scripts/digitalocean-img-check`, a linting script, has a hardcoded list of allowed base images. This script should be updated from its upstream source whenever DO updates the allowed list.
