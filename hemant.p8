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
   dr = 50,
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
   box = {x1 = -4, x2 = 6, y1 = -3, y2 = 7},
   sx = 0,   -- sfx
   dx = 0,   -- speed x
   dy = -2,  -- speed y
 }
 info.bullet = {
   type = "bullet",
   sp = 18,
   sx = 1,   -- sfx
   box = {x1 = 7, x2 = 7, y1 = 0, y2 = 2},
   dx = 0,
   dy = -3,
 }

function _init()
 ship = {
  type = "ship",
  sp = 1, -- current sprite
  spn = 2, -- how many sprites to animate
  sps = {1,2}, -- which sprites to animate
  animt = 6,  -- total time over which to animate
  x = 60,
  y = 60,
  w = 8,
  h = 8
 }
 bullets = {}
 enemies = {}
 dead_enemies = {}
 bound = {x1 = 0, x2 = 128,
 y1 = 0, y2 = 120}
 ammos = {}
 ammos[0] = {
  type = "bomb",
  n = 5,    -- qty
  t = 0,    -- last time fired
  dr = 100,   -- replenish rate
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
 local i = flr(o.spn * k / o.animt)
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

-- /utils

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
  e = spawn("tie", { x=rndi(100), y=0 })
  --  printh(t.. " spawned: " .. e.x .. " " .. " " .. e.y .." " ..  e.dx .. " ".. e.dy)
  add(enemies, e)
 end
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
  -- printh("checking collision of " .. obj.w .. " with " .. o.type .. ":" .. o.w)
  if (collide(obj, o)) then add(collisions, o) end
 end
 return collisions
end

function explode(de)
 -- sfx(2)
end


function continue_exploding()
  local to_kill = {}
  -- printh("dead_enemies (u):" .. #dead_enemies)
  for e in all(dead_enemies) do
   printh(t .. "|" .. e.id .. ": " .. e.sp)
   if e.sp >= 8 then
      add(to_kill, e)
   else
      if (t%3) == 0 then
       e.sp = e.sp + 1
      end
   end
  end
  for e in all(to_kill) do
   del(dead_enemies, e)
  end
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
  else
   for de in all(newly_died) do
    -- explode(de)
    score.good += 1
    del(enemies, de)
   end
  end
  merge(dead_enemies, newly_died)
 end

 continue_exploding()

 for e in all(enemies) do
  moveobj(e)
  if not in_bound(e, bound) then
    score.bad += 1
    del(enemies, e)
  end
 end

 -- buttons
 if btn(⬆️) then ship.y-=1 end
 if btn(⬇️) then ship.y+=1 end
 if btn(⬅️) then ship.x-=1 end
 if btn(➡️) then ship.x+=1 end
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
  spr(b.sp, b.x, b.y)
 end
 for e in all(enemies) do
  spr(e.sp, e.x, e.y)
 end
 -- printh("dead_enemies: (d):" .. #dead_enemies)
 for de in all(dead_enemies) do
  printh(t .. "| => " .. e.id .. ": " .. e.sp)
  spr(e.sp, e.x, e.y)
 end

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
