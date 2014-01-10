function init(virtual)
  pipes.init({itemPipe})
end

--------------------------------------------------------------------------------
function main(args)
  pipes.update(entity.dt())
end
