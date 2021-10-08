pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
--main
camx=0
camy=0


units={}

bfield={
sx=16,
sy=14
}


turn=1
in_battle=true
cur={x=8,y=8}
menus={}
path={}
act_un=nil
camh=14
camw=16
focus=true
slds={0}
moving=false
movespeed=5
movetimer=0

function _init()
	init_units()
	place_unit(4,1,goblin)
	place_unit(5,1,goblin)
	place_unit(6,1,goblin)
	place_unit(7,1,goblin)

	place_unit(1,1,anya)
	place_unit(4,2,rachel)
	next_turn()
end



function _update()
	focus=false
	show_stats=true
	active_men=menus[#menus]
	if(moving) then
		movetimer+=1
		if(movetimer > movespeed) then
		move_unit()
		movetimer=0
		end
	end
	if(act_un.enemy) act_un.stats.brain(act_un)
	
	if(active_men) then
		active_men.update(active_men)
	end
	if(cur and not focus) then
		if(btnp(⬆️)) cur.y-=1
		if(btnp(⬇️)) cur.y+=1
		if(btnp(⬅️)) cur.x-=1
		if(btnp(➡️)) cur.x+=1
	end
end

function _draw()
	cls()
	camera(camx,camy)
	map(0,0,flr(camx/8),flr(camy/8),
	flr(camx/8)+camw,
	flr(camy/8)+camh)
	
	
	if(in_battle) then
		foreach(units,draw_unit)
		if(active_men) active_men.draw(active_men)
		if(cur) spr(5,cur.x*8,cur.y*8)
		line(camx,camy+111,camx+128,camy+111,7)
		if(act_un and show_stats) then
			if(not act_un.enemy) then
				draw_stats(act_un,true,true,true)
			else
				draw_stats(act_un,true,false,false)
				print(pack_string(action_announce,20),44,113)
			end
		end
		
	end
	foreach(effects,draw_effect)
	print(stat(7),0,0)
end
-->8
--units

function standard_death(u)
	u.alive=false
	u.k=18
	update_nav()
end


function make_unit(name,k,hp,def,atk,sp,ma,wp,aff,brain)
	st={
		name=name,
		k=k,
		["hp"]=hp,
		["maxhp"]=hp,
		["def"]=def,
		["atk"]=atk,
		["spd"]=sp,
		["ma"]=ma,
		["maxma"]=ma,
		res={0,0,0},
		typ=aff,
		spells={},
		enemy=false,
		move_cost=1,
		die=standard_death,
		weapon=wp, --0 sword, 1 spear, 2 axe, 3 bow
		aff=aff,
		brain=brain
	}
	return st
end

function init_units()
	anya=make_unit("anya",2,30,5,20,8,25,"fireball",1)
	rachel=make_unit("rachel",1,40,12,15,8,10,"sword",1)

	goblin=make_unit("goblin",17,12,5,15,4,0,"sword",1,default_brain)
	goblin.enemy=true
	goblin.spells={"sword"}
end


function place_unit(x,y,stats)
	local unit= {
		x=x,
		y=y,
		k=stats.k,
		name=stats.name,
		stats=clone(stats),
		modifiers=clone(stats,1),
		buffs={},
		weapon=stats.weapon,
		enemy=stats.enemy,
		alive=true,
		nav=navgrid(x,y,slds),
		ap=0,
		move_cost=stats.move_cost
	}
	add(units,unit)
end

function get_stat(unit,keyword)
	return unit.stats[keyword] * unit.modifiers[keyword]
end

function change_stat(unit,key,change)
	unit.stats[key] += change
	if(get_stat(unit,"hp") <= 0) then
		unit.stats.die(unit)
	end
end







-->8
--abilities
effects={}

function create_atkeff(x,y,k)
	add(effects,{x=x,y=y,k=k})
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
		--act_un.nav=navgrid(act_un.x,act_un.y,slds)
		update_nav()
	end
end

function deal_dmg(trgt,atkr,dmg,typ)
	dmg -= get_stat(trgt,"def")/2
	dmg -= dmg*trgt.stats.res[typ]
	if(typ==0 and trgt.stats.typ==0) dmg *= 0.75
	if(typ==1 and trgt.stats.typ==2) dmg *= 0.75
	if(typ==2 and trgt.stats.typ==1) dmg *= 0.75
	dmg=max(1,dmg)
	change_stat(trgt,"hp",-round(dmg))
end


function basic_attack(user,coord,attack,aoeslave)
	if(not aoeslave and attack.aoe) then
		get_range(coord.x,coord.y,attack.aoe,attack.aoelos)
			for v = 1,#valid_tiles do
				basic_attack(user,valid_tiles[v],attack,true)
			end
		return
	end
	
	target=check_unit(coord.x,coord.y)
	if(target) then
		if(target.stats) then
			deal_dmg(target,user,attack.dmg*get_stat(user,"atk"),attack.typ)
		end
	end
	create_atkeff(coord.x,coord.y,attack.eff)
	

	
end



atks ={
["sword"] = {
	name="sword",
	dmg=0.45,
	crit=10,
	rng=2,
	ap=3,
	uselos=true,
	atk=basic_attack,
	typ=1, --1 = phyiscal, 2=light, 3=dark
	aoe=nil,
	trgtd=true,
	ma=0,
	eff=7
},
["fireball"] = {
	name="fireball",
	dmg=0.5,
	crit=5,
	rng=5,
	ap=5,
	uselos=true,
	atk=basic_attack,
	typ=2,
	aoe=2,
	trgtd=true,
	ma=5,
	aoelos=true,
	eff=23
}
}
-->8
--turn logic


function next_turn()
	menus={}
	turn+=1
	path={}
	if(turn > #units) turn=1
	act_un=units[turn]
	act_un.ap=get_stat(act_un,"spd")
	if(not act_un.enemy) then
		make_menu(2,77,24,32,nil,{"move","attack","guard","rest"},nil,b_menu,nil,true)
		cur={x=act_un.x,y=act_un.y}
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
			cpy[i]=v
		end
		i,v=next(to_copy,i)
	end
	return cpy
end

function navgrid(sx,sy,flgs,mx)
	stack={{x=sx,y=sy,c=0}}
	local pos=1
	local sol = false
	while pos <= #stack do
		crd=stack[pos]
		n=crd.c+1
		for x=crd.x-1,crd.x+1 do
			for y=crd.y-1,crd.y+1 do
				a={x=x,y=y,c=n}
				if(not stack_has(stack,a) and in_battle(a) and not has_flag(a,flgs) and not check_unit(a.x,a.y)) then

							if(not mx or n < mx) add(stack,a)
					end
				end
		end
		if(en) then
			if(crd.x==tx and crd.y==tx) then
				return stack
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
	if(not alive) alive=true
	for u =1,#units do
		un=units[u]
		if(un.x==x and un.y==y and un != ignore and un.alive==alive) then
			return un
		end
	end
	return nil
end

function update_nav()
	foreach(units,function(u) 
		if(u.alive) u.nav=navgrid(u.x,u.y,slds,get_stat(u,"spd"))
	end)
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

function adjacent(x,y,nav)
	local b=nil
	for xx=x-1,x+1 do
		for yy=y-1,y+1 do
			local crd={x=xx,y=yy}
			local c = stack_has(nav,crd)
			if(in_battle(crd) and not check_unit(xx,yy) and c) then
				if(b == nil or c.c < b.c) b=c
			end
		end
	end
	return b
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
	if(flgs==nil) return false
	s=mget(crd.x,crd.y)
	
	for f=1,#flgs do
		if(fget(s,flgs[f])) return true
	end
	return false
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
function find_closest(x,y,enemy)
	local closest=nil
	local d=nil
	for i=1,#actors do
		local a = actors[i]
		if(a.enemy==enemy and (a.x != x or a.y != y)) then
			if(closest) then
				if(dist(a.x,a.y,x,y) < d) then 
					closest=a
				end
			end
			else
				closest=a
				d=dist(a.x,a.y,x,y)
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

		if(a.enemy == enemy and cel) then
			if(cel.c > 0) then
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
	for i =1,#s,l do
		r = r .. sub(s,i,i+l) .. "\n"
	end
	return r
end

function get_range(cx,cy,r,uselos)
	valid_tiles={}
	for x=cx-r,cx+r do
		for y=cy-r,cy+r do
			if(in_battle({x=x,y=y})) then
			if(dist({x=cx,y=cy},{x=x,y=y}) < r) then
				d=true
				if((uselos)) then
					d= los(cx,cy,x,y)
				end
				if(d) add(valid_tiles,{x=x,y=y})
			end
			end
		end
	end
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
	offset=0
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



function draw_unit(u) 
	spr(u.k,u.x*8,u.y*8)
	if(u.stat_disp) spr(u.stat_disp,u.x*8,u.y*8)
end

function print_just(t,x,y,c)
	print(t,x-(#t*2),y-4,c)
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
	spr(e.k,e.x*8,e.y*8)
	e.k+=0.1
	if(fget(flr(e.k)-1,1)) del(effects,e)
end

function draw_range()
	foreach(valid_tiles,function(a) spr(6,a.x*8,a.y*8) end)
end

function draw_stats(u,namehp,atkdef,spdma) 
	if(namehp) print(u.name.."\nhp:"..get_stat(u,"hp").."/"..get_stat(u,"maxhp"), camx,camy+113,7)
	if(atkdef) print("atk:"..get_stat(u,"atk").."\ndef:"..get_stat(u,"def"),camx+44,camy+113)
	if(spdma) print("spd:"..u.ap.."/"..get_stat(u,"spd").."\nma:"..get_stat(u,"ma").."/"..get_stat(u,"maxma"),camx+77,camy+113)
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

function b_menu(s)
	if(s==1) then --move selection
		make_menu(-4,-4,0,0,nil,nil,move_menu,nil,mm_draw)
	elseif(s==2) then -- attack menu
		make_menu(2,77,64,32,nil,{act_un.weapon.."("..atks[act_un.weapon].ap..")"},nil,atk_slct)
	elseif(s==3) then -- guard menu
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
	atkdata=nil
	if(s==1) then
		atkdata=atks[act_un.weapon]
	end
	if(atkdata==nil) return
	if(atkdata.ap > act_un.ap) then
		make_menu(32,64,64,16,"not enough ap!")
		return
	elseif(atkdata.ma > get_stat(act_un,"ma")) then
		make_menu(32,64,64,16,"not enough mana!")
		return
	elseif(atkdata.trgtd) then
		get_range(act_un.x,act_un.y,atkdata.rng,atkdata.uselos)
		make_menu(0,0,0,0,nil,nil,target_update,nil,target_draw)
	end
	
end

function move_menu(m)
	if(not moving and path_regen()) path=find_path(cur,act_un.nav)
	if(btnp(❎) and #path > 1) moving=true
	if(btnp(🅾️) and not moving) del(menus,m)
end

function mm_draw(m)
	local r = act_un.ap/act_un.move_cost
	draw_path(path,r)
	show_stats=false
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
	if(btn()) trgt=check_unit(cur.x,cur.y)
	if(btnp(❎) and stack_has(valid_tiles,{x=cur.x,y=cur.y})) then
		atkdata.atk(act_un,cur,atkdata)
		act_un.ap-=atkdata.ap
		change_stat(act_un,"ma",-atkdata.ma)
		del(menus,m)
	elseif(btnp(🅾️)) then 
		del(menus,m)
	end
end

function target_draw(m)
	show_stats=false
	draw_range()
	print("❎ confirm\n🅾️ cancel",camx+77,camy+113)
	if(trgt) then
		draw_stats(trgt,true)
	 --print(trgt.name.."\nhp:"..get_stat(trgt,"hp").."/"..get_stat(trgt,"maxhp"),camx,camy+113)
		--print("def:"..get_stat(trgt,"def"),camx+44,camy+119)
	end
end
-->8
--brains
action_time=60 --how many frames to wait after performing an action

action_announce=""



function default_brain(u)
	if(moving) return

	if(not u.alive) then 
		next_turn()
		return
	end
	if(movetimer!=0) then
		movetimer-=1
		return
	else
		action_announce=""
	end
	
	target=nil
	
	for i=1,#u.stats.spells do
		atkdata=atks[u.stats.spells[i]]
		if(atkdata.ap <= u.ap) then
			get_range(u.x,u.y,atkdata.rng,atkdata.uselos)
			for v=1,#valid_tiles do
				local val=valid_tiles[v]
				local t=check_unit(val.x,val.y,u)
				if(t) then
					if(t.enemy != u.enemy) then
						target=t
						break					
					end 
				end
			end
			if(target) break
		end
	end
	
	if(target) then
		atkdata.atk(u,target,atkdata)
		u.ap -= atkdata.ap
		movetimer=action_time
		action_announce=u.name.." used "..atkdata.name.." on "..target.name
		return
	elseif(u.ap >= u.stats.move_cost) then
		target=find_shortest(u.nav,not u.enemy)
		if(target and not moving) then	
			if(dist(u,target) > 2) then		
				dest=adjacent(target.x,target.y,u.nav)
				path=find_path(dest,u.nav)
				draw_path(path)
				if(#path > 1) then
					moving=true
					return
				end
			end
		end
	end
	next_turn()
	
end
__gfx__
00000000000aa00000088000bbbbbbbb66666666aaaaaaaa88888888000000000000001000000000000000000000000000000000000000000000000000000000
0000000000affa000088f800bbbbbbbb66666666a000000a80000008000000000000611000000660000000000000000000000000000000000000000000000000
00700700000ffa00008ff800bbbbbbbb66666666a000000a80000008000000000006610000006600000000000000000000000000000000000000000000000000
00077000004444a008666680bbbbbbbb66666666a000000a80000008000100000066100000001000000000000000000000000000000000000000000000000000
0007700000f55fa008f11f80bbbbbbbb66666666a000000a80000008001100000061000000000000000000000000000000000000000000000000000000000000
007007000004400000055000bbbbbbbb66666666a000000a80000008011000000010000000000000000000000000000000000000000000000000000000000000
0000000000f00f0000600600bbbbbbbb66666666a000000a80000008010000000010000000000000000000000000000000000000000000000000000000000000
000000000440040000500500bbbbbbbb66666666aaaaaaaa88888888000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000099990000999900000000000000000000000000000000000000000000000000
00000000000330000008007000000000000000000000000000000000000000000097790009777790000000000000000000000000000000000000000000000000
00000000000330000078870000000000000000000000000000000000000990000978889097888879000000000000000000000000000000000000000000000000
00000000004444000887880000000000000000000000000000000000009889000988879097888879000000000000000000000000000000000000000000000000
00000000003943000088788000000000000000000000000000000000009889000988879097888879000000000000000000000000000000000000000000000000
00000000003493000078878800000000000000000000000000000000000990000988889097888879000000000000000000000000000000000000000000000000
00000000000330000780000000000000000000000000000000000000000000000097890009777790000000000000000000000000000000000000000000000000
00000000003003000000000000000000000000000000000000000000000000000099990000999900000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030000000000000
__label__
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbabbbbbbabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbabbbbbbabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbabbbbbbabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbabbbbbbabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbabbbbbbabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbabbbbbbabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbb88bbbbbbbbbbb6666666666666666666666666666666666666666bbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbb88f8bbbbbbbbbb6666666666666666666666666666666666666666bbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbb8ff8bbbbbbbbbb6666666666666666666666666666666666666666bbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbb866668bbbbbbbbb6666666666666666666666666666666666666666bbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbb8f11f8bbbbbbbbb6666666666666666666666666666666666666666bbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbb55bbbbbbbbbbb6666666666666666666666666666666666666666bbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbb6bb6bbbbbbbbbb6666666666666666666666666666666666666666bbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbb5bb5bbbbbbbbbb6666666666666666666666666666666666666666bbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
66666666bbbbbbbb6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666bbbbbbbb6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666bbbbbbbb6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666bbbbbbbb6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666bbbbbbbb6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666bbbbbbbb6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666bbbbbbbb6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666bbbbbbbb6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
bbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666666666666666666666666666bbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666666666666666666666666666bbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666666666666666666666666666bbbbbbbbbbbbbbbbbbbbbbbb
77777777777777777777777777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666666666666666666666666666bbbbbbbbbbbbbbbbbbbbbbbb
70000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666666666666666666666666666bbbbbbbbbbbbbbbbbbbbbbbb
70000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666666666666666666666666666bbbbbbbbbbbbbbbbbbbbbbbb
70000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666666666666666666666666666bbbbbbbbbbbbbbbbbbbbbbbb
700000bbb00bb0b0b0bbb00000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666666666666666666666666666bbbbbbbbbbbbbbbbbbbbbbbb
700000bbb0b0b0b0b0b0000000007bbbbbbbbbbb666666666666666666666666666666666666666666666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
700000b0b0b0b0b0b0bb000000007bbbbbbbbbbb666666666666666666666666666666666666666666666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
700000b0b0b0b0bbb0b0000000007bbbbbbbbbbb666666666666666666666666666666666666666666666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
700000b0b0bb000b00bbb00000007bbbbbbbbbbb666666666666666666666666666666666666666666666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
70000000000000000000000000007bbbbbbbbbbb666666666666666666666666666666666666666666666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
70000000000000000000000000007bbbbbbbbbbb666666666666666666666666666666666666666666666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
70000000000000000000000000007bbbbbbbbbbb666666666666666666666666666666666666666666666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
70777077707770777007707070007bbbbbbbbbbb666666666666666666666666666666666666666666666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
70707007000700707070007070007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
70777007000700777070007700007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
70707007000700707070007070007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
70707007000700707007707070007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
70000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
70000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
70000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
70000770707077707770770000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
70007000707070707070707000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
70007000707077707700707000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
70007070707070707070707000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
70007770077070707070777000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb4444bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
70000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3943bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
70000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3493bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
70000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
70000077707770077077700000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
70000070707000700007000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
70000077007700777007000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
70000070707000007007000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
70000070707770770007000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
70000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
70000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
70000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77707700707077700000000000000000000000000000777077707070000077707770000000000077077707700000077707770007077007770777000000000000
70707070707070700000000000000000000000000000707007007070070000707000000000000700070707070070070707070070007007070707000000000000
77707070777077700000000000000000000000000000777007007700000007707770000000000777077707070000077707770070007007070707000000000000
70707070007070700000000000000000000000000000707007007070070000700070000000000007070007070070000707070070007007070707000000000000
70707070777070700000000000000000000000000000707007007070000077707770000000000770070007770000000707770700077707770777000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70707770000077707770007077707770000000000000770077707770000077007770000000000777077700000770077700070770077700000000000000000000
70707070070070007070070070007070000000000000707070007000070007007070000000000777070700700070070000700070070000000000000000000000
77707770000077707070070077707070000000000000707077007700000007007070000000000707077700000070077700700070077700000000000000000000
70707000070000707070070000707070000000000000707070007000070007007070000000000707070700700070000700700070000700000000000000000000
70707000000077707770700077707770000000000000777077707000000077707770000000000707070700000777077707000777077700000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000001000000000200000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
a101000000250112501425016250182501a2501d2501f250212500020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200
01100000180501b0501f0501b0501f050220502405000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000c0500f050130500f0501305016050180550c0550c0550c0550c0550c0000b0000b0000b0000b000130001300013000130000e0000e0000e0000e0000000000000000000000000000000000000000000
001018000c0550c0550c0550a0550a0550a0550805508055080550705507055070550505505055050550705507055070550805508055080550505505055050550c0000c0000c0001600016000160000000000000
001000181801018010180201802018030180301804018040180501805018060180601806018060180601a0701a0701a0701b0701b0701b0701d0701d0701d0701f0001f0001f0001800018000180001800018000
000f00001f0501f0501f0501f0501f0501f0501805018050180501805018050180500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001f0501f0501f0501805018050180500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 01024344
01 04034544
01 06034344

