--!strict

local packages = script.Parent.roblox_packages;
local DialogueMakerTypes = require(packages.DialogueMakerTypes);

type Client = DialogueMakerTypes.Client;
type Dialogue = DialogueMakerTypes.Dialogue;
type DialogueSettings = DialogueMakerTypes.DialogueSettings;
type Effect = DialogueMakerTypes.Effect;
type GetContentFunction = DialogueMakerTypes.GetContentFunction;
type RunInitializationActionFunction = DialogueMakerTypes.RunInitializationActionFunction;
type RunCompletionActionFunction = DialogueMakerTypes.RunCompletionActionFunction;
type VerifyConditionFunction = DialogueMakerTypes.VerifyConditionFunction;
type Page = DialogueMakerTypes.Page;
type OptionalDialogueSettings = DialogueMakerTypes.OptionalDialogueSettings;

export type ConstructorProperties = {
  content: (string | Effect | Page)?;
  getContent: GetContentFunction?;
  children: {Dialogue}?;
  getChildren: ((self: Dialogue) -> {Dialogue})?;
  runInitializationAction: RunInitializationActionFunction;
  runCompletionAction: RunCompletionActionFunction;
  verifyCondition: VerifyConditionFunction;
  settings: OptionalDialogueSettings?;
  type: "Message" | "Response" | "Redirect";
}

local Dialogue = {
  defaultSettings = {
    theme = {
      component = nil;
    };
    speaker = {
      name = nil;
    };
    typewriter = {
      characterDelaySeconds = 0.025; 
      canPlayerSkipDelay = true;
      shouldShowResponseWhileTyping = false;
    };
  } :: DialogueSettings;
};

--[[
  Creates a new Dialogue object.
]]
function Dialogue.new(properties: ConstructorProperties): Dialogue
  
  assert(properties.type == "Message" or properties.type == "Response" or properties.type == "Redirect", "[Dialogue Maker] ModuleScript must have a DialogueType attribute set to either Message, Response, or Redirect.");
  assert(properties.children or properties.getChildren, "[Dialogue Maker] Please provide a children property or a getChildren function.");
  assert(properties.content or properties.getContent, "[Dialogue Maker] Please provide a content property or a getContent function.");

  local settings: DialogueSettings = {
    theme = {
      component = if properties.settings and properties.settings.theme then properties.settings.theme.component else Dialogue.defaultSettings.theme.component;
    };
    speaker = {
      name = if properties.settings and properties.settings.speaker and properties.settings.speaker.name ~= nil then properties.settings.speaker.name else Dialogue.defaultSettings.speaker.name;
    };
    typewriter = {
      characterDelaySeconds = if properties.settings and properties.settings.typewriter and properties.settings.typewriter.characterDelaySeconds ~= nil then properties.settings.typewriter.characterDelaySeconds else Dialogue.defaultSettings.typewriter.characterDelaySeconds; 
      canPlayerSkipDelay = if properties.settings and properties.settings.typewriter and properties.settings.typewriter.canPlayerSkipDelay ~= nil then properties.settings.typewriter.canPlayerSkipDelay else Dialogue.defaultSettings.typewriter.canPlayerSkipDelay; 
      shouldShowResponseWhileTyping = if properties.settings and properties.settings.typewriter and properties.settings.typewriter.shouldShowResponseWhileTyping ~= nil then properties.settings.typewriter.shouldShowResponseWhileTyping else Dialogue.defaultSettings.typewriter.shouldShowResponseWhileTyping;
    };
  };

  local function getChildren(self: Dialogue): {Dialogue}

    if properties.children then

      return properties.children;

    elseif properties.getChildren then

      return properties.getChildren(self);

    end;

    error("[Dialogue Maker] Dialogue is missing a children property or a getChildren function.");

  end;

  local function findNextVerifiedDialogue(self: Dialogue): Dialogue?

    for _, child in self:getChildren() do
      
      if child:verifyCondition() then

        return child;

      end

    end

    return nil;

  end;

  local function runInitializationAction(self: Dialogue, client: Client): ()

    if properties.runInitializationAction then

      properties.runInitializationAction(self, client);

    end;

  end;

  local function runCompletionAction(self: Dialogue, client: Client, requestedDialogue: Dialogue?): ()

    if properties.runCompletionAction then

      properties.runCompletionAction(self, client, requestedDialogue);

    else

      local nextDialogue = requestedDialogue or self:findNextVerifiedDialogue();
      client:setDialogue(nextDialogue);

    end;

  end;

  local function getContent(self: Dialogue): Page
    
    if properties.getContent then

      return properties.getContent(self);

    elseif properties.content then

      if typeof(properties.content) == "string" or (properties.content :: Effect).type == "Effect" then

        return {properties.content :: string | Effect};

      else

        return properties.content;

      end;

    end;

    error("[Dialogue Maker] Dialogue is missing a content property or a getContent function.");

  end;

  local function verifyCondition(self: Dialogue): boolean

    if properties.verifyCondition then

      return properties.verifyCondition(self);

    end;

    return true;

  end;

  local dialogue: Dialogue = {
    type = properties.type;
    settings = settings;
    getContent = getContent;
    getChildren = getChildren;
    runCompletionAction = runCompletionAction;
    runInitializationAction = runInitializationAction;
    findNextVerifiedDialogue = findNextVerifiedDialogue;
    verifyCondition = verifyCondition;
  };

  return dialogue;

end;

--[[
  Returns a list of Dialogue objects from the given instance.
  The instance should contain ModuleScripts with the "DialogueScript" tag.
]]
function Dialogue.listFromInstance(instance: Instance): {Dialogue}

  local dialogueInstances = {};

  for _, child in script:GetChildren() do

    local isDialogueScript = child:IsA("ModuleScript") and child:HasTag("DialogueScript");
    local isRedirect = child:IsA("ObjectValue") and child:HasTag("DialogueRedirectValue") and child.Value and child.Value:IsA("ModuleScript") and child.Value:HasTag("DialogueScript");
    if not isDialogueScript and not isRedirect then

      continue;

    end;

    table.insert(dialogueInstances, child);

  end;

  table.sort(dialogueInstances, function(instance1, instance2)

    return instance1.Name < instance2.Name;

  end);

  local dialogueList = {};

  for _, dialogueInstance in dialogueInstances do

    local dialogueScript: ModuleScript = if dialogueInstance:IsA("ModuleScript") then dialogueInstance else dialogueInstance.Value;
    local dialogue = require(dialogueScript) :: Dialogue;
    table.insert(dialogueList, dialogue);

  end;

  return dialogueList;

end;

return Dialogue;
