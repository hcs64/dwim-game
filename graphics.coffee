# mostly from obot right now

g = {}

g.cell_size = cell_size = 32

clear_style = fill: 'black'
lined_style = stroke: 'white', width: 1.5, fill: 'black'
thick_lined_style = stroke: 'white', width: 2.5, fill: 'black'
pixlined_style = stroke: 'white', width: 1, fill: 'black'
filled_style = fill: 'white'
exit_text_style =
  font: '12px monospace', fill: 'white', align: 'center', baseline: 'middle'
obstacle_cell_style = fill: 'white'
program_cell_style = fill: 'blue'

g.thick_lined_style = thick_lined_style
g.lined_style  = lined_style
bot_style = lined_style

g.setStyle = setStyle = (ctx, s) ->
  ctx.fillStyle   = s.fill   if s.fill
  ctx.strokeStyle = s.stroke if s.stroke
  ctx.lineWidth   = s.width  if s.width
  ctx.font        = s.font   if s.font
  ctx.textAlign   = s.align  if s.align
  ctx.textBaseline = s.baseline if s.baseline

g.clear = (ctx, width, height) ->
  ctx.save()
  setStyle(ctx, clear_style)
  ctx.fillRect(0,0,width,height)
  ctx.restore()

g.border = (ctx, width, height) ->
  ctx.save()
  setStyle(ctx, lined_style)
  ctx.strokeRect(0,0,width,height)
  ctx.restore()

# bot graphics
hr3 = Math.sqrt(3)/2
rr3 = 1/Math.sqrt(3)
g.bot_size = bot_size = cell_size*.75
bot_points = [
  (x: bot_size * rr3, y: 0),
  (x: -bot_size * (hr3-rr3), y: -bot_size/2),
  (x: -bot_size * (hr3-rr3), y: bot_size/2)
]

g.renderBot = (ctx) ->
  bp = bot_points
  ctx.save()
  ctx.translate((@showxi + .5) * cell_size, (@showyi + .5) * cell_size)
  ctx.rotate(-@showdir)

  ctx.beginPath()
  ctx.moveTo(bp[0].x, bp[0].y)
  ctx.lineTo(bp[1].x, bp[1].y)
  ctx.lineTo(bp[2].x, bp[2].y)
  ctx.closePath()

  setStyle(ctx, bot_style)

  ctx.fill()
  ctx.stroke()

  # "eye"
  ctx.beginPath()
  ctx.arc(bot_points[0].x, bot_points[0].y, bot_size/4,
    (1-1/5)*Math.PI, (1+1/5)*Math.PI)
  ctx.stroke()

  ctx.restore()

  return

# obstacle graphics
g.renderMine = (ctx) ->
    setStyle(ctx, pixlined_style)

    ctx.beginPath()
    ctx.moveTo(-cell_size*.35,-cell_size*.35)
    ctx.lineTo(cell_size*.35,cell_size*.35)
    ctx.moveTo(cell_size*.35,-cell_size*.35)
    ctx.lineTo(-cell_size*.35,cell_size*.35)

    ctx.moveTo(0,-cell_size*.4)
    ctx.lineTo(0,cell_size*.4)
    ctx.moveTo(cell_size*.4,0)
    ctx.lineTo(-cell_size*.4,0)
    ctx.stroke()

    ctx.beginPath()
    ctx.arc(0,0, cell_size*.3, 0, Math.PI*2)
    ctx.fill()
    ctx.stroke()

    return

g.renderArrow  = (ctx, dir, size) ->
  as = size*.75  # arrow size
  ahs = size*.2 # arrowhead size

  ctx.rotate(-dir)

  ctx.beginPath()
  ctx.moveTo(-as/2, 0)
  ctx.lineTo(as/2, 0)
  ctx.lineTo(as/2-ahs,ahs)
  ctx.moveTo(as/2,0)
  ctx.lineTo(as/2-ahs,-ahs)
  ctx.stroke()

  ctx.rotate(dir)

  return

