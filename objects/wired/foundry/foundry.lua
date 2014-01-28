-- OmnipotentEntity compiled in support for doing config="{...JSON...}" so this approach is how we'll proceed
function init(virtual)
  if virtual then return nil end
  entity.setInteractive(true)
  -- world.logInfo("foundry.lua:init(): ultimate box has done its init")

  fullLabel = nil
  fullTxt = nil
end

function onInteraction(args)
  -- world.logInfo("foundry.lua:onInteraction(): Got interacted with!")
  buttons = generateButtons()
  return { "OpenCraftingInterface", {config={
  ["requiresBlueprint"] = false,
  ["paneLayout"] = {
    ["panefeature"] = {
      ["type"] = "panefeature",
      ["keyDismissable"] = true,
      ["persistent"] = true
    },
    ["background"] = {
      ["type"] = "background",
      ["fileHeader"] = "/interface/foundry/craftingheader.png",
      ["fileBody"] = "/interface/foundry/craftingbody.png",
      ["fileFooter"] = "/interface/foundry/craftingfooter.png"
    },
    ["close"] = {
      ["type"] = "button",
      ["base"] = "/interface/inventory/x.png",
      ["hover"] = "/interface/inventory/xhover.png",
      ["press"] = "/interface/inventory/xpress.png",
      ["position"] = {322, 261}
    },
    ["windowtitle"] = {
      ["type"] = "title",
      ["title"] = "  FOUNDRY",
      ["subtitle"] = "  This gon' be gud!",
      ["position"] = {-5, 252},
      ["icon"] = {
        ["type"] = "image",
        ["file"] = "/interface/foundry/craftingtable.png",
        ["position"] = {0, -20},
        ["zlevel"] = -1
      }
    },
    
    ["lblSchematics"] = {
      ["type"] = "label",
      ["position"] = {88, 243},
      ["hAnchor"] = "mid",
      ["value"] = "SCHEMATICS"
    },
    ["lblProducttitle"] = {
      ["type"] = "label",
      ["position"] = {265, 243},
      ["hAnchor"] = "mid",
      ["value"] = "PRODUCT"
    },
    ["spinCount"] = {
      ["type"] = "spinner",
      ["position"] = {202, 40},
      ["upOffset"] = 34
    },
    ["tbSpinCount"] = {
      ["type"] = "textbox",
      ["position"] = {214, 40},
      ["textAlign"] = "center",
      ["maxWidth"] = 15,
      ["regex"] = "x?\\d{0,3}",
      ["hint"] = ""
    },
    ["lblAmountInput"] = {
      ["type"] = "image",
      ["file"] = "/interface/crafting/amount.png",
      ["position"] = {208, 39},
      ["zlevel"] = -3
    },
    ["lbllvlSort"] = {
      ["type"] = "image",
      ["file"] = "/interface/crafting/organizelevelhigher.png",
      ["position"] = {123, 232},
      ["zlevel"] = -3
    },
    ["btnCraft"] = {
      ["type"] = "button",
      ["base"] = "/interface/button.png",
      ["hover"] = "/interface/buttonhover.png",
      ["position"] = {274, 38},
      ["caption"] = "Craft"
    },
    ["btnFilterHaveMaterials"] = {
      ["type"] = "button",
      ["base"] = "/interface/crafting/checkboxnocheck.png",
      ["baseImageChecked"] = "/interface/crafting/checkboxcheck.png",
      ["checkable"] = true,
      ["checked"] = false,
      ["position"] = {26, 84}
    },
    ["lblProduct"] = {
      ["type"] = "label",
      ["position"] = {51, 83},
      ["hAnchor"] = "left",
      ["value"] = "MATERIALS AVAILABLE"
    },

    ["scrollArea"] = {
      ["type"] = "scrollArea",
      ["rect"] = {5, 93, 174, 231},
      ["children"] = {
        ["itemList"] = {
          ["type"] = "list",
          ["schema"] = {
            ["selectedBG"] = "/interface/foundry/craftableselected.png",
            ["unselectedBG"] = "/interface/foundry/craftablebackground.png",
            ["spacing"] = {0, 1},
            ["memberSize"] = {156, 20},
            ["listTemplate"] = {
              ["background"] = {
                ["type"] = "image",
                ["file"] = "/interface/foundry/craftablebackground.png",
                ["position"] = {0, 0},
                ["zlevel"] = -1
              },
              ["itemName"] = {
                ["type"] = "wraplabel",
                ["position"] = {21, 11},
                ["hAnchor"] = "left",
                ["width"] = 116,
                ["value"] = "Replace Me"
              },
              ["itemIcon"] = {
                ["type"] = "itemslot",
                ["position"] = {1, 1},
                ["callback"] = "null"
              },
              ["level"] = {
                ["type"] = "label",
                ["position"] = {138, 9},
                ["hAnchor"] = "mid",
                ["value"] = "Lvl. 100"
              },
              ["moneyIcon"] = {
                ["type"] = "image",
                ["position"] = {126, 1},
                ["file"] = "/interface/money.png"
              },
              ["priceLabel"] = {
                ["type"] = "label",
                ["position"] = {138, 1},
                ["hAnchor"] = "left",
                ["value"] = "0"
              },
              ["notcraftableoverlay"] = {
                ["type"] = "image",
                ["file"] = "/interface/crafting/notcraftableoverlay.png",
                ["position"] = {0, 0},
                ["zlevel"] = 1
              }
            }
          }
        }
      }
    },
    ["description"] = {
      ["type"] = "widget",
      ["position"] = {190, 50},
      ["size"] = {140, 220}
    },
    ["filter"] = {
      ["type"] = "textbox",
      ["position"] = {56, 68},
      ["hint"] = "Search",
      ["maxWidth"] = 70,
      ["escapeKey"] = "close",
      ["enterKey"] = "filter",
      ["focus"] = true
    },
    ["fullLabel"]=fullLabel,
    ["fullTxt"]=fullTxt,
    ["categories"] = {
      ["type"] = "radioGroup",
      ["toggleMode"] = true,
      ["buttons"] = buttons
    },
    ["rarities"] = {
      ["type"] = "radioGroup",
      ["toggleMode"] = true,
      ["buttons"] = {
        {
          ["position"] = {8, 232},
          ["baseImage"] = "/interface/crafting/sortcommon.png",
          ["baseImageChecked"] = "/interface/crafting/sortcommonselected.png",
          ["data"] = {
            ["rarity"] = { "common" }
          }
        },
        {
          ["position"] = {14, 232},
          ["baseImage"] = "/interface/crafting/sortuncommon.png",
          ["baseImageChecked"] = "/interface/crafting/sortuncommonselected.png",
          ["data"] = {
            ["rarity"] = { "uncommon" }
          }
        },
        {
          ["position"] = {20, 232},
          ["baseImage"] = "/interface/crafting/sortrare.png",
          ["baseImageChecked"] = "/interface/crafting/sortrareselected.png",
          ["data"] = {
            ["rarity"] = { "rare" }
          }
        },
        {
          ["position"] = {26, 232},
          ["baseImage"] = "/interface/crafting/sortlegendary.png",
          ["baseImageChecked"] = "/interface/crafting/sortlegendaryselected.png",
          ["data"] = {
            ["rarity"] = { "legendary" }
          }
        }
      }
    }
  },
  ["tooltip"] = {
    ["panefeature"] = {
      ["type"] = "panefeature",
      ["keyDismissable"] = true,
      ["persistent"] = true
    },
    ["itemList"] = {
      ["position"] = {2, 3},
      ["type"] = "list",
      ["schema"] = {
        ["spacing"] = {0, 0},
        ["memberSize"] = {125, 25},
        ["listTemplate"] = {
          ["itemName"] = {
            ["type"] = "wraplabel",
            ["position"] = {22, 10},
            ["hAnchor"] = "left",
            ["width"] = 116,
            ["value"] = "Golden Moustache"
          },
          ["itemIcon"] = {
            ["type"] = "itemslot",
            ["position"] = {1, 1},
            ["callback"] = "null"
          },
          ["count"] = {
            ["type"] = "label",
            ["position"] = {118, 0},
            ["hAnchor"] = "right",
            ["value"] = "19/99"
          }
        }
      }
    }
  }
},
filter={"foundry"} }}
end

