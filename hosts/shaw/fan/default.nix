{ pkgs, config, lib, ... }:

let
  patchedLmSensors = pkgs.lm_sensors.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or []) ++ [
      ./0-fancontrol-remove-check.patch
    ];
  });

  fanConfig = ''
    INTERVAL=10
    DEVPATH=hwmon0=devices/platform/asustor_it87.656 hwmon2=devices/platform/coretemp.0
    DEVNAME=hwmon0=it8625 hwmon2=coretemp
    FCTEMPS= hwmon0/pwm1=hwmon2/temp2_input
    FCFANS= hwmon0/pwm1=hwmon0/fan1_input
    MINTEMP= hwmon0/pwm1=20
    MAXTEMP= hwmon0/pwm1=80
    MINSTART= hwmon0/pwm1=30
    MINSTOP= hwmon0/pwm1=18
    MINPWM=0 hwmon0/pwm1=0
    MAXPWM=255
  '';
in
{
  config = {
    hardware.asustor.enable = true;

    boot.blacklistedKernelModules = [
      "it87"
    ];

    boot.kernelModules = [
      "asustor"
      "asustor_it87"
      "asustor_gpio_it87"
    ];

    systemd.services.fancontrol = {
      serviceConfig = {
        Restart = "on-failure";
        ExecStart = "${lib.getExe' patchedLmSensors "fancontrol"} ${pkgs.writeText "fancontrol.conf" fanConfig}";
      };
    };
  };
}
