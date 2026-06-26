# AWS Windows Free Tier Experiment

This Terraform configuration creates a low-cost Windows EC2 test host for checking whether the SSAFY Race simulator can run without a GPU instance.

This is an experiment. The default `t3.small` is free-tier eligible in the current account, but it may fail to run Unreal/AirSim graphics workloads. If the simulator does not start or no AirSim RPC response is available, switch to a larger CPU instance if allowed or to a GPU instance such as `g4dn.xlarge`.

## Create a Key

```sh
ssh-keygen -t rsa -b 4096 -f ~/.ssh/aws-windows
```

## Configure AWS Credentials

Terraform uses the same AWS credential sources as the AWS CLI. Configure credentials before running `terraform plan` or `terraform apply`.

Access key flow:

```sh
aws configure
aws sts get-caller-identity
```

SSO flow:

```sh
aws configure sso
aws sso login
aws sts get-caller-identity --profile <PROFILE_NAME>
export AWS_PROFILE=<PROFILE_NAME>
```

`aws sts get-caller-identity` must return your AWS account and ARN before Terraform can create the instance.

## Apply

Create the instance:

```sh
terraform init
terraform apply
```

By default, Terraform detects your current public IP and allows only that `/32` for RDP and AirSim RPC.

The instance also enables OpenSSH Server for code deployment from this machine.

## Connect

Use the `public_ip` output for RDP.

The encrypted Administrator password is available with:

```sh
terraform output -raw administrator_password_encrypted
```

Decrypt it with the matching private key using AWS Console, AWS CLI, or an OpenSSL RSA decrypt command.

## Probe AirSim RPC

After RDP login, copy the SSAFY simulator files to the Windows host and start the simulator. Then from the repository root on macOS:

```sh
python3 tools/airsim_rpc_probe.py "$(terraform -chdir=infra/aws-windows-t3 output -raw public_ip)"
```

Expected success output includes `OK getServerVersion`.

## Deploy Local Code

After `terraform apply` completes and Windows finishes first boot, deploy the local Java sources from macOS:

```sh
tools/deploy_windows_code.sh
```

The script copies:

- `Bot_Java/MyCar.java`
- `Bot_Java/TestRunner.java`
- `Bot_Java/DrivingInterface/`

to:

```text
C:\ssafy-race\Bot_Java
```

If `javac` is installed on the Windows host, the script also compiles `MyCar.java` and `TestRunner.java`.

The simulator itself is still a GUI workload. Start `Algo.exe` from the RDP desktop, then use the deployment script to update Java code between runs.

## Deploy From GitHub Actions

The repository includes `.github/workflows/deploy-windows-code.yml` for deploying committed Java code to the Windows host without running a local shell script.

Add these GitHub repository secrets:

```text
WINDOWS_HOST=<terraform output -raw public_ip>
WINDOWS_SSH_PRIVATE_KEY=<contents of ~/.ssh/aws-windows>
AWS_ACCESS_KEY_ID=<AWS access key allowed to edit the EC2 security group>
AWS_SECRET_ACCESS_KEY=<matching AWS secret key>
```

Then run the `Deploy Windows Code` workflow manually, or push changes to `master` that touch:

- `Bot_Java/MyCar.java`
- `Bot_Java/TestRunner.java`
- `Bot_Java/DrivingInterface/**`

The workflow copies the files to `C:\ssafy-race\Bot_Java` and compiles them if `javac` is installed on the Windows host.

The Windows host must already exist. The workflow temporarily opens SSH port `22` for the current GitHub-hosted runner IP, deploys the files, then revokes that temporary rule.

## Cleanup

Stop billing by destroying the instance when the experiment is done:

```sh
terraform destroy
```
