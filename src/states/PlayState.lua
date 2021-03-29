PlayState = Class{__includes = BaseState}

function PlayState:init()
    
    self.transitionAlpha = 255

    self.boardHighlightX = 0
    self.boardHighlightY = 0

    self.rectHighlighted = false

    self.canInput = true

    self.highlightedTile = nil

    self.score = 0
    self.timer = 60

    Timer.every(0.5, function()
        self.rectHighlighted = not self.rectHighlighted
    end)

    Timer.every(1, function()
        self.timer = self.timer - 1

        if self.timer <= 5 then
            gSounds['clock']:play()
        end
    end)
end

function PlayState:enter(params)
    
    self.level = params.level

    self.board = params.board

    self.score = params.score or 0

    self.scoreGoal = self.level * 1.25 * 1000
end

function PlayState:update(dt)
    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end

    if self.timer <= 0 then
        
        Timer.clear()
        
        gSounds['game-over']:play()

        gStateMachine:change('game-over', {
            score = self.score
        })
    end

    if self.score >= self.scoreGoal then
        
        Timer.clear()

        gSounds['next-level']:play()

        gStateMachine:change('begin-game', {
            level = self.level + 1,
            score = self.score
        })
    end

    if self.canInput then
        if love.keyboard.wasPressed('up') then
            self.boardHighlightY = math.max(0, self.boardHighlightY - 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('down') then
            self.boardHighlightY = math.min(7, self.boardHighlightY + 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('left') then
            self.boardHighlightX = math.max(0, self.boardHighlightX - 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('right') then
            self.boardHighlightX = math.min(7, self.boardHighlightX + 1)
            gSounds['select']:play()
        end

        if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
            
            local x = self.boardHighlightX + 1
            local y = self.boardHighlightY + 1
            
            if not self.highlightedTile then
                self.highlightedTile = self.board.tiles[y][x]

            elseif self.highlightedTile == self.board.tiles[y][x] then
                self.highlightedTile = nil

            elseif math.abs(self.highlightedTile.gridX - x) + math.abs(self.highlightedTile.gridY - y) > 1 then
                gSounds['error']:play()
                self.highlightedTile = nil
            else
                
                local tempX = self.highlightedTile.gridX
                local tempY = self.highlightedTile.gridY

                local newTile = self.board.tiles[y][x]

                self.highlightedTile.gridX = newTile.gridX
                self.highlightedTile.gridY = newTile.gridY
                newTile.gridX = tempX
                newTile.gridY = tempY

                self.board.tiles[self.highlightedTile.gridY][self.highlightedTile.gridX] =
                    self.highlightedTile

                self.board.tiles[newTile.gridY][newTile.gridX] = newTile

                if self.board:calculateMatches() then 

                    Timer.tween(0.1, {
                        [self.highlightedTile] = {x = newTile.x, y = newTile.y},
                        [newTile] = {x = self.highlightedTile.x, y = self.highlightedTile.y}
                    })
                    :finish(function()
                        self:calculateMatches()
                        if not self:potentialMatches() then 
                            self.board = Board(VIRTUAL_WIDTH - 272, 16, self.level)
                        end
                    end)

                else
                    gSounds['error']:play()
                    newTile.gridX = self.highlightedTile.gridX
                    newTile.gridY = self.highlightedTile.gridY
                    self.highlightedTile.gridX = tempX
                    self.highlightedTile.gridY = tempY

                    self.board.tiles[self.highlightedTile.gridY][self.highlightedTile.gridX] =
                        self.highlightedTile
                    self.board.tiles[newTile.gridY][newTile.gridX] = newTile
                
                    Timer.tween(0.1, {
                        [self.highlightedTile] = {x = newTile.x, y = newTile.y},
                        [newTile] = {x = self.highlightedTile.x, y = self.highlightedTile.y}
                    })
                    :finish(function()
                        Timer.tween(0.1, {
                            [self.highlightedTile] = {x = newTile.x, y = newTile.y},
                            [newTile] = {x = self.highlightedTile.x, y = self.highlightedTile.y}
                        })
                    end)
                end
            end
        end
    end

    Timer.update(dt)
end

function PlayState:potentialMatches()
    for y = 2, 7 do
        for x = 2, 7 do
            if self:swapTiles(self.board.tiles[y][x], self.board.tiles[y-1][x]) then 
                return true 
            elseif self:swapTiles(self.board.tiles[y][x], self.board.tiles[y+1][x]) then 
                return true 
            elseif self:swapTiles(self.board.tiles[y][x], self.board.tiles[y][x-1]) then 
                return true
            elseif self:swapTiles(self.board.tiles[y][x], self.board.tiles[y][x+1]) then
                return true 
            end
        end 
    end
    if self:swapTiles(self.board.tiles[1][1], self.board.tiles[1][2]) then
        return true
    elseif self:swapTiles(self.board.tiles[1][1], self.board.tiles[2][1]) then 
        return true
    elseif self:swapTiles(self.board.tiles[1][8], self.board.tiles[8][7]) then 
        return true 
    elseif self:swapTiles(self.board.tiles[1][8], self.board.tiles[2][8]) then 
        return true 
    elseif self:swapTiles(self.board.tiles[8][1], self.board.tiles[7][1]) then 
        return true 
    elseif self:swapTiles(self.board.tiles[8][1], self.board.tiles[8][2]) then 
        return true 
    elseif self:swapTiles(self.board.tiles[8][8], self.board.tiles[8][7]) then 
        return true 
    else
        return false 
    end
end

function PlayState:swapTiles(tile1, tile2)
    local tempX = tile1.gridX
    local tempY = tile1.gridY

    tile1.gridX = tile2.gridX
    tile1.gridY = tile2.gridY
    tile2.gridX = tempX
    tile2.gridY = tempY

    self.board.tiles[tile1.gridY][tile1.gridX] = tile1
    self.board.tiles[tile2.gridY][tile2.gridX] = tile2

    local result = self.board:calculateMatches()
    
    tile2.gridX = tile1.gridX
    tile2.gridY = tile1.gridY
    tile1.gridX = tempX
    tile1.gridY = tempY
    self.board.tiles[tile1.gridY][tile1.gridX] = tile1
    self.board.tiles[tile2.gridY][tile2.gridX] = tile2

    return result

end

function PlayState:calculateMatches()
    self.highlightedTile = nil

    local matches = self.board:calculateMatches()
    
    if matches then
        gSounds['match']:stop()
        gSounds['match']:play()

        for k, match in pairs(matches) do
            for i, tile in pairs(match) do
                self.score = self.score + (tile.variety * 50)
                self.timer = self.timer + 1
            end
        end

        self.board:removeMatches()

        local tilesToFall = self.board:getFallingTiles(self.level)

        Timer.tween(0.25, tilesToFall):finish(function()
            
            self:calculateMatches()
        end)
    
    else
        self.canInput = true
    end
end

function PlayState:render()
    self.board:render()

    if self.highlightedTile then
        
        love.graphics.setBlendMode('add')

        love.graphics.setColor(255, 255, 255, 96)
        love.graphics.rectangle('fill', (self.highlightedTile.gridX - 1) * 32 + (VIRTUAL_WIDTH - 272),
            (self.highlightedTile.gridY - 1) * 32 + 16, 32, 32, 4)

        love.graphics.setBlendMode('alpha')
    end

    if self.rectHighlighted then
        love.graphics.setColor(217, 87, 99, 255)
    else
        love.graphics.setColor(172, 50, 50, 255)
    end

    love.graphics.setLineWidth(4)
    love.graphics.rectangle('line', self.boardHighlightX * 32 + (VIRTUAL_WIDTH - 272),
        self.boardHighlightY * 32 + 16, 32, 32, 4)

    love.graphics.setColor(56, 56, 56, 234)
    love.graphics.rectangle('fill', 16, 16, 186, 116, 4)

    love.graphics.setColor(99, 155, 255, 255)
    love.graphics.setFont(gFonts['medium'])
    love.graphics.printf('Level: ' .. tostring(self.level), 20, 24, 182, 'center')
    love.graphics.printf('Score: ' .. tostring(self.score), 20, 52, 182, 'center')
    love.graphics.printf('Goal : ' .. tostring(self.scoreGoal), 20, 80, 182, 'center')
    love.graphics.printf('Timer: ' .. tostring(self.timer), 20, 108, 182, 'center')
end