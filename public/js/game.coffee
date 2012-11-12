class Game
  constructor: (@height, @width, @cell_size) ->
    this.height    = parseInt(@height / @cell_size) + 8
    this.width     = parseInt(@width / @cell_size) + 8
    this.cell_size = @cell_size
    this.universe  = null
    
  initialize_universe: ->
    height_count  = 0
    this.universe = new Array(this.height)
    while height_count < this.height
      this.universe[height_count] = new Array(this.width)
      width_count = 0
      while width_count < this.width
        this.universe[height_count][width_count] = new Cell(width_count, height_count)
        width_count += 1
      height_count += 1

  initial_state: (ary) ->
    for cell in ary
      this.universe[cell.y][cell.x].alive = true

class SandMan
  constructor: (@universe, @animate, @tick_limit) ->
    this.current_tick = 0

  evaluate_current_universe: ->
    for row, row_index in this.universe
      for cell, cell_index in row
        neighbors = this.evaluate_neighbors(cell)
        this.determine_cell_state(cell, neighbors)

  evaluate_next_universe: ->
    for row, row_index in this.universe
      for cell, cell_index in row
        cell.alive = cell.next

  tick: ->
    this.evaluate_current_universe()
    this.evaluate_next_universe()
    this.animate.draw_universe(this.universe)
    this.current_tick += 1

  is_not_border: (cell) ->
    this.is_not_top(cell) && this.is_not_bottom(cell) && this.is_not_left(cell) && this.is_not_right(cell)
  
  is_not_top: (cell) ->
    cell.y != 0
  
  is_not_bottom: (cell) ->
    cell.y != this.universe.length - 1
  
  is_not_left: (cell) ->
    cell.x != 0
  
  is_not_right: (cell) ->
    cell.x != this.universe[0].length - 1

  evaluate_neighbors: (cell) ->
    alive_neighbors = 0        
    alive_neighbors += this.above_neighbors(cell)
    alive_neighbors += this.next_to_neighbors(cell)
    alive_neighbors += this.below_neighbors(cell)
    alive_neighbors
  
  above_neighbors: (cell) ->
    alive_neighbors = 0
    if this.is_not_top(cell)
      alive_neighbors += 1 if this.universe[cell.y-1][cell.x].alive   == true
      if this.is_not_left(cell)
        alive_neighbors += 1 if this.universe[cell.y-1][cell.x-1].alive == true
      if this.is_not_right(cell)
        alive_neighbors += 1 if this.universe[cell.y-1][cell.x+1].alive == true
    alive_neighbors

  next_to_neighbors: (cell) ->
    alive_neighbors = 0
    if this.is_not_left(cell)
      alive_neighbors += 1 if this.universe[cell.y][cell.x-1].alive == true
    if this.is_not_right(cell)
      alive_neighbors += 1 if this.universe[cell.y][cell.x+1].alive == true      
    alive_neighbors
  
  below_neighbors: (cell) ->
    alive_neighbors = 0
    if this.is_not_bottom(cell)
      alive_neighbors += 1 if this.universe[cell.y+1][cell.x].alive   == true
      if this.is_not_left(cell)
        alive_neighbors += 1 if this.universe[cell.y+1][cell.x-1].alive == true
      if this.is_not_right(cell)
        alive_neighbors += 1 if this.universe[cell.y+1][cell.x+1].alive == true
    alive_neighbors
  
  determine_cell_state: (cell, neighbor_count) ->
    if cell.alive == true
      # Any live cell with fewer than two live neighbours dies, as if caused by under-population.
      cell.next  = false if neighbor_count < 2
    
      # Any live cell with two or three live neighbours lives on to the next generation.
      cell.next  = true if neighbor_count == 2 || neighbor_count == 3

      # Any live cell with more than three live neighbours dies, as if by overcrowding.
      cell.next  = false if neighbor_count > 3
    else
      # Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.
      cell.next  = true if neighbor_count == 3
      
