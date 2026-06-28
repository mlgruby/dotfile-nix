# home-manager/modules/pi.nix
#
# Pi Coding Agent local provider configuration.
#
# Pi reads custom model providers from ~/.pi/agent/models.json. Keep local model
# plumbing here so shell aliases only select a provider/model and do not carry
# fragile JSON or endpoint details.
{ pkgs, ... }:
let
  json = pkgs.formats.json { };
in
{
  programs.pi-coding-agent.enable = true;

  home.file.".pi/agent/models.json".source = json.generate "pi-models.json" {
    providers = {
      lmstudio = {
        baseUrl = "http://localhost:1234/v1";
        api = "openai-completions";
        apiKey = "lm-studio";
        compat = {
          supportsDeveloperRole = false;
          supportsReasoningEffort = false;
        };
        models = [
          {
            id = "google/gemma-4-26b-a4b";
            name = "Gemma 4 26B (LM Studio)";
            reasoning = true;
            input = [ "text" ];
            contextWindow = 128000;
            maxTokens = 16384;
            cost = {
              input = 0;
              output = 0;
              cacheRead = 0;
              cacheWrite = 0;
            };
          }
        ];
      };
    };
  };
}
