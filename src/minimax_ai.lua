local Board = require('board')
local TIE, CELL_X, CELL_O = Board.TIE, Board.CELL_X, Board.CELL_O

function choose_best_move(board, current_player)
    local best_move
    local best_score = -math.huge
    local empty_cells = board:get_empty_cells()

    for i = 1, #empty_cells do
        local cell = empty_cells[i]

        board:set_cell(cell.x, cell.y, current_player)
        local score = minimax_score(board, 0, false, current_player)
        board:set_cell(cell.x, cell.y, nil)

        if score > best_score then
            best_score = score
            best_move = {x = cell.x, y = cell.y}
        end
    end

    return best_move
end

function minimax_score(board, depth, is_maximizing, who_i_am)
    local winner = board:get_winner()
    if winner ~= nil then
        if winner == TIE then
            return 0
        elseif winner == who_i_am then
            return 1
        else
            return -1
        end
    end

    local best_score
    local empty_cells = board:get_empty_cells()

    if is_maximizing then
        best_score = -math.huge
        for i = 1, #empty_cells do
            local cell = empty_cells[i]
            board:set_cell(cell.x, cell.y, who_i_am)
            local score = minimax_score(board, depth + 1, false, who_i_am)
            board:set_cell(cell.x, cell.y, nil)
            best_score = math.max(score, best_score)
        end
    else
        best_score = math.huge
        for i = 1, #empty_cells do
            local cell = empty_cells[i]
            board:set_cell(cell.x, cell.y, get_opponent(who_i_am))
            local score = minimax_score(board, depth + 1, true, who_i_am)
            board:set_cell(cell.x, cell.y, nil)
            best_score = math.min(score, best_score)
        end
    end

    return best_score
end

function get_opponent(cell)
    if cell == CELL_X then
        return CELL_O
    elseif cell == CELL_O then
        return CELL_X
    end
end

return {
    choose_best_move = choose_best_move
}