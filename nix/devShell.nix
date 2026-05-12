{ inputs, pkgs, ... }:
let
  agentSkillsLib = inputs."agent-skills".lib."agent-skills";
  agentBundle = import ./agent-bundle.nix {
    inherit agentSkillsLib;
    personalSkills = inputs."personal-skills";
  };
  entireConfig = {
    agents = [
      # "claude"
      "opencode"
    ];
    checkpointRemote = "github:rencire/entire-cli-flake-checkpoints";
  };
  mkEntireInit =
    pkgs:
    import ./entire-init.nix {
      inherit pkgs entireConfig;
      entire = inputs."entire-cli-nix".packages.${pkgs.system}.entire;
    };
  pkgs' = (pkgs.extend inputs."llm-agents".overlays.shared-nixpkgs).extend (
    _: prev: {
      wofr = inputs.wofr.packages.${prev.system}.default;
    }
  );
  configured = inputs.confix.lib.configure {
    pkgs = pkgs';
    configDir = ./confix;
  };
  agentPackages = map (
    agent:
    if agent == "opencode" then configured.opencode else throw "Unsupported entire agent: ${agent}"
  ) entireConfig.agents;
in
{
  packages = [
    inputs."entire-cli-nix".packages.${pkgs'.system}.entire
    (mkEntireInit pkgs')
  ]
  ++ agentPackages
  ++ [
    # pkgs'.llm-agents.claude-code
    # pkgs'.llm-agents.codex
    # pkgs'.llm-agents.gemini-cli
    pkgs'.git
  ];
  shellHook = agentSkillsLib.mkShellHook {
    pkgs = pkgs';
    bundle = agentBundle.bundle pkgs';
    targets = agentBundle.targets;
  };
}
