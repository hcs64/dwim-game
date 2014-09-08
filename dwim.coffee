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



class Dwim
  constructor: (@cnv) ->
    @ctx = @cnv.getContext('2d')
    @W = @cnv.width
    @H = @cnv.height

    @Wi = Math.floor(@W / @g.cell_size)
    @Hi = Math.floor(@H / @g.cell_size)
  
  g: window.dwim_graphics

  start: ->
    @botx = 5
    @boty = 5
    @botdir = UP.theta
    @startRenderer()
    @startInput()

  startRenderer: ->
    requestAnimationFrame(@render)

  startInput: ->
    registerKeyFunction(@keyboardCB)

  render: =>
    @g.clear(@ctx, @W, @H)
    @g.border(@ctx, @W, @H)

    bot =
      showxi: @botx
      showyi: @boty
      showdir: @botdir
      render: @g.renderBot

    bot.render(@ctx)
    
    if not @stop_render
      requestAnimationFrame(@render)

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

window.Dwim = Dwim
