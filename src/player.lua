

local Player = {}

function Player:load()
   self.x = 100
   self.y = 300
   self.startX = self.x
   self.startY = self.y
   self.width = 20
   self.height = 60
   self.xVel = 0
   self.yVel = 0
   self.maxSpeed = 400
   self.acceleration = 4000
   self.friction = 3500
   self.gravity = 1500
   self.jumpAmount = -750
   self.coins = 0
   self.health = {current = 3, max = 3}

   self.graceTime = 0
   self.graceDuration = 0.1

   self.gameisgoing = true
   self.grounded = false
   self.hasDoubleJump = true

   self.direction = "right"
   self.state = "idle"

   self:loadAssets()

   self.physics = {}
   self.physics.body = love.physics.newBody(World, self.x, self.y, "dynamic")
   self.physics.body:setFixedRotation(true)
   self.physics.shape = love.physics.newRectangleShape(self.width, self.height)
   self.physics.fixture = love.physics.newFixture(self.physics.body, self.physics.shape)
   self.physics.body:setGravityScale(0)
end

function Player:loadAssets()
   self.animation = {timer = 0, rate = 0.1}

   self.animation.idle = {total = 1, current = 1, img = {}}
   for i=1, self.animation.idle.total do
      self.animation.idle.img[i] = love.graphics.newImage("assets/player/penguin.png")
   end


   self.animation.draw = self.animation.idle.img[1]
   self.animation.width = self.animation.draw:getWidth()
   self.animation.height = self.animation.draw:getHeight()
end

function Player:takeDamage(amount)
   if self.health.current - amount > 0 then
      self.health.current = self.health.current - amount
   else
      self.health.current = 0
      self:endgame()
   end
   print("Player health: "..self.health.current)
end

function Player:endgame()
   print("Game Over")
   self.gameisgoing = false
end

function Player:respawn()
   self.coins = 0
   if not self.gameisgoing then
      self:resetPosition()
      self.health.current = self.health.max
      self.gameisgoing = true
   end
end

function Player:resetPosition()
   self.physics.body:setPosition(self.startX, self.startY)
end


function Player:incrementCoins()
   self.coins = self.coins + 1
end

function Player:update(dt)
  -- self:respawn()
   self:setState()
   self:setDirection()
   self:decreaseGraceTime(dt)
   self:syncPhysics()
   self:move(dt)
   self:applyGravity(dt)
end


function Player:setState()
   if not self.grounded then
      self.state = "air"
   elseif self.xVel == 0 then
      self.state = "idle"
   else
      self.state = "run"
   end
end

function Player:setDirection()
   if self.xVel < 0 then
      self.direction = "left"
   elseif self.xVel > 0 then
      self.direction = "right"
   end
end


function Player:setNewFrame()
   local anim = self.animation[self.state]
   if anim.current < anim.total then
      anim.current = anim.current + 1
   else
      anim.current = 1
   end
   self.animation.draw = anim.img[anim.current]
end

function Player:decreaseGraceTime(dt)
   if not self.grounded then
      self.graceTime = self.graceTime - dt
   end
end

function Player:applyGravity(dt)
   if not self.grounded then
      self.yVel = self.yVel + self.gravity * dt
   end
end

function Player:move(dt)
	-- only allow movement if gameisgoing
    if self.gameisgoing then
	    self.xVel = math.min(self.xVel + self.acceleration * dt, self.maxSpeed)
    
	else
	self:applyFriction(dt)
	end
   
  -- if love.keyboard.isDown("d", "right") then
   --   self.xVel = math.min(self.xVel + self.acceleration * dt, self.maxSpeed)

 --  else
  --    self:applyFriction(dt)
  -- end
end

function Player:applyFriction(dt)
   if self.xVel > 0 then
      self.xVel = math.max(self.xVel - self.friction * dt, 0)
   elseif self.xVel < 0 then
      self.xVel = math.min(self.xVel + self.friction * dt, 0)
   end
end

function Player:syncPhysics()
   self.x, self.y = self.physics.body:getPosition()
   self.physics.body:setLinearVelocity(self.xVel, self.yVel)
end

function Player:beginContact(a, b, collision)
   if self.grounded == true then return end
   local nx, ny = collision:getNormal()
   if a == self.physics.fixture then
      if ny > 0 then
         self:land(collision)
      elseif ny < 0 then
         self.yVel = 0
      end
   elseif b == self.physics.fixture then
      if ny < 0 then
         self:land(collision)
      elseif ny > 0 then
         self.yVel = 0
      end
   end
end

function Player:land(collision)
   self.currentGroundCollision = collision
   self.yVel = 0
   self.grounded = true
   self.hasDoubleJump = true
   self.graceTime = self.graceDuration
end

function Player:jump(key)
   if (key == "space" or key == "up") then
      if self.grounded or self.graceTime > 0 then
         self.yVel = self.jumpAmount
         self.graceTime = 0
      elseif self.hasDoubleJump then
         self.hasDoubleJump = false
         self.yVel = self.jumpAmount * 0.8
      end
   end
   if not self.gameisgoing then
      self:respawn()
   end
end

function Player:endContact(a, b, collision)
   if a == self.physics.fixture or b == self.physics.fixture then
      if self.currentGroundCollision == collision then
         self.grounded = false
      end
   end
end

function Player:draw()
   local scaleX = 1
   love.graphics.draw(self.animation.draw, self.x, self.y, 0, scaleX, 1, self.animation.width / 1.4, self.animation.height / 1.5)
end

return Player
