--------------------- SAMPLE MINIMAL IMPLEMENTATION --------------------

--- TODO: documents args

function init(virtual)
  if not virtual then
    local pipeTypes = ({liquidPipe, itemPipe}) --only use the types you need
    pipes.init(pipeTypes)
  end
end

function main()
  pipes.update()
end

--------------------- HOOKS --------------------

-- TODO: document filter format