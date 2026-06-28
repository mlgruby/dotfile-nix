{
  description = "Pinned agent skill and plugin marketplace sources";

  inputs = {
    # Skills
    compound-engineering = {
      url = "github:EveryInc/compound-engineering-plugin";
      flake = false;
    };
    hyperframes-skills = {
      url = "github:heygen-com/hyperframes";
      flake = false;
    };
    mattpocock-skills = {
      url = "github:mattpocock/skills";
      flake = false;
    };
    caveman-skill = {
      url = "github:JuliusBrussee/caveman";
      flake = false;
    };
    everyskill = {
      url = "github:EveryInc/everyskill";
      flake = false;
    };

    # Plugin marketplaces
    claude-plugins-official = {
      url = "github:anthropics/claude-plugins-official";
      flake = false;
    };
    codex-plugin-cc = {
      url = "github:openai/codex-plugin-cc";
      flake = false;
    };
  };

  outputs = _: { };
}
