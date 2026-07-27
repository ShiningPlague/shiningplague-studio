# Agents Index — dispatch table

> Machine-readable roster for Claude: match the work against the descriptions below, then dispatch via the Agent tool (subagent_type = the agent name). Auto-generated from `.claude/agents/*.md` frontmatter.

## Active roster (loaded by default)

| Agent | Role |
|---|---|
| `accessibility-specialist` | The Accessibility Specialist ensures the game is playable by the widest possible audience. They enforce accessibility standards, review UI for compliance, and design assistive features including remap |
| `ai-programmer` | The AI Programmer implements game AI systems: behavior trees, state machines, pathfinding, perception systems, decision-making, and NPC behavior. Use this agent for AI system implementation, pathfindi |
| `analytics-engineer` | The Analytics Engineer designs telemetry systems, player behavior tracking, A/B test frameworks, and data analysis pipelines. Use this agent for event tracking design, dashboard specification, A/B tes |
| `art-director` | The Art Director owns the visual identity of the game: style guides, art bible, asset standards, color palettes, UI/UX visual design, and the art production pipeline. Use this agent for visual consist |
| `audio-director` | The Audio Director owns the sonic identity of the game: music direction, sound design philosophy, audio implementation strategy, and mix balance. Use this agent for audio direction decisions, sound pa |
| `community-manager` | The community manager owns player-facing communication: patch notes, social media posts, community updates, player feedback collection, bug report triage from players, and crisis communication. They t |
| `creative-director` | The Creative Director is the highest-level creative authority for the project. This agent makes binding decisions on game vision, tone, aesthetic direction, and resolves conflicts between design, art, |
| `devops-engineer` | The DevOps Engineer maintains build pipelines, CI/CD configuration, version control workflow, and deployment infrastructure. Use this agent for build script maintenance, CI configuration, branching st |
| `economy-designer` | The Economy Designer specializes in resource economies, loot systems, progression curves, and in-game market design. Use this agent for loot table design, resource sink/faucet analysis, progression cu |
| `engine-programmer` | The Engine Programmer works on core engine systems: rendering pipeline, physics, memory management, resource loading, scene management, and core framework code. Use this agent for engine-level feature |
| `game-designer` | The Game Designer owns the mechanical and systems design of the game. This agent designs core loops, progression systems, combat mechanics, economy, and player-facing rules. Use this agent for any que |
| `gameplay-programmer` | The Gameplay Programmer implements game mechanics, player systems, combat, and interactive features as code. Use this agent for implementing designed mechanics, writing gameplay system code, or transl |
| `godot-gdscript-specialist` | The GDScript specialist owns all GDScript code quality: static typing enforcement, design patterns, signal architecture, coroutine patterns, performance optimization, and GDScript-specific idioms. The |
| `godot-shader-specialist` | The Godot Shader specialist owns all Godot rendering customization: Godot shading language, visual shaders, material setup, particle shaders, post-processing, and rendering performance. They ensure vi |
| `godot-specialist` | The Godot Engine Specialist is the authority on all Godot-specific patterns, APIs, and optimization techniques. They guide GDScript vs C# vs GDExtension decisions, ensure proper use of Godot's node/sc |
| `lead-programmer` | The Lead Programmer owns code-level architecture, coding standards, code review, and the assignment of programming work to specialist programmers. Use this agent for code reviews, API design, refactor |
| `level-designer` | The Level Designer creates spatial designs, encounter layouts, pacing plans, and environmental storytelling guides for game levels and areas. Use this agent for level layout planning, encounter design |
| `localization-lead` | Owns internationalization architecture, string management, locale testing, and translation pipeline. Use for i18n system design, string extraction workflows, locale-specific issues, or translation qua |
| `narrative-director` | The Narrative Director owns story architecture, world-building, character design, and dialogue strategy. Use this agent for story arc planning, character development, world rule definition, and narrat |
| `performance-analyst` | The Performance Analyst profiles game performance, identifies bottlenecks, recommends optimizations, and tracks performance metrics over time. Use this agent for performance profiling, memory analysis |
| `producer` | The Producer manages all production concerns: sprint planning, milestone tracking, risk management, scope negotiation, and cross-department coordination. This is the primary coordination agent. Use th |
| `prototyper` | Rapid prototyping specialist for pre-production. Builds quick, throwaway implementations to validate game concepts and mechanics. Use during pre-production for concept validation, vertical slices, or  |
| `qa-lead` | The QA Lead owns test strategy, bug triage, release quality gates, and testing process design. Use this agent for test plan creation, bug severity assessment, regression test planning, or release read |
| `qa-tester` | The QA Tester writes detailed test cases, bug reports, and test checklists. Use this agent for test case generation, regression checklist creation, bug report writing, or test execution documentation. |
| `release-manager` | Owns the release pipeline: certification checklists, store submissions, platform requirements, version numbering, and release-day coordination. Use for release planning, platform certification, store  |
| `security-engineer` | The Security Engineer protects the game from cheating, exploits, and data breaches. They review code for vulnerabilities, design anti-cheat measures, secure save data and network communications, and e |
| `sound-designer` | The Sound Designer creates detailed specifications for sound effects, documents audio events, and defines mixing parameters. Use this agent for SFX spec sheets, audio event planning, mixing documentat |
| `systems-designer` | The Systems Designer creates detailed mechanical designs for specific game subsystems -- combat formulas, progression curves, crafting recipes, status effect interactions. Use this agent when a mechan |
| `technical-artist` | The Technical Artist bridges art and engineering: shaders, VFX, rendering optimization, art pipeline tools, and performance profiling for visual systems. Use this agent for shader development, VFX sys |
| `technical-director` | The Technical Director owns all high-level technical decisions including engine architecture, technology choices, performance strategy, and technical risk management. Use this agent for architecture-l |
| `tools-programmer` | The Tools Programmer builds internal development tools: editor extensions, content authoring tools, debug utilities, and pipeline automation. Use this agent for custom tool creation, editor workflow i |
| `ui-programmer` | The UI Programmer implements user interface systems: menus, HUDs, inventory screens, dialogue boxes, and UI framework code. Use this agent for UI system implementation, widget development, data bindin |
| `ux-designer` | The UX Designer owns user experience flows, interaction design, accessibility, information architecture, and input handling design. Use this agent for user flow mapping, interaction pattern design, ac |
| `world-builder` | The World Builder designs detailed world lore: factions, cultures, history, geography, ecology, and the rules that govern the game world. Use this agent for lore consistency checks, faction design, hi |
| `writer` | The Writer creates dialogue, lore entries, item descriptions, environmental text, and all player-facing written content. Use this agent for dialogue writing, lore creation, item/ability descriptions,  |

