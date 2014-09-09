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
  c: 'circle'
  d: 'diamond'
  h: 'hex'

g = window.dwim_graphics

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

class Dwim
  constructor: (@cnv) ->
    @ctx = @cnv.getContext('2d')
    @W = @cnv.width
    @H = @cnv.height

    @Wi = Math.floor(@W / g.cell_size)
    @Hi = Math.floor(@H / g.cell_size)
  
  start: (level) ->
    @botx = level.startpos.x
    @boty = level.startpos.y
    @botdir = RIGHT.theta

    @Wi = level.dims.w
    @Hi = level.dims.h
    @cnv.width  = @W = @Wi * g.cell_size
    @cnv.height = @H = @Hi * g.cell_size
    @ctx = @cnv.getContext('2d')

    @level = []
    for x in [0...@Wi]
      @level[x] = []
      for y in [0..@Hi]
        @level[x][y] = {type: 'empty'}

    @programs = []
    for program in level.programs
      id = @programs.length
      @programs[id] = program

      for {x:x, y:y} in parseRanges(program.loc)
        @level[x][y] = {type: 'program', id: id}

    @obstacles = []
    for obstacle in level.obstacles
      id = @obstacles.length
      @obstacles[id] = obstacle

      for {x:x, y:y} in parseRanges(obstacle)
        @level[x][y] = {type: 'obstacle', id: id}

    @available_mappings = level.available_mappings

    @active_program = null
    @allowed_move = null
    @mappings = [ new Mapping() ]
    @active_mapping = null
    
    @startRenderer()
    @startInput()

  startRenderer: ->
    requestAnimationFrame(@renderCB)

  startInput: ->
    registerKeyFunction(@keyboardCB)

  renderCB: =>
    g.clear(@ctx, @W, @H)
    g.border(@ctx, @W, @H)

    for x in [0...@Wi]
      for y in [0...@Hi]
        switch @level[x][y].type
          when 'empty'
            true
          when 'program'
            @renderProgramCell(x, y)
          when 'obstacle'
            @renderObstacleCell(x, y)

    bot =
      showxi: @botx
      showyi: @boty
      showdir: @botdir
      render: g.renderBot

    bot.render(@ctx)

    if not @stop_render
      requestAnimationFrame(@renderCB)

  keyboardCB: (key) =>
    if key of keymap
      dir = keymap[key]
      @requestBotMove( dir )

  renderProgramCell: (x, y) ->
    cs = g.cell_size
    @ctx.save()
    @ctx.fillStyle = 'blue'
    @ctx.fillRect(x*cs, y*cs, cs, cs)
    @ctx.restore()

  renderObstacleCell: (x, y) ->
    cs = g.cell_size
    @ctx.save()
    @ctx.fillStyle = 'white'
    @ctx.fillRect(x*cs, y*cs, cs, cs)
    @ctx.restore()

  updateAllowedMove: () ->
    if not @active_program?
      @allowed_move = null
      return

    # set, but invalid, no move possible
    @allowed_move = {x:-1,y:-1}

    action = @translateInstruction(@currentInstruction())
    if action.type == 'move'
      @allowed_move = x: @botx + action.dir.dx, y: @boty + action.dir.dy
    if action.type == 'blank'
      @allowed_move = null

    # otherwise movement is not possible
    return

  isMoveAllowed: (x, y) ->
    # check borders
    if x < 0 or y < 0 or x >= @Wi or y >= @Hi
      return false

    if @level[x][y].type == 'obstacle'
      return false

    if @allowed_move?
      console.log('allowed ' +@allowed_move.x+','+@allowed_move.y)
      if @allowed_move.x != x or @allowed_move.y != y
        return false

    return true

  requestBotMove: (dir) ->
    x = @botx + dir.dx
    y = @boty + dir.dy

    console.log('want ' +x+','+y)
    
    if @isMoveAllowed(x,y)
      if @active_program?
        @execute({type: 'move', dir: dir})
      else
        # free movement
        @botx = x
        @boty = y
        @botdir = dir.theta

        @updateProgram()
    else if not @active_program?
      # at least turn in the desired direction
      @botdir = dir.theta

    return

  currentInstruction: () ->
    return @active_program.code.charAt(@pc)

  translateInstruction: (instruction) ->
    return @active_mapping.mapCode(instruction)

  execute: (requested_action) ->
    ra = requested_action
    if not @active_program?
      return false

    action = @translateInstruction(@currentInstruction())

    # check that requested action matches action to execute
    if action.type != 'blank' and action.type != ra.type
      return false

    switch action.type
      when 'move'
        if ra.dir.dx + @botx == @allowed_move.x and
           ra.dir.dy + @boty == @allowed_move.y
          @botx = @allowed_move.x
          @boty = @allowed_move.y
          @botdir = ra.dir.theta
        else
          return false
      when 'mapping'
        if ra.id == action.id
          @active_mapping = @mappings[action.id]
        else
          return false
      when 'blank'
        @installMapping(@active_mapping, requested_action,
                        @currentInstruction())
        @updateProgram()
        # recursively execute the command
        return @execute(requested_action)

    @pc += 1
    if @pc == @active_program.code.length
      @active_program = null
      @active_mapping = null # questionable

    @updateProgram()

    return true

  updateProgram: () ->
    cell = @level[@botx][@boty]
    if cell.type == 'program'
      if @active_program? and
           @active_program.code == @programs[cell.id].code
          true # no change
        else
          # TODO: notify user
          @active_program = @programs[cell.id]
          @active_mapping = @mappings[0] # questionable
          @pc = 0

    @updateAllowedMove()
    #@showExecutionStatus()
    return

  installMapping: (mapping, action, instruction) ->
    new_action = null

    switch action.type
      when 'move'
        console.log('install')
        new_action = new MoveCommand(action.dir)

    mapping.setMapping(instruction, new_action)

