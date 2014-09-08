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

    @ctx.fillStyle = 'black'
    @ctx.fillRect(0, 0, @cnv.width, @cnv.height)
    bot =
      showxi: @botx
      showyi: @boty
      showdir: @botdir
      render: window.dwim_graphics.renderBot

    bot.render(@ctx)
    
    if not @stop_render
      requestAnimationFrame(@render)

  keyboardCB: (key) =>
    if key of keymap
      dir = keymap[key]
      @botx += dir.dx
      @boty += dir.dy
      @botdir = dir.theta

window.Dwim = Dwim
