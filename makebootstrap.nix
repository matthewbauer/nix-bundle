{ arx, maketar }:
{ name, targets, startup }:

arx {
  inherit name startup;
  archive = maketar {
    inherit name targets;
  };
}
