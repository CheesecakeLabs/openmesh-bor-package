{ config, lib, pkgs, ... }:

let
  eachBor = config.services.bor;

  borOpts = { config, lib, name, ... }: {
    options = {

      enable = lib.mkEnableOption "Polygon Bor Node";

      chain = lib.mkOption {
        type = lib.types.str;
        default = "mainnet";
        description = "Name of the chain to sync ('amoy', 'mumbai', 'mainnet') or path to a genesis file.";
      };

      syncmode = lib.mkOption {
        type = lib.types.str;
        default = "full";
        description = "Blockchain sync mode (only 'full' is supported by Bor).";
      };

      gcmode = lib.mkOption {
        type = lib.types.str;
        default = "full";
        description = "Blockchain garbage collection mode.";
      };

      grpc = {
        address = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1:3131";
          description = "Address for the GRPC API.";
        };
      };

      verbosity = lib.mkOption {
        type = lib.types.int;
        default = 3;
        description = "Logging verbosity level (5=trace, 4=debug, 3=info, 2=warn, 1=error, 0=crit).";
      };

      heimdallUrl = lib.mkOption {
        type = lib.types.str;
        default = "http://localhost:1317";
        description = "URL of the Heimdall service.";
      };

      logs = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable log retrieval.";
      };

      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Additional arguments for the Bor executable.";
      };

      package = lib.mkPackageOption pkgs [ "bor" ] { };
    };
  };

in {
  ###### Interface
  options = {
    services.bor = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule borOpts);
      default = {};
      description = "Specification of one or more Bor node instances.";
    };
  };

  ###### Implementation
  config = lib.mkIf (eachBor != {}) {

    environment.systemPackages = lib.flatten (lib.mapAttrsToList (borName: cfg: [
      cfg.package
    ]) eachBor);

    systemd.services = lib.mapAttrs' (borName: cfg: let
      stateDir = "polygon/bor/${borName}/${cfg.chain}";
      dataDir = "/var/lib/${stateDir}";
    in (
      lib.nameValuePair "bor-${borName}" (lib.mkIf cfg.enable {
        description = "Polygon Bor Node (${borName})";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];

        serviceConfig = {
          ExecStart = ''
            ${cfg.package}/bin/bor server \
              --datadir ${dataDir} \
              --chain ${cfg.chain} \
              --syncmode ${cfg.syncmode} \
              --gcmode ${cfg.gcmode} \
              --grpc.addr ${cfg.grpc.address} \
              --bor.heimdall ${cfg.heimdallUrl} \
              --verbosity ${toString cfg.verbosity} \
              ${lib.optionalString cfg.logs "--log"} \
              ${lib.escapeShellArgs cfg.extraArgs}
          '';
          DynamicUser = true;
          Restart = "always";
          RestartSec = 5;
          StateDirectory = stateDir;

          # Hardening options
          PrivateTmp = true;
          ProtectSystem = "full";
          NoNewPrivileges = true;
          PrivateDevices = true;
          MemoryDenyWriteExecute = true;
          StandardOutput = "journal";
          StandardError = "journal";
          User = "bor";
        };
      })
    )) eachBor;
  };
}