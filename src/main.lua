local colors = require('colors')
local utils = require('utils')

local random_ai = require('random_ai')
local minimax_ai = require('minimax_ai')

local Board = require('board')
local TIE, CELL_X, CELL_O = Board.TIE, Board.CELL_X, Board.CELL_O
Board = Board.Board
local CELL_RANDOM = -1

local MOUSE_LMB_BUTTON = 1
local MENU_NONE, MENU_MAIN, MENU_SETTINGS = 0, 1, 2
local MODE_HUMAN_VS_HUMAN, MODE_HUMAN_VS_AI, MODE_AI_VS_AI = 0, 1, 2
local AI_RANDOM, AI_MINIMAX, AI_MINIMAX_ALPHA_BETA_PRUNING = 0, 1, 2

local board_draw_offset = { x = 0, y = 50 }
local message_text = ''
local fonts = {}
local board, current_player, current_menu, gamemode, ai_type, first_cell_turn, ai_player_cell
local main_buttons, settings_buttons

function love.load()
    math.randomseed(os.time())

    love.graphics.setBackgroundColor(colors.WHITE)

    set_board_size(3)
    set_ai_type(AI_MINIMAX)
    set_ai_player_cell(CELL_O)
    set_gamemode(MODE_HUMAN_VS_AI)
    set_first_turn(CELL_RANDOM)
    set_current_menu(MENU_MAIN)

    fonts[12] = love.graphics.newFont(12)
    fonts[16] = love.graphics.newFont(16)
    fonts[24] = love.graphics.newFont(24)
    init_buttons()
end

function love.mousepressed(x, y, button, is_touch, presses)
    if button == MOUSE_LMB_BUTTON then
        -- Do not process clicks if the game is over.
        if current_menu ~= MENU_NONE then
            return
        end

        local a, b = board:get_cell_on_point(x, y)
        if a == nil or b == nil then
            return
        end

        -- Do not process clicks for AI.
        if gamemode == MODE_AI_VS_AI or (gamemode == MODE_HUMAN_VS_AI and current_player == ai_player_cell) then
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

function new_button(text, fn, selected)
    return {
        text = text,
        callback = fn,
        clicked_now = false,
        clicked_last = false,
        selected = selected or false
    }
end

function new_selecting_buttons(...)
    local items = {...}
    local btns = {}

    for i = 1, #items do
        local item = items[i]

        btns[i] = new_button(item[1], function()
            -- Highlight the current item and deselect the others.
            for j = 1, #btns do
                btns[j].selected = i == j
            end

            item[2]() -- Call buttons handler.
        end, item[3])
    end

    return btns
end

function init_buttons()
    main_buttons = {
        new_button('Start', restart_game),
        new_button('Settings', function()
            set_current_menu(MENU_SETTINGS)
        end),
        new_button('Exit', function()
            love.event.quit()
        end)
    }

    settings_buttons = {
        {'Board size', new_selecting_buttons(
            {'3x3', function() set_board_size(3) end, true},
            {'4x4', function() set_board_size(4) end},
            {'5x5', function() set_board_size(5) end}
        )},
        {'Game mode', new_selecting_buttons(
            {'Human vs AI', function() set_gamemode(MODE_HUMAN_VS_AI) end, true},
            {'Human vs Human', function() set_gamemode(MODE_HUMAN_VS_HUMAN) end},
            {'AI vs AI', function() set_gamemode(MODE_AI_VS_AI) end}
        )},
        {'AI type', new_selecting_buttons(
            {'Random', function() set_ai_type(AI_RANDOM) end},
            {'Minimax', function() set_ai_type(AI_MINIMAX) end, true}
        ), function()
            return gamemode ~= MODE_HUMAN_VS_HUMAN
        end},
        {'AI cell', new_selecting_buttons(
            {'X', function() set_ai_player_cell(CELL_X) end},
            {'O', function() set_ai_player_cell(CELL_O) end, true}
        ), function()
            return gamemode == MODE_HUMAN_VS_AI
        end},
        {'First turn', new_selecting_buttons(
            {'X', function() set_first_turn(CELL_X) end},
            {'O', function() set_first_turn(CELL_O) end},
            {'Random', function() set_first_turn(CELL_RANDOM) end, true}
        )}
    }
end

function draw_buttons(buttons, x, y, horizontal, button_width, button_height, margin, font)
    local buttons_count = #buttons
    local half_total_width, half_total_height

    if horizontal then
        half_total_width = ((button_width + margin) * buttons_count) * 0.5
        half_total_height = button_height * 0.5
    else
        half_total_width = button_width * 0.5
        half_total_height = ((button_height + margin) * buttons_count) * 0.5
    end

    local cursor = 0

    for i = 1, buttons_count do
        local btn = buttons[i]

        btn.clicked_last = btn.clicked_now
        btn.clicked_now = love.mouse.isDown(MOUSE_LMB_BUTTON)

        local button_x = x - half_total_width
        local button_y = y - half_total_height

        local half_text_width = font:getWidth(btn.text) * 0.5
        local half_text_height = font:getHeight(btn.text) * 0.5
        local text_x, text_y

        if horizontal then
            text_x = half_text_width + button_x + cursor
            text_y = y - half_text_height
            button_x = button_x + cursor
            cursor = cursor + margin + button_width
        else
            text_x = x - half_text_width
            text_y = half_text_height + button_y + cursor
            button_y = button_y + cursor
            cursor = cursor + margin + button_height
        end

        local mx, my = love.mouse.getPosition()
        local mouse_on_button = utils.is_point_in_square(mx, my, button_x, button_y, button_width, button_height)
        local btn_color = colors.GRAY_BLUE

        if mouse_on_button then
            btn_color = colors.GRAYISH_BLUE
            if btn.clicked_now and not btn.clicked_last then
                btn.callback(btn)
            end
        end

        if btn.selected then
            btn_color = colors.GREEN
        end

        love.graphics.setColor(btn_color)
        love.graphics.rectangle('fill', button_x, button_y, button_width, button_height)

        love.graphics.setColor(colors.BLACK)
        if current_menu == MENU_SETTINGS then text_x = text_x - (half_text_width * 0.9) end -- Temporary crutch...
        love.graphics.print(btn.text, font, text_x, text_y)
    end