class Program
  constructor: (@instructions) ->

  render: (ctx, t = 0) ->
    cs = g.command_size

    ctx.save()
    g.setStyle(ctx, g.thick_lined_style)

    if @active?
      ctx.translate(cs/2, cs/2 - (@active+t) * cs)
    else
      ctx.translate(cs/2, cs/2)

    for instruction in @instructions
      g.renderShape(ctx, instruction, g.inner_command_size/2)

      ctx.translate(0, cs)

    ctx.restore()

    if @active?
      ctx.save()
      g.setStyle(ctx, g.lined_style)
      ctx.strokeRect(0, 0, cs, cs)
      ctx.restore()


class Mapping
  constructor: () ->
    @instructions = []
    @commands = []

  mapCode: (instruction) ->
    idx = @instructions.indexOf(instruction)

    if idx == -1
      return {type: 'blank'}
    else
      return @commands[idx]

  setMapping: (instruction, command) ->
    idx = @instructions.indexOf(instruction)
    if idx == -1
      idx = @instructions.length
      @instructions[idx] = instruction

    @commands[idx] = command

  render: (ctx) ->
    ocs = g.outer_command_size
    len = @instructions.length

    ctx.save()
    g.setStyle(ctx, g.lined_style)

    # container
    ctx.beginPath()
    ctx.moveTo(0,0)
    ctx.lineTo(ocs * 2, 0)
    ctx.lineTo(ocs * 2, ocs * len)
    ctx.lineTo(0, ocs * len)
    ctx.closePath()
    ctx.stroke()

    # vertical divider
    ctx.beginPath()
    ctx.moveTo(ocs, 0)
    ctx.lineTo(ocs, ocs * len)
    ctx.stroke()

    # horizontal dividers
    for idx in [1...len]
      ctx.beginPath()
      ctx.moveTo(0, ocs * idx)
      ctx.lineTo(ocs * 2, ocs * idx)
      ctx.stroke()
    
    # symbols
    ctx.save()
    ctx.translate(ocs/2, ocs/2)
    for char in @instructions
      g.renderShape(ctx, instruction_names[char], g.inner_command_size/2)
      ctx.translate(0, ocs)
    ctx.restore()

    # commands (if present)
    ctx.translate(ocs*3/2, ocs/2)
    for idx in [0...len]
      if idx of @commands
        @commands[idx].render(ctx)
      ctx.translate(0, ocs)

    ctx.restore()

    ctx.save()
    g.setStyle(ctx, g.lined_style)
    ctx.restore()

class MoveCommand
  constructor: (@dir) ->

  type: 'move'

  render: (ctx) ->
    ctx.save()
    g.setStyle(ctx, g.lined_style)
    g.renderArrow(ctx, @dir.theta, g.inner_command_size)
    ctx.restore()

window.Dwim = Dwim

