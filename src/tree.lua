local Tree = {img = love.graphics.newImage("assets/tree" .. tostring(math.random(1,4)) .. ".png")}
Tree.__index = Tree

Tree.width = Tree.img:getWidth()
Tree.height = Tree.img:getHeight()

local ActiveTrees = {}
local Player = require("player")

function Tree.removeAll()


   ActiveTrees = {}
end

function Tree.new(x,y,num)
   local instance = setmetatable({}, Tree)
   instance.x = x
   instance.y = y
   instance.num = math.random(1,4)



   table.insert(ActiveTrees, instance)
end

function Tree:update(dt)

end

function Tree:draw()
   treeimg = love.graphics.newImage("assets/tree" .. tostring(self.num) .. ".png")
   love.graphics.draw(treeimg, self.x, self.y, 0, 1, 1, self.width / 2, self.height / 2)
end

function Tree.updateAll(dt)
   for i,instance in ipairs(ActiveTrees) do
      instance:update(dt)
   end
end

function Tree.drawAll()
   for i,instance in ipairs(ActiveTrees) do
      instance:draw()
   end
end


return Tree
