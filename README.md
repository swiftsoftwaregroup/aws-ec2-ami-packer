# aws-ec2-ami-packer
Build AWS Amazon Machine Image (AMI) with Packer

## Setup for macOS

Make sure you do this setup first:

1. [Setup macOS for AWS Cloud DevOps](https://blog.swiftsoftwaregroup.com/setup-macos-for-aws-cloud-devops)

2. [AWS Authentication](https://blog.swiftsoftwaregroup.com/aws-authentication)

3. Install Packer via Homebrew:

   ```bash
   # install
   brew tap hashicorp/tap
   brew install hashicorp/tap/packer
   
   # verify
   packer -help
   ```

## Development

Configure the project:

```bash
source configure.sh
```

Format configuration:

```bash
packer fmt .
```

Validate configuration:

```bash
packer validate .
```

## Build

```bash
packer build .
```

## Test

This script will launch an instance from the AMI and run tests on it:  

```bash
./test.sh
```

## Cleanup

Deregister the AMI image and delete ALL image snapshots.

```bash
./cleanup.sh
```

## How to create a new project

```bash
# create main.pkr.hcl
cat << 'EOF' > main.pkr.hcl
packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}
EOF

# initialize the project
packer init .
```

