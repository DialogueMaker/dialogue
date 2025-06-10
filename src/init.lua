--!strict

local packages = script.Parent.roblox_packages;
local DialogueMakerTypes = require(packages.DialogueMakerTypes);

type Client = DialogueMakerTypes.Client;
type Conversation = DialogueMakerTypes.Conversation;
type Dialogue = DialogueMakerTypes.Dialogue;
type DialogueSettings = DialogueMakerTypes.DialogueSettings;
type Effect = DialogueMakerTypes.Effect;
type GetContentFunction = DialogueMakerTypes.GetContentFunction;
type RunInitializationActionFunction = DialogueMakerTypes.RunInitializationActionFunction;
type RunCompletionActionFunction = DialogueMakerTypes.RunCompletionActionFunction;
type VerifyConditionFunction = DialogueMakerTypes.VerifyConditionFunction;
type Page = DialogueMakerTypes.Page;
type OptionalDialogueSettings = DialogueMakerTypes.OptionalDialogueSettings;
type DialogueConstructorPropertiesWithType = DialogueMakerTypes.DialogueConstructorPropertiesWithType;
type OptionalDialogueConstructorProperties = DialogueMakerTypes.OptionalDialogueConstructorProperties;
type DialogueConstructorContent = DialogueMakerTypes.DialogueConstructorContent;
type DialogueConstructorChildren = DialogueMakerTypes.DialogueConstructorChildren;

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
function Dialogue.new(content: DialogueConstructorContent?, properties: DialogueConstructorPropertiesWithType, children: DialogueConstructorChildren?): Dialogue

  local function clone(self: Dialogue, newProperties: OptionalDialogueConstructorProperties?): Dialogue

    local clonedProperties: DialogueConstructorPropertiesWithType = if newProperties then {
      type = newProperties.type or properties.type;
      settings = newProperties.settings or properties.settings;
      runInitializationAction = newProperties.runInitializationAction or properties.runInitializationAction;
      runCompletionAction = newProperties.runCompletionAction or properties.runCompletionAction;
      verifyCondition = newProperties.verifyCondition or properties.verifyCondition;
      parent = newProperties.parent or properties.parent;
    } else properties;

    return Dialogue.new(content, clonedProperties, children);

  end;

  local function getChildren(self: Dialogue): {Dialogue}

    if typeof(children) == "table" then

      return children;

    elseif typeof(children) == "function" then

      return children(self);

    else

      return {};

    end

  end;

  local function findNextVerifiedDialogue(self: Dialogue): Dialogue?

    for _, child in self:getChildren() do
      
      if child:verifyCondition() then

        return child;

      end

    end

    return nil;

  end;

  local function getNextVerifiedDialogue(self: Dialogue): Dialogue

    local nextDialogue = self:findNextVerifiedDialogue();
    assert(nextDialogue, "No verified child found in dialogue.");

    return nextDialogue;

  end;

  local function runInitializationAction(self: Dialogue, client: Client): ()

    if properties.runInitializationAction then

      properties.runInitializationAction(self, client);

    end;

  end;

  local function runCompletionAction(self: Dialogue, client: Client): ()

    if properties.runCompletionAction then

      properties.runCompletionAction(self, client);

    end;

  end;

  local function runCleanupAction(self: Dialogue, client: Client, requestedDialogue: Dialogue?): ()

    if properties.runCleanupAction then

      properties.runCleanupAction(self, client, requestedDialogue);

    else

      self:runDefaultCleanupAction(client, requestedDialogue);

    end;

  end;

  local function runDefaultCleanupAction(self: Dialogue, client: Client, requestedDialogue: Dialogue?): ()

    local nextDialogue = requestedDialogue or self:findNextVerifiedDialogue();
    if nextDialogue then

      client:clone({
        dialogue = nextDialogue;
      });

    else

      client:cleanup();

    end;

  end;

  local function getContent(self: Dialogue): Page
    
    if content then

      if typeof(content) == "function" then

        return content(self);

      elseif typeof(content) == "string" or (content :: Effect).type == "Effect" then

        return {content :: string | Effect};

      end

      return content;

    end;

    return {};

  end;

  local function getParent(self: Dialogue): Dialogue | Conversation

    assert(self.parent, "[Dialogue Maker] Dialogue is missing a parent property.");

    return self.parent;

  end;

  local function verifyCondition(self: Dialogue): boolean

    if properties.verifyCondition then

      return properties.verifyCondition(self);

    end;

    return true;

  end;

  local function getConversation(self: Dialogue): Conversation

    local parent = self:getParent();

    while parent.type ~= "Conversation" do

      parent = parent:getParent();

    end;

    return parent :: Conversation;

  end;

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

  local dialogue: Dialogue = {
    parent = properties.parent;
    settings = settings;
    type = properties.type;
    clone = clone;
    getConversation = getConversation;
    getContent = getContent;
    getParent = getParent;
    getChildren = getChildren;
    runCompletionAction = runCompletionAction;
    getNextVerifiedDialogue = getNextVerifiedDialogue;
    runInitializationAction = runInitializationAction;
    runCleanupAction = runCleanupAction;
    runDefaultCleanupAction = runDefaultCleanupAction;
    findNextVerifiedDialogue = findNextVerifiedDialogue;
    verifyCondition = verifyCondition;
  };

  if children and typeof(children) == "table" then

    for index, childDialogue in children do

      if childDialogue.parent ~= dialogue then

        children[index] = childDialogue:clone({
          parent = dialogue;
        });

      end;

    end;

  end;

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
