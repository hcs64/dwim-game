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

    @bot = {x: level.startpos.x, y: level.startpos.y}

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

  requestBotMove: (dir) ->
    dest = {x: @bot.x + dir.dx, y: @bot.y + dir.dy}
    if @level[dest.x][dest.y].type != 'obstacle'
      @bot.x = dest.x
      @bot.y = dest.y
      return true
    else
      return false

################

class Dwim
  constructor: (@parent_div, @level) ->
    @state = new DwimState(@level)
    gfx = @gfx = new window.DwimGraphics(@parent_div, @state)

    @bot_sprite =
      # this of course all belongs in graphics
      computePos: =>
        x: (@state.bot.x+.5)*@gfx.block+@gfx.board_dims.x-.5
        y: (@state.bot.y+.5)*@gfx.block+@gfx.board_dims.y-.5
      render: (ctx) ->
         ctx.strokeStyle = 'white'
         ctx.fillStyle = 'black'
         stretch = 2*(1-Math.abs(@t-.5))
         if @dir == UP or @dir == DOWN
           ctx.scale(1/stretch, stretch)
         else
           ctx.scale(stretch, 1/stretch)
         ctx.lineWidth = 1.5
         gfx.renderShape('circle', gfx.block*.4, true)
      animations: []
      leftover_t: 0
    {x:@bot_sprite.x, y:@bot_sprite.y} = @bot_sprite.computePos()
    @gfx.sprites.push(@bot_sprite)
  render: (absolute_t) ->
    do_next = true
    while do_next and @bot_sprite.animations.length > 0
      do_next = false
      anim = @bot_sprite.animations[0]
      @bot_sprite.dir = anim.dir
      if not anim.start_t?
        anim.start_t = absolute_t
        anim.start_t -= @bot_sprite.leftover_t
        @bot_sprite.leftover_t = 0
      t = (absolute_t - anim.start_t) / anim.duration

      if t >= 1
        @bot_sprite.leftover_t = absolute_t - (anim.start_t + anim.duration)
        @bot_sprite.animations.shift()
        do_next = true
        @bot_sprite.x = anim.x1
        @bot_sprite.y = anim.y1
        @bot_sprite.t = anim.t1
      else
        @bot_sprite.x = (anim.x1 - anim.x0) * t + anim.x0
        @bot_sprite.y = (anim.y1 - anim.y0) * t + anim.y0
        @bot_sprite.t = (anim.t1 - anim.t0) * t + anim.t0

    @bot_sprite.leftover_t = 0
    @gfx.render()
  keyboardCB: (key) =>
    t = Date.now()
    if key of keymap
      dir = keymap[key]
      old_pos = @bot_sprite.computePos()
      if @state.requestBotMove(dir)
        new_pos = @bot_sprite.computePos()
        @bot_sprite.animations.push(
          duration: 150
          t0: 0, t1: 1
          x0: old_pos.x, y0: old_pos.y
          x1: new_pos.x, y1: new_pos.y
          dir: dir
        )
      else
        howfar = .15*@gfx.block
        new_pos = x: old_pos.x+dir.dx*howfar, y: old_pos.y+dir.dy*howfar
        @bot_sprite.animations.push(
          duration: 15
          t0: 0, t1: .10
          x0: old_pos.x, y0: old_pos.y
          x1: new_pos.x, y1: new_pos.y
          dir: dir
        )
        @bot_sprite.animations.push(
          duration: 50
          t0: .10, t1: 0
          x0: new_pos.x, y0: new_pos.y
          x1: new_pos.x, y1: new_pos.y
          dir: dir
        )
        @bot_sprite.animations.push(
          duration: 50
          t0: 0, t1: .1
          x0: new_pos.x, y0: new_pos.y
          x1: (new_pos.x+old_pos.x)/2, y1: (new_pos.y+old_pos.y)/2
          dir: dir
        )
        @bot_sprite.animations.push(
          duration: 50
          t0: .1, t1: 0
          x0: (new_pos.x+old_pos.x)/2, y0: (new_pos.y+old_pos.y)/2
          x1: old_pos.x, y1: old_pos.y
          dir: dir
        )


window.Dwim = Dwim
