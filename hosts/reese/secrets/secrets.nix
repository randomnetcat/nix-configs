let
  system = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOccenq6rA3lk3UtC0ywkJiiNV+76o6RQsfIQMY8cLw5 root@instance-20211029-1400";
in
{
  "discord-config-agora-prod-msmtp.age".publicKeys = [ system ];

  "tailscale-authkey".publicKeys = [ system ];

  "matrix-secret-config".publicKeys = [ system ];
  "mastodon-smtp-pass".publicKeys = [ system ];
  "mastodon-personal-s3".publicKeys = [ system ];
  "syncoid-id-zfs-rent".publicKeys = [ system ];

  "wiki-ia-keys".publicKeys = [ system ];

  "diplomacy-bot-token".publicKeys = [ system ];
}
