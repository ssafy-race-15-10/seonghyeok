# AWS Windows t3.large Experiment

This Terraform configuration creates a low-cost Windows EC2 test host for checking whether the SSAFY Race simulator can run without a GPU instance.

This is an experiment. `t3.large` may fail to run Unreal/AirSim graphics workloads. If the simulator does not start or no AirSim RPC response is available, switch to a GPU instance such as `g4dn.xlarge`.

## Create a Key

```sh
ssh-keygen -t rsa -b 4096 -f ~/.ssh/aws-windows
```

## Apply

Create the instance:

```sh
terraform init
terraform apply
```

By default, Terraform detects your current public IP and allows only that `/32` for RDP and AirSim RPC.

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

## Cleanup

Stop billing by destroying the instance when the experiment is done:

```sh
terraform destroy
```
