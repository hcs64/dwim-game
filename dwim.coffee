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
      new Instruction('circle'),
      new Instruction('square'),
      new Instruction('diamond'),
      new Instruction('hex'),
      new MoveCommand(UP.theta),
      new MoveCommand(DOWN.theta),
      new MoveCommand(LEFT.theta),
      new MoveCommand(RIGHT.theta)
      ])

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
    
    if not @stop_render
      requestAnimationFrame(@renderCB)

  keyboardCB: (key) =>
    if key of keymap
      dir = keymap[key]
      @moveBotTo(
        @botx + dir.dx,
        @boty + dir.dy,
        dir.theta
      )

  moveBotTo: (x, y, dir) ->
    # check borders
    if x < 0 or y < 0 or x >= @Wi or y >= @Hi
      return false

    @botx = x
    @boty = y
    @botdir = dir

    return true


class Program
  constructor: (@instructions) ->

  render: (ctx) ->
    ctx.save()
    for i in @instructions
      ctx.translate(0, g.command_size)
      i.render(ctx)
    ctx.restore()

class Symbol
  constructor: () ->

  render: (ctx) ->
    g.renderCommandScrim(ctx)

class Instruction extends Symbol
  constructor: (@shape) ->

  render: (ctx) ->
    super ctx

    ctx.save()
    g.setStyle(ctx, g.lined_style)
    g.renderShape(ctx, @shape, g.inner_command_size/2)
    ctx.restore()

class Command extends Symbol
  constructor: () ->

class MoveCommand extends Command
  constructor: (@movedir) ->

  render: (ctx) ->
    super ctx

    ctx.save()
    g.setStyle(ctx, g.lined_style)
    g.renderArrow(ctx, @movedir, g.inner_command_size)
    ctx.restore()

window.Dwim = Dwim

