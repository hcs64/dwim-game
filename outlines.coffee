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

  for x in [-1..dims.width]
    obstacle_present[x] = {'-1':true}
    obstacle_present[x][dims.height] = true
  for y in [-1..dims.height]
    obstacle_present[-1][y] = true
    obstacle_present[dims.width][y] = true

  for {x:x,y:y} in parseRanges(obstacles)
    obstacle_present[x][y] = true

  ctx.strokeStyle = 'grey'
  ctx.lineWidth = 1
  for x in [0...dims.width]
    for y in [0...dims.height]
      if not obstacle_present[x][y]
        ctx.strokeRect(x*dims.block-.5, y*dims.block-.5, dims.block, dims.block)

  # collect borders
  outline_links = []

  for x in [0..dims.width]
    was_in = true
    for y in [0..dims.height]
      is_in = obstacle_present[x][y] == true
      if was_in and not is_in
        outline_links.push({
            x0: x*dims.block, y0: y*dims.block-1,
            x1: (x+1)*dims.block-1, y1: y*dims.block-1})
      if not was_in and is_in
        outline_links.push({
            x0: x*dims.block, y0: y*dims.block,
            x1: (x+1)*dims.block-1, y1: y*dims.block})

      was_in = is_in

  for y in [0..dims.height]
    was_in = true
    for x in [0..dims.width]
      is_in = obstacle_present[x][y] == true
      if was_in and not is_in
        outline_links.push({
          x0: x*dims.block-1, y0: y*dims.block,
          x1: x*dims.block-1, y1: (y+1)*dims.block-1})
      if not was_in and is_in
        outline_links.push({
          x0: x*dims.block, y0: y*dims.block,
          x1: x*dims.block, y1: (y+1)*dims.block-1})

      was_in = is_in

  ctx.lineWidth = 4
  ctx.lineCap = 'round'
  ctx.strokeStyle = 'white'
  ctx.beginPath()
  for {x0:x0,y0:y0,x1:x1,y1:y1} in outline_links
    ctx.moveTo(x0,y0)
    ctx.lineTo(x1,y1)
  ctx.stroke()
