{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.services.polygon-bor;
  polygon-bor = pkgs.callPackage ./package.nix {
    lib = pkgs.lib;
    stdenv = pkgs.stdenv;
    buildGoModule = pkgs.buildGoModule;
    fetchFromGitHub = pkgs.fetchFromGitHub;
    libobjc = pkgs.darwin.libobjc;
    IOKit = pkgs.darwin.IOKit;
  };
in
{
  options = {
    services.polygon-bor = {
      enable = lib.mkEnableOption "Polygon Bor Node";

      chain = lib.mkOption {
        type = lib.types.str;
        default = "mainnet";
        description = "Name of the chain to sync ('amoy', 'mumbai', 'mainnet').";
      };

      authrpc = {
        addr = lib.mkOption {
          type = lib.types.str;
          default = "localhost";
          description = "Listening address for authenticated APIs";
        };
        port = lib.mkOption {
          type = lib.types.int;
          default = 8551;
          description = "Listening port for authenticated APIs";
        };
        vhosts = lib.mkOption {
          type = lib.types.str;
          default = "localhost";
          description = "Comma separated list of virtual hostnames from which to accept requests (server enforced). Accepts '*' wildcard.";
        };
      };

      http = {
        addr = lib.mkOption {
          type = lib.types.str;
          default = "localhost";
          description = "HTTP-RPC server listening interface.";
        };
        api = lib.mkOption {
          type = lib.types.str;
          default = "eth,net,web3,txpool,bor";
          description = "API's offered over the HTTP-RPC interface.";
        };
        corsdomain = lib.mkOption {
          type = lib.types.str;
          default = "localhost";
          description = "Comma separated list of domains from which to accept cross origin requests (browser enforced).";
        };
        ep-requesttimeout = lib.mkOption {
          type = lib.types.str;
          default = "0s";
          description = "Request Timeout for rpc execution pool for HTTP requests.";
        };
        ep-size = lib.mkOption {
          type = lib.types.int;
          default = 40;
          description = "Maximum size of workers to run in rpc execution pool for HTTP requests.";
        };
        port = lib.mkOption {
          type = lib.types.int;
          default = 8545;
          description = "HTTP-RPC server listening port.";
        };
        rpcprefix = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "HTTP path path prefix on which JSON-RPC is served. Use '/' to serve on all paths.";
        };
      };
      
      ws = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable the WS-RPC server.";
        };
        addr = lib.mkOption {
          type = lib.types.str;
          default = "localhost";
          description = "WS-RPC server listening interface.";
        };
        api = lib.mkOption {
          type = lib.types.str;
          default = "net,web3";
          description = "API's offered over the WS-RPC interface.";
        };
        ep-requesttimeout = lib.mkOption {
          type = lib.types.str;
          default = "0s";
          description = "Request Timeout for rpc execution pool for WS requests.";
        };
        ep-size = lib.mkOption {
          type = lib.types.int;
          default = 40;
          description = "Maximum size of workers to run in rpc execution pool for WS requests.";
        };
        origins = lib.mkOption {
          type = lib.types.str;
          default = "localhost";
          description = "Origins from which to accept websockets requests.";
        };
        port = lib.mkOption {
          type = lib.types.int;
          default = 8546;
          description = "WS-RPC server listening port.";
        };
        rpcprefix = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "HTTP path prefix on which JSON-RPC is served. Use '/' to serve on all paths.";
        };
      };

      bor = {
        runheimdall = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Run Heimdall service.";
        };
        runheimdallargs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Additional arguments for the Heimdall executable.";
        };
        useheimdallapp = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Use child heimdall process to fetch data, Only works when bor.runheimdall is true";
        };
      };

      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Additional arguments for the Bor executable.";
      };

      verbosity = lib.mkOption {
        type = lib.types.int;
        default = 3;
        description = "Logging verbosity level (5=trace, 4=debug, 3=info, 2=warn, 1=error, 0=crit).";
      };

      bootNodes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "enode://b8f1cc9c5d4403703fbf377116469667d2b1823c0daf16b7250aa576bacf399e42c3930ccfcb02c5df6879565a2b8931335565f0e8d3f8e72385ecf4a4bf160a@3.36.224.80:30303"
          "enode://8729e0c825f3d9cad382555f3e46dcff21af323e89025a0e6312df541f4a9e73abfa562d64906f5e59c51fe6f0501b3e61b07979606c56329c020ed739910759@54.194.245.5:30303"
        ];
        description = "List of bootnodes to connect to.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.polygon-bor = {
      description = "Polygon Bor Node";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        ExecStart = ''
        ${polygon-bor}/bin/bor server \
          --datadir '/var/lib/polygon/bor/${cfg.chain}' \
          --chain ${cfg.chain} \
          --authrpc.addr ${cfg.authrpc.addr} \
          --authrpc.port ${toString cfg.authrpc.port} \
          --authrpc.vhosts ${cfg.authrpc.vhosts} \
          --http.addr ${cfg.http.addr} \
          --http.api ${cfg.http.api} \
          --http.corsdomain ${cfg.http.corsdomain} \
          --http.ep-requesttimeout ${cfg.http.ep-requesttimeout} \
          --http.ep-size ${toString cfg.http.ep-size} \
          --http.port ${toString cfg.http.port} \
          --http.rpcprefix ${cfg.http.rpcprefix} \
          ${lib.optionalString cfg.ws.enable "--ws"} \
          ${lib.optionalString cfg.ws.enable "--ws.addr ${cfg.ws.addr}"} \
          ${lib.optionalString cfg.ws.enable "--ws.api ${cfg.ws.api}"} \
          ${lib.optionalString cfg.ws.enable "--ws.ep-requesttimeout ${cfg.ws.ep-requesttimeout}"} \
          ${lib.optionalString cfg.ws.enable "--ws.ep-size ${toString cfg.ws.ep-size}"} \
          ${lib.optionalString cfg.ws.enable "--ws.origins ${cfg.ws.origins}"} \
          ${lib.optionalString cfg.ws.enable "--ws.port ${toString cfg.ws.port}"} \
          ${lib.optionalString cfg.ws.enable "--ws.rpcprefix ${cfg.ws.rpcprefix}"} \
          ${lib.optionalString cfg.bor.runheimdall "--bor.runheimdall"} \
          ${lib.optionalString cfg.bor.runheimdall "--bor.runheimdallargs ${lib.escapeShellArgs cfg.bor.runheimdallargs}"} \
          ${lib.optionalString cfg.bor.useheimdallapp "--bor.useheimdallapp"} \
          --bootnodes ${lib.concatStringsSep "," cfg.bootNodes} \
          --verbosity ${toString cfg.verbosity} \
          ${lib.escapeShellArgs cfg.extraArgs}
        '';
        DynamicUser = true;
        Restart = "always";
        RestartSec = 5;
        StateDirectory = "polygon/bor/${cfg.chain}";

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

    networking.firewall.allowedTCPPorts = [ 30303 8545 8546 8547 9091 3001 7071 30301 26656 1317 ];
    networking.firewall.allowedUDPPorts = [ 30303 8545 8546 8547 9091 3001 7071 30301 26656 1317 ];
  };
}