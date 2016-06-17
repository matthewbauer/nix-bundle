{ arx, maketar }:

  { name, target, run }:
    arx {
      inherit name;
      startup = "${target}${run}";
      archive = maketar {
        inherit name target;
      };
    }