class Cell
  constructor: (@x, @y) ->
    this.x     = @x
    this.y     = @y
    this.alive = false
    this.next  = false

class Animate
  constructor: (@id, @canvas_height, @canvas_width, @stroke, @frame_rate) ->
    this.ctx        = document.getElementById("#{@id}").getContext("2d")
    this.height     = @canvas_height
    this.width      = @canvas_width
    this.stroke     = @stroke
    this.list_size  = 0
    this.frame_rate = @frame_rate

  reset_canvas: ->
    this.ctx.clearRect(0, 0, this.height, this.width)

  draw_universe: (array) ->
    for row, row_index in array
      for cell, cell_index in row
        this.draw_frame(cell)
      
  draw_frame: (current_cell) ->
    switch current_cell.alive
      when false
        this.ctx.clearRect(current_cell.x * this.stroke, current_cell.y * this.stroke, this.stroke, this.stroke)
        this.ctx.fillStyle = "rgb(45,123,200)"
        this.ctx.fillRect(current_cell.x * this.stroke, current_cell.y * this.stroke, this.stroke, this.stroke)
      when true
        this.ctx.clearRect(current_cell.x * this.stroke, current_cell.y * this.stroke, this.stroke, this.stroke)
        this.ctx.fillStyle = "rgb(255,153,0)"
        this.ctx.fillRect(current_cell.x * this.stroke, current_cell.y * this.stroke, this.stroke, this.stroke)

$(document).ready ->
  # number in milliseconds to pause between animation frames
  frame_rate = 100

  # number in pixels to determine size of individual cells (as a square)
  cell_size = 10

  canvas_height = parseInt($('#game').css('height').replace("px", ""))
  canvas_width  = parseInt($('#game').css('width').replace("px", ""))
  animate       = new Animate("game", canvas_height, canvas_width, cell_size, frame_rate)
  game          = new Game(canvas_height, canvas_width, cell_size)
  
  game.initialize_universe()
  game.initial_state(gospers_glider_gun)
  animate.draw_universe(game.universe)
  sandman = new SandMan(game.universe, animate, 500)

  $('#hidden_stop').val(false)

  $('#stop').toggle(
    () ->
        $('#hidden_stop').val(true)
        $('#stop').html("Resume")
    ,
    () ->
        $('#hidden_stop').val(false)
        $('#stop').html("Stop")
  )

  $('#start').click () ->
    start_game(sandman, frame_rate)

  $('.selection').click () ->
    $('.selected').removeClass("selected")
    $(this).addClass("selected")
    $('#hidden_stop').val(true)
    $('#hidden_stop').html("Stop")
    window.setTimeout(
      () =>
        game.initialize_universe()
        selection = starting_condition($(this).attr("id"))
        game.initial_state(selection)
        animate.draw_universe(game.universe)
        sandman.universe = game.universe
        $('#start').unbind('click').click () ->
          $('#hidden_stop').val(false)
          start_game(sandman, frame_rate)
      ,
        500
    )

start_game = (sandman, frame_rate) ->
  if $('#hidden_stop').val() == false
    sandman.tick()
  window.setTimeout(
    () =>
      start_game(sandman, stop, frame_rate)
    ,
      frame_rate
  )

