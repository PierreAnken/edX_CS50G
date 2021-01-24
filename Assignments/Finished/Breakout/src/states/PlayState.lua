--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.balls = params.balls
    self.level = params.level
    self.recoverPoints = params.recoverPoints
    self.paddleGrowPoints = params.paddleGrowPoints

    for k, ball in pairs(self.balls) do
    -- give ball random starting velocity
        ball.dx = math.random(-200, 200)
        ball.dy = math.random(-50, -60)
    end
    -- init new table for powerups
    self.powerups = {}

    -- counter for powerup generation
    self.nextPowerup = 3

end

function PlayState:addBall()
    newBall = Ball()
    newBall.dx = math.random(-200, 200)
    newBall.dy = math.random(-50, -60)
    newBall.x = self.paddle.x + (self.paddle.width / 2) - 4
    newBall.y = self.paddle.y - 8
    table.insert(self.balls, newBall)
end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    if self.nextPowerup <= 0 then
        -- spawn new powerups every 8-15 seconds
        self.nextPowerup = math.random(8,15)

        -- generate powerups
        -- 4 = death, 9 = new ball, 10 = key
        availablePowerup = {4,9}
        if self:countLockedBricks() > 0 then
            availablePowerup[3] = 10
        end
        -- if > 50% of remaining bricks we force keys
        if self:countActiveBricks()/2 < self:countLockedBricks() then
            availablePowerup = {10}
        end


        nextType = availablePowerup[math.random(1, #availablePowerup)]

        table.insert(self.powerups, Powerup(nextType))
    else
        self.nextPowerup = self.nextPowerup - dt
    end

    -- update positions based on velocity
    self.paddle:update(dt)

    for k, ball in pairs(self.balls) do
        ball:update(dt)
    end
    

    for k, powerup in pairs(self.powerups) do

        if powerup.isActive then 
            powerup:update(dt)

            -- apply power up effect
            if powerup:collides(self.paddle) then

                -- death
                if powerup.type == 4 then
                    self:removeLife()
                -- new ball
                elseif powerup.type == 9 then
                    self:addBall()
                -- key
                elseif powerup.type == 10 then
                    -- unlock one brick
                    for k, brick in pairs(self.bricks) do
                        if brick.locked then
                            brick.locked = false
                            break
                        end
                    end
                end

                powerup.isActive = false
            end
        end
    end

    for k, ball in pairs(self.balls) do
        if ball:collides(self.paddle) then
            -- raise ball above paddle in case it goes below it, then reverse dy
            ball.y = self.paddle.y - 8
            ball.dy = -ball.dy

            --
            -- tweak angle of bounce based on where it hits the paddle
            --

            -- if we hit the paddle on its left side while moving left...
            if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))
            
            -- else if we hit the paddle on its right side while moving right...
            elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
            end

            gSounds['paddle-hit']:play()
        end
    end

    -- detect collision across all bricks with the ball
    for k, brick in pairs(self.bricks) do

        -- only check collision if we're in play
        if brick.inPlay then

            collidingBalls = {}
            for k, ball in pairs(self.balls) do
                if ball:collides(brick) then
                    table.insert(collidingBalls, ball)
                end
            end

            if table.getn(collidingBalls) > 0 then
                
                if not brick.locked then
                    -- add to score
                    scoreIncrement = brick.tier * 200 + brick.color * 25
                    
                    -- increased value for locked bricks
                    if brick.wasLocked then
                        scoreIncrement = 1000
                    end

                    self.score = self.score + scoreIncrement
                end

                -- trigger the brick's hit function, which removes it from play
                brick:hit()

                -- if we have enough points, recover a point of health
                if self.score > self.recoverPoints then
                    -- can't go above 3 health
                    self.health = math.min(3, self.health + 1)

                    -- multiply recover points by 2
                    self.recoverPoints = self.recoverPoints + 3000

                    -- play recover sound effect
                    gSounds['recover']:play()
                end

                -- if we have enough points, grow the paddle
                if self.score > self.paddleGrowPoints then
                    
                    if self.paddle.size < 4 then
                        self.paddle:addSize(1)

                        -- multiply paddle grow points by 2
                        self.paddleGrowPoints = self.paddleGrowPoints + 2000

                        -- play recover sound effect
                        gSounds['grow']:play()
                    end
                end

                -- go to our victory screen if there are no more bricks left
                if self:checkVictory() then
                    gSounds['victory']:play()

                    gStateMachine:change('victory', {
                        level = self.level,
                        paddle = self.paddle,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        balls = self.balls,
                        recoverPoints = self.recoverPoints,
                        paddleGrowPoints = self.paddleGrowPoints
                    })
                end


                for k, ball in pairs(collidingBalls) do
                    --
                    -- collision code for bricks
                    --
                    -- we check to see if the opposite side of our velocity is outside of the brick;
                    -- if it is, we trigger a collision on that side. else we're within the X + width of
                    -- the brick and should check to see if the top or bottom edge is outside of the brick,
                    -- colliding on the top or bottom accordingly 
                    --

                    -- left edge; only check if we're moving right, and offset the check by a couple of pixels
                    -- so that flush corner hits register as Y flips, not X flips
                    if ball.x + 2 < brick.x and ball.dx > 0 then
                        
                        -- flip x velocity and reset position outside of brick
                        ball.dx = -ball.dx
                        ball.x = brick.x - 8
                    
                    -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                    -- so that flush corner hits register as Y flips, not X flips
                    elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then
                        
                        -- flip x velocity and reset position outside of brick
                        ball.dx = -ball.dx
                        ball.x = brick.x + 32
                    
                    -- top edge if no X collisions, always check
                    elseif ball.y < brick.y then
                        
                        -- flip y velocity and reset position outside of brick
                        ball.dy = -ball.dy
                        ball.y = brick.y - 8
                    
                    -- bottom edge if no X collisions or top collision, last possibility
                    else
                        
                        -- flip y velocity and reset position outside of brick
                        ball.dy = -ball.dy
                        ball.y = brick.y + 16
                    end

                    -- slightly scale the y velocity to speed up the game, capping at +- 150
                    if math.abs(ball.dy) < 150 then
                        ball.dy = ball.dy * 1.02
                    end

                    -- only allow colliding with one brick, for corners
                    break
                end
            end
        end
    end

    -- if ball goes below bounds, revert to serve state and decrease health
    for k, ball in pairs(self.balls) do
        if ball.y >= VIRTUAL_HEIGHT then
            table.remove(self.balls, k)
            
            if table.getn(self.balls) == 0 then
                self:removeLife()
            end
        end
    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:countLockedBricks()
    count = 0
    for k, brick in pairs(self.bricks) do
        if brick.locked then
            count = count + 1
        end
    end
    return count
end

function PlayState:countActiveBricks()
    count = 0
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            count = count + 1
        end
    end
    return count
end

function PlayState:removeLife()
    self.health = self.health - 1
    gSounds['hurt']:play()

    -- shrink paddle size
    self.paddle:addSize(-1)

    if self.health == 0 then
        gStateMachine:change('game-over', {
            score = self.score,
            highScores = self.highScores
        })
    else
        gStateMachine:change('serve', {
            paddle = self.paddle,
            bricks = self.bricks,
            health = self.health,
            score = self.score,
            highScores = self.highScores,
            level = self.level,
            recoverPoints = self.recoverPoints,
            paddleGrowPoints = self.paddleGrowPoints
        })
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()
    for k, ball in pairs(self.balls) do
        ball:render()
    end
    
    renderScore(self.score)
    renderHealth(self.health)

    for k, powerup in pairs(self.powerups) do
        powerup:render()
    end

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end