# general directions
UP = (theta: Math.PI/2, dx: 0, dy: -1)
LEFT = (theta: Math.PI, dx: -1, dy: 0)
RIGHT = (theta: 0, dx: 1, dy: 0)
DOWN = (theta: -Math.PI/2, dx: 0, dy: 1)

keymap =
  # traditional wasd
  'w': UP
  'a': LEFT
  's': DOWN
  'd': RIGHT
  # arrow keys
  '<up>': UP
  '<left>': LEFT
  '<down>': DOWN
  '<right>': RIGHT

reverseDir = (dir) ->
  switch dir
    when UP
      return DOWN
    when DOWN
      return UP
    when LEFT
      return RIGHT
    when RIGHT
      return LEFT


instruction_names =
  s: 'square'
  c: 'star'
  d: 'diamond'
  h: 'hex'

parseRanges = (ranges_string) ->
  point_list = []

  for range in ranges_string.split(' ')
    [rangex, rangey] =
      for d in range.split(',')
        if d.indexOf('-') == -1
          i = parseInt(d, 10)
          [i, i]
        else
          i = d.split('-')
          [parseInt(i[0], 10), parseInt(i[1], 10)]
    for x in [rangex[0]..rangex[1]]
      for y in [rangey[0]..rangey[1]]
        point_list.push({x:x,y:y})

  point_list


################

class DwimState
  constructor: (level) ->
    @Wi = level.dims.w
    @Hi = level.dims.h

    @botx = level.startpos.x
    @boty = level.startpos.y

    @level = {}
    for x in [-1..@Wi]
      @level[x] = {}
      for y in [-1..@Hi]
        @level[x][y] = {type: 'empty'}

    # border
    for x in [-1..@Wi]
      @level[x][-1] = {type: 'obstacle', id: 0}
      @level[x][@Hi] = {type: 'obstacle', id: 0}
    for y in [-1..@Hi]
      @level[-1][y] = {type: 'obstacle', id: 0}
      @level[@Wi][y] = {type: 'obstacle', id: 0}

    # general obstacles
    @obstacles = [{}]
    for obstacle in level.obstacles
      id = @obstacles.length
      @obstacles[id] = obstacle

      for {x:x, y:y} in parseRanges(obstacle)
        if @level[x][y].type == 'obstacle' and @level[x][y].id == 0
          throw 'overwriting border with lesser obstacle'
        @level[x][y] = {type: 'obstacle', id: id}

    # programs
    @programs = []
    for program in level.programs
      id = @programs.length
      @programs[id] = program

      for {x:x, y:y} in parseRanges(program.loc)
        if @level[x][y].type == 'obstacle' and @level[x][y].id == 0
          throw 'overwriting border with program'
        @level[x][y] = {type: 'program', id: id}

    # exit
    if @level[level.exitpos.x][level.exitpos.y].type == 'obstacle' and
       @level[level.exitpos.x][level.exitpos.y].id == 0
      throw 'overwriting border with exit'
    @level[level.exitpos.x][level.exitpos.y] = {type: 'exit'}

    @available_mappings = level.available_mappings

################

class Dwim
  constructor: (@parent_div, @level) ->
    @state = new DwimState(@level)
    @gfx = new window.DwimGraphics(@parent_div, @state)
  render: ->
    @gfx.render()

window.Dwim = Dwim
