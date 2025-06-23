--!strict

local packages = script.Parent.Parent.roblox_packages;
local Dialogue = require(script.Parent);
local DialogueMakerTypes = require(packages.DialogueMakerTypes);
local ijw = require(packages.ijw);
local describe = ijw.describe;
local it = ijw.it;
local expect = ijw.expect;

type Client = DialogueMakerTypes.Client;
type Conversation = DialogueMakerTypes.Conversation;

return {
  describe("Dialogue", {

    it("can clone itself", function()

      local message = Dialogue.new("", {
        type = "Message" :: "Message"
      });

      local clonedMessage = message:clone();

      expect(clonedMessage.type).toBe(message.type);
      expect(clonedMessage.settings).toDeepEqual(message.settings);
      expect(clonedMessage.runInitializationAction).toBe(message.runInitializationAction);
      expect(clonedMessage.runCleanupAction).toBe(message.runCleanupAction);
      expect(clonedMessage.runCompletionAction).toBe(message.runCompletionAction);
      expect(clonedMessage.verifyCondition).toBe(message.verifyCondition);
      expect(clonedMessage.parent).toBe(message.parent);

    end);
    
    it("can contain children", function()
  
      local message = Dialogue.new("Parent", {
        type = "Message" :: "Message"
      }, {
        Dialogue.new("Child 1", {
          type = "Message" :: "Message"
        }),
        Dialogue.new("Child 2", {
          type = "Message" :: "Message"
        })
      });

      local children = message:getChildren();

      expect(#children).toBe(2);
      expect(children[1]:getContent()[1]).toBe("Child 1");
      expect(children[2]:getContent()[1]).toBe("Child 2");
  
    end);

    it("can have static content", function()
    
      -- Test direct string content.
      local message = Dialogue.new("This is a static message.", {
        type = "Message" :: "Message"
      });

      local content = message:getContent();

      expect(#content).toBe(1);
      expect(content[1]).toBe("This is a static message.");

      -- How about a table with a single string?
      message = Dialogue.new({"This is a static message."}, {
        type = "Message" :: "Message"
      });

      content = message:getContent();

      expect(#content).toBe(1);
      expect(content[1]).toBe("This is a static message.");

    end);

    it("can have dynamic content", function()
  
      local message = Dialogue.new(function() return {"This is a dynamic message."}; end, {
        type = "Message" :: "Message"
      });

      local content = message:getContent();

      expect(#content).toBe(1);
      expect(content[1]).toBe("This is a dynamic message.");
  
    end);

    it("can find the next verified dialogue", function()
  
      local message = Dialogue.new("This is the starting message.", {
        type = "Message" :: "Message"
      }, {
        Dialogue.new("This response should not be selected.", {
          type = "Response" :: "Response";
          verifyCondition = function() return false; end;
        });
        Dialogue.new("This message should be selected.", {
          type = "Message" :: "Message",
        });
        Dialogue.new("This message should not be selected.", {
          type = "Message" :: "Message",
        });
        Dialogue.new("", {
          type = "Redirect" :: "Redirect";
        });
      });

      local nextDialogue = message:findNextVerifiedDialogue();

      assert(nextDialogue);
      expect(nextDialogue.type).toBe("Message");
      expect(nextDialogue:getContent()[1]).toBe("This message should be selected.");
  
    end);

    it("can error if it can't find a next verified dialogue", function()
  
      -- Check that an error is raised when there are no verified dialogues.
      local message = Dialogue.new("This is the starting message.", {
        type = "Message" :: "Message"
      }, {
        Dialogue.new("This response should not be selected.", {
          type = "Response" :: "Response";
          verifyCondition = function() return false; end;
        });
        Dialogue.new("This message should not be selected.", {
          type = "Message" :: "Message";
          verifyCondition = function() return false; end;
        });
      });

      expect(function()
      
        message:getNextVerifiedDialogue();

      end).toError();

      -- Check that an error is raised when there are no children.
      local emptyMessage = Dialogue.new("This is the starting message.", {
        type = "Message" :: "Message"
      });

      expect(function()

        emptyMessage:getNextVerifiedDialogue();

      end).toError();
  
    end);

    it("can run a user-defined initialization action", function()

      local didActionRun = false;
      local message;
      local mockClient = {} :: Client;

      message = Dialogue.new("", {
        type = "Message" :: "Message",
        runInitializationAction = function(possibleMessage, possibleClient)

          expect(possibleMessage).toBe(message);
          expect(possibleClient).toBe(mockClient);
          didActionRun = true;

        end
      });

      message:runInitializationAction(mockClient);

      expect(didActionRun).toBe(true);

    end);

    it("can run a user-defined completion action", function()

      local didActionRun = false;
      local message;
      local mockClient = {} :: Client;

      message = Dialogue.new("", {
        type = "Message" :: "Message",
        runCompletionAction = function(possibleMessage, possibleMockClient)

          expect(possibleMessage).toBe(message);
          expect(possibleMockClient).toBe(mockClient);
          didActionRun = true;

        end
      });

      message:runCompletionAction(mockClient);

      expect(didActionRun).toBe(true);

    end);

    it("can run a user-defined cleanup action", function()

      local didActionRun = false;
      local message;
      local mockClient = {} :: Client;

      local requestedDialogue = Dialogue.new("", {
        type = "Message" :: "Message"
      });

      message = Dialogue.new("", {
        type = "Message" :: "Message",
        runCleanupAction = function(possibleMessage, possibleMockClient, possibleRequestedDialogue)

          expect(possibleMessage).toBe(message);
          expect(possibleMockClient).toBe(mockClient);
          didActionRun = true;

        end
      });

      message:runCleanupAction(mockClient, requestedDialogue);

      expect(didActionRun).toBe(true);

    end);

    it("can continue the conversation by default if there is requested dialogue", function()

      local didSucceed = false;
      local nextDialogue = Dialogue.new("Next Dialogue", {
        type = "Message" :: "Message"
      });
      local mockClient = {
        clone = function(self, properties)

          expect(properties.dialogue).toBe(nextDialogue);
          didSucceed = true;

        end :: unknown;
      } :: Client;

      local message = Dialogue.new("", {
        type = "Message" :: "Message",
      });

      message:runCleanupAction(mockClient, nextDialogue);

      expect(didSucceed).toBe(true);

    end);

    it("can end the conversation by default if there is no requested dialogue", function()

      local didSucceed = false;
      local mockClient = {
        cleanup = function()

          didSucceed = true;

        end :: unknown;
      } :: Client;

      local message = Dialogue.new("", {
        type = "Message" :: "Message",
      });

      message:runCleanupAction(mockClient);

      expect(didSucceed).toBe(true);

    end);

    it("can get its parent", function()

      local parentDialogue = Dialogue.new("Parent", {
        type = "Message" :: "Message"
      }, {
        Dialogue.new("Child", {
          type = "Message" :: "Message"
        });
      });

      local childDialogue = parentDialogue:getChildren()[1];
      expect(childDialogue:getParent()).toBe(parentDialogue);
      
    end);

    it("can error if it can't find its parent", function()

      local message = Dialogue.new("", {
        type = "Message" :: "Message"
      });

      expect(function()

        message:getParent();

      end).toError();
      
    end);

    it("can get its conversation", function()

      local mockConversation = {
        type = "Conversation" :: "Conversation";
      } :: Conversation;

      local parentDialogue = Dialogue.new("Parent", {
        type = "Message" :: "Message";
        parent = mockConversation;
      }, {
        Dialogue.new("Child", {
          type = "Message" :: "Message"
        });
      });

      local childDialogue = parentDialogue:getChildren()[1];
      expect(childDialogue:getConversation()).toBe(mockConversation);
      
    end);

    it("can error if it can't its conversation", function()

      local parentDialogue = Dialogue.new("Parent", {
        type = "Message" :: "Message";
      }, {
        Dialogue.new("Child", {
          type = "Message" :: "Message"
        });
      });

      local childDialogue = parentDialogue:getChildren()[1];
      expect(function()
      
        childDialogue:getConversation()

      end).toError();
      
    end);

  })
};