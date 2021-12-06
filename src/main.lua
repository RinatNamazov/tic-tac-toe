local colors = require('colors')

local Board = require('board')
local CELL_X, CELL_O = Board.CELL_X, Board.CELL_O
Board = Board.Board

local random_ai = require('random_ai')

-- Settings
local board_size = 5
local board_space = 100
local current_player = CELL_X

local process_game = true
local message_text = ''
local board

function love.load()
    love.graphics.setBackgroundColor(colors.WHITE)

    board = Board:new(board_size, board_space, {x = 0, y = 50})
end

function love.mousepressed(x, y, button, is_touch, presses)
    if button == 1 then -- LMB
        -- Do not process clicks if the game is over.
        if not process_game then
            return
        end

        local a, b = board:get_cell_on_point(x, y)
        if a == nil or b == nil then
            return
        end

        -- Do not change the status of already set cells.
        if board:get_cell(a, b) == nil then
            board:set_cell(a, b, current_player)
            switch_player()
            check_win()
        end
    end
end

function love.draw()
    love.graphics.setColor(colors.BLACK)

    love.graphics.print(message_text, 0, 0)

    -- Separator betwen message and board.
    love.graphics.line(0, 50, 500, 50)

    board:draw()
end

function play_ai()
    local cell = random_ai.choose_random_move(board)
    if cell then
        board:set_cell(cell.x, cell.y, current_player)
        switch_player()
        check_win()
    end
end

function switch_player()
    current_player = current_player == CELL_X and CELL_O or CELL_X
    message_text = 'Player ' .. (current_player == CELL_X and 'X' or 'O') .. ' turn'
    if current_player == CELL_O then
        play_ai()
    end
end

function check_win()
    local winner = board:get_winner()
    if winner == nil then
        return
    end

    process_game = false

    if winner == CELL_X then
        message_text = 'Player X won.'
    elseif winner == CELL_O then
        message_text = 'Player O won.'
    elseif winner == -1 then
        message_text = 'Tie.'
    end
end
