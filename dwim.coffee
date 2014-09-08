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

g = window.dwim_graphics

class Dwim
  constructor: (@cnv) ->
    @ctx = @cnv.getContext('2d')
    @W = @cnv.width
    @H = @cnv.height

    @Wi = Math.floor(@W / g.cell_size)
    @Hi = Math.floor(@H / g.cell_size)
  
  start: ->
    @botx = 5
    @boty = 5
    @botdir = UP.theta

    @program = new Program( [
      'circle',
      'circle',
      'square',
      'diamond',
      'square',
      'circle',
      'diamond'
      ])

    @mapping = new Mapping( [
      'circle',
      'square'
      'diamond'
      'hex'
      ])

    @mapping.commands[0] = new MoveCommand(LEFT)
    @mapping.commands[1] = new MoveCommand(UP)
    #@mapping.commands[2] = new MoveCommand(DOWN)
    @mapping.commands[3] = new MoveCommand(RIGHT)

    @pc = 0
    @execute()

    @startRenderer()
    @startInput()

  startRenderer: ->
    requestAnimationFrame(@renderCB)

  startInput: ->
    registerKeyFunction(@keyboardCB)

  renderCB: =>
    g.clear(@ctx, @W, @H)
    g.border(@ctx, @W, @H)

    bot =
      showxi: @botx
      showyi: @boty
      showdir: @botdir
      render: g.renderBot

    bot.render(@ctx)

    @ctx.save()
    @ctx.translate(30,30)
    @program.render(@ctx)
    @ctx.restore()

    @ctx.save()
    @ctx.translate(230,30)
    @mapping.render(@ctx)
    @ctx.restore()
    
    if not @stop_render
      requestAnimationFrame(@renderCB)

  keyboardCB: (key) =>
    if key of keymap
      dir = keymap[key]
      @moveBotTo(
        @botx + dir.dx,
        @boty + dir.dy,
        dir
      )

  execute: () ->
    @program.active = @pc
    @mapping.active = @program.instructions[@pc]

    next_command = @mapping.mapActive()
    console.log('active instr = ' + @mapping.active)

    if next_command?
      @allowed_move = next_command.movePoint((x: @botx, y: @boty))
    else
      @allowed_move = null

  installMapping: (new_command) ->
    cmd = null
    switch new_command.command_type
      when 'move'
        cmd = new MoveCommand(new_command.dir)

    if cmd?
      @mapping.installForActive(cmd)

  moveBotTo: (x, y, dir) ->
    console.log('want ' +x+','+y)
    # check borders
    if x < 0 or y < 0 or x >= @Wi or y >= @Hi
      return false

    if @allowed_move?
      console.log('allowed ' +@allowed_move.x+','+@allowed_move.y)
      if @allowed_move.x != x or @allowed_move.y != y
        return false
    else
      @installMapping((command_type: 'move', dir: dir))

    @botx = x
    @boty = y
    @botdir = dir.theta

    @pc +=1
    @execute()

    return true


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
  constructor: (@symbol_names) ->
    @commands = []

  mapActive: () ->
    if @active?
      idx = @symbol_names.indexOf(@active)
      if idx == -1
        return null
      else
        return @commands[idx]
    else
      return null

  installForActive: (cmd) ->
    idx = @symbol_names.indexOf(@active)
    if idx == -1
      return null
    @commands[idx] = cmd

  render: (ctx) ->
    ocs = g.outer_command_size

    ctx.save()
    g.setStyle(ctx, g.lined_style)

    # container
    ctx.beginPath()
    ctx.moveTo(0,0)
    ctx.lineTo(ocs * 2, 0)
    ctx.lineTo(ocs * 2, ocs * @symbol_names.length)
    ctx.lineTo(0, ocs * @symbol_names.length)
    ctx.closePath()
    ctx.stroke()

    # vertical divider
    ctx.beginPath()
    ctx.moveTo(ocs, 0)
    ctx.lineTo(ocs, ocs * @symbol_names.length)
    ctx.stroke()

    # horizontal dividers
    for idx in [1...@symbol_names.length]
      ctx.beginPath()
      ctx.moveTo(0, ocs * idx)
      ctx.lineTo(ocs * 2, ocs * idx)
      ctx.stroke()
    
    # symbols
    ctx.save()
    ctx.translate(ocs/2, ocs/2)
    for name in @symbol_names
      g.renderShape(ctx, name, g.inner_command_size/2)
      ctx.translate(0, ocs)
    ctx.restore()

    # commands (if present)
    ctx.translate(ocs*3/2, ocs/2)
    for idx in [0...@symbol_names.length]
      if idx of @commands
        @commands[idx].render(ctx)
      ctx.translate(0, ocs)

    ctx.restore()

    ctx.save()
    g.setStyle(ctx, g.lined_style)
    ctx.restore()

class MoveCommand
  constructor: (@movedir) ->

  movePoint: (pos) ->
    return x: pos.x + @movedir.dx, y: pos.y + @movedir.dy

  render: (ctx) ->
    ctx.save()
    g.setStyle(ctx, g.lined_style)
    g.renderArrow(ctx, @movedir.theta, g.inner_command_size)
    ctx.restore()

window.Dwim = Dwim

