--------------------- SAMPLE MINIMAL IMPLEMENTATION --------------------

function init(virtual)
  if not virtual then
    datawire.init()
  end
end

function onNodeConnectionChange()
  datawire.onNodeConnectionChange()
end

function main()
  datawire.update()
end

--------------------- HOOKS --------------------

--- hook for implementing scripts to add their own initialization code when main() is first called
function initAfterLoading() end

--- Validates data received from another datawire object
-- @param data the data to be validated
-- @param dataType the data type to be validated ("boolean", "number", "string", "area", etc.)
-- @param nodeId the inbound node id on which data was received
-- @returns true if the data is valid
function validateData(data, dataType, nodeId)
  return true
end

--- Hook for datawire objects to use received data
-- @param data the data
-- @param dataType the data type ("boolean", "number", "string", "area", etc.)
-- @param nodeId the inbound node id on which data was received
function onValidDataReceived(data, dataType, nodeId) end