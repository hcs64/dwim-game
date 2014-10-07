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


window.outlineRender = (dims, obstacles, ctx) ->
  ctx.fillStyle = 'black'
  ctx.fillRect(0,0,(dims.width+2)*dims.block,(dims.height+2)*dims.block)

  obstacle_present = {}

  for x in [0..dims.width+1]
    obstacle_present[x] = {'0':true}
    obstacle_present[x][dims.height+1] = true
  for y in [0..dims.height+1]
    obstacle_present[0][y] = true
    obstacle_present[dims.width+1][y] = true

  for {x:x,y:y} in parseRanges(obstacles)
    obstacle_present[x+1][y+1] = true

  ctx.fillStyle = 'grey'
  for x in [0..dims.width+1]
    for y in [0..dims.height+1]
      if obstacle_present[x][y]
        ctx.fillRect(x*dims.block, y*dims.block, dims.block-1, dims.block-1)

  # collect borders
  yneg = []
  ypos = []
  xneg = []
  xpos = []

  for x in [0..dims.width+1]
    was_in = true
    for y in [1..dims.height+1]
      is_in = obstacle_present[x][y] == true
      if was_in and not is_in
        ypos.push({x:x,y:y-1})
      if not was_in and is_in
        yneg.push({x:x,y:y})

      was_in = is_in

  for y in [0..dims.height+1]
    was_in = true
    for x in [1..dims.width+1]
      is_in = obstacle_present[x][y] == true
      if was_in and not is_in
        xpos.push({x:x-1,y:y})
      if not was_in and is_in
        xneg.push({x:x,y:y})

      was_in = is_in

  ctx.lineWidth = 4
  ctx.lineCap = 'round'

  ctx.strokeStyle = 'white'
  for {x:x,y:y} in yneg
    ctx.beginPath()
    ctx.moveTo(x*dims.block, y*dims.block)
    ctx.lineTo((x+1)*dims.block-1, y*dims.block)
    ctx.stroke()
  ctx.strokeStyle = 'white'
  for {x:x,y:y} in ypos
    ctx.beginPath()
    ctx.moveTo(x*dims.block, (y+1)*dims.block-1)
    ctx.lineTo((x+1)*dims.block-1, (y+1)*dims.block-1)
    ctx.stroke()
  ctx.strokeStyle = 'white'
  for {x:x,y:y} in xneg
    ctx.beginPath()
    ctx.moveTo(x*dims.block, y*dims.block)
    ctx.lineTo(x*dims.block, (y+1)*dims.block-1)
    ctx.stroke()
  ctx.strokeStyle = 'white'
  for {x:x,y:y} in xpos
    ctx.beginPath()
    ctx.moveTo((x+1)*dims.block-1, y*dims.block)
    ctx.lineTo((x+1)*dims.block-1, (y+1)*dims.block-1)
    ctx.stroke()