_35 active agents._

## Engine packs (dormant — activate by copying into `.claude/agents/`)

### godot-extras

| Agent | Role |
|---|---|
| `godot-csharp-specialist` | The Godot C# specialist owns all C# code quality in Godot 4 projects: .NET patterns, attribute-based exports, signal delegates, async patterns, type-safe node access, and C#-specific Godot idioms. The |
| `godot-gdextension-specialist` | The GDExtension specialist owns all native code integration with Godot: GDExtension API, C/C++/Rust bindings (godot-cpp, godot-rust), native performance optimization, custom node types, and the GDScri |

### other

| Agent | Role |
|---|---|
| `live-ops-designer` | The live-ops designer owns post-launch content strategy: seasonal events, battle passes, content cadence, player retention mechanics, live service economy, and engagement analytics. They ensure the ga |
| `network-programmer` | The Network Programmer implements multiplayer networking: state replication, lag compensation, matchmaking, and network protocol design. Use this agent for netcode implementation, synchronization stra |

### unity

| Agent | Role |
|---|---|
| `unity-addressables-specialist` | The Addressables specialist owns all Unity asset management: Addressable groups, asset loading/unloading, memory management, content catalogs, remote content delivery, and asset bundle optimization. T |
| `unity-dots-specialist` | The DOTS/ECS specialist owns all Unity Data-Oriented Technology Stack implementation: Entity Component System architecture, Jobs system, Burst compiler optimization, hybrid renderer, and DOTS-based ga |
| `unity-shader-specialist` | The Unity Shader/VFX specialist owns all Unity rendering customization: Shader Graph, custom HLSL shaders, VFX Graph, render pipeline customization (URP/HDRP), post-processing, and visual effects opti |
| `unity-specialist` | The Unity Engine Specialist is the authority on all Unity-specific patterns, APIs, and optimization techniques. They guide MonoBehaviour vs DOTS/ECS decisions, ensure proper use of Unity subsystems (A |
| `unity-ui-specialist` | The Unity UI specialist owns all Unity UI implementation: UI Toolkit (UXML/USS), UGUI (Canvas), data binding, runtime UI performance, input handling, and cross-platform UI adaptation. They ensure resp |

### unreal

| Agent | Role |
|---|---|
| `ue-blueprint-specialist` | The Blueprint specialist owns Blueprint architecture decisions, Blueprint/C++ boundary guidelines, Blueprint optimization, and ensures Blueprint graphs stay maintainable and performant. They prevent B |
| `ue-gas-specialist` | The Gameplay Ability System specialist owns all GAS implementation: abilities, gameplay effects, attribute sets, gameplay tags, ability tasks, and GAS prediction. They ensure consistent GAS architectu |
| `ue-replication-specialist` | The UE Replication specialist owns all Unreal networking: property replication, RPCs, client prediction, relevancy, net serialization, and bandwidth optimization. They ensure server-authoritative arch |
| `ue-umg-specialist` | The UMG/CommonUI specialist owns all Unreal UI implementation: widget hierarchy, data binding, CommonUI input routing, widget styling, and UI optimization. They ensure UI follows Unreal best practices |
| `unreal-specialist` | The Unreal Engine Specialist is the authority on all Unreal-specific patterns, APIs, and optimization techniques. They guide Blueprint vs C++ decisions, ensure proper use of UE subsystems (GAS, Enhanc |

