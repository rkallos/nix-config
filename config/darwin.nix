{ config, lib, pkgs, ... }@args:

let home_directory = "/Users/johnw";
    xdg_configHome = "${home_directory}/.config";
    xdg_dataHome = "${home_directory}/.local/share";
    tmp_directory = "/tmp";
    localconfig = import <localconfig>;

in {
  # imports = [ <home-manager/nix-darwin> ];

  system.defaults = {
    NSGlobalDomain = {
      AppleKeyboardUIMode = 3;
      ApplePressAndHoldEnabled = false;
    };

    dock = {
      autohide    = true;
      launchanim  = false;
      orientation = "right";
    };

    trackpad.Clicking = true;
  };

  networking = {
    dns = [ "127.0.0.1" ];
    search = [ "local" ];
    knownNetworkServices = [ "Ethernet" "Wi-Fi" ];
  };

  launchd.daemons =
    let iterate = interval: {
        LowPriorityIO = true;
        Nice = 5;
        StartInterval = interval;
        # StartCalendarInterval.Hour = 3;
        AbandonProcessGroup = true;
      }; in {

    cleanup = {
      script = ''
        export PYTHONPATH=$PYTHONPATH:${pkgs.dirscan}/libexec
        ${pkgs.python2}/bin/python ${pkgs.dirscan}/bin/cleanup -u \
            >> /var/log/cleanup.log 2>&1
      '';
      serviceConfig = iterate 86400;
    };

    limit-maxfiles = {
      command = "/bin/launchctl limit maxfiles 524288 524288";
      serviceConfig.RunAtLoad = true;
    };

    limit-maxproc = {
      command = "/bin/launchctl limit maxproc 2048 2048";
      serviceConfig.RunAtLoad = true;
    };

    pdnsd = {
      script = ''
        cp -pL /etc/pdnsd.conf ${tmp_directory}/.pdnsd.conf
        chmod 700 ${tmp_directory}/.pdnsd.conf
        chown root ${tmp_directory}/.pdnsd.conf
        touch ${home_directory}/.cache/pdnsd/pdnsd.cache
        ${pkgs.pdnsd}/sbin/pdnsd -c ${tmp_directory}/.pdnsd.conf
      '';
      serviceConfig.RunAtLoad = true;
      serviceConfig.KeepAlive = true;
    };
  } //
  (if localconfig.hostname == "athena" then {
    snapshots = {
      script = ''
        export PATH=$PATH:${pkgs.my-scripts}/bin:/usr/local/bin
        date >> /var/log/snapshots.log 2>&1
        snapshots tank
      '';
      serviceConfig = iterate 2700;
    };
   } else {});

  launchd.user.agents =
    let iterate = interval: {
          LowPriorityIO = true;
          Nice = 5;
          StartInterval = interval;
          # StartCalendarInterval.Hour = 3;
          AbandonProcessGroup = true;
        };

        runCommand = command: {
          inherit command;
          serviceConfig.RunAtLoad = true;
          serviceConfig.KeepAlive = true;
        };

    in {

    aria2c = runCommand 
      ("${pkgs.aria2}/bin/aria2c "
        + "--enable-rpc "
        + "--dir ${home_directory}/Downloads "
        + "--log ${xdg_dataHome}/aria2c/aria2c.log "
        + "--check-integrity "
        + "--continue ");

    dovecot = {
      command = "${pkgs.dovecot}/libexec/dovecot/imap -c /etc/dovecot/dovecot.conf";
      serviceConfig.WorkingDirectory = "${pkgs.dovecot}/lib";
      serviceConfig.inetdCompatibility.Wait = "nowait";
      serviceConfig.Sockets.Listeners = {
        SockNodeName = "127.0.0.1";
        SockServiceName = "9143";
      };
    };

    leafnode = {
      command = "${pkgs.leafnode}/sbin/leafnode "
        + "-d ${home_directory}/Messages/Newsdir "
        + "-F ${home_directory}/Messages/leafnode/config";
      serviceConfig.WorkingDirectory = "${pkgs.dovecot}/lib";
      serviceConfig.inetdCompatibility.Wait = "nowait";
      serviceConfig.Sockets.Listeners = {
        SockNodeName = "127.0.0.1";
        SockServiceName = "9119";
      };
    };

    locate = {
      script = ''
        export PATH=${pkgs.findutils}/bin:$PATH
        export HOME=${home_directory}
        if [[ ! -d ${xdg_dataHome}/locate ]]; then
            mkdir ${xdg_dataHome}/locate
        fi
        date >> ${xdg_dataHome}/locate/locate.log 2>&1
        ${pkgs.my-scripts}/bin/update.locate \
            >> ${xdg_dataHome}/locate/locate.log 2>&1
      '';
      serviceConfig = iterate 86400;
    };

    rdm = rec {
      script = ''
        ${pkgs.rtags}/bin/rdm \
            --verbose \
            --launchd \
            --inactivity-timeout 300 \
            --socket-file ${serviceConfig.Sockets.Listeners.SockPathName}
            --log-file ${xdg_dataHome}/rdm/rtags.launchd.log
      '';
      serviceConfig.Sockets.Listeners.SockPathName
        = "${home_directory}/.cache/rdm/socket";
    };

    haproxy = runCommand "${pkgs.haproxy}/bin/haproxy -- /etc/haproxy.conf";

    privoxy1 = runCommand "${pkgs.privoxy}/bin/privoxy --no-daemon /etc/privoxy/config1";
    privoxy2 = runCommand "${pkgs.privoxy}/bin/privoxy --no-daemon /etc/privoxy/config2";
    privoxy3 = runCommand "${pkgs.privoxy}/bin/privoxy --no-daemon /etc/privoxy/config3";
    privoxy4 = runCommand "${pkgs.privoxy}/bin/privoxy --no-daemon /etc/privoxy/config4";
    privoxy5 = runCommand "${pkgs.privoxy}/bin/privoxy --no-daemon /etc/privoxy/config5";
    privoxy6 = runCommand "${pkgs.privoxy}/bin/privoxy --no-daemon /etc/privoxy/config6";
    privoxy7 = runCommand "${pkgs.privoxy}/bin/privoxy --no-daemon /etc/privoxy/config7";
    privoxy8 = runCommand "${pkgs.privoxy}/bin/privoxy --no-daemon /etc/privoxy/config8";
    privoxy9 = runCommand "${pkgs.privoxy}/bin/privoxy --no-daemon /etc/privoxy/config9";

    tor1 = runCommand "${pkgs.tor}/bin/tor -f /etc/torrc1";
    tor2 = runCommand "${pkgs.tor}/bin/tor -f /etc/torrc2";
    tor3 = runCommand "${pkgs.tor}/bin/tor -f /etc/torrc3";
    tor4 = runCommand "${pkgs.tor}/bin/tor -f /etc/torrc4";
    tor5 = runCommand "${pkgs.tor}/bin/tor -f /etc/torrc5";
    tor6 = runCommand "${pkgs.tor}/bin/tor -f /etc/torrc6";
    tor7 = runCommand "${pkgs.tor}/bin/tor -f /etc/torrc7";
    tor8 = runCommand "${pkgs.tor}/bin/tor -f /etc/torrc8";
    tor9 = runCommand "${pkgs.tor}/bin/tor -f /etc/torrc9";
  } //
  (if localconfig.hostname == "athena" then {
     # b2-sync = {
     #   script = ''
     #     export PATH=$PATH:${pkgs.my-scripts}/bin
     #     export PATH=$PATH:${pkgs.backblaze-b2}/bin
     #     export PATH=$PATH:${pkgs.rclone}/bin
     #     if [[ -d /Volumes/tank/Backups ]]; then
     #         ${pkgs.my-scripts}/bin/b2-sync /Volumes/tank tank \
     #             >> /var/log/b2-sync.log 2>&1
     #     fi
     #   '';
     #   serviceConfig = iterate 86400;
     # };
   }
   else if localconfig.hostname == "vulcan" then {
     znc = runCommand "${pkgs.znc}/bin/znc -f -d ${xdg_configHome}/znc";
   } else {});

  system.activationScripts.postActivation.text = ''
    chflags nohidden ${home_directory}/Library

    sudo launchctl load -w \
        /System/Library/LaunchDaemons/com.apple.atrun.plist > /dev/null 2>&1 \
        || exit 0

    cp -pL /etc/DefaultKeyBinding.dict \
       ${home_directory}/Library/KeyBindings/DefaultKeyBinding.dict
  '';

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = false;
      allowUnsupportedSystem = false;

      # jww (2020-03-02): Support for OpenSSL 1.0.2 ended with 2019.
      permittedInsecurePackages = [
        "openssl-1.0.2u"
      ];
    };

    overlays =
      let path = ../overlays; in with builtins;
      map (n: import (path + ("/" + n)))
          (filter (n: match ".*\\.nix" n != null ||
                      pathExists (path + ("/" + n + "/default.nix")))
                  (attrNames (readDir path)))
        ++ [ (import ./envs.nix) ];
  };

  environment =
    let
    privoxyConf = name: port: ''
      user-manual ${pkgs.privoxy}/share/doc/privoxy/user-manual/
      confdir ${pkgs.privoxy}/etc
      logdir ${xdg_dataHome}/privoxy
      actionsfile /etc/privoxy/match-all.action
      actionsfile default.action
      actionsfile user.action
      filterfile default.filter
      filterfile user.filter
      logfile ${name}.log
      listen-address 127.0.0.1:${port}
      toggle 1
      enable-remote-toggle 0
      enable-remote-http-toggle 0
      enable-edit-actions 0
      enforce-blocks 0
      buffer-limit 4096
      enable-proxy-authentication-forwarding 0
      forwarded-connect-retries 0
      accept-intercepted-requests 0
      allow-cgi-request-crunching 0
      split-large-forms 0
      keep-alive-timeout 5
      tolerate-pipelining 1
      socket-timeout 300
      debug 1
      forward-socks5t / 127.0.0.1:9050 .
      forward 192.168.*.*/ .
      forward 10.*.*.*/ .
      forward 127.*.*.*/ .
      forward localhost/ .
    '';

    torConf = name: port: ''
      SOCKSPort 127.0.0.1:${port}
      SOCKSPolicy accept 127.0.0.1/32
      SOCKSPolicy reject *
      Log notice file ${xdg_dataHome}/tor/${name}.log
      DataDirectory ${xdg_dataHome}/tor/${name}
    '';

    in {
    systemPackages = import ./packages.nix { inherit pkgs; };

    systemPath = [
      "/Applications/Docker.app/Contents/Resources/bin"
    ];

    variables = {
      HOME_MANAGER_CONFIG = "${home_directory}/src/nix/config/home.nix";

      MANPATH = [
        "${home_directory}/.nix-profile/share/man"
        "${home_directory}/.nix-profile/man"
        "${config.system.path}/share/man"
        "${config.system.path}/man"
        "/usr/local/share/man"
        "/usr/share/man"
        "/Developer/usr/share/man"
        "/usr/X11/man"
      ];

      LC_CTYPE     = "en_US.UTF-8";
      LESSCHARSET  = "utf-8";
      LEDGER_COLOR = "true";
      PAGER        = "less";

      TERM = "xterm-256color";
    };

    shellAliases = {
      rehash = "hash -r";
    };

    pathsToLink = [ "/info" "/etc" "/share" "/include" "/lib" "/libexec" ];

    etc."dovecot/dovecot.conf".text = ''
      default_login_user = johnw
      default_internal_user = johnw
      auth_mechanisms = plain
      disable_plaintext_auth = no
      lda_mailbox_autocreate = yes
      log_path = syslog
      mail_gid = 20
      mail_location = mdbox:${home_directory}/Messages/Mailboxes
      mail_plugin_dir = ${config.system.path}/lib/dovecot
      mail_plugins = fts fts_lucene zlib
      mail_uid = 501
      postmaster_address = postmaster@newartisans.com
      protocols = imap
      sendmail_path = ${pkgs.msmtp}/bin/sendmail
      ssl = no
      syslog_facility = mail

      protocol lda {
        mail_plugins = $mail_plugins sieve
      }
      userdb {
        driver = prefetch
      }

      passdb {
        driver = static
        args = uid=501 gid=20 home=${home_directory} password=pass
      }

      namespace {
        type = private
        separator = .
        prefix =
        location =
        inbox = yes
        subscriptions = yes
      }

      service auth {
        unix_listener auth-userdb {
          mode = 0644
          user = johnw
          group = johnw
        }
      }

      plugin {
        fts = lucene
        fts_squat = partial=4 full=10

        fts_lucene = whitespace_chars=@.
        fts_autoindex = yes

        zlib_save_level = 6
        zlib_save = gz
      }
      plugin {
        sieve_extensions = +editheader
        sieve = ${home_directory}/Messages/dovecot.sieve
        sieve_dir = ${home_directory}/Messages/sieve
      }
    '';

    etc."pdnsd.conf".text = ''
      global {
          perm_cache   = 8192;
          cache_dir    = "${home_directory}/.cache/pdnsd";
          server_ip    = 127.0.0.1;
          status_ctl   = on;
          query_method = udp_tcp;
          min_ttl      = 1h;    # Retain cached entries at least 1 hour.
          max_ttl      = 4h;    # Four hours.
          timeout      = 10;    # Global timeout option (10 seconds).
          udpbufsize   = 1024;  # Upper limit on the size of UDP messages.
          neg_rrs_pol  = on;
          par_queries  = 4;
          debug        = on;
      }

      server {
          label       = "google";
          ip          = 8.8.8.8, 8.8.4.4;
          preset      = on;
          uptest      = none;
          edns_query  = yes;
          exclude     = ".local";
          include     = "vpn.dfinity.systems";
          exclude     = ".dfinity.build";
          exclude     = ".dfinity.internal";
          purge_cache = off;
      }

      server {
          label       = "DFINITY";
          ip          = 10.20.13.192;
          preset      = off;
          uptest      = ping;
          edns_query  = yes;
          lean_query  = yes;
          exclude     = "vpn.dfinity.systems";
          include     = ".dfinity.build";
          include     = ".dfinity.internal";
          proxy_only  = on;
          purge_cache = off;
      }

      server {
          label       = "dyndns";
          ip          = 216.146.35.35, 216.146.36.36;
          preset      = on;
          uptest      = none;
          edns_query  = yes;
          exclude     = ".local";
          include     = "vpn.dfinity.systems";
          exclude     = ".dfinity.build";
          exclude     = ".dfinity.internal";
          purge_cache = off;
      }

      # The servers provided by OpenDNS are fast, but they do not reply with
      # NXDOMAIN for non-existant domains, instead they supply you with an
      # address of one of their search engines. They also lie about the
      # addresses of the search engines of google, microsoft and yahoo. If you
      # do not like this behaviour the "reject" option may be useful.
      server {
          label       = "opendns";
          ip          = 208.67.222.222, 208.67.220.220;
          # You may need to add additional address ranges here if the addresses
          # of their search engines change.
          reject      = 208.69.32.0/24,
                        208.69.34.0/24,
                        208.67.219.0/24;
          preset      = on;
          uptest      = none;
          edns_query  = yes;
          exclude     = ".local";
          include     = "vpn.dfinity.systems";
          exclude     = ".dfinity.build";
          exclude     = ".dfinity.internal";
          purge_cache = off;
      }

      # This section is meant for resolving from root servers.
      server {
          label             = "root-servers";
          root_server       = discover;
          ip                = 198.41.0.4, 192.228.79.201;
          randomize_servers = on;
          exclude           = ".local";
          include           = "vpn.dfinity.systems";
          exclude           = ".dfinity.build";
          exclude           = ".dfinity.internal";
      }

      source {
          owner         = localhost;
          serve_aliases = on;
          file          = "/etc/hosts";
      }

      rr {
          name    = localhost;
          reverse = on;
          a       = 127.0.0.1;
          owner   = localhost;
          soa     = localhost,root.localhost,42,86400,900,86400,86400;
      }

      rr { name = localunixsocket;       a = 127.0.0.1; }
      rr { name = localunixsocket.local; a = 127.0.0.1; }
      rr { name = bugs.ledger-cli.org;   a = 192.168.128.132; }

      neg {
          name  = doubleclick.net;
          types = domain;           # This will also block xxx.doubleclick.net, etc.
      }

      neg {
          name  = bad.server.com;   # Badly behaved server you don't want to connect to.
          types = A,AAAA;
      }
    '';

    etc."haproxy.conf".text = ''
      global
          maxconn 4096
          ulimit-n 65536
          quiet
          nbproc 1
          nbthread 16
          user johnw
          group staff

      defaults
          retries 3
          option redispatch
          maxconn 2000
          timeout connect 5s
          timeout client 5s
          timeout server 5s

      listen privoxytor
          bind :8118
          mode tcp
          balance roundrobin

          server privoxy1 127.0.0.1:8119
          server privoxy2 127.0.0.1:8129
          server privoxy3 127.0.0.1:8139
          server privoxy4 127.0.0.1:8149
          server privoxy5 127.0.0.1:8159
          server privoxy6 127.0.0.1:8169
          server privoxy7 127.0.0.1:8179
          server privoxy8 127.0.0.1:8189
          server privoxy9 127.0.0.1:8199

      listen socks
          bind :9050
          mode tcp
          balance roundrobin

          server tor1 127.0.0.1:9051
          server tor2 127.0.0.1:9061
          server tor3 127.0.0.1:9071
          server tor4 127.0.0.1:9081
          server tor5 127.0.0.1:9091
          server tor6 127.0.0.1:9101
          server tor7 127.0.0.1:9111
          server tor8 127.0.0.1:9121
          server tor9 127.0.0.1:9131
    '';

    etc."privoxy/config1".text = privoxyConf "privoxy1" "8119";
    etc."privoxy/config2".text = privoxyConf "privoxy2" "8129";
    etc."privoxy/config3".text = privoxyConf "privoxy3" "8139";
    etc."privoxy/config4".text = privoxyConf "privoxy4" "8149";
    etc."privoxy/config5".text = privoxyConf "privoxy5" "8159";
    etc."privoxy/config6".text = privoxyConf "privoxy6" "8169";
    etc."privoxy/config7".text = privoxyConf "privoxy7" "8179";
    etc."privoxy/config8".text = privoxyConf "privoxy8" "8189";
    etc."privoxy/config9".text = privoxyConf "privoxy9" "8199";

    etc."privoxy/match-all.action".text = ''
      {+change-x-forwarded-for{block} \
       +client-header-tagger{css-requests} \
       +client-header-tagger{image-requests} \
       +client-header-tagger{range-requests} \
       +deanimate-gifs{last} \
       +filter{refresh-tags} \
       +filter{img-reorder} \
       +filter{banners-by-size} \
       +filter{webbugs} \
       +filter{jumping-windows} \
       +filter{ie-exploits} \
       +hide-from-header{block} \
       +hide-referrer{conditional-block} \
       +session-cookies-only \
       +set-image-blocker{pattern} \
      }
      / # Match all URLs
    '';

    etc."torrc1".text = torConf "tor1" "9051";
    etc."torrc2".text = torConf "tor2" "9061";
    etc."torrc3".text = torConf "tor3" "9071";
    etc."torrc4".text = torConf "tor4" "9081";
    etc."torrc5".text = torConf "tor5" "9091";
    etc."torrc6".text = torConf "tor6" "9101";
    etc."torrc7".text = torConf "tor7" "9111";
    etc."torrc8".text = torConf "tor8" "9121";
    etc."torrc9".text = torConf "tor9" "9131";

    etc."DefaultKeyBinding.dict".text = ''
      {
        "~f"    = "moveWordForward:";
        "~b"    = "moveWordBackward:";

        "~d"    = "deleteWordForward:";
        "~^h"   = "deleteWordBackward:";
        "~\010" = "deleteWordBackward:";    /* Option-backspace */
        "~\177" = "deleteWordBackward:";    /* Option-delete */

        "~v"    = "pageUp:";
        "^v"    = "pageDown:";

        "~<"    = "moveToBeginningOfDocument:";
        "~>"    = "moveToEndOfDocument:";

        "^/"    = "undo:";
        "~/"    = "complete:";

        "^g"    = "_cancelKey:";
        "^a"    = "moveToBeginningOfLine:";
        "^e"    = "moveToEndOfLine:";

        "~c"	  = "capitalizeWord:"; /* M-c */
        "~u"	  = "uppercaseWord:";	 /* M-u */
        "~l"	  = "lowercaseWord:";	 /* M-l */
        "^t"	  = "transpose:";      /* C-t */
        "~t"	  = "transposeWords:"; /* M-t */
      }
    '';
  };

  services = {
    nix-daemon.enable = false;
    activate-system.enable = true;
  };

  nix = {
    package = pkgs.nixStable;

    useDaemon = false;

    useSandbox = false;
    sandboxPaths = [
      "/System/Library/Frameworks"
      "/System/Library/PrivateFrameworks"
      "/usr/lib"
      "/private/tmp"
      "/private/var/tmp"
      "/usr/bin/env"
    ];

    nixPath = [
      "darwin-config=$HOME/src/nix/config/darwin.nix"
      "home-manager=$HOME/src/nix/home-manager"
      "darwin=$HOME/src/nix/darwin"
      "nixpkgs=$HOME/src/nix/nixpkgs"
      "ssh-config-file=$HOME/.ssh/config"
      "ssh-auth-sock=${xdg_configHome}/gnupg/S.gpg-agent.ssh"
    ];

    trustedUsers = [ "johnw" "@admin" ];

    binaryCaches = [
    ];
    binaryCachePublicKeys = [
      "newartisans.com:RmQd/aZOinbJR/G5t+3CIhIxT5NBjlCRvTiSbny8fYw="
      "cache.dfinity.systems-1:IcOn/2SVyPGOi8i3hKhQOlyiSQotiOBKwTFmyPX5YNw="
      "hydra.dfinity.systems-2:KMTixHrh9DpAjF/0xU/49VEtNuGzQ71YaVIUSOLUaCM="
    ];

    extraOptions = ''
      secret-key-files = ${xdg_configHome}/gnupg/nix-signing-key.sec
    '';
  } //
  (let zrh-3 = {
         hostName = "zrh-3";
         sshUser = "johnw";
         sshKey = "${xdg_configHome}/ssh/id_dfinity";
         system = "x86_64-linux";
         maxJobs = 16;
         buildCores = 4;
         speedFactor = 4;
         supportedFeatures = [ "kvm" ];
       };
       vulcan = {
         hostName = "vulcan";
         sshUser = "johnw";
         sshKey = "${xdg_configHome}/ssh/id_local";
         system = "x86_64-darwin";
         maxJobs = 20;
         buildCores = 10;
         speedFactor = 4;
       }; in
   if localconfig.hostname == "hermes" then rec {
     maxJobs = 16;
     buildCores = 8;
     distributedBuilds = true;

     buildMachines = [
       # vulcan
       zrh-3
     ];

     requireSignedBinaryCaches = false;
     binaryCaches = [
       ssh://vulcan
       https://nix.dfinity.systems
     ];
   }
   else if localconfig.hostname == "athena" then rec {
     maxJobs = 8;
     buildCores = 4;
     distributedBuilds = true;

     buildMachines = [
       # vulcan
       zrh-3
     ];

     requireSignedBinaryCaches = false;
     binaryCaches = [
       ssh://vulcan
     ];
   }
   else if localconfig.hostname == "vulcan" then rec {
     maxJobs = 20;
     buildCores = 10;
     distributedBuilds = true;

     buildMachines = [
       zrh-3
     ];

     binaryCaches = [
       https://nix.dfinity.systems
     ];
   }
   else {});

  programs.bash.enable = true;

  programs.zsh = {
    enable = true;
    enableFzfCompletion = true;
    enableFzfGit = true;
    enableFzfHistory = true;
    enableSyntaxHighlighting = true;
  };

  programs.nix-index.enable = true;

  system.stateVersion = 2;

  # users.users.johnw = {
  #   name = "johnw";
  #   home = "/Users/johnw";
  #   shell = pkgs.zsh;
  # };

  # home-manager = {
  #   useUserPackages = true;
  #   users.johnw = import ./home.nix;
  # };
}
