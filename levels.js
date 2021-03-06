levelsFcn = function () {

levels = {
// 0
'0': {
  dims: {w: 10, h: 10},
  startpos: {x: 0, y: 8},
  exitpos: {x: 7, y: 9},
  obstacles: ['0,0-3 0-1,7 1,8 1-2,5 3-6,5-9 6,0-1 6,3-4 8,1 8-9,3-9'],
  programs: [
    {code: 'ggb', loc: '0,4-6'},
    {code: 'rrrggbbppp', loc: '6-9,2 7-9,0 7,1 9,1'},
    {code: 'rgbp', loc: '7,5-8'}
  ],
  mappings: [
    {lookup: {r: {type: 'move', dir: LEFT},
              g: {type: 'move', dir: UP},
              b: {type: 'move', dir: RIGHT},
              p: {type: 'move', dir: DOWN}},
              symbols: ['r','g','b','p']},
    {lookup: {r: {type: 'move', dir: RIGHT},
              g: {type: 'move', dir: UP},
              b: {type: 'move', dir: LEFT},
              p: {type: 'move', dir: DOWN}},
              symbols: ['r','g','b','p']},
    {lookup: {r: {type: 'move', dir: DOWN},
              g: {type: 'move', dir: DOWN},
              b: {type: 'move', dir: DOWN},
              p: {type: 'move', dir: DOWN}},
              symbols: ['r','g','b','p']}],
  next_level: '1a'
},

// 2
'2': {
  dims: {w: 10, h: 10},
  startpos: {x: 0, y: 9},
  exitpos: {x: 7, y: 2},
  obstacles: ['0-2,0-8 3-6,0-4 4-6,6-8 7,0-1 8-9,0-9'],
  programs: [
    {code: 'r', loc: '3,9'},
    {code: 'rrrbr', loc: '4-7,5 7,5-8'}],
  mappings: [
    {lookup: {r: {type: 'move', dir: UP},
              b: {type: 'mode', idx: 1}},
             symbols: ['r','b']},
    {lookup: {r: {type: 'move', dir: RIGHT},
              b: {type: 'mode', idx: 0}},
             symbols: ['r','b']}],
  next_level: '2a'
},

// 2a
'2a': {
  dims: {w: 10, h: 10},
  startpos: {x: 0, y: 4},
  exitpos: {x: 5, y: 4},
  obstacles: ['0-2,0-1 3,0 0,2-3 1,2 0,5-6 1,6 0-2,7-9 3,8-9 4-9,9',
              '6-7,0-1 6-7,7-8 7-8,0-2 7-8,6-8 8,0-3 8,5-8 9,0-8',
              '2,4 3,3-5 4,2-6',
              '5,0 5,8',
              '5,3 5,5'
              ],
  programs: [
    {code: 'r', loc: '1,4'},
    {code: 'g', loc: '2,3'},
    {code: 'g', loc: '2,5'},
    {code: 'bgb', loc: '4,1'},
    {code: 'bgb', loc: '4,7'},
    {code: 'r', loc: '6,4'},
  ],
  mappings: [
    {lookup: {r: {type: 'move', dir: LEFT},
              g: {type: 'move', dir: RIGHT},
              b: {type: 'move', dir: UP}},
             symbols: ['r','g','b']},
    {lookup: {r: {type: 'move', dir: UP},
              g: {type: 'move', dir: DOWN},
              b: {type: 'mode', idx: 0}},
             symbols: ['r','g','b']},
    {lookup: {r: {type: 'move', dir: DOWN},
              g: {type: 'move', dir: UP},
              b: {type: 'mode', idx: 0}},
             symbols: ['r','g','b']}],
  next_level: '3'
}, 

// 1a
'1a': {
  dims: {w: 10, h: 10},
  startpos: {x: 0, y: 4},
  exitpos: {x: 9, y: 1},
  obstacles: ['0-6,9 6,0-3 6,5-8 7,3 7,7 8,1 8,4-5 9,2 9,7'],
  programs: [
    {code: 'gggppp', loc: '3,0-8'},
    {code: 'r', loc: '8,2'},
    {code: 'gbgb', loc: '9,4-6'},
    {code: 'bgggpggg', loc: '7-9,9'},
  ],
  mappings: [
    {lookup: {r: {type: 'move', dir: DOWN},
              g: {type: 'move', dir: UP},
              b: {type: 'move', dir: LEFT},
              p: {type: 'move', dir: RIGHT}},
             symbols: ['r','g','b', 'p']}],
  next_level: '1'
},

// 1
'1': {
  dims: {w: 10, h: 10},
  startpos: {x: 1, y: 3},
  exitpos: {x: 3, y: 8},
  obstacles: ['0,0-4 3-4,1 6-7,1 0-9,5-6 4,4 6,4 0-4,7 6-9,7 0-2,8-9 8-9,8-9 3-7,9'],
  programs: [
    {code: 'rrrrrr', loc: '5,1'},
    {code: 'rr', loc: '5,4-6'},
    {code: 'bb', loc: '4-6,8'}],
  mappings: [
    {lookup: {r: {type: 'move', dir: UP},
              b: {type: 'move', dir: LEFT}},
             symbols: ['r','b']},
    {lookup: {r: {type: 'move', dir: DOWN},
              b: {type: 'move', dir: UP}},
             symbols: ['r','b']}],
  next_level: '2'
},

// 3
'3': {
  dims: {w: 10, h: 10},
  startpos: {x: 0, y:0},
  exitpos: {x:5, y:5},
  programs: [
    {code: 'gggg', loc: '1,3-6'},
    {code: 'rrrr', loc: '3-6,8'},
    {code: 'bbbb', loc: '8,3-6'},
    {code: 'ppgggrrpg', loc: '4-6,1 4,2-4 5-6,4'},
  ],
  obstacles: [
    '0-9,3-6',
    '3-6,0-9'
  ],
  mappings: [{lookup: {}, symbols: []}],
  next_level: '4',
},

// 4, redundant dir change
'4': {
  dims: {w: 10, h: 10},
  startpos: {x: 0, y: 0},
  exitpos: {x: 0, y: 5},
  programs: [
    {code: 'ggbbrbbggg',
     loc: '3-5,0 5,1-2 4,2-4 5-6,4'},
    {code: 'pbrrrrr',
     loc: '3-7,6'},
  ],
  obstacles: [
    '0-5,2 5-6,5-6 3-6,0-7',
    '0-2,3-4',
    '7-9,0-2',
    '0-9,8-9'
  ],
  mappings: [{lookup: {}, symbols: []}],
  next_level: '5',
},

// 5, tricky dir change
'5': {
  dims: {w: 10, h: 10},
  startpos: {x: 0, y: 0},
  exitpos: {x: 7, y: 7},
  programs: [
    {code: 'gg', loc: '0-1,1 1,0'},
    {code: 'rr', loc: '0-3,3 3,0-3'},
    {code: 'rr', loc: '4-5,6'},
    {code: 'gg', loc: '6,4-5'},
    {code: 'g', loc: '7,6'},
    {code: 'r', loc: '6,7'},
  ],
  obstacles: [
    '4-5,4-7 4-7,4-5',
    '0-9,8-9 8-9,0-9',
    '0-3,7 7,0-3'
  ],
  mappings: [{lookup: {}, symbols: []}],
  next_level: '6',
},
// 6, one way out
'6': {
  dims: {w: 9, h: 9},
  startpos: {x: 4, y: 4},
  exitpos: {x: 8, y: 4},
  obstacles: [
    '5-6,1-7 1-3,1-3 1-3,5-7 8,0-8',
  ],
  programs: [
    {code: 'pgr', loc: '1-3,4'},
    {code: 'brg', loc: '4,1-3'},
    {code: 'grb', loc: '4,5-7'},
    {code: 'b', loc: '7,4'}
  ],
  mappings: [{lookup: {}, symbols: []}],
  next_level: '7',
},
// 7, mapping change
'7': {
  dims: {w: 9, h: 9},
  startpos: {x: 8, y: 1},
  exitpos: {x: 8, y: 8},
  obstacles: [
    '4-8,2 3-5,0-8 4-8,6 3-5,4-8 4-8,4',
    '0-1,0-8',
    '8,3-5',
    '2,0 2,4 2,8'
  ],
  programs: [
    {code: 'ggg', loc: '3-5,1'},
    {code: 'bggg', loc: '3-5,3'},
    {code: 'r', loc: '7,4'},
    {code: 'ggrrbggg', loc: '3-5,5 3-5,7 3,6'}
  ],
  mappings: [{lookup: {}, symbols: []},
             {lookup: {}, symbols: []}],
  next_level: '8',
},

// 10, burn extra instructions
'10': {
  dims: {w: 10, h: 10},
  startpos: {x: 0, y: 0},
  exitpos: {x: 9, y: 8},
  obstacles: [ '0-4,1-9 6-9,0 5-8,2 6-9,4 9,5-7, 7,6 5-6,6-9 8,8' ],
  programs: [
    {code: 'grrr', loc: '1-4,0'},
    {code: 'grrr', loc: '6-8,1'},
    {code: 'grrr', loc: '6-7,5'},
    {code: 'grrr', loc: '8,9'},
  ],
  mappings: [{lookup: {}, symbols: []},
             {lookup: {}, symbols: []}],
  next_level: 'end'
},

// 8, Tank!
'8': {
  dims: {w: 10, h: 10},
  startpos: {x: 0, y: 0},
  exitpos: {x: 5, y: 5},
  obstacles: ['0-2,1 3-8,1-2 3,3-6 4-6,6 6,4-5 5,4 8,3-7 1,3-8 2-8,8'],
  programs: [
    {code: 'rrr', loc: '1-3,0'},
    {code: 'rrrrgrrrrr', loc: '5-9,0 9,1-9 0-8,9 0,5-8'},
    {code: 'rgrrrrrbrr', loc: '2,2-7 1,2 3,7'},
    {code: 'rbrrr', loc: '7,3-7 6,7 5-6,3'}
  ],
  mappings: [{lookup: {}, symbols: []},
             {lookup: {}, symbols: []},
             {lookup: {}, symbols: []},
             {lookup: {}, symbols: []}],
  next_level: '9'
},

// 9, counts
'9': {
  dims: {w: 10, h: 10},
  startpos: {x: 1, y: 9},
  exitpos: {x: 9, y: 8},
  obstacles: ['0-1,0-8 0,9 2-3,0-3 2,4-6 3,8-9 5,1 5-6,2-4 4-7,5-9 7,0 8-9,0-3 9,4-7 8-9,9'],
  programs: [
    {code: 'rp', loc: '2,7-8'},
    {code: 'rp', loc: '3,4-6'},
    {code: 'rp', loc: '4,0-3'},
    {code: 'gp', loc: '6,0-1'},
    {code: 'gp', loc: '7,2-4'},
    {code: 'gp', loc: '8,5-8'},
  ],
  mappings: [{lookup: {}, symbols: []},
             {lookup: {}, symbols: []},
             {lookup: {}, symbols: []}],
  next_level: '10'
}

};

return levels;
};