starting_condition = (selection) ->
  switch selection
    when "r_pentomino"
      r_pentomino = []
      r_pentomino[0] = new Cell(20, 15)
      r_pentomino[1] = new Cell(21, 15)
      r_pentomino[2] = new Cell(20, 16)
      r_pentomino[3] = new Cell(20, 17)
      r_pentomino[4] = new Cell(19, 16)
      return r_pentomino
    when "diehard"
      diehard = []
      diehard[0] = new Cell(20, 20)
      diehard[1] = new Cell(21, 20)
      diehard[2] = new Cell(21, 21)
      diehard[3] = new Cell(26, 19)
      diehard[4] = new Cell(26, 21)
      diehard[5] = new Cell(25, 21)
      diehard[6] = new Cell(27, 21)
      return diehard
    when "acorn"
      acorn = []
      acorn[0] = new Cell(54, 20)
      acorn[1] = new Cell(55, 20)
      acorn[2] = new Cell(55, 18)
      acorn[3] = new Cell(57, 19)
      acorn[4] = new Cell(58, 20)
      acorn[5] = new Cell(59, 20)
      acorn[6] = new Cell(60, 20)
      return acorn
    when "gospers_glider_gun"
      gospers_glider_gun = []
      gospers_glider_gun[0] = new Cell(2, 7)
      gospers_glider_gun[1] = new Cell(3, 7)
      gospers_glider_gun[2] = new Cell(2, 8)
      gospers_glider_gun[3] = new Cell(3, 8)
      gospers_glider_gun[4] = new Cell(12, 7)
      gospers_glider_gun[5] = new Cell(12, 8)
      gospers_glider_gun[6] = new Cell(12, 9)
      gospers_glider_gun[7] = new Cell(13, 6)
      gospers_glider_gun[8] = new Cell(14, 5)
      gospers_glider_gun[9] = new Cell(15, 5)
      gospers_glider_gun[10] = new Cell(13, 10)
      gospers_glider_gun[11] = new Cell(14, 11)
      gospers_glider_gun[12] = new Cell(15, 11)
      gospers_glider_gun[13] = new Cell(16, 8)
      gospers_glider_gun[14] = new Cell(17, 6)
      gospers_glider_gun[15] = new Cell(18, 7)
      gospers_glider_gun[16] = new Cell(18, 8)
      gospers_glider_gun[17] = new Cell(18, 9)
      gospers_glider_gun[18] = new Cell(17, 10)
      gospers_glider_gun[19] = new Cell(19, 8)
      gospers_glider_gun[20] = new Cell(22, 5)
      gospers_glider_gun[21] = new Cell(23, 5)
      gospers_glider_gun[22] = new Cell(22, 6)
      gospers_glider_gun[23] = new Cell(23, 6)
      gospers_glider_gun[24] = new Cell(22, 7)
      gospers_glider_gun[25] = new Cell(23, 7)
      gospers_glider_gun[26] = new Cell(24, 4)
      gospers_glider_gun[27] = new Cell(24, 8)
      gospers_glider_gun[28] = new Cell(26, 4)
      gospers_glider_gun[29] = new Cell(26, 3)
      gospers_glider_gun[30] = new Cell(26, 8)
      gospers_glider_gun[31] = new Cell(26, 9)
      gospers_glider_gun[32] = new Cell(36, 5)
      gospers_glider_gun[33] = new Cell(36, 6)
      gospers_glider_gun[34] = new Cell(37, 5)
      gospers_glider_gun[35] = new Cell(37, 6)
      return gospers_glider_gun
    when "random"
      height_count  = 0
      universe      = new Array(40)
      while height_count < 40
        random = Math.floor((Math.random() * 1000))
        cell = new Cell(Math.floor((Math.random() * 100) % 50), Math.floor((Math.random() * 100) % 20))
        cell.alive = true if (random % 3 == 0)
        if cell.alive
          universe[height_count] = cell
          new_cell = new Cell(cell.x + 1, cell.y + 1)
          new_cell.active = true
          universe[height_count + 1] = new_cell
          new_cell2 = new Cell(cell.x - 1, cell.y)
          new_cell2.active = true
          universe[height_count + 2] = new_cell2
          new_cell3 = new Cell(cell.x - 1, cell.y + 1)
          new_cell3.active = true
          universe[height_count + 3] = new_cell3
          new_cell4 = new Cell(cell.x - 1, cell.y - 1)
          new_cell4.active = true
          universe[height_count + 4] = new_cell4
          height_count += 4
      return universe
      