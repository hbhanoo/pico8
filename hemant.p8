pico-8 cartridge // http://www.pico-8.com
version 27
__lua__

t=0
global_id=0
 info = {}
 score = {good=0, bad=0}
 info.tie = {
   type = "tie",
   sp = 3,
   x = 0,
   y = 0,
   box = {x1 = 0, x2 = 8, y1 = 0, y2 = 8},
   dx = 0,
   dy = 0.5,
   dr = 40,
   bullet = "tie_bullet",
 }
 info.ship = {
   type = "ship",
   spn = 2, -- how many sprites to animate
   sps = {1,2}, -- which sprites to animate
   animt = 6,  -- total time over which to animate
   x = 60,
   y = 60,
   box = {x1 = 0, x2 = 7, y1 = 0, y2 = 76},
 }
 info.bomb = {
   type = "bomb",
   sp = 17,  -- sprite
   box = {x1 = -24, x2 = 32, y1 = -8, y2 = 8},
   sx = 0,   -- sfx
   dx = 0,   -- speed x
   dy = -1,  -- speed y
 }
 info.bullet = {
   type = "bullet",
   sp = 18,
   sx = 1,   -- sfx
   box = {x1 = 7, x2 = 7, y1 = 0, y2 = 2},
   dx = 0,
   dy = -3,
 }
 info.explosion = {
  type = "explosion",
  sp = 4,
  sps = {4, 5, 6, 7},
  spi = 0
 }

function _init()
 ship = {
  type = "ship",
  sp = 1, -- current sprite
  sps = {1,2}, -- which sprites to animate
  animt = 6,  -- total time over which to animate
  x = 60,
  y = 60,
  w = 8,
  h = 8
 }
 bullets = {}
 enemies = {}
 explosions = {}
 bound = {x1 = 2, x2 = 128, y1 = 0, y2 = 120}
 ammos = {}
 ammos[0] = {
  type = "bomb",
  n = 5,    -- qty
  t = 0,    -- last time fired
  dr = 200,   -- replenish rate
  df = 30,  -- fire rate
  mx = 10,  -- max
 }
 ammos[1] = {
  type = "bullet",
  n = 10,
  t = 0,
  dr = 25,
  df = 3,
  mx = 20,
 }
end


function replenish()
 create_enemy()

 -- replenish ammo
 for k,a in pairs(ammos) do
--  local a = ammos[k]
  if ((t % a.dr) == 0 and a.n < a.mx) then
    a.n += 1
  end
 end
end


function create_enemy()
 if ((t % info.tie.dr) == 0) then
  e = spawn("tie", { x=rndi(100), y=1 })
  add(enemies, e)
 end
end

function continue_exploding()
  local to_kill = {}
  for e in all(explosions) do
   if e.spi >= #e.sps then
      del(explosions, e)
   else
      if (t%3) == 0 then
       e.spi = e.spi + 1
       e.sp = e.sps[e.spi]
      end
   end
  end
  for e in all(to_kill) do
   del(dead_enemies, e)
  end
end

function killed(b, tbl)
 local expl = {}
 for de in all(tbl) do
  sfx(2)
  score.good += 1
  info[de.type].dr -= 1
  info[de.type].dy += 0.1
  del(enemies, de)
  del(bullets, b)
  add(expl, spawn("explosion", { x = de.x, y = de.y }))
 end
 return expl
end


function _update()
 t += 1
 animate(ship)
 replenish()
 for b in all(bullets) do
  moveobj(b)
  if not in_bound(b, bound) then
   del(bullets, b)
  end
  local newly_died = collide_any(b, enemies)
  if next(newly_died) == nil then
  else merge(explosions, killed(b, newly_died)) end
 end

 continue_exploding()

 for e in all(enemies) do
  printh(e.id .. ": [" .. e.x .. ", " .. e.y .. "]")
  moveobj(e)
  if not in_bound(e, bound) then
    score.bad += 1
    info[e.type].dr = max(info[e.type].dr + 1, 50)
    info[e.type].dy = min(info[e.type].dy - 0.3, 0.5)
    del(enemies, e)
  end
 end


 -- buttons
 if btn(⬆️) then
  ship.dy = min(0, ship.dy) - 0.1
  ship.y+=ship.dy
 end
 if btn(⬇️) then
  ship.dy = max(0, ship.dy) + 0.1
  ship.y+=ship.dy
 end
 if btn(⬅️) then
  ship.dx = min(0, ship.dx) - 0.1
  ship.x += ship.dx
 end
 if btn(➡️) then
  ship.dx = max(0, ship.dx) + 0.1
  ship.x+=ship.dx
 end
 constrain(ship, bound)

 if btn(🅾️) then fire(0) end
 if btn(❎) then fire(1) end
end