g.renderShape = (ctx, shape, radius) ->
  ctx.beginPath()
  switch shape
    when 'circle'
      ctx.arc(0,0,radius*.8,0,Math.PI*2)
    when 'square'
      r = radius*.75
      ctx.moveTo(-r,-r)
      ctx.lineTo(-r,+r)
      ctx.lineTo(+r,+r)
      ctx.lineTo(+r,-r)
      ctx.closePath()
    when 'diamond'
      r = radius*Math.SQRT1_2*1.125
      ctx.moveTo(-r,0)
      ctx.lineTo(0,+r)
      ctx.lineTo(+r,0)
      ctx.lineTo(0,-r)
      ctx.closePath()
    when 'hex'
      r = radius * .8
      r2 = r/2
      ctx.moveTo(-r,0)
      ctx.lineTo(-r2,-r)
      ctx.lineTo(+r2,-r)
      ctx.lineTo(+r,0)
      ctx.lineTo(+r2,+r)
      ctx.lineTo(-r2,+r)
      ctx.closePath()
    when 'question'
      r = radius*.75
      ctx.moveTo(-r*.75, -.5*r)
      ctx.lineTo(-r*.75, -r)
      ctx.lineTo(+r*.75, -r)
      ctx.lineTo(+r*.75, 0)
      ctx.lineTo(0, 0)
      ctx.lineTo(0, .625*r)
      ctx.moveTo(0, .75*r)
      ctx.lineTo(0, r)
 
  ctx.stroke()
  return

# command graphics
g.command_size = command_size = 32
g.inner_command_size = inner_command_size = 29
g.outer_command_size = 38
command_scrim_points = do ->
  ics = inner_command_size
  [
    (x: -ics/2, y: -ics/2),
    (x: -ics/2, y: +ics/2),
    (x: +ics/2, y: +ics/2),
    (x: +ics/2, y: -ics/2)
  ]

g.renderCommandScrim = (ctx, current = false) ->
  cs = command_size
  ics = inner_command_size

  ctx.save()
  
  setStyle(ctx, lined_style)

  ctx.strokeRect( -ics/2, -ics/2, ics, ics )

  if current
    setStyle(ctx, filled_style)
    for pt in command_scrim_points
      ctx.fillRect(pt.x-ics*.1, pt.y-ics*.1, ics*.2, ics*.2)
 
  ctx.restore()

  return

g.renderProgramCell = (ctx, x, y) ->
  cs = command_size
  ctx.save()
  setStyle(ctx, program_cell_style)
  ctx.fillRect(x*cs, y*cs, cs, cs)
  ctx.restore()

g.renderObstacleCell = (ctx, x, y) ->
  cs = command_size
  ctx.save()
  setStyle(ctx, obstacle_cell_style)
  ctx.fillRect(x*cs, y*cs, cs, cs)
  ctx.restore()

g.renderExitCell = (ctx, x, y) ->
  cs = command_size
  setStyle(ctx, exit_text_style)
  ctx.fillText("exit", (x+.5)*cs, (y+.5)*cs)
  setStyle(ctx, lined_style)
  ctx.strokeRect(x*cs, y*cs, cs, cs)
 
# from around every corner
digit_graphics = [
  # 0
  [ [[0,0],[4,0],[4,4],[0,4],[0,0]] ],
  # 1
  [ [[2,0],[2,4]] ],
  # 2
  [ [[0,0],[4,0],[4,2],[0,2],[0,4],[4,4]] ],
  # 3
  [ [[0,0],[4,0],[4,4],[0,4]],
    [[0,2],[4,2]] ],
  # 4
  [ [[0,0],[0,2],[4,2]],
    [[4,0],[4,4]] ],
  # 5
  [ [[4,0],[0,0],[0,2],[4,2],[4,4],[0,4]] ],
  # 6
  [ [[4,0],[0,0],[0,4],[4,4],[4,2],[0,2]] ],
  # 7
  [ [[0,0],[4,0],[4,4]] ],
  # 8
  [ [[0,0],[0,4],[4,4],[4,0],[0,0]],
    [[0,2],[4,2]] ],
  # 9
  [ [[0,4],[4,4],[4,0],[0,0],[0,2],[4,2]] ]
]

g.renderNumber = renderNumber = (ctx, n, scale = 4) ->
  s = []
  if n < 0 or n != Math.floor(n)
    console.log("tried to render #{number}, only nonnegative integers supported")
  if n == 0
    s = [0]
  while n > 0
    s[s.length] = n % 10
    n = Math.floor(n / 10)

  ctx.save()

  for i in [s.length-1..0] by -1
    ctx.beginPath()
    for line in digit_graphics[s[i]]
      ctx.moveTo(line[0][0]*scale, line[0][1]*scale)
      for point in line[1..]
        ctx.lineTo(point[0]*scale, point[1]*scale)
    ctx.stroke()

    ctx.translate(5*scale, 0)

  ctx.restore()

window.dwim_graphics = g
