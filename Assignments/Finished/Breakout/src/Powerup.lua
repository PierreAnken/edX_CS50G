--[[

]]

Powerup = Class{}

function Powerup:init(type)
    self.type = type
    self.x = math.random(18, VIRTUAL_WIDTH-18)
    self.y = 10
    self.isActive = true
    self.width = 16
    self.height = 16
end


function Powerup:collides(target)

    -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end 

    -- if the above aren't true, they're overlapping
    return true
end

--[[
    Places the ball in the middle of the screen, with no movement.
]]

function Powerup:update(dt)
    
    if self.isActive then 
        self.y = self.y + 20 * dt

        -- disable powerup when touching the bottom
        if self.y > VIRTUAL_HEIGHT then
            self.isActive = false
        end
    end
end

function Powerup:render()
    -- gTexture is our global texture for all blocks
    -- gBallFrames is a table of quads mapping to each individual ball skin in the texture
    if self.isActive then 
        love.graphics.draw(gTextures['powerups'], gFrames['powerups'][self.type], self.x, self.y)
    end
end