function _draw()
 cls()
 print(score.good or 0, 40, 120, 6)
 print(score.bad  or 0, 60, 120, 8)
 print(ammos[0].n .. "/" .. ammos[0].mx, 0,120, 7)
 print(ammos[1].n .. "/" .. ammos[1].mx, 90,120, 7)
 spr(ship.sp, ship.x, ship.y)
 for b in all(bullets) do
  spr(b.sp, flr(b.x), flr(b.y))
 end
 for e in all(enemies) do
  spr(e.sp, flr(e.x), flr(e.y))
 end
 for de in all(explosions) do
  spr(de.sp, flr(de.x), flr(de.y))
 end

end
-->8
-- PAGE 1
-- a = 0 or 1
function fire(k)
 if (k < 0 or k > 1 or ammos[k].n <= 0) then return end
 a = ammos[k]
 if ((t - a.t) < a.df) then return end
 a.n -= 1
 a.t = t
 local b = spawn(a.type, {
   x = ship.x,
   y = ship.y,
 })
 add(bullets, b)
 sfx(b.sx, a)
end
-- utils
function copy(a)
 local n = {}
 for k,v in pairs(a) do n[k] = v end
 return n
end

function merge(a,b)
 for k,v in pairs(b) do a[k] = v end
end

function animate(o)
 if o.animt == nil then return end -- not animatable
 local k = t % o.animt
 local i = flr(#o.sps * k / o.animt)
 o.sp = o.sps[i + 1]
end

function constrain(o, b)
 if o.x < b.x1 then o.x = b.x1 end
 if o.x + o.w > b.x2 then o.x = b.x2 - o.w end
 if o.y < b.y1 then o.y = b.y1 end
 if o.y + o.h > b.y2 then o.y = b.y2 - o.h end
end

function in_bound(o, b)
 return (o.x > b.x1 and o.x < b.x2 and
         o.y > b.y1 and o.y < b.y2)
end

function moveobj(b)
  b.x += b.dx
  b.y += b.dy
end

function spawn(name, initial)
 local e = copy(info[name])
 global_id += 1
 initial.id = global_id
 merge(e, initial)
 return e
end

function rndi(n)
 return flr(rnd(n))
end

function collide(a, b)
 if (a.x + a.box.x1 > b.x + b.box.x2 or
     a.y + a.box.y1 > b.y + b.box.y2 or
     b.x + b.box.x1 > a.x + a.box.x2 or
     b.y + b.box.y1 > a.y + a.box.y2) then
  return false
 else
  return true
 end
end

function collide_any(obj, objects)
 local collisions = {}
 for o in all(objects) do
  if (collide(obj, o)) then add(collisions, o) end
 end
 return collisions
end

-- /utils

-->8
-- PAGE 2
function showids(tbl)
 local str = ""
 for k,v in pairs(tbl) do
  if (type(v) == 'table') then v = v.id end
  str = str .. v .. ", "
 end
 return str
end

__gfx__
00000000000060000000600050000005500000a5a8800005080a08a00a0000000000000000000000000000000000000000000000000000000000000000000000
0000000000006000000060005555555555a9a9aa9a9a55559a9a889a000a09000000000000000000000000000000000000000000000000000000000000000000
00700700000060000000600055f0f85555f988559889888598898880090090a00000000000000000000000000000000000000000000000000000000000000000
00077000000666000006660055fff85555f8885588888895a88880900a0000900000000000000000000000000000000000000000000000000000000000000000
000770000606660606066606555555555a9599a5888888a5088a88a9000000a00000000000000000000000000000000000000000000000000000000000000000
007007000666666606666666500000055000000580000005808a8089a00a00090000000000000000000000000000000000000000000000000000000000000000
00000000000666900096660000000000000000000000000090099aaa900000000000000000000000000000000000000000000000000000000000000000000000
0000000000906000000060900000000000000000000000000990aa900090a0000000000000000000000000000000000000000000000000000000000000000000
500000050500000000000008500000a5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50000005555000000000000855a9a9aa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55055055555000000000000855f98855000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55558555080000000000000055f88855000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5505505500000000000000005a9599a5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50000005000000000000000050000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000a8800005080a08a00a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000009a9a55559a9a889a000a090000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000009889888598898880090090a000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000088888895a88880900a00009000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000888888a5088a88a9000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000080000005808a8089a00a000900000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000090099aaa9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000990aa900090a00000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0005000002610046200c6301264017650196701b6701b6701a660166400e6300763004620006200f6000a60007600046000060000600006000060000600006000060000600006000060000600016000060000000
000101000000000010160100161028020006202802028020016202402021010006201b03000630120301004009040030700007000070000700007000000000000000000000000000000000000000000000000000
000500001b65003650206502065022650286502d6503065032650336503465035650326502d650236501965013650106000d6000b6000660002600006001960013600116000f6000f6000d6000a6000860005600
