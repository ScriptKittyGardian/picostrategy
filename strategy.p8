pico-8 cartridge // http://www.pico-8.com
version 33
__lua__
--main
camx=0
camy=0

turn=1
menus={}
camh=14
camw=16
focus=true
movespeed=5
movetimer=0

function _init()
	init_units()
	add_member(rachel)
	init_map()
	gold=100
	game_state="menu"
	music(0)
end



function _update()
	if(game_state=="battle") battle()
	if(game_state=="campaign") campaign()
	active_men=menus[#menus]
	if(active_men) active_men.update(active_men)
	if(showcur and not focus) then
		if(btnp(⬆️)) cur.y-=1
		if(btnp(⬇️)) cur.y+=1
		if(btnp(⬅️)) cur.x-=1
		if(btnp(➡️)) cur.x+=1
		cur = {x=mid(0,cur.x,mapw-1),y=mid(0,cur.y,maph-1)}
	end
	if(game_state=="placement") placement()
	if(game_state=="menu") then
		if(btnp(❎)) game_state="campaign"
		if(btnp(🅾️)) game_state="directions"
	end
end

function _draw()
	if(game_state!="finalvictory") then
	cls()
 if(game_state=="directions") then 
		camx=0
		camy=0
		print("instructions",40,0)
		print("use arrow keys to move player",0,8)
		print("press x to select items \ntravel to towns and collect new\ncharacters ")
		print("combat instructions",28,35)
		print("use inspect to read about\ndifferent characters\nuse move to move your character\na set amount of spaces\nuse attack to attack a certain\nenemy, but be careful because\nyou can harm yourself\nacquire more spd to fight with\npress x to play game",0,44)
		if(btnp(❎)) game_state="menu"
	end
	camera(camx,camy)

 if(game_state=="victory") showcur=false
	if(game_state=="battle" or game_state=="placement" or game_state=="victory" or game_state=="lose") then

	map(0,0,flr(camx/8),flr(camy/8),
				flr(camx/8)+camw,
		flr(camy/8)+camh)
		foreach(units,draw_corpse)
		foreach(units,draw_unit)
		end
		
	if(game_state=="menu") then
		draw_map()
		if(camx < 1)  camdir = 1
		if(camx > mapw*8-128) camdir = -1
		camx+= camdir
		print_just("the skull of secrets",64,24,7)
		print_just("press ❎ to start",64,64,7)
		print_just("press 🅾️ for directions",64,82,7)

	end
	if(game_state=="lose") then
		rectfill(0,54,128,76,0)
		showcur=false
		print_just("you have been defeated",64,64,8)
		print_just("reboot to try again",64,72,7)
	end
	if(game_state=="battle" ) then
  showcur=true
		line(camx,camy+111,camx+128,camy+111,7)
		if(act_un and show_stats) then
			if(not act_un.enemy) then
				draw_stats(act_un,true,true,true,true)
			else
				draw_stats(act_un,true,false,false,true)
				print(pack_string(action_announce,20),44,113)
			end
		end
	elseif(game_state == "placement") then
			print("placement",camx,camy+113,8)
			for i = 1,3 do 
				if(i < #unplaced) then
					print(i.."."..unplaced[i].name,camx+80*flr(i/2),camy+113+(8*((i)%2)),7)
				end
			end
			
			for x = 0,bfield.sx-1 do
				for y = 0,bfield.sy-1 do
					col=nil
					if(x <= fstart) col=7
					if(x >= estart) col=8
					if(col and not has_flag({x=x,y=y},slds) and not check_unit(x,y)) rect(x*8,y*8,x*8+7,y*8+7,col)
				end
			end
			if(not unplaced[1].enemy and placevalid) spr(unplaced[1].k,cur.x*8,cur.y*8)
	elseif(game_state=="victory") then
		rectfill(camx+32,camy+32,camx+96,camy+96,0)
		print_just("victory!",camx+64,camy+40,10)
		spr(57,camx+40,camy+48)
		spr(61,camx+40,camy+57)
		print(goldreward,camx+50,camy+50)
		print(xpreward,camx+50,camy+59)
		for i = 1,#lvlups do
			local p = lvlups[i]
			spr(p.k,camx+40,camy+58+(8*i))
			print("⬆️ lvl " .. p.lvl,camx+50,camy+58+(8*i),11)
		end
		if(btnp(❎)) game_state = "campaign"
	
	
	
	elseif(game_state=="campaign") then
		draw_map()
		spr(57,camx,camy)
		print(gold,camx + 10,camy+2,10)
	end
	if(showcur) spr(5,cur.x*8,cur.y*8)

	if(active_men) active_men.draw(active_men)

	foreach(effects,draw_effect)
	else
		--draw_map()
		circfill(rnd(128),rnd(128),rnd(16),0)
		print_just("victory!\nreboot to play again",64,64,10)
		--if(armypos > 2) armypos-=0.1
	end
end
-->8
--units

function standard_death(u)
	u.alive=false
	u.buffs={}
	del(party,u)
	update_nav()
end


function make_unit(name,k,class,tal,aff,lvl,brain,enemy)
	if(not enemy) enemy=false
	st={
		name=name,
		lvl=lvl,
		x=0,
		y=0,
		k=k,
		res={0,0,0},
		typ=aff,
		class=class,
		corpse=18,
		spells={tal},
		enemy=enemy,
		move_cost=1,
		die=standard_death,
		brain=brain,
		buffs={},
		alive=true,
		ap=0,
		nav={},
		modifiers={},
		xp=0
	}
	
	copy_stats(st,class,lvl)
	st.hp = st["maxhp"]
	st.ma = st["maxma"]
	return st
end

function list_has(l,item)
	for i=1,#l do
		if(l[i] == item) return true
	end
	return false
end

function select_spells(st,num)
	for i = 1,num do
		while true do
			cand=charspells[flr(rnd(#charspells)) + 1]
   c = atks[cand]
			if(atks[cand].typ == st.typ  and not list_has(st.spells,cand) and c.ma <= get_stat(st,"maxma") and c.ap <= get_stat(st,"spd")) then
				add(st.spells,cand)
				break
			end
		end
	end
end


function init_units()
	anya=make_unit("anya",2,"mage","thunder",3,1)
	select_spells(anya,1)
	rachel=make_unit("rachel",1,"fighter","sword",1,1)
	select_spells(rachel,1)
	priest=make_unit("father",31,"mage","heal",2,1)
	select_spells(priest,1)
	bowman=make_unit("jeff",34,"fighter","bow",1,1)
	tim=make_unit("tim",33,"mage","fireball",3,1)
	select_spells(tim,1)
	recruits={anya,priest,bowman,tim}
	monsters={
		["slime"]=make_unit("slime",21,"fighter","squish",1,-3,default_brain,true),
		["goblin"] =	make_unit("goblin",17,"fighter","sword",1,-1,default_brain,true),
		["wolf"] =	make_unit("wolf",11,"fighter","bite",1,-3,default_brain,true),
		["troll"] = make_unit("troll",12,"tank","hammer",1,1,default_brain,true),
  ["footman"] = make_unit("footman",32,"fighter","spear",1,4,default_brain,true),
  ["axeman"] = make_unit("axeman",35,"tank","hammer",1,4,default_brain,true),
  ["gmage"] = make_unit("curser",29,"mage","fireball",1,1,default_brain,true),
  ["harpy"] = make_unit("harpy",47,"mage","bite",1,2,harpy_brain,true),
  ["necromancer"] = make_unit("necromancer",30,"mage","raise",1,5,necro_brain,true)
	}
end


function place_unit(x,y,unit,copy)
	if(copy) unit = clone(unit)
	unit.x = x
	unit.y = y
	add(units,unit)
end

function get_stat(unit,keyword)

	toreturn= unit[keyword] 
	if(unit.modifiers[keyword]) toreturn *= unit.modifiers[keyword]
	if(toreturn) return flr(toreturn)
	return nil
end

function change_stat(unit,key,change)
	unit[key] += change
	limit = get_stat(unit,"max"..key)
 if(limit) unit[key] = min(unit[key],limit)
end







-->8
--abilities
effects={}

function create_atkeff(x,y,k)
	add(effects,{x=x,y=y,k=k})
end

function field_text(x,y,text,c)
	if(not c) c = 7
	add(effects,{x=x,y=y,text=text,c=c,lifetime=0})
end

function move_unit()
	nc=path[#path]
	if(act_un.ap > 0 and nc) then
		if(nc.c == 0) then
			del(path,nc)
			move_unit()
			return false
		end
		act_un.x=nc.x
		act_un.y=nc.y
		del(path,nc)
		act_un.ap-=act_un.move_cost
	else
		moving=false
		update_nav()
	end
end

function deal_dmg(trgt,atkr,dmg,typ)
	dmg -= get_stat(trgt,"def")/2
	dmg -= dmg*trgt.res[typ]
	dmg=round(max(1,dmg))
	field_text(trgt.x,trgt.y-0.5,""..dmg,8)
	if(dmg > 0 and rnd(1) < 0.5) cleanse_buff(trgt,"sleep")
	trgt.hp -= dmg
	if(trgt.hp <= 0) trgt.die(trgt)
end


function basic_attack(user,coord,attack,aoeslave)
	if(not aoeslave and attack.aoe) then
		valid_tiles=get_range(coord.x,coord.y,attack.aoe,attack.aoelos,atkdata.min_range)
			for v = 1,#valid_tiles do
				basic_attack(user,valid_tiles[v],attack,true)
			end
		return
	end
	target=check_unit(coord.x,coord.y)
	create_atkeff(coord.x,coord.y,attack.eff)
	if(target) then
			for b,v in pairs(attack.buffs) do
				apply_buff(target,b,v)
			end
		if(attack.dmg > 0) deal_dmg(target,user,attack.dmg*get_stat(user,"atk"),attack.typ)
		if(attack.dmg < 0) heal(target,user,attack.dmg*get_stat(user,"atk"))
	end
end

function heal(target,user,amount)
	amount=round(amount)
	change_stat(target,"hp",-amount)
	if(game_state=="battle") field_text(target.x,target.y-0.5,""..amount*-1)
end


function teleport(user,coord,attack)
	newcord={}
	target=check_unit(coord.x,coord.y)
	create_atkeff(coord.x,coord.y,attack.eff)
	if(target) then
		while true do
			newcord.x = flr(rnd(bfield.sx))
			newcord.y = flr(rnd(bfield.sy))
			if(not check_unit(newcord.x,newcord.y) and not has_flag(newcord,slds)) then
				target.x=newcord.x
				target.y=newcord.y
				create_atkeff(newcord.x,newcord.y,attack.eff)
				update_nav()
				cur=newcord
				return
			end
		end
	end
end

function raise(user,coord,attack) 
	target=check_unit(coord.x,coord.y,nil,false)
	if(target and not check_unit(coord.x,coord.y,nil,true)) then
		target["hp"] = ceil(get_stat(target,"maxhp")/2)
		target.alive=true
		create_atkeff(target.x,target.y,attack.eff)
	end
end


charspells = {
"sword",
"fireball",
"sleep",
"slime",
"missile",
"rift",
"thunder",
"hammer",
"bow",
"heal",
"spear",
"raise"}

atks ={
["sword"] = {
	name="sword",
	dmg=0.4,
	rng=1.5,
	ap=3,
	uselos=true, 
	atk=basic_attack,
	typ=1, --1 = phyiscal, 2=light, 3=dark
	trgtd=true,
	ma=0,
	eff=7
},
["bow"] = {
	name="bow",
	dmg=0.75,
	rng=3,
	ap=4,
	uselos=true, 
	atk=basic_attack,
	typ=1, --1 = phyiscal, 2=light, 3=dark
	trgtd=true,
	ma=0,
	eff=7,
 min_range=1.5
},
["hammer"] = {
	name="hammer",
	dmg=0.75,
	rng=2,
	ap=4,
	uselos=true, 
	atk=basic_attack,
	typ=1, --1 = phyiscal, 2=light, 3=dark
	aoe=1,
	trgtd=true,
	aoelos=true,
	ma=0,
	eff=80
},
["bite"] = {
	name="bite",
	dmg=0.25,
	rng=1.5,
	ap=2,
	monster=true,
	uselos=true,
	atk=basic_attack,
	typ=1, --physical
	ma=0,
	eff=7
},
["fireball"] = {
	name="fireball",
	dmg=0.75,
	crit=5,
	rng=3.5,
	ap=5,
	uselos=true,
	atk=basic_attack,
	typ=2, --light
	aoe=1.5,
	trgtd=true,
	ma=5,
	aoelos=true,
	eff=23
},
["squish"] = {
	name="squish",
	dmg=0.5,
	crit=0,
	rng=1.5,
	ap=2,
	monster=true,
	uselos=true,
	atk=basic_attack,
	typ=1, --physical
	buffs={["slimed"]=1},
	eff=49
},
["sleep"] = {
	name="sleep",
	dmg=0,
	rng=3.5,
	ap=1,
	uselos=true,
	atk=basic_attack,
	typ=2,
	aoe=1.5,
	trgtd=true,
	ma=3,
	buffs={["sleep"]=3},
	aoelos=true,
	eff=54
},
["heal"] = {
	name="heal",
	dmg=-0.25,
	rng=3.5,
	ap=1,
	uselos=true,
	atk=basic_attack,
	typ=2,
	aoe=1.5,
	trgtd=true,
	ma=4,
	aoelos=true,
	eff=54
},
["missile"] = {
	name="missile",
	dmg=1,
	rng=4.5,
	ap=2,
	uselos=true,
	atk=basic_attack,
	typ=2, --light
	trgtd=true,
	ma=8,
	eff=64,
 min_range=2
},
["slime"] = {
	name="slime",
	dmg=0.25,
	rng=2.5,
	ap=1,
	uselos=true,
	atk=basic_attack,
	typ=3, --shadow
	aoe=1,
	trgtd=true,
	ma=4,
	aoelos=true,
	buffs={["slimed"]=2},
	eff=49
},
["rift"] = { 
	name="rift",
	dmg=0,
	rng=2,
	ap=3,
	atk=teleport,
	typ=3, --shadow
	trgtd=true,
	ma=7,
	eff=58
},
["thunder"] = { 
	name="thunder",
	dmg=0.5,
	rng=3.5,
	ap=3,
	atk=basic_attack,
	typ=3, --shadow
	trgtd=true,
	aoe=2,
	uselos=true,
	aoelos=false,
	ma=10,
	buffs={["def⬇️"]=2},
	eff=68
},
["spear"] = {
 name="spear",
 dmg=1,
 rng=2,
 ap=5,
 ma=0,
 uselos=true,
 atk=basic_attack,
 typ=1,
 trgtd=true,
 eff=7,
 min_range=1.5
},
["raise"] = {
 name="raise",
 rng=1.5,
 ap=5,
 ma=10,
 uselos=true,
 atk=raise,
 typ=3,
 trgtd=true,
 eff=64
}
}
-->8
--turn logic


function next_turn()
	menus={}
	turn+=1
	path={}
	if(turn > #units) then
		if(game_state=="placement") game_state = "battle"
		turn=1
	end
	if(game_state=="battle") then
		act_un=units[turn]
		update_buffs(act_un)
		act_un.ap=get_stat(act_un,"spd")
		update_nav()
  mana_regen = 3

  change_stat(act_un,"ma",mana_regen,get_stat(act_un,"maxma"))
		
		if(not act_un.enemy) then
			make_menu(2,76,26,33,nil,{"inspect","move","attack","stop"},nil,b_menu,nil,true)
			cur={x=act_un.x,y=act_un.y}
		end
	end
end
-->8
--util
function clone(to_copy,val)
	local cpy={}
	local i, v = next(to_copy,nil)
	while i do
		if(val) then
		
			cpy[i]=val
		else
			if(type(v) == "table") then
				cpy[i] = clone(v)
			else
				cpy[i]=v
			end
		end
		i,v=next(to_copy,i)
	end
	return cpy
end

function navgrid(sx,sy,flgs,mx,use_enemy,enemy)
	stack={{x=sx,y=sy,c=0}}
	local pos=1
	local sol = false
	while pos <= #stack do
		crd=stack[pos]
		n=crd.c+1
		for x=crd.x-1,crd.x+1 do
			for y=crd.y-1,crd.y+1 do
				a={x=x,y=y,c=n}
				local u=check_unit(x,y,nil,true)
				if(u and use_enemy) then
					if(u.enemy != enemy) then
						return stack
					end
				end
				
				if(not stack_has(stack,a) and in_battle(a) and not has_flag(a,flgs) and not u and not check_unit(a.x,a.y)) then
							if(use_enemy) then
								add(stack,a)
							else
									if(not mx or n <= mx) add(stack,a)
							end
					end
				end
		end


		pos+=1
	end
	
	return stack
	
end

function find_path(pos,grid)
		local returnstk={}
		pos=stack_has(grid,pos)
		while pos do
			add(returnstk,pos)
			pos=next_move(pos,grid)
		end
		
		if(#returnstk > 0) then 
			if(returnstk[#returnstk].c == 0) then
				return returnstk
			else
				return {{x=cur.x,y=cur.y}}
		end
		end
		return returnstk
end

function check_unit(x,y,ignore,alive)
	if(alive == nil) alive=true
	for u =1,#units do
		un=units[u]
		if(un.x==x and un.y==y and un != ignore and un.alive==alive) then
			return un
		end
	end
end

function update_nav()
	act_un.nav=navgrid(act_un.x,act_un.y,slds,get_stat(act_un,"spd"),act_un.brain,act_un.enemy)
end

function next_move(p,grid)
	local p=stack_has(grid,p)
	if(p==nil or p.c==0 or check_unit(p.x,p.y,act_un)) return nil
	local best=p
	local len = #grid
	for i=1,len do
		cel= grid[i]
		d=dist(p,cel)
		if(d < 2 and cel.c <= best.c) then
			if(d < dist(p,best) or best == p) best=cel
		end
	end
	if(best==p) return nil
	return best
end




function in_battle(coord)
	if(coord.x >= 0 and coord.x < bfield.sx) then
		if(coord.y >= 0 and coord.y < bfield.sy) return true
	end
	return false
end

function dist(p1,p2)
	return sqrt((p1.x-p2.x)^2+(p1.y-p2.y)^2)
end

function has_flag(crd,flgs)
	return fget(mget(crd.x,crd.y),flgs)
end

function stack_has(st,cd)
	if(st==nil) return nil
	for i=1,#st do
		if(cd.x==st[i].x and cd.y == st[i].y) return st[i]
	end
	return nil
end

function round(n)
	if(flr(n)-n < ceil(n)-n) return flr(n)
	return ceil(n)
end



function los(x1,y1,x2,y2)
	x1=x1*8+4
	x2=x2*8+4
	y1=y1*8+4
	y2=y2*8+4
	d=dist({x=x1,y=y1},{x=x2,y=y2})
	yinc=(y2-y1)/d
	xinc=(x2-x1)/d
	ox=x1
	oy=y1
	seenstk={}
	for i=0,d do
		local crd = {x=round(x1/8),y=round(y1/8)}
		if(has_flag(crd,slds)) return nil
		if(not stack_has(seenstk,crd)) add(seenstk,crd)
		y1+=yinc
		x1+=xinc
	end
	return seenstk
end

--closest crow dist
function find_closest(u,enemy,alive)
	closest=nil
	if(alive == nil) alive = true
	d=10000
	for i=1,#units do
		a = units[i]
		if(a.enemy != enemy and a.alive == alive) then
			r=dist(a,u)
			if(d > r) then 
				d=r
				closest=units[i]
			end
		end
	end
	return closest
end

function find_shortest(nav,enemy)
	local best=nil
	local bestd=nil
	for i=1,#units do
		local a= units[i]
		local cel=adjacent(a.x,a.y,nav)

		if(a.enemy == enemy and cel and a.alive) then
			if(cel.c >= 0) then
				if(best) then
					if(cel.c < bestd) then
						best=a
						bestd=cel.c
					end
				else
					best=a
					bestd=cel.c
				end
			end
		end
	end
	return best
end

function pack_string(s,l)
	if(#s < l) return s
	local r=""
	for i=l,#s+l,l do
		r = r .. sub(s,i-l+1,i) .. "\n"
	end
	return r
end

function get_range(cx,cy,r,uselos,min_range)
	local tor={}
	local intr=round(r)
	for x=cx-intr,cx+intr do
		for y=cy-intr,cy+intr do
			if(in_battle({x=x,y=y})) then
    local d = dist({x=cx,y=cy},{x=x,y=y})
				if(d <= r) then
					local r = true
						if(uselos) then
							r = los(cx,cy,x,y)
						end
      if(r and min_range) then
       r = (d > min_range) 
      end
					if(r) add(tor,{x=x,y=y})
				end
			end
		end
	end
	return tor
end
-->8
--rendering
function draw_path(p,range)
	if(p) then
		if(#p > 1) then
			last=cur
			col=9
			for i=1,#p do
				col=9
				if(range) then
					if(i <= #p-range)  col=8 
				end
				line(last.x*8+4,last.y*8+4,p[i].x*8+4,p[i].y*8+4,col)
				last=p[i]
			end
		end
	end
end


function options(opt,x,y,sl,txt)
	local offset=0
	if(txt)then
	 print_just(txt,x,y,7) 
		offset=1
	end
	for o=1,#opt do
		local col=7
		if(sl==o) col=11
		print_just(opt[o],x,y+(o-1+offset)*8,col)
	end
end


function draw_corpse(u)
	if(u.alive) return
	spr(round(u.corpse),u.x*8,u.y*8)
end

function draw_unit(u) 
	if(not u.alive) return
	if(fget(u.k,2) or fget(u.k,3)) u.k += 0.05
	if(fget(u.k,3) and flr(u.k + 0.05) > flr(u.k)) u.k -= 1.95
	spr(round(u.k),u.x*8,u.y*8)
	for b,v in pairs(u.buffs) do
		bdata=buffs[b]
		if(bdata.mapicon) spr(bdata.mapicon,u.x*8,u.y*8)
	end
end

function print_just(t,x,y,c)
	longest_seg=0
	local i = 1
	local seg = 1
	local segs=1
	
	if(not t) return
	while i < #t+1 do
		if(ord(t,i) == 10) then
			longest_seg=max(seg,longest_seg)
			seg=0
			segs+=1
		else
			if(ord(t,i) < 128) seg += 1.75
			if(ord(t,i) >= 128) seg += 4
		end
		i+=1
	end
	longest_seg=max(seg,longest_seg)

	print(t,camx + x-flr(longest_seg),camy + y-(segs*3),c)
end

function draw_menu(m)
	rectfill(camx+m.x-2,camy+m.y-2,
	camx+m.x+m.w+2,
	camy+m.y+m.h+2,0)
	rect(camx+m.x-2,camy+m.y-2,
	camx+m.x+m.w+2,
	camy+m.y+m.h+2,7)
	if(m.text and not m.op) print_just(m.text,m.x+m.w/2,m.y+m.h/2,7)
	if(m.op) options(m.op,m.x+m.w/2,m.y+6,m.sl,m.text)  
end

function draw_effect(e)
	if(e.k) then
		spr(e.k,e.x*8,e.y*8)
		e.k+=0.1
		if(fget(flr(e.k)-1,1)) del(effects,e)
	else
		print_just(e.text,e.x*8+4,e.y*8+4,e.c)
		e.lifetime+=1
		e.y -= 0.001
		if(e.lifetime > 40) del(effects,e)
	end
end

function draw_range(r,s)
	foreach(r,function(a) 
		if(a.x != cur.x or a.y != cur.y) then
	 spr(s,a.x*8,a.y*8) end end)
end

function draw_stats(u,namehp,atkdef,spdma,bf) 
	local namecol=7
	if(u.enemy) namecol=8
	if(namehp) print(u.name.."\nhp:"..u.hp.."/"..get_stat(u,"maxhp"), camx,camy+113,namecol)
	if(atkdef) print("atk:"..get_stat(u,"atk").."\ndef:"..get_stat(u,"def"),camx+44,camy+113)
	if(spdma) print("spd:"..u.ap.."/"..get_stat(u,"spd").."\nma:"..u.ma.."/"..get_stat(u,"maxma"),camx+77,camy+113)
	if(bf) then
		b=0
		for i,v in pairs(u.buffs) do
			rectfill(camx+100,camy+104-(b*8),camx+128,camy+110-(b*8),0)
			rect(camx+99,camy+103-(b*8),camx+127,camy+111-(b*8),7)
			print_just(i,camx+114,camy+108-(b*8),buffs[i].c)
			b+=1
		end
	end
end
-->8
--ui


function make_menu(x,y,w,h,text,op,update,on_sel,draw,delte)
	if(not update) then 
		if(text) update=dismiss_wait
		if(op) update=sel_menu
	end
	if(not draw) draw=draw_menu
	add(menus,{
		x=x,
		y=y,
		w=w,
		h=h,
		text=text,
		op=op,
		sl=1,
		update=update,
		on_sel=on_sel,
		draw=draw,
		delte=delte
	})
end

function dismiss_wait(m)
	focus=true
	if(btnp(❎)) del(menus,m)
end

function sel_menu(m)
	focus=true
	if(btnp(⬆️)) m.sl-=1
	if(btnp(⬇️)) m.sl+=1
	if(m.sl<1) m.sl=#m.op
	if(m.sl>#m.op) m.sl=1
	if(btnp(❎)) m.on_sel(m.sl)
	if(btnp(🅾️) and not m.delte) del(menus,m)
end

function format_spells(spls)
	rtrn={}
	for i = 1,#spls do
		dat=atks[spls[i]]
		local toadd = dat.name .. "("..dat.ap.." spd"
		if(dat.ma > 0) toadd = toadd.. " + "..dat.ma.."ma"
		toadd..=")"
		add(rtrn,toadd)
	end
	return rtrn
end


function b_menu(s)
	if(s==1) then
		make_menu(0,0,0,0,nil,nil,inspect_update,nil,inspect_draw)
	elseif(s==2) then --move selection
		make_menu(-4,-4,0,0,nil,nil,move_menu,nil,mm_draw)
		moved=false
	elseif(s==3) then -- attack menu
		make_menu(2,77,96,32,nil,format_spells(act_un.spells),nil,atk_slct)
	elseif(s==4) then -- rest
		next_turn()
	end
	
end

function path_regen()
	if(#path < 1) return true
	if(path[1].x != cur.x or path[1].y != cur.y) return true
	return false
end

function atk_slct(s)
	atkdata=atks[act_un.spells[s]]
	if(atkdata==nil) return
	if(atkdata.ap > act_un.ap) then
		make_menu(32,64,64,16,"not enough spd!")
		return
	elseif(atkdata.ma > act_un.ma) then
		make_menu(32,64,64,16,"not enough mana!")
		return
	elseif(atkdata.trgtd) then
		valid_tiles=get_range(act_un.x,act_un.y,atkdata.rng,atkdata.uselos,atkdata.min_range)
		make_menu(0,0,0,0,nil,nil,target_update,nil,target_draw)
		fired=false
	end
	
end

function move_menu(m)
	show_stats=false

	if(moved and not moving) del(menus,m)
	if(not moving and path_regen()) path=find_path(cur,act_un.nav)
	if(btnp(❎) and #path > 1) then 
		moving=true
		moved=true
	end
	if(btnp(🅾️) and not moving) del(menus,m)
end

function mm_draw(m)
	local r = act_un.ap/act_un.move_cost
	draw_path(path,r)
	print(act_un.name,camx,camy+113,7)
	if(not moving) print("❎ confirm\n🅾️ cancel",camx+60,camy+113)
	consumption= max((#path-1)*act_un.move_cost,0)
	col=7
	if(consumption>act_un.ap) col=8
	if(not moving) then 
		print("spd used:"..consumption.."/"..act_un.ap,camx,camy+119,col)
	else
		print("moving...",camx,camy+119)
	end
end


function target_update(m)
	if(#effects == 0 and fired) del(menus,m)
	if(btn()) trgt=check_unit(cur.x,cur.y)
	show_stats=false
	aoe_tiles=nil
	if(btnp(🅾️)) then 
		del(menus,m)
		return
	end
	if(stack_has(valid_tiles,cur)) then
			if(atkdata.aoe) aoe_tiles=get_range(cur.x,cur.y,atkdata.aoe,atkdata.aoelos,atkdata.min_range)
			if(btnp(❎) ) then
				atkdata.atk(act_un,cur,atkdata)
				act_un.ap-=atkdata.ap
				act_un.ma -= atkdata.ma
				fired=true
	end
	end
end

function target_draw(m)
	if(fired) return
	draw_range(valid_tiles,6)
 print("❎ confirm\n🅾️ cancel",camx+77,camy+113)
	if(trgt) then
		draw_stats(trgt,true)
	end
	if(aoe_tiles) draw_range(aoe_tiles,10)
end

function inspect_update(m)
	trgt=check_unit(cur.x,cur.y)
	tile=mget(cur.x,cur.y)
	show_stats=false
	corpse=check_unit(cur.x,cur.y,nil,false)
	if(btnp(❎) and trgt) make_menu(22,22,84,84,"",nil,nil,nil,inspect_target)
	if(btnp(🅾️)) del(menus,m)
end

function inspect_target(m)
	draw_menu(m)
	sspr((round(trgt.k)%16)*8,flr(trgt.k/16)*8,8,8,m.x+m.w*0.1,m.y+m.h*0.1,16,16)
	print_just(trgt.name,m.x+m.w*0.5,m.y+m.h*0.1,7)
	
	print_just(creatures[trgt.name],m.x+m.w/2,m.y+m.h*0.75,7)

end

function inspect_draw(m)
	if(trgt) then
		draw_stats(trgt,true,true,true)
	elseif(corpse) then
		print(corpse.name.." corpse",camx,camy+113)
	else
		print(tiles[tile],camx,camy+113)
		if(has_flag(cur,slds)) print("solid",camx,camy+121,8)
	end
end



-->8
--brains
action_time=60 --how many frames to wait after performing an action

action_announce=""


function brain_update(u)
 if(moving) return false

 if(not u.alive) then 
  next_turn()
  return false
 end
 if(movetimer!=0) then
  movetimer-=1
  return false
 else
  action_announce=""
 end
 return true
end

function harpy_brain(u)
	if(not brain_update(u)) return
 target=find_closest(u,u.enemy)
	atkdata=atks["bite"]
	if(not target.buffs["sleep"] and rnd(10) <= 1) then
		atkdata=atks["sleep"]
	end
	if(move_and_attack(u,target,atkdata)) next_turn()
end


function necro_brain(u)
	if(not brain_update(u)) return
 target=find_closest(u,not u.enemy,false) --look for dead allies
	atkdata=atks["raise"]
	if(target == nil) then
		target=find_closest(u,u.enemy) --look for dead allies
		atkdata=atks["rift"]
	end
	if(move_and_attack(u,target,atkdata)) next_turn()
end


function default_brain(u)
 if(not brain_update(u)) return
 target=find_closest(u,u.enemy)
 atkdata=atks[u.spells[1]]
 if(move_and_attack(u,target,atkdata)) next_turn()
end

function move_and_attack(u,target,atkdata)
 tomove=get_attack_pos(u,target,atkdata)
 if(tomove) then 
  if(tomove.c > 0) then
   if(u.ap > 0) navigate_to_point(u,tomove)
   return false
  else
  	 if(u.ap >= atkdata.ap) then 
	   if(#effects == 0) use_spell(u,target,atkdata)
	   return false
	  end
	 end
 end
 return true
end

function get_attack_pos(u,target,atkdata)

 mrange = max(atkdata.min_range,atkdata.aoe)
 local valid_tiles=get_range(target.x,target.y,atkdata.rng,atkdata.uselos,atkdata.aoe)
 
 
 best=nil
 for i = 1,#valid_tiles do
  d = stack_has(u.nav,valid_tiles[i])
  if(d) then
	  if(best == nil or d.c < best.c) then
	   best=d
	  end
  end
 end
 return best
end


function navigate_to_point(u,dest)
 path=find_path(dest,u.nav)
 if(#path > 1) then
  moving=true   
 end
end


function get_enemy_in_range(u,atkdata)
 valid_tiles = get_range(u.x,u.y,atkdata.rng,atkdata.uselos,atkdata.min_range)
 for v=1,#valid_tiles do
  local t=check_unit(valid_tiles[v].x,valid_tiles[v].y,u)
  if(t) then
   if(t.enemy != u.enemy) then
    return t
   end 
  end
 end
 return nil
end

function use_spell(u,trgt,atkdata)
  atkdata.atk(u,trgt,atkdata)
  u.ap -= atkdata.ap
  movetimer=action_time
  action_announce=u.name.." used "..atkdata.name.." on "..trgt.name
  return
end

-->8
--descriptions


tiles={
	[3] = "grass",
	[4] = "bricks",
	[42] = "daisy",
	[43] = "tulip",
	[46] = "grass",
	[39] = "rock",
	[103]="tree",
	[104]="tree",
	[38]= "tree"
}

creatures={
	["goblin"] = "a foul creature\nof the wastes\ndo not come between\nthem and treasure.",
	["anya"] = "archmage\nanya volkovia\nskilled in\nthe deployment\nof fire magics.",
	["rachel"] = "rachel llyadwell\nblademaster of\nthe forest\nkingdom of campton.",
	["slime"] = "sentient discharge\nfrom dark\nexperiments.\nvery sticky.",
	["father"] = "a priest of the\nvalley",
 ["jeff"] = "a woodsman\nof some note.",
 ["troll"] = "brutish creatures\nwith more brawl\nthan brain.",
 ["wolf"] = "small but ferocious.",
 ["footman"] = "soldier of darkness",
 ["axeman"] = "soldier of darkness",
 ["tim"] = "he likes to\nblow things up.",
 ["necromancer"] = "a servant of\ndarkness.\nwill try to raise/nthe dead."
}
-->8
--classes
classes = {
	["tank"]={
		["maxhp"]=20,
		["atk"]=8,
		["def"]=10,
		["spd"]=4,
		["maxma"]=6
	},
	["fighter"]={
		["maxhp"]=15,
		["atk"]=16,
		["def"]=5,
		["spd"]=8,
		["maxma"]=4
	},
	["mage"] = {
		["maxhp"]=10,
		["atk"]=14,
		["def"]=3,
		["spd"]=5,
		["maxma"]=12
	}
}

mods={
	["maxhp"]=3,
	["atk"]=1,
	["def"]=2,
	["spd"]=0.5,
	["maxma"]=1
}

function copy_stats(stats,class,lvl)
	local b=classes[class]
	local a,v = next(b,nil)
	while(a) do
		stats[a] = v + flr(mods[a] * lvl)
		stats.modifiers[a] = 1
		a,v=next(b,a)
	end
	stats["hp"] = stats["maxhp"]
	stats["ma"] = stats["maxma"]
end
-->8
--buffs woooooo

buffs={
	["slimed"]={
		mods={["spd"] = -0.25},
		update=nil,
		apply=nil,
		cleanse=nil,
		mapicon=52,
		c=3
	},
		["sleep"]={
		mods={["spd"] = -1},
		mapicon=53,
		c=12
	},
	["def⬇️"]={
		mods={["def"] = -0.25},
		c=8
	}
}


function apply_buff(unit,buff,duration)
	if(unit.buffs[buff]) then
		unit.buffs[buff] += duration
	else
		bdata=buffs[buff]
		unit.buffs[buff] = duration
		field_text(unit.x,unit.y+0.1,buff,bdata.c)
		--apply mods
		for key,val in pairs(bdata.mods) do
			unit.modifiers[key] += val
		end
	end
end


function update_buffs(unit)
	todel={}
	for buff,dur in pairs(unit.buffs) do
		bdata = buffs[buff]
		if(unit.buffs[buff] <= 0) then
			if(bdata.cleanse) bdata.cleanse(unit)
			cleanse_buff(unit,buff)
		else
			if(bdata.update) then
				bdata.update(unit)
			end
			
			unit.buffs[buff] -= 1
		end
	end
end


function cleanse_buff(unit,buff)
	if(unit.buffs[buff] == nil) return
	--field_text(unit.x,unit.y+0.1,buffs[buff].ctext,buffs[buff].c)
	for key,val in pairs(buffs[buff].mods) do
		unit.modifiers[key] -= val
	end
	unit.buffs[buff] = nil
end
-->8
--party logic

party={}

function add_member(unit)
	add(party,unit) 
	party=sort_party(party)
end


function sort_party(party)
	local r = true
	if(#party < 2) return party
	while r do
		r = false
		for i = 2,#party do
			if(get_stat(party[i-1],"spd") < get_stat(party[i],"spd")) then
				t = party[i]
				party[i] = party[i-1]
				party[i-1] = t
				r = true
			end
		end
	end
	return party
end
-->8
--environment


function get_environment(tile)
	for t=1,#environments do
		e=environments[t]
		if(find_i(e.mtiles,tile)) return e
	end
end

forest={
	ground={3,46,46},
	mtiles={38,103,104},
	danger=70,
	deco={42,43},
	obsticles={38,39,103},
	obsnum=20
}
grass={
	ground={3,46,46},
	mtiles={3,46},
	danger=60,
	deco={42,43},
	obsticles={4,39},
	obsnum=10
}
roads={
	ground={3,46,46,84,85},
	mtiles={67,84,85},
	danger=35
}

environments={forest,grass,roads}

-->8
--encounters
function generate_battlefield(w,h,env)
	bfield = {sx=w,sy=h}
	fstart = w/4
	estart = w - fstart
	for x = 0,w do
		for y = 0,h do
			mset(x,y,rnd(env.ground))
			if(rnd(1) > 0.95 and env.deco) mset(x,y,rnd(env.deco))
		end
	end
	if(env.obsticles) then
		obsticles=flr(rnd(env.obsnum/2) + env.obsnum/2)
		for o = 0,obsticles do
			ox = flr(rnd(w+1))
			oy = flr(rnd(h+1))
			mset(ox,oy,rnd(env.obsticles))
		end
	end
end


function begin_encounter(encounter,environment)
	generate_battlefield(16,14,environment)
	game_state="placement"
	unplaced = {}
	units={}
	menus={}
	camx=0
	camy=0
	cur={x=8,y=7}

	for i = 1,#party do
		add(unplaced,party[i])
	end
	
	if(encounter.bosses) foreach(encounter.bosses,function(a) add(unplaced,monsters[a]) end)
	b = min(rint(encounter.num/2,encounter.num),#party + 2)
	for i = 1, b do
		add(unplaced,monsters[rnd(encounter.crowd)])
	end
	
	unplaced = sort_party(unplaced)
end


function find_i(l,i)

	for k=1,#l do
		if(i==l[k]) return true
	end
	
	return false
end


function get_encounter(env)
	if(not env) return nil
	e={}
	weight_sum=0
	if(rnd(100) >= env.danger) return nil
	
	for i=1,#encounters do
		b=encounters[i]
		if(find_i(b.env,env)) add(e,b) weight_sum+= b.weight
	end
	r = rnd(weight_sum)
	w=0

	for i = 1,#e do
		w+= e[i].weight

		if(r < w) then
			
			return e[i]
		end
	end
end




encounters = {
	{
		env={roads,grass},
		crowd={"goblin"}, --crowd enemies
		bosses={"troll"}, --boss enemies
		num=4, --how many total opponents +- n/2
		name="a troll gang", --preceded by "you have encoutnered"
		weight=10,
		escape=2
	},
	{
		env={roads,grass},
		crowd={"goblin"},
		num=5, 
		name="goblin band", 
		weight=20,
		escape=6
	},
		{
		env={grass,forest},
		crowd={"slime"}, --crowd enemies
		num=5, --how many total opponents +- n/2
		name="a sludge of slimes", --preceded by "you have encoutnered"
		weight=50,
		escape=1
	},
	{
		env={grass,forest},
		crowd={"wolf"}, --crowd enemies
		num=6, --how many total opponents +- n/2
		name="a pack of wolves", --preceded by "you have encoutnered"
		weight=60,
		escape=10
	},
	{
		env={grass,forest},
		crowd={"goblin"},
		num=2,
		name="goblin enchanter",
		weight=40,
		escape=6,
		bosses={"gmage"}
	},
	{
		env={grass},
		crowd={"harpy"},
		num=3,
		name="band of harpies",
		weight=10,
		escape=15
	},
	{
		env={roads},
		options={
			{"pie",25,"hp",4},
			{"bun",10,"hp",2},
			{"bread",50,"hp",10},
			{"cookie",30,"spd",1},
			{"cookie",30,"hp",5}
		},
		name="wandering baker",
		weight=20,
		escape=0
	},
		{
		env={roads},
		options={
			{"armor",50,"def",2},
			{"shoes",100,"spd",2},
			{"mana vial",40,"maxma",5},
			{"gold heart",100,"maxhp",10},
			{"nails",70,"atk",2}
		},
		name="wandering merchant",
		weight=15,
		escape=0
	}
		
}

army = {
 crowd={"footman","axeman"},
 num=10,
 name="soldiers of darkness",
 escape=200
}

finalboss= {
	crowd={"footman","axeman"},
	bosses={"gmage","necromancer"},
	num=5,
	name="a malevalent force",
	escape=200
}

-->8
--update loops
function battle()
	focus=false
	show_stats=true
	win=true
	lose=true
	for i = 1,#units do
		if(units[i].alive) then
			if(units[i].enemy) then
			 win=false
			else
				lose=false
			end
		end
	end
	if(lose and #effects == 0) then
		game_state="lose"
	end
	if(win and #effects == 0) then
		game_state="victory"
		menus={}
		goldreward=0
		xpreward=0
		lvlups={}
		
		foreach(units,function(a) 
			if(a.enemy)then 
			 goldreward += max(10,25*a.lvl)
				xpreward += max(10,20*a.lvl)
			end
		end)
		gold += goldreward
		foreach(party,function(p) 
			p.xp += xpreward
			while(p.xp > 100) do
				p.xp -= 100
				p.lvl+=1
				copy_stats(p,p.class,p.lvl)
    if(lvl == 2) select_spells(p,1)
				if(not find_i(lvlups,p)) add(lvlups,p)
			end
		end)
		return
	end
	if(not act_un) then
		turn=0
		next_turn()
	end
	if(moving) then
		movetimer+=1
		if(movetimer > movespeed) then
			move_unit()
			movetimer=0
		end
	end
	if(act_un.brain) act_un.brain(act_un)

	act_un.ap = mid(0,act_un.ap,get_stat(act_un,"spd"))
	if(act_un.ap <= 0 or not act_un.alive and #effects == 0) next_turn()
end

function placement() 
	showcur=true
	focus=false

	placevalid = (cur.x <= fstart and cur.y < bfield.sy and not has_flag(cur,slds) and not check_unit(cur.x,cur.y))
	placing=unplaced[1]
	if(placing.enemy) then
		while true do
			px=round(rnd(fstart) + estart)
			py=round(rnd(bfield.sy))
			if(not has_flag({x=px,y=py},slds) and not check_unit(px,py)) then
				place_unit(px,py,placing,true)
				del(unplaced,placing)
				break
			end 
		end
	elseif(btnp(❎) and placevalid) then
		place_unit(cur.x,cur.y,placing)
		del(unplaced,unplaced[1])
	end
	
	if(#unplaced == 0) then
	 game_state = "battle"
		turn=0
		next_turn()
	end
end

function campaign()
	nx=0
	ny=0
	showcur=false
	if(btnp(⬅️)) nx=-1 ny=0 
	if(btnp(➡️)) nx=1 ny = 0
	if(btnp(⬆️)) ny=-1 nx=0
	if(btnp(⬇️)) ny=1 nx = 0

	if(ny+nx!=0  and encounter == nil) then
		f=mid(1,partyx+nx,mapw)
		g=mid(1,partyy+ny,maph)
		local s=cmap[f][g]
		if(not fget(s,4) and f != partyx or g != partyy) then
			partyx=f
			partyy=g
			armypos+=0.4 --armypeed
			if(s == 83) then
				local m = rnd(recruits)
				if(m) add_member(m)
				del(recruits,m)
				cmap[partyx][partyy] = 3
				make_menu(30,100,90,24,m.name .. " has joined")
			end
			if(s== 97) game_state="finalvictory"
			
			cur_env=get_environment(s)
			encounter=get_encounter(cur_env)
   if(partyx+1 < armypos) encounter = army
			if(partyx == mapw-1) encounter = finalboss
			if(encounter) then
				n="fight"
				if(encounter.options) n="talk"
			 make_menu(42,100,44,24,"what do?",{n,"run"},nil,sel_enc,nil,true)
			end
			end 
	end
	camx=mid(0,(partyx-8)*8,mapw*8-128)
end

function sel_enc(n)
	if(n == 1) then
		if(encounter.options) then
			items={rnd(encounter.options),rnd(encounter.options)}
			make_menu(32,90,64,34,"buy something?",{items[1][1].."("..items[1][2].."g)",items[2][1].."("..items[2][2].."g)","nope"},nil,buy_item,nil,true)		
		else
			begin_encounter(encounter,cur_env)
			encounter=nil
		end 
	elseif(n == 2) then
		if(rnd(get_stat(party[#party],"spd")) > encounter.escape) then
			encounter=nil
			menus={}
		else
			make_menu(42,100,44,24,"caught!",{"fight"},nil,sel_enc,nil,true)
		end
	end
end


function buy_item(n)
	i = items[n]
	if(n == 3) then
		encounter = nil
		menus={}
		return
	end
	if(gold >= i[2]) then
		gold -= i[2]
		pname={}
		foreach(party,function(a) add(pname,a.name .. "(" .. get_stat(a,i[3])..")") end)
		make_menu(22,80,84,44,"increase "..i[3].." by "..i[4],pname,nil,sel_apply,nil,true)
	end
end

function sel_apply(n)
	change_stat(party[n],i[3],i[4])
	encounter=nil
	menus={}
end
-->8
--campaign map

mapw=32
maph=16
armypos=1
mountainw=3

shadow_edge={87,88,89}
mapeffects=0

function mountains(sx,ex)
	for x = sx,ex,sgn(ex-sx) do
		for i = 1,maph do
			if(rnd(5) < 5 - (x-sx)*(sgn(ex-sx))) then
				cmap[x][i] = rnd({62,63})
			end
		end
	end
end

function road(sx,sy,ex,ey)
	for x = sx,ex,sgn(ex-sx) do
		if(x != ex and x != sx) cmap[x][sy] = rnd(roads.mtiles)
	end
	for y = sy,ey,sgn(ey-sy) do
		if(y != ey) cmap[ex][y] = rnd(roads.mtiles)
	end
end

function rint(mn,mx)
	return flr(rnd(mx)) + mn
end

function update_shadow()
	d_edge={}
	for i = 1,mapw do
		add(d_edge,rnd(shadow_edge))
	end
end

function init_map()
	cmap={}
	villages={}
	for i = 1,mapw do 
		add(cmap,{})
		for y = 1,maph do
			add(cmap[i],rnd(grass.mtiles))
		end
	end
	partyx=2
	partyy=flr(maph/2)
	update_shadow()
	mountains(1,mountainw)
	mountains(mapw,mapw-mountainw+1)
	biome(rint(mountainw,mapw-mountainw),rint(1,maph),forest.mtiles,10)

	for i = 1,3 do
		v={x=flr(mapw/4 * i)+1,y=rint(1,maph)}
		add(villages,v)
		cmap[v.x][v.y] = 83
	end
	add(villages,{x=0,y=flr(maph/2)},1)
	add(villages,{x=mapw,y=villages[#villages].y})
	cmap[mapw][villages[#villages].y] = 97
	for i = 2,#villages do
		st=villages[i-1]
		en=villages[i]
		road(st.x,st.y,en.x,en.y)
	end
	
end

function on_map(x,y)
	return (x < mapw and x > 0 and y < maph and y > 0) 
end

function biome(x,y,b,s)
	cmap[x][y] = rnd(b)
	for a=x-1,x+1 do
		for c=y-1,y+1 do
			if(not(a==x and c==y)) then
				if(on_map(a,c) and rnd(10) < s and find_i(grass.mtiles,cmap[a][c])) biome(a,c,b,s-1)
			end
		end
	end
end


function draw_map()
	mapeffects+=1
	if(mapeffects > 30) then
		mapeffects=1
		update_shadow()
	end
	for x = flr(armypos),mapw do
		for y = 1,maph do
			spr(cmap[x][y],(x-1)*8,(y-1)*8)
			a=nil
			if(x == flr(armypos)) spr(d_edge[y],(x-1)*8,(y-1)*8)
		end
	end
	rectfill(0,0,flr(armypos)*8-8,maph*8,1)
	spr(party[1].k,partyx*8-8,partyy*8-8)

	if(encounter) then
		rectfill(camx,camy+54,camx+128,camy+76,0)
		print_just(encounter.name,64,70,7)
		print_just("spotted!",64,60,8)
	end
end


__gfx__
00000000000aa00000088000bbbbbbbbeeee5eeeaaaaaaaa888888880000000000000010000000005555555504004000406006000000000005555500000bb000
0000000000affa000088f800b33bbbbb88885e88a000000a80000008000000000000611000000660500000050555500640666630066066005151555000bbbb00
00700700000ffa00008ff800bbbbbbbb88885e88a000000a80000008000000000006610000006600500000050a5a500643a6a633055556005555500500abab00
00077000004444a008666680bbbbbbbb55555555a000000a800000080001000000661000000010005000000545555555436663330a5a500051155000b0bbb300
0007700000f55fa008f11f80bbbbbbbbe5eeeeeea000000a800000080011000000610000000000005000000555555555603333030555500651150000b3333330
007007000004400000055000bbbbbbbb85e88888a000000a80000008011000000010000000000000500000050055565540444406555555065515000000333bb0
0000000000f00f0000600600bbbbb33b85e88888a000000a80000008010000000010000000000000500000050060506500644600060555500555500000333300
000000000440040000500500bbbbbbbb85e88888aaaaaaaa88888888000000000000000000000000555555550060506500300300000555500055555500300300
111111110000000000000000000000000000000000aaaa00000000000000000000999900009999000066000000000000000000008002222280066000a00ff000
15553351000555500008007000000000505000000a3333a000000000000000000097790009777790066660000000000000000000a02222006066660050fff600
13355551605555000078870000606000040000000a33b3a000aaaa00000990000978889097888879006060000060060000000000a083820060d6d606505f5f00
13355551608385000887880006676660440000000a333b3a0a3333a00098890009888790978888790666556000666600000888803033320322666220f0ffff00
1555335130333550008878806616666604949447a333333a0a33b3a00098890009888790978888796055550655a6a65500888888a22222206022220056666660
1555335105555503007887880666676004444470a333333a0a333ba0000990000988889097888879000660000566655009985858a022220060222200506566f0
1555535100555500078000000066660000400400a33333aa0a3333a0000000000097890009777790005555000056650059958585a02222206022222050555660
11111111005005000000000005000050004004000aaaaaa00aaaaaa0000000000099990000999900005005000000505050050505a02222226022222250656666
6000000000011110040333306650000000000000d20dd000bbbb3bbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbb000000000000a600bbbbbbbb00000000
6006600010111100403333006658888000055550ddd0d000bb3333bbbbbbbbbbcccccccccc77ccccbbbbbbbbbb88888b000000000000a000bbbbbbbb00000000
40666600505f5100405f530060577780605555002d2d0000b333333bbbb55bbbccccccccc7cc7cccbbbb7bbbbbb888bb000000006a00a000bbbbbbbb00000000
40868800f0fff100f0fff3000058788060838500d2d2d000b333333bbb5555bbccccccccccccccccbbb7a7bbbbb888bb000000000aaaaa06bbbbbbbb00aaaa00
8888844051111110433333300058888830333550dddd0000bbb44bbbbb55555bccccccccccccccccbbbb7bbbbbbb3bbb05500000aaaaaaaabbbbbbbb112f2a11
40888440501111f0404444f000888888055555032dd00000bbb44bbbb555555bcccccccccccc77ccbbbb3bbbbbbb3bbb005000006166aaa0bbbbbbbb01fff1a0
4088880050111110403333000058888000555500d22d0000bbb44bbbbbbbbbbbccccccccccc7cc7cbbbb3bbbbbbb3bbb00600000a66aaaa6bbbbbbbb001881a0
4080080050111111043003000058008000500500ddd22000bbb44bbbbbbbbbbbccccccccccccccccbbbb3bbbbbbb3bbb006000000aaaaa00bbbbbbbb00000f0f
0066660000000000000000000000000000000000000cccc000000000000000000000000000999900005555500555500005000000000011106666666666666666
0677776000000000000003303300033000000000000000c000000e000007ee000e00000009aaaa90051151555555500055000000000010016667666666666666
677777760003300000330b303b0003300000000000000c000000e7e000000000000000009aa7aaa9551111555511100050000000000010016677766666666666
6dc77cd6003bb300003b00000000b000000000000000c00000000e0000000000000000709a7aaaa9511111555511100055100000b000b1106655566666666666
67777776003bb30000000b3000000000000000000000cccc0000000000e00000000000009aaaaaa95111111551111000511100000b0b10006555556666655666
0677776000033000000003300000000000000000000000000000000000e00000000000009aaaaaa951111555555110005511000000b010006555156666555556
007cc700000000000000000000000b300b3333b0000000000e0000000ee7000000000e0009aaaa905551155555555000500000000b0b10005555555665555555
006776000000000000000000000003303333b333000000000000000000e000000000000000999900055555500555500005000000b000b0005555555665555555
000000000000000000070000444444440a00000000000000000000000000000000088000000100000010000000100000000a000000a0000000a0000000000000
0000000000007000000b0000499444440aa0000000000000000000000000000000800800000100000110010001100000000a00000aa00a000aa0000000000000
000000000000b000000000004444499400a0000000a00000000000000000000000008000000100011000110011000000000a000aa000aa00aa00000000000000
000bb0000000b0007b0b0bb04944444400aa000000aa00000a70007a007000070008000000100011000010000000000000a000aa0000a0000000000000000000
00bbbb0007bb00bb000000004444994400000000000aa0000a70007a0000000a000800000110001000010000000000000aa000a0000a00000000000000000000
000bb0000000bb0000000b0049944444000000000000a0000aa707aa0aa000aa000000000100011000110000000000000a000aa000aa00000000000000000000
00000000000070000007000044449944000000000000a00000aa7aa00a00000000080000110001000010000000000011aa000a0000a00000000000aa00000000
000000000000b00000000000444449440000000000000000000aaa0000000000000000000000000000000000000000100000000000000000000000a000000000
000000000000000007000070bbbbbbbb444449994444444411111111111100001110000012110000000007777770000000000000000000000000000000000000
000000000070070070000007bbb4bbbb444444444444444411111111111110001111000012110000000777777777700000000000000000000000777777700000
000660000700007070000007bb444bbb444444444444644411111111111110001111000011100000007777777777770000000000000000000007777777770000
006666000700607000000007b44994bb444449444444444411111111111110001110000011110000077777777777777000000000000000000000700780700000
0066660007060070700006004499944b444499444444444411111111111110001100000011111000777777777777777000000000000000000000787777700000
000660000070070070000007449994bb944444444644464411111111121100001200000011111000771177777771177700000000000000000000087078800000
000000000000000070000007b49994bb944444444444444411111111121100001200000011111000771177777771177700000000000000000007777888777000
000000000000000007000070b49994bb499444444444444411111111111000001110000011111000777777711777777700000000000000008777078808000700
bbbabbbb54544545ccccccccccccccccccccccccaaaaaaaaaaaaaaaabbb33bbbbbbbbbbb00000000777777711777777700000000000000008800087878000700
bbaaabbb55544555c171ccccccccc117ccccccccaaaaa9aaaa9aaaaabb3333bbb3bbbbbb00000000777777777777777700000000000000008000000700008700
bb6a6bbb56555565cccccccccccccccccc11ccccaaaaaaaaaaaaaaaab333333b343bbbbb00000000077777777777777000000000000000000000077777007800
b66a66bb56666665ccccccccccccccccccccccccaaaaaaaaaaaaaaaa33333333b4bbbbbb00000000000777177177700000000000000000000800070707000800
6677766b56666665ccccc7cccccccccccccccc7caa9aaaaaaaaaaaaa33344333b4bbbb3b00000000000077111177000000000000000000000000077770000000
6677766b56611665cccc111cccccccccccccccccaaaaaaaaaaaaaaaabbb44bbbb4bbb34300000000000077777777000000000000000000000007700007700800
b67176bb56611665ccccccccc117cccccccc111caaaaaa9aaa9aaaa9bbb44bbbb4bbbb4b00000000000077777777000000000000000000000077000007777008
b67176bb55511555ccccccccccccccccccccccccaaaaaaaaaaaaaaaabbb44bbbb4bbbb4b00000000000007777770000000000000000000000077000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303003d3d3d3d303d3d303030303030303030303030303030303030303030303030330303030303030303030000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303003d3d3d3d3d3d3d3d3d3d3d3030303030303030303030303030303030303030330303030303030303030000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303003d3d3d3d3d3d303d303d3d3d3d3d3d3d303030303030303d3d303030303030330303030303030303030000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303003d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d30303030303030330303030303030303030000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303003d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d303d3d3d30303030303030303030330303030303030303030000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000d3d3d3d3d30000000000000000000000000000000000000000000000000000000000
__label__
777b777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b37b7b7bb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbb
b77b7b7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb7b7b7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
777b777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb88bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb388f8bbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb8ff8bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb866668bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb8f11f8bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbb6bb63bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb5bb5bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbaaaabbbbbbbbbbbbbbbbbbaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b33bbbbbba3333abb33bbbbbb33bbbbba3affabab33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbbb88888bb33bbbbbb33bbbbbb33bbbbbb33bbbbb
bbbbbbbbba33b3abbbbbbbbbbbbbbbbbabbffababbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbba333b3abbbbbbbbbbbbbbbbab4444aabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbba333333abbbbbbbbbbbbbbbbabf55faabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbba333333abbbbbbbbbbbbbbbbabb44bbabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb33ba33333aabbbbb33bbbbbb33babfbbf3abbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbb3bbbbbbbb33bbbbbb33bbbbbb33bbbbbb33b
bbbbbbbbbaaaaaabbbbbbbbbbbbbbbbbaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbbb88888bb33bbbbbb33bbbbbb33bbbbbbbbbbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb888bbbbbbbbbbbbbbbbbbbbbbbbbbbbb7a7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbb3bbbbbbbb33bbbbbb33bbbbbb33bbbbb3bbbbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b33bbbbbb33bbbbbb33bbbbbb33bbbbbbbbbbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7a7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbb3bbbbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
eeee5eeebbbbbbbbeeee5eeeeeee5eeeeeee5eeeeeee5eeeeeee5eeeeeee5eeeeeee5eeeeeee5eeeeeee5eeeeeee5eeeeeee5eeeeeee5eeeeeee5eeeeeee5eee
88885e88b33bbbbb88885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e88
88885e88bbbbbbbb88885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e88
55555555bbbbbbbb5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
e5eeeeeebbbbbbbbe5eeeeeee5eeeeeee5eeeeeee5eeeeeee5eeeeeee5eeeeeee5eeeeeee5eeeeeee5eeeeeee5eeeeeee5eeeeeee5eeeeeee5eeeeeee5eeeeee
85e88888bbbbbbbb85e8888885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e88888
85e88888bbbbb33b85e8888885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e88888
85e88888bbbbbbbb85e8888885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e8888885e88888
bbbbbbbbbbbbbbbbeeee5eeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbeeee5eeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b33bbbbbb33bbbbb88885e88b33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbb88885e88b33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbb
7777777777777777777777777777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb88885e88bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7000000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55555555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7000000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbe5eeeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7000000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb85e88888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7000000000000000000000000000007bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33b85e88888bbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33b
70bbb0bb000bb0bbb0bbb00bb0bbb07bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb85e88888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
700b00b0b0b000b0b0b000b0000b007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbeeee5eeeeeee5eeeeeee5eeeeeee5eeebbbbbbbbbbbbbbbbbbbbbbbb
700b00b0b0bbb0bbb0bb00b0000b007bb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbb88885e8888885e8888885e8888885e88b33bbbbbb33bbbbbb33bbbbb
700b00b0b000b0b000b000b0000b007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb88885e8888885e8888885e8888885e88bbbbbbbbbbbbbbbbbbbbbbbb
70bbb0b0b0bb00b000bbb00bb00b007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55555555555555555555555555555555bbbbbbbbbbbbbbbbbbbbbbbb
7000000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbe5eeeeeee5eeeeeee5eeeeeee5eeeeeebbbbbbbbbbbbbbbbbbbbbbbb
7000000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb85e8888885e8888885e8888885e88888bbbbbbbbbbbbbbbbbbbbbbbb
7000000000000000000000000000007bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33b85e8888885e8888885e8888885e88888bbbbb33bbbbbb33bbbbbb33b
7000000777007707070777000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb85e8888885e8888885e8888885e88888bbbbbbbbbbbbbbbbbbbbbbbb
7000000777070707070700000000007bbbbbbbbbeeee5eeeeeee5eeeeeee5eeeeeee5eeeeeee5eeeeeee5eeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7000000707070707070770000000007bb33bbbbb88885e8888885e8888885e8888885e8888885e8888885e88b33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbb
7000000707070707770700000000007bbbbbbbbb88885e8888885e8888885e8888885e8888885e8888885e88bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7000000707077000700777000000007bbbbbbbbb555555555555555555555555555555555555555555555555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7000000000000000000000000000007bbbbbbbbbe5eeeeeee5eeeeeee5eeeeeee5eeeeeee5eeeeeee5eeeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7000000000000000000000000000007bbbbbbbbb85e8888885e8888885e8888885e8888885e8888885e88888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7000000000000000000000000000007bbbbbb33b85e8888885e8888885e8888885e8888885e8888885e88888bbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33b
7000777077707770777007707070007bbbbbbbbb85e8888885e8888885e8888885e8888885e8888885e88888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7000707007000700707070007070007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbeeee5eeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7000777007000700777070007700007bb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbb88885e88b33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbb
7000707007000700707070007070007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb88885e88bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7000707007000700707007707070007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55555555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7000000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbe5eeeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7000000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb85e88888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7000000000000000000000000000007bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33b85e88888bbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33b
7000000770707077707770770000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb85e88888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7000007000707070707070707000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7000007000707077707700707000007bb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbb
7000007070707070707070707000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7000007770077070707070777000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7000000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7000000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7000000000000000000000000000007bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33b
7000000777077700770777000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7000000707070007000070000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbeeee5eeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7000000770077007770070000000007bb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbb88885e88b33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbb
7000000707070000070070000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb88885e88bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7000000707077707700070000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55555555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7000000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbe5eeeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7000000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb85e88888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7000000000000000000000000000007bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33b85e88888bbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33b
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77707770077070707770700000000000000000000000777077707070000077007770000000000077077707700000077700070777000000000000000000000000
70707070700070707000700000000000000000000000707007007070070007000070000000000700070707070070070700700707000000000000000000000000
77007770700077707700700000000000000000000000777007007700000007000070000000000777077707070000077700700777000000000000000000000000
70707070700070707000700000000000000000000000707007007070070007000070000000000007070007070070070700700707000000000000000000000000
70707070077070707770777000000000000000000000707007007070000077700070000000000770070007770000077707000777000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70707770000077707770007077707770000000000000770077707770000077700000000000000777077700000777000707770000000000000000000000000000
70707070070000707070070000707070000000000000707070007000070070700000000000000777070700700700007007000000000000000000000000000000
77707770000077707070070077707070000000000000707077007700000077700000000000000707077700000777007007770000000000000000000000000000
70707000070070007070070070007070000000000000707070007000070000700000000000000707070700700007007000070000000000000000000000000000
70707000000077707770700077707770000000000000777077707000000000700000000000000707070700000777070007770000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000001000000000200000000000000000000000408000002000000000000000000000000010105090000000000000000000200000000020000000200101000000200000000020000000000000000000002000000000000000000000000000000000000000001010000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303040303040303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03030403030303040303032b0303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03030403042b0303032a03030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0304030303030304030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2903030403030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
030303032a030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0403040404040404040404040404040404040303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303040303030303030403030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303040303030303030404040403030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303040303040404040404030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303040303030303030304030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030304030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030304030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030304030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030304030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
011018001805000000180501b0501a0501b0501805000000180501b0501a0501b0501805000000180501b0501a0501b050180501a0501b0501d0501b0501a0500000000000000000000000000000000000000000
001018002405024050240502405024050240502b0502b0502b0502b0502b0502b0502b0502b0502b0502705027050270502905029050290502c0502c0502c0500000000000000000000000000000000000000000
011018002b0502b0502b0502b0502b0502b0502405024050240502405024050240500000000000000002605026050260502705027050270502305023050230500000000000000000000000000000000000000000
001018000c0550c0550c0550a0550a0550a0550805508055080550705507055070550505505055050550705507055070550805508055080550505505055050550c0000c0000c0001600016000160000000000000
001000181801018010180201802018030180301804018040180501805018060180601806018060180601a0701a0701a0701b0701b0701b0701d0701d0701d0701f0001f0001f0001800018000180001800018000
000f00001f0501f0501f0501f0501f0501f0501805018050180501805018050180500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001f0501f0501f0501805018050180500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002205022050220502205022050220502705027050270502705027050270500000000000000002905029050290502b0502b0502b0502c0502c0502c0500000000000000000000000000000000000000000
01101800160501b0501f050220501f0501b050160501b0501f050220501f0501b050160501b0501f050220501f0501b050160501b0501f050220501f0501b0500000000000000000000000000000000000000000
01101e002b0502b0502b0502b0502b0502b0502705027050270502705027050270500000000000000002a0002a000000002a0502a0502a0502a0502a0502a0502705027050270502705027050270500000000000
01101e00160501b0501f050220501f0501b050160501b0501f050220501f0501b050160501b0501f050220501f0501b05015050190501e050210501e0501905015050190501e050210501e050150500000000000
011000002605026050260502605026050260500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 00014344
00 00024544
00 00014344
00 00024344
00 07084344
02 090a4344

