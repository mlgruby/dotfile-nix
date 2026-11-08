{
  description = "Pinned agent skill and plugin marketplace sources";

  inputs = {
    # Skills
    caveman-skill = {
      url = "github:JuliusBrussee/caveman";
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

  outputs = inputs: {
    sources = removeAttrs inputs [ "self" ];
  };
}
