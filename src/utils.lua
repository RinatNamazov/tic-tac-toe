function is_point_in_square(x, y, rect_x, rect_y, width, height)
    return x > rect_x and x < (rect_x + width) and
           y > rect_y and y < (rect_y + height)
end

return {
    is_point_in_square = is_point_in_square,
}
