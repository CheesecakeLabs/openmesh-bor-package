# Polygon Bor NixOS Module

This NixOS module simplifies the deployment and management of a Polygon Bor node. Bor is the EVM-compatible layer of the Polygon network, ensuring fast and efficient transactions. This README provides detailed instructions for configuring and running the Bor node using this module.

## Features

- Supports multiple chains: `mainnet`, `mumbai`, and `amoy`.
- Configurable HTTP, WebSocket, and gRPC server settings.
- Integrated support for Heimdall services.
- Bootnode management.
- Additional arguments for customization.
- Hardened systemd configuration.

## Installation

1. Add the flake to your NixOS `flake.nix` file (usually stored in `/etc/nixos/flake.nix`).

   ```nix
   {
     inputs = {
       nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
       # Add the polygon-bor flake
       polygon-bor.url = "github:CheesecakeLabs/polygon-bor-nix";
     };

     outputs = { self, nixpkgs, polygon-bor }: {
       nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
         system = "x86_64-linux";
         modules = [
           ./path/to/your/configuration.nix
           # Include the polygon-bor module
           polygon-bor.nixosModules.polygon-bor
         ];
       };
     };
   }
   ```

2. Enable the service and configure options in your `configuration.nix`.

   ```nix
   services.polygon-bor = {
     enable = true;
     chain = "mainnet";
   };
   ```

3. Apply your configuration:

   ```bash
   sudo nixos-rebuild switch
   ```

## Configuration Options

| Option            | Type       | Default                       | Description                                          |
| ----------------- | ---------- | ----------------------------- | ---------------------------------------------------- |
| `enable`          | boolean    | `false`                       | Enable the Polygon Bor service.                      |
| `chain`           | string     | `mainnet`                     | Chain to sync. Options: `mainnet`, `mumbai`, `amoy`. |
| `authrpc.addr`    | string     | `localhost`                   | Listening address for authenticated APIs.            |
| `authrpc.port`    | int        | `8551`                        | Listening port for authenticated APIs.               |
| `authrpc.vhosts`  | string     | `localhost`                   | List of virtual hostnames for requests.              |
| `http.addr`       | string     | `localhost`                   | HTTP-RPC server listening interface.                 |
| `http.port`       | int        | `8545`                        | HTTP-RPC server listening port.                      |
| `http.api`        | string     | `eth,net,web3,txpool,bor`     | APIs available over the HTTP-RPC interface.          |
| `ws.enable`       | boolean    | `false`                       | Enable the WS-RPC server.                            |
| `ws.port`         | int        | `8546`                        | WS-RPC server listening port.                        |
| `grpc.addr`       | string     | `:3131`                       | gRPC server listening interface.                     |
| `bor.heimdall`    | string     | `http://0.0.0.0:1317`         | URL of Heimdall service.                             |
| `bor.runheimdall` | boolean    | `false`                       | Run Heimdall service.                                |
| `bootNodes`       | listOf str | Predefined list of bootnodes. | Bootnodes for network connectivity.                  |
| `verbosity`       | int        | `3`                           | Logging verbosity level (5=trace, 0=critical).       |
| `extraArgs`       | listOf str | `[]`                          | Additional arguments for Bor.                        |

## Firewall Configuration

The module automatically configures the following ports in the NixOS firewall:

- **TCP Ports:** 30303, 8545, 8546, 9091, 3001, 7071, 30301, 26656, 1317
- **UDP Ports:** 30303, 8545, 8546, 9091, 3001, 7071, 30301, 26656, 1317

## Systemd Service

The Bor node is managed as a systemd service with the following features:

- Automatically restarts on failure.
- Runs in a hardened environment with limited privileges.
- Logs output to the system journal.

### Service Configuration

The service uses the following configuration:

- **ExecStart:** Runs the Bor executable with the provided options.
- **DynamicUser:** Ensures the service runs as a non-root user.
- **Hardening:** Includes `PrivateTmp`, `ProtectSystem`, `NoNewPrivileges`, and other settings to enhance security.
- **State Directory:** Stores data under `/var/lib/polygon/bor/<chain>`.

## Example Usage

Here's a complete example of configuring the service for the `mumbai` testnet:

```nix
services.polygon-bor = {
  enable = true;
  chain = "mumbai";
  http.addr = "0.0.0.0";
  http.port = 8545;
  bootNodes = [
    "enode://b8f1cc9c5d4403703fbf377116469667d2b1823c0daf16b7250aa576bacf399e42c3930ccfcb02c5df6879565a2b8931335565f0e8d3f8e72385ecf4a4bf160a@3.36.224.80:30303"
  ];
  extraArgs = ["--syncmode full"];
};
```

## Troubleshooting

- **Service Logs:** Check the logs using `journalctl`.

  ```bash
  journalctl -u polygon-bor.service
  ```

- **Configuration Errors:** Ensure all required options are correctly configured in your `configuration.nix` file.
- **Connectivity Issues:** Verify that the bootnodes and RPC URLs are accessible.

## License

This module is provided under the MIT License. See the LICENSE file for more details.

---

Happy syncing with Polygon Bor!
