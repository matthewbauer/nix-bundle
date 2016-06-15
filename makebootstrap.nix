{makeself, makedir}:

  { name, target, run }:
    makeself {
      inherit name;
      startup = ".${target}${run}";
      archive = makedir {
        name = "${name}-dir";
        toplevel = target;
      };
    }
