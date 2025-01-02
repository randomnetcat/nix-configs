{ config, lib, pkgs, inputs, ... }:

let
  birdsongNetdev = config.systemd.network.netdevs."30-birdsong";
  birdsongPeers = birdsongNetdev.wireguardPeers;
  birdsongInterface = config.birdsong.peering.interface;
in
{
  config = {
    birdsong.peering = {
      enable = true;
      privateKeyCredential = "wireguard-birdsong-key";
      persistentKeepalive = 23;
    };

    environment.systemPackages = [
      pkgs.wireguard-tools
    ];

    systemd.services.systemd-networkd = {
      serviceConfig = {
        LoadCredentialEncrypted = [
          "wireguard-birdsong-key:${./secrets/wireguard-birdsong-key}"
        ];
      };
    };

    systemd.services.networkd-wireguard-reresolve = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      startAt = "*-*-* *:0/2:00";

      serviceConfig = {
        Type = "oneshot";
        RuntimeDirectory = "networkd-wireguard-reresolve";
        RuntimeDirectoryMode = "0700";
        DynamicUser = true;

        StateDirectory = [];

        ExecStart = [
          "+${pkgs.writeShellScript "reresolve-write-output" ''
y           set -eu

            ${lib.escapeShellArgs [ "wg" "show" birdsongInterface "latest-handshakes" ]} > "$RUNTIME_DIRECTORY/wg-output"
          ''}"

          (pkgs.writeShellScript "reresolve-write-timeouts" ''
            set -eu
            id

            time_now="$(date +%s)"

            cat "$RUNTIME_DIRECTORY/wg-output" >&2

            # Output peers that haven't had a handshake in a while, which suggests
            # they might be disconnected.
            {
              while read -r peer handshake; do
                if ! [[ "$handshake" =~ ^[0-9]+$ ]]; then
                  echo "Unexpected handshake format: $handshake" >&2
                  continue
                fi

                time_delta="$(( time_now - handshake ))"

                if [[ "$time_delta" -gt 150 ]]; then
                  echo "$peer"
                fi
              done
            } < "$RUNTIME_DIRECTORY/wg-output" > "$RUNTIME_DIRECTORY/refresh-peers"
          '')

          "+${pkgs.writeShellScript "update-peers" ''
            set -eu

            {
              while IFS="" read -r in_peer; do
                ${lib.concatMapStringsSep "\n" (peer: ''
                  if [[ "$in_peer" = ${lib.escapeShellArg peer.PublicKey} ]]; then
                    echo ${lib.escapeShellArg "Reresolving DNS for peer ${peer.PublicKey} (endpoint: ${peer.Endpoint})"} >&2

                    # Setting the endpoint with the CLI forces reresolution of DNS names.
                    ${lib.escapeShellArgs [
                      "wg"
                      "set"
                      birdsongInterface
                      "peer"
                      peer.PublicKey
                      "endpoint"
                      peer.Endpoint
                    ]}
                  fi
                '') (lib.filter (peer: peer ? Endpoint) birdsongPeers)}
              done
            } < "$RUNTIME_DIRECTORY/refresh-peers"
          ''}"
        ];
      };

      path = [ pkgs.wireguard-tools ];
    };

    assertions = [
      {
        assertion = birdsongNetdev.netdevConfig.Name == birdsongInterface;
        message = "expected configured interface ${birdsongInterface} to match name in netdev ${birdsongNetdev.netdevConfig.Name}; could the module have changed unknowingly?";
      }
    ] ++ (lib.concatMap (peer: [
      {
        assertion = !(lib.hasPrefix "@" peer.PublicKey);
        message = "birdsong peer must have a known public key, but \"${peer.PublicKey}\" is a credential";
      }

      {
        assertion = (peer ? Endpoint) -> !(lib.hasPrefix "@" peer.Endpoint);
        message = "birdsong peer must have a known endpoint, but \"${peer.Endpoint}\" is a credential";
      }
    ]) birdsongPeers);
  };
}