function generateButtons()
local buttonArrayX = 366
local buttonArrayY = 235
local buttonArrayMaxWidth = 2
local buttonArrayMaxHeight = 11
local buttonArrayHSpacing = 61
local buttonArrayVSpacing = 20

local buttons = entity.configParameter("filterButtons")

-- world.logInfo("'buttons' is set to %s",buttons)

local b = {
        
      }

  local num = 1
  for _,bt in ipairs(buttons) do
    -- world.logInfo("iteration %d, bt is %s",num,bt)
    -- for k,v in pairs(bt) do world.logInfo("key %s is val %s",k,v) end
    if num > buttonArrayMaxWidth*buttonArrayMaxHeight then 
      fullLabel = {
        ["type"] = "image",
        ["file"] = "/interface/foundry/maxbuttons.png",
        ["position"] = {buttonArrayX, 23},
        ["zlevel"] = 3
        }
      fullTxt = {
      ["type"] = "label",
      ["position"] = {buttonArrayX+8, 24},
      ["hAnchor"] = "left",
      ["value"] = tostring(#buttons-buttonArrayMaxWidth*buttonArrayMaxHeight) .." mod filters not shown",
      ["zlevel"] = 4
    }
      break 
    end
    local x = buttonArrayX + buttonArrayHSpacing*( (num-1) % buttonArrayMaxWidth )
    local y = buttonArrayY - buttonArrayVSpacing*math.floor((num-1)/buttonArrayMaxWidth)
    
    if not bt["baseImage"] then bt["baseImage"] = "/interface/foundry/iconmissing.png" end
    if not bt["baseImageChecked"] then bt["baseImageChecked"] = "/interface/foundry/iconmissingchecked.png" end
    
    local bnew = nil
    if bt["filter"] then
      bnew = {
        position = {x,y},
        baseImage = bt["baseImage"],
        baseImageChecked = bt["baseImageChecked"],
        data = {
          filter = { bt["filter"] }
        }
      }
      num = num + 1
    else
      -- world.logInfo("Warning: Tabula Rasa is skipping a button with no filter set, 'bt' is %s",bt)
    end
    table.insert(b,bnew)
end
      
return b
end