end

function draw_settings(buttons, x, y)
    -- Calculate max text width for space betwen buttons and label.
    local max_text_width = -math.huge
    for i = 1, #buttons do
        max_text_width = math.max(fonts[12]:getWidth(buttons[i][1]), max_text_width)
    end

    local cursor = 0

    local text_x = x * 0.1
    local text_y = y - (y / 3) + cursor
    local btn_x = text_x + max_text_width + 200

    for i = 1, #buttons do
        local btn = buttons[i]

        local need_draw = false
        if btn[3] == nil then
            need_draw = true
        else
            need_draw = btn[3]()
        end

        if need_draw then
            local name = btn[1] .. ':'

            local text_y = text_y + cursor
            local btn_y = text_y

            love.graphics.setColor(colors.WHITE)
            love.graphics.print(name, fonts[12], text_x, text_y)

            draw_buttons(btn[2], btn_x, btn_y + 10, true, 120, 40, 10, fonts[12])

            cursor = cursor + 60
        end
    end

    draw_buttons({new_button('OK', function()
        set_current_menu(MENU_MAIN)
    end)}, x, text_y + cursor + 10, false, 100, 40, 10, fonts[16])
end

function love.draw()
    local window_width, window_height = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.setColor(colors.BLACK)

    love.graphics.print(message_text, 0, 0)

    -- Separator betwen message and board.
    love.graphics.line(0, board_draw_offset.y, window_width, board_draw_offset.y)

    board:draw()

    if current_menu ~= MENU_NONE then
        love.graphics.setColor(0, 0, 0, 0.9) -- Semi-transparent black. Todo: Use a blur shader.
        love.graphics.rectangle('fill', 0, 0, window_width, window_height)

        local x = window_width * 0.5
        local y = window_height * 0.5

        love.graphics.setColor(colors.WHITE)
        love.graphics.print(message_text, fonts[16], x - fonts[16]:getWidth(message_text) * 0.5, y - (y * 0.5))

        if current_menu == MENU_MAIN then
            draw_buttons(main_buttons, x, y, false, 200, 50, 10, fonts[24])
        else
            draw_settings(settings_buttons, x, y)
        end
    end
end

function get_board_space_for_size(size)
    return love.graphics.getWidth() / size
end

function restart_game()
    main_buttons[1].text = 'Retry'
    board:reset_cells()
    set_current_menu(MENU_NONE)
    set_current_player(get_first_turn())
end

function play_ai()
    local cell
    if ai_type == AI_RANDOM then
        cell = random_ai.choose_random_move(board)
    elseif ai_type == AI_MINIMAX then
        cell = minimax_ai.choose_best_move(board, current_player)
    end
    if cell then
        board:set_cell(cell.x, cell.y, current_player)
        switch_player()
        check_win()
    end
end

function switch_player()
    set_current_player(current_player == CELL_X and CELL_O or CELL_X)
end

local waiting_timer = 0
local need_play_as_ai = false

function love.update(dt)
    waiting_timer = waiting_timer + dt
    if waiting_timer > 0.5 then
        waiting_timer = 0
        if need_play_as_ai then
            need_play_as_ai = false
            play_ai()
        end
    end
end

function set_current_player(player)
    current_player = player
    message_text = 'Player ' .. (current_player == CELL_X and 'X' or 'O') .. ' turn.'

    if gamemode == MODE_HUMAN_VS_AI then
        if current_player == ai_player_cell then
            play_ai()
        end
    elseif gamemode == MODE_AI_VS_AI then
        need_play_as_ai = true
    end
end

function set_board_size(size)
    board = Board:new(size, get_board_space_for_size(size), board_draw_offset)
end

function set_ai_type(ai)
    ai_type = ai
end

function set_gamemode(mode)
    gamemode = mode
end

function set_current_menu(menu)
    current_menu = menu
end

function set_first_turn(cell)
    first_cell_turn = cell
end

function set_ai_player_cell(cell)
    ai_player_cell = cell
end

function get_first_turn()
    if first_cell_turn == CELL_RANDOM then
        local r = math.random(1, 2)
        return r == 1 and CELL_X or CELL_O
    else
        return first_cell_turn
    end
end

function check_win()
    local winner = board:get_winner()
    if winner ~= nil then
        if winner == CELL_X then
            message_text = 'Player X won.'
        elseif winner == CELL_O then
            message_text = 'Player O won.'
        elseif winner == TIE then
            message_text = 'Tie.'
        end
        set_current_menu(MENU_MAIN)
    end
end
