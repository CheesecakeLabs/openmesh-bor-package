{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.bor;

  inherit (lib)
    mkEnableOption
    mkPackageOption
    mkOption
    types
    mkIf
    ;
in
{
  ###### Interface
  options = {
    services.bor = {
      enable = mkEnableOption "Polygon Bor Node";

      chain = mkOption {
        type = types.str;
        default = "mainnet";
        description = "Name of the chain to sync ('amoy', 'mumbai', 'mainnet') or path to a genesis file.";
      };

      syncmode = mkOption {
        type = types.str;
        default = "full";
        description = "Blockchain sync mode (only 'full' is supported by Bor).";
      };

      gcmode = mkOption {
        type = types.str;
        default = "full";
        description = "Blockchain garbage collection mode.";
      };

      grpc = {
        address = mkOption {
          type = types.str;
          default = "http://localhost:3131";
          description = "Address for the GRPC API.";
        };
      };

      verbosity = mkOption {
        type = types.int;
        default = 3;
        description = "Logging verbosity level (5=trace, 4=debug, 3=info, 2=warn, 1=error, 0=crit).";
      };

      heimdallUrl = mkOption {
        type = types.str;
        default = "http://localhost:1317";
        description = "URL of the Heimdall service.";
      };

      logs = mkOption {
        type = types.bool;
        default = false;
        description = "Enable log retrieval.";
      };

      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Additional arguments for the Bor executable.";
      };

      bootNodes = mkOption {
        type = types.listOf types.str;
        default = [
          "enode://b8f1cc9c5d4403703fbf377116469667d2b1823c0daf16b7250aa576bacf399e42c3930ccfcb02c5df6879565a2b8931335565f0e8d3f8e72385ecf4a4bf160a@3.36.224.80:30303"
          "enode://8729e0c825f3d9cad382555f3e46dcff21af323e89025a0e6312df541f4a9e73abfa562d64906f5e59c51fe6f0501b3e61b07979606c56329c020ed739910759@54.194.245.5:30303"
        ];
        description = "List of bootnodes to connect to.";
      };

      package = mkPackageOption pkgs [ "bor" ] { };
    };
  };

  ###### Implementation
  config = mkIf cfg.enable {

    environment.systemPackages = [ pkgs.bor ];

    systemd.services.bor = {
      stateDir = "polygon/bor/${cfg.chain}";
      dataDir = "/var/lib/${stateDir}";
      description = "Polygon Bor Node";
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
            --bootnodes ${lib.concatStringsSep "," cfg.bootNodes} \
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
    };

  };
}