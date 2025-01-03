{ pkgs, lib, config, inputs, ... }:

{
  # https://devenv.sh/packages/
  packages = [
    pkgs.git
    pkgs.watchexec
    # pkgs.shunit2
  ];

  # https://devenv.sh/languages/
  languages.racket.enable = true;

  # https://devenv.sh/processes/
  processes.code.exec = "code .";
  process.managers.process-compose.settings = {
    processes = {
      test-wait = {
        command = "watchexec -e txt,rkt --timings 'raco test day22-test.rkt'";
        is_tty = true;
      };
    };
  };

  cachix.enable = false;
}
