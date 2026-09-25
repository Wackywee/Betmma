--- STEAMODDED HEADER
--- MOD_NAME: Betmma Vouchers
--- MOD_ID: BetmmaVouchers
--- MOD_AUTHOR: [Betmma]
--- MOD_DESCRIPTION: 58 Vouchers and 24 Fusion Vouchers! v3.0.2.3
--- PREFIX: betm_vouchers
--- VERSION: 3.0.2.3(20250519)
--- BADGE_COLOUR: ED40BF
--- PRIORITY: -1

----------------------------------------------
------------MOD CODE -------------------------

-- acknowledgements:

-- thanks to Denverplays2, RenSixx, KEKC, Zahrizi, Sameone and other discord users for their ideas
-- thanks to ChromaPIE and BaiMao for zh_CN translation


-- ideas:
-- peek the first card in packs (impractical?) / skipped packs get 50% refund (someone's joker has done it)
-- Global Interpreter Lock: set all jokers to eternal / not eternal, once per round (more like an ability that is used manually)
-- suspended process: if this ability is on, round won't end until you run out of hands
-- sold jokers become a tag that replaces the next joker appearing in shop (also an ability)
-- complete a quest to get a soul
-- fusion vouchers:
-- Forbidden Word: Fusion voucher and joker may appear in the store.  Forbidden magic: Purchased fusion Joker and voucher give things related to their fusion
-- Randomize Lucky Card effects (+Chip, Mult, xMult, money, copy first card played, generate consumable, generate joker (oops all 6 maybe), comsumable slot, joker slot, random tag, enhance jokers, enhance cards, retrigger ...)
-- (upgraded of above) if probabilities in lucky card, that is written as A in B, satisfies A>B, this can trigger more than 1 time
-- Overstock + Reroll Surplus could make it so that whenever you buy something, it's automatically replaced with a card of the same type
-- enhancements can stack
-- give $1 per 10 cards left when round ends
-- Grand Finale: if no cards left when round ends, gives $10
-- money grabber + gold coin :
--[[
get_end_of_round_effect
]]
--sendDebugMessage(tprint(table))
function pprint(x)
    if type(x)=='table' then
        sendDebugMessage(tprint(x))
    else
        print(x)
    end
end

IN_SMOD1=MODDED_VERSION>='1.0.0'
local JOKER_MOD_PREFIX=IN_SMOD1 and "betm_jokers_"or ''
MOD_PREFIX=IN_SMOD1 and 'betm_vouchers_' or ''
MOD_PREFIX_V='v_'..MOD_PREFIX
MOD_PREFIX_V_LEN=string.len(MOD_PREFIX_V)
USING_BETMMA_VOUCHERS=true

-- Config: You can disable unwanted vouchers and my other mods in AppData/Roaming/Balatro/config/BetmmaVouchers.jkr. The config below is a default one if such .jkr doesn't exist, and .jkr is automatically created in such case.
betmma_config=SMODS.load_mod_config and SMODS.load_mod_config{id='BetmmaVouchers'}or{}
if #betmma_config==0 then
    if not IN_SMOD1 then
        print('config file isn\'t available in SMOD<1')
    else
        print('betmma config not found')
    end
end
betmma_config_vouchers = {
    -- normal vouchers
    v_oversupply=true,
    v_oversupply_plus=true,
    v_gold_coin=true,
    v_gold_bar=true,
    v_abstract_art=true,
    v_mondrian=true,
    v_round_up=true,
    v_round_up_plus=true,
    v_reserve_area=true,
    v_reserve_area_plus=true,
    v_3d_boosters=true,
    v_4d_boosters=true,
    v_flipped_card=true,
    v_double_flipped_card=true,
    v_bonus_plus=true,
    v_mult_plus=true,
    v_omnicard=true,
    v_bulletproof=true,
    v_eternity=true,
    v_half_life=true,
    v_debt_burden=true,
    v_bobby_pin=true,
    v_bargain_aisle=true,
    v_clearance_aisle=true,
    v_rich_boss=true,
    v_richer_boss=true,
    v_gravity_assist=true,
    v_gravitational_wave=true,
    v_echo_wall=true,
    v_echo_chamber=true,

    -- fusion vouchers
    v_reroll_cut=true,
    v_slate=true,
    v_recycle_area=true,
}
if betmma_config.vouchers==nil then
    betmma_config.vouchers=betmma_config_vouchers
end
for k,v in pairs(betmma_config_vouchers) do
    if betmma_config.vouchers[k]==nil then
        betmma_config.vouchers[k]=v
    end
end
if betmma_config.jokers==nil then
    betmma_config.jokers=true
end
if betmma_config.abilities==nil then
    betmma_config.abilities=true
end
if betmma_config.spells==nil then
    betmma_config.spells=true
end
if betmma_config.enable_voucher_rarity==nil then
    betmma_config.enable_voucher_rarity=true
end
SMODS.current_mod.config=betmma_config
SMODS.save_mod_config(SMODS.current_mod)
if not IN_SMOD1 then
    betmma_config.vouchers.v_undying=false
    betmma_config.vouchers.v_reincarnate=false
    betmma_config.vouchers.v_voucher_tycoon=false
    betmma_config.vouchers.v_cryptozoology=false
end

-- example: if used_voucher('slate') then ... end 
-- setting it to global is for lovely patches
function used_voucher(raw_key)
    return G.GAME.used_vouchers[MOD_PREFIX_V..raw_key]
end
-- example: get_voucher('slate').config.extra
function get_voucher(raw_key)
    return G.P_CENTERS[MOD_PREFIX_V..raw_key]
end

function normalize_rarity(rarity)
    if not rarity then return 1 end
    return math.max(1,math.min(math.ceil(rarity),#RARITY_VOUCHER_PROBABILITY))
end
local function get_rarity(key)
    local card= G.P_CENTERS[key]
    return card and card.config and normalize_rarity(card.config.rarity) or 1
end -- input: raw_key like v_betm_vouchers_abstract_art
function get_rarity_card(card)
    return card and card.config and normalize_rarity(card.config.rarity) or 1
end -- input: a card object (equal to G.P_CENTERS[key])

-- example: handle_atlas('slate') loads 'v_slate.png' and assign it
local function handle_atlas(raw_key,this_v)
    if IN_SMOD1 then
        local key='v_'..raw_key
        SMODS.Atlas{key=key, path=key..".png", px=71, py=95}
        key = MOD_PREFIX .. key
        this_v.atlas=key
    else
        local id=raw_key
        SMODS.Sprite:new("v_"..id, SMODS.findModByID("BetmmaVouchers").path, "v_"..id..".png", 71, 95, "asset_atli"):register()
    end
end

-- register card if in SMOD 0.9.8
local function handle_register(this_v)
    if not IN_SMOD1 then
        this_v:register()
    end
end

local fusion_voucher_weight=4
-- set default weight of fusion vouchers to 4
if IN_SMOD1 then
    local SMODS_Center_inject=SMODS.Center.inject
    SMODS.Center.inject =function(self)
        -- print(SMODS.current_mod+"....."+self.set)
        if self.key:find(MOD_PREFIX_V) and self.set=='Voucher'then
            if not betmma_config.vouchers['v_'..self.key:sub(MOD_PREFIX_V_LEN+1,-1)] then return false end
            self.mod_name='Betmma Vouchers'
            if self.requires and #self.requires>1 and not self.config.weight then 
                self.config.weight=fusion_voucher_weight
            end
        end
        SMODS_Center_inject(self)
    end
else
    local SMODS_Voucher_register=SMODS.Voucher.register
    function SMODS.Voucher:register()
        if SMODS._MOD_NAME=='Betmma Vouchers' then
            if not betmma_config.vouchers[self.slug] then return false end
            if self.loc_vars then
                self.loc_def=function(self2)
                    local loc_vars=self.loc_vars
                    return self.loc_vars(self2,nil,{ability=self2.config}).vars
                end
            end
            if self.requires and #self.requires>1 then 
                self.config.weight=fusion_voucher_weight
            end
        end
        SMODS_Voucher_register(self)
    end
end

SMODS_Voucher_ref=SMODS.Voucher -- 0.9.8 compat thing
SMODS_Voucher_fake=function(table)
    if IN_SMOD1 then
        return SMODS_Voucher_ref(table)
    else
        local this_v= SMODS_Voucher_ref:new(table.name,table.key,
        table.config,
        table.pos,table.loc_txt,
        table.cost,table.unlocked,table.discovered,table.available,
        table.requires)
        this_v.rarity=table.rarity
        return this_v
    end
end

real_random_data={}
betmma_extra_data={}
SMODS.current_mod=SMODS.current_mod or {}
function SMODS.current_mod.process_loc_text()
    G.localization.misc.dictionary["k_fusion_voucher"] = "Fusion Voucher"
    G.localization.misc.challenge_names.c_mod_testvoucher = "TestVoucher"
    G.localization.misc.dictionary.b_reserve = "RESERVE"
    G.localization.misc.dictionary.k_transfer_ability = "Transfer!"
    G.localization.misc.dictionary.b_flip_hand = "Flip"
    G.localization.misc.dictionary.k_bulletproof = "Bulletproof!"
    G.localization.misc.dictionary.over_retriggered = "Over-retriggered: "
    for k,v in pairs(real_random_data) do
        G.localization.descriptions.Enhanced['real_random_'..k] =v 
    end
    G.localization.descriptions.Enhanced.ellipsis={text={'{C:inactive}(#1# abilities omitted)'}}
    G.localization.descriptions.Enhanced.multiples={text={'{C:inactive}(X#1#)'}}
    -- borrowed from SDM0
    G.localization.descriptions.Other.perishable_no_debuff = {
        name = "Perishable",
        text = {
            "Debuffed after",
            "{C:attention}#1#{} rounds"
        }
    }
    for k, v in pairs(betmma_extra_data) do
        for k2, v2 in pairs(v) do
            G.localization.misc[k][k2]=v2
        end
    end
end

local usingTalisman = function() return SMODS.Mods and SMODS.Mods["Talisman"] and Big and Talisman.config_file.break_infinity or false end
local usingCryptid=SMODS.Mods and SMODS.Mods["Cryptid"] or false

function TalismanCompat(num)
    local using=usingTalisman()
    if not using then return num end
    if using=='omeganum'then
        return to_big(num)
    end
    if (using==true or using=='bignumber')then
        return to_big(num)
    end
	return num
end

local function get_plain_text_from_localize(final_line)
    local ret=''
    for k,v in pairs(final_line) do
        local config=v.config
        if config.text then ret=ret..config.text..''
        elseif v.nodes then ret=ret..v.nodes[1].config.text..''
        else ret=ret..config.object.config.string[1]..''
        end
    end
    return ret
end

-- return index of obj in array. If not found return -1.
local function get_index_in_array(array,obj)
    local index=1
    while array[index]~=obj and index<=#array do
        index=index+1
    end
    if index<=#array then
        return index
    end
    return -1
end

do -- randomly create card function series
    function randomly_redeem_voucher(no_random_please) -- xD
        -- local voucher_key = time==0 and "v_voucher_bulk" or get_next_voucher_key(true)
        -- time=1
        local area
        if G.STATE == G.STATES.HAND_PLAYED then
            if not G.redeemed_vouchers_during_hand then
                -- may need repositioning
                G.redeemed_vouchers_during_hand = CardArea(
                    G.play.T.x, G.play.T.y, G.play.T.w, G.play.T.h, 
                    {type = 'play', card_limit = 5})
            end
            area = G.redeemed_vouchers_during_hand
        else
            area = G.play
        end
        local voucher_key = no_random_please or get_next_voucher_key(true)
        local card = Card(area.T.x + area.T.w/2 - G.CARD_W/2,
        area.T.y + area.T.h/2-G.CARD_H/2, G.CARD_W, G.CARD_H, G.P_CARDS.empty, G.P_CENTERS[voucher_key],{bypass_discovery_center = true, bypass_discovery_ui = true})
        card:start_materialize()
        area:emplace(card)
        card.cost=0
        card.shop_voucher=false
        local current_round_voucher=G.GAME.current_round.voucher
        card:redeem()
        G.GAME.current_round.voucher=current_round_voucher -- keep the shop voucher unchanged since the voucher bulk may be from voucher pack or other non-shop source
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            --blockable = false,
            --blocking = false,
            delay =  0,
            func = function() 
                card:start_dissolve()
                return true
            end}))   
    end
    function randomly_create_joker(jokers_to_create,tag,message,extra)
        extra=extra or {}
        G.GAME.joker_buffer = G.GAME.joker_buffer + jokers_to_create
        G.E_MANAGER:add_event(Event({
            func = function() 
                for i = 1, jokers_to_create do
                    local card = create_card('Joker', G.jokers, nil, 0, nil, nil, nil, tag)
                    card:add_to_deck()
                    if extra.edition~=nil then
                        card:set_edition(extra.edition,true,false)
                    end
                    G.jokers:emplace(card)
                    card:start_materialize()
                    G.GAME.joker_buffer = 0
                
                    if message~=nil then
                        card_eval_status_text(card,'jokers',nil,nil,nil,{message=message})
                    end
                end
                return true
            end}))   
    end
    function randomly_create_consumable(card_type,tag,message,extra)
        extra=extra or {}
        
        if #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit or extra and extra.edition and extra.edition.negative then
            G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
            G.E_MANAGER:add_event(Event({
                trigger = 'before',
                delay = 0.0,
                func = (function()
                        local card = create_card(card_type,G.consumeables, nil, nil, nil, nil, extra.forced_key or nil, tag)
                        card:add_to_deck()
                        if extra.edition~=nil then
                            card:set_edition(extra.edition,true,false)
                        end
                        if extra.eternal~=nil then
                            card.ability.eternal=extra.eternal
                        end
                        if extra.perishable~=nil then
                            card.ability.perishable = extra.perishable
                            card.ability.perish_tally = G.GAME.perishable_rounds
                        end
                        if extra.extra_ability~=nil then
                            card.ability[extra.extra_ability]=true
                        end
                        card.ability.BetmmaVouchers=true
                        -- G.jokers:emplace(card)
                        G.consumeables:emplace(card)
                        G.GAME.consumeable_buffer = 0
                        if message~=nil then
                            card_eval_status_text(card,'extra',nil,nil,nil,{message=message})
                        end
                    return true
                end)}))
        end
    end
    function randomly_create_spectral(tag,message,extra)
        return randomly_create_consumable('Spectral',tag,message,extra)
    end
    function randomly_create_tarot(tag,message,extra)
        return randomly_create_consumable('Tarot',tag,message,extra)
    end
    function randomly_create_planet(tag,message,extra)
        return randomly_create_consumable('Planet',tag,message,extra)
    end
end

local ability_names={'mult','h_mult','h_x_mult','h_dollars','p_dollars','t_mult','t_chips','h_size','d_size','bonus'}
-- for cards whose ability is changed, load ability values to config.center so that these can be displayed in hover ui. Note that after doing this config.center is no longer the same in G.P_CENTERS so this function should be used as little as possible
-- the reverse verion of the function above
-- return (a or default_value)+(b or default_value)
local function safe_add(a,b,default_value)
    return (a or default_value)+(b or default_value)
end


-- I don't know why there are so many reports about housing choice causing get_straight and get_X_same such function to crash, it seems that some card's rank becomes nil and someone has guessed about voucher created has no rank but created card won't come into played hands. Anyway I should try this
    local Card_get_id_ref=Card.get_id
    function Card:get_id()
        local ret=Card_get_id_ref(self)
        return ret or -math.random(100,1000000)
    end

function GET_PATH_COMPAT()
    return IN_SMOD1 and SMODS.current_mod.path or SMODS.findModByID('BetmmaVouchers').path
end

local function INIT()
    local PATH=GET_PATH_COMPAT()
    
    -- NFS.load(PATH .. 'Betmma_Abilities.lua')

--- deal with enhances effect changes when saving & loading
do
    local enhanced_prototype_centers = {}

    function setup_consumables()
        -- Save vanilla enhanced centers
        enhanced_prototype_centers.m_bonus = G.P_CENTERS.m_bonus.config.bonus
        enhanced_prototype_centers.m_mult = G.P_CENTERS.m_mult.config.mult
        enhanced_prototype_centers.m_glass = G.P_CENTERS.m_glass.config.Xmult
        enhanced_prototype_centers.m_steel = G.P_CENTERS.m_steel.config.h_x_mult
        enhanced_prototype_centers.m_stone = G.P_CENTERS.m_stone.config.bonus
        enhanced_prototype_centers.m_gold = G.P_CENTERS.m_gold.config.h_dollars
    end


    -- Restore vanilla enhancements
    local Game_delete_run_ref = Game.delete_run
    function Game.delete_run(self)

        G.P_CENTERS.m_bonus.config.bonus = enhanced_prototype_centers.m_bonus
        G.P_CENTERS.m_mult.config.mult = enhanced_prototype_centers.m_mult
        G.P_CENTERS.m_glass.config.Xmult = enhanced_prototype_centers.m_glass
        G.P_CENTERS.m_steel.config.h_x_mult = enhanced_prototype_centers.m_steel
        G.P_CENTERS.m_stone.config.bonus = enhanced_prototype_centers.m_stone
        G.P_CENTERS.m_gold.config.h_dollars = enhanced_prototype_centers.m_gold


        Game_delete_run_ref(self)
    end

    -- Restore enhanced cards effect changes
    local Game_start_run_ref = Game.start_run
    function Game.start_run(self, args)
        G.GAME.voucher_rate=(G.GAME.voucher_rate or 0)

        G.P_CENTERS.m_bonus.config.bonus = enhanced_prototype_centers.m_bonus
        G.P_CENTERS.m_mult.config.mult = enhanced_prototype_centers.m_mult
        G.P_CENTERS.m_glass.config.Xmult = enhanced_prototype_centers.m_glass
        G.P_CENTERS.m_steel.config.h_x_mult = enhanced_prototype_centers.m_steel
        G.P_CENTERS.m_stone.config.bonus = enhanced_prototype_centers.m_stone
        G.P_CENTERS.m_gold.config.h_dollars = enhanced_prototype_centers.m_gold

        Game_start_run_ref(self, args)

        local saveTable = args and args.savetext or nil
        if saveTable then
            if used_voucher('bonus_plus') then
                G.P_CENTERS.m_bonus.config.bonus=G.P_CENTERS.m_bonus.config.bonus+get_voucher('bonus_plus').config.extra
            end
            if used_voucher('mult_plus') then
                G.P_CENTERS.m_mult.config.mult=G.P_CENTERS.m_mult.config.mult+get_voucher('mult_plus').config.extra
            end
            if used_voucher('slate') then
                G.P_CENTERS.m_stone.config.bonus=G.P_CENTERS.m_stone.config.bonus+get_voucher('slate').config.extra
            end
        end
    end
end --


local function get_weight(v)
    local _type=type(v)

    if _type~='table' and _type~='string' then return 1 end
    -- if _type=='table' and v.name == "Ace of Spades"then return 9999 end
    if _type=='string' then
        if G.P_CENTERS[v] then
            v=G.P_CENTERS[v]
        end
    end
    if betmma_config.enable_voucher_rarity then
        if v.weight then return v.weight end
        if v.config and v.config.weight then return v.config.weight end
    end
    return 1
end

local function pseudorandom_element_weighted(_t, seed)
    if seed then math.randomseed(seed) end
    -- local keys = {}
    -- for k, v in pairs(_t) do
    --     keys[#keys+1] = {k = k,v = v}
    -- end
  
    -- if keys[1] and keys[1].v and type(keys[1].v) == 'table' and keys[1].v.sort_id then
    --   table.sort(keys, function (a, b) return a.v.sort_id < b.v.sort_id end)
    -- else
    --   table.sort(keys, function (a, b) return a.k < b.k end)
    -- end
    local _type
    local cume, it, center, center_key = 0, 0, nil, nil
    for k, v in pairs(_t) do
        _type=type(v)
        if (_type~='table') or (not G.GAME.banned_keys[v.key]) then cume = cume + get_weight(v) end
    end
    local poll = pseudorandom(pseudoseed((seed or 'weighted_random')..G.GAME.round_resets.ante))*cume
    
    for k, v in pairs(_t) do
        if (_type~='table') or (not G.GAME.banned_keys[v.key]) then 
            it = it + get_weight(v) 
            if it >= poll and it - get_weight(v) <= poll then center = v; center_key=k; break end
        end
    end
    if center == nil then center.a() end
    return center,center_key
end

    setup_consumables()
    RARITY_VOUCHER_PROBABILITY={1,2,4,20}
    local get_current_pool_ref=get_current_pool
    function get_current_pool(_type, _rarity, _legendary, _append)
        if _type=='Voucher'then _append='lol' end -- MathIsFun will do something to prevent crash with Deck of Equilibrium when _append has value
        local ret={get_current_pool_ref(_type, _rarity, _legendary, _append)}
        if _type=='Voucher' then
            local pool=ret[1]
            local new_pool={}
            local _pool_size=0
            for k,v in pairs(pool) do
                if v~='UNAVAILABLE' then
                    local card= G.P_CENTERS[v]
                    local rarity=card.config and normalize_rarity(card.config.rarity)
                    if (pseudorandom('std_'..v) < 1/RARITY_VOUCHER_PROBABILITY[rarity]) then
                        new_pool[#new_pool+1]=v
                        _pool_size=_pool_size+1
                    end
                else
                    new_pool[#new_pool+1]=v
                end
            end
            if _pool_size == 0 then
                new_pool = EMPTY(G.ARGS.TEMP_POOL)
                new_pool[#new_pool + 1] = "v_blank"
            end
            ret[1]=new_pool
            return unpack(ret)
        end
        return unpack(ret)
    end -- this function adds rarity check 

    local get_current_pool_copy=get_current_pool -- this is because when the following function is called get_current_pool has been replaced to itself
    function get_specific_rarity_vouchers_pool(rarity)
        local pool,pool_key=get_current_pool_ref('Voucher')
        local new_pool={}
        local _pool_size=0
        for k,v in pairs(pool) do
            if v~='UNAVAILABLE' then
                local card_rarity=get_rarity(v)
                if card_rarity==rarity then
                    new_pool[#new_pool+1]=v
                    _pool_size=_pool_size+1
                end
            end
        end
        if _pool_size == 0 then
            return get_current_pool_copy('Voucher')
        end
        return new_pool,pool_key
    end -- this function bypasses rarity check so specific rarity vouchers are guaranteed to be in the pool, but not requirements (e.g. tier 2 needs tier 1)

    local function get_voucher_pool_with_filter_and_reqs(func)
        -- func should take in G.P_CENTERS[key] and return a boolean
        local pool,pool_key=get_current_pool_ref('Voucher')
        local new_pool={}
        local _pool_size=0
        for k,v in pairs(pool) do
            if v~='UNAVAILABLE' then
                local card= G.P_CENTERS[v]
                if func(card) then
                    new_pool[#new_pool+1]=v
                    _pool_size=_pool_size+1
                end
            end
        end
        if _pool_size == 0 then
            return get_current_pool_copy('Voucher')
        end
        return new_pool,pool_key
    end -- this function bypasses rarity check but not requirements (same as above but more flexible since you can input a func)

    function get_voucher_pool_with_filter(func)
        -- func should take in G.P_CENTERS[key] and return a boolean
        local _starting_pool, _pool_key = G.P_CENTER_POOLS['Voucher'], 'Voucher'
        local _pool=EMPTY(G.ARGS.TEMP_POOL)
        local _pool_size=0
        for k, v in ipairs(_starting_pool) do
            if func(v) and not G.GAME.banned_keys[v.key] and not G.GAME.used_vouchers[v.key] then 
                -- don't check for requires
                _pool[#_pool + 1] = v.key
                _pool_size = _pool_size + 1
            end
        end
        if _pool_size == 0 then
            return get_current_pool_copy('Voucher')
        end
        return _pool,_pool_key
    end -- this function bypasses everything except for banned keys and used_vouchers

    get_next_voucher_key_ref=get_next_voucher_key
    function get_next_voucher_key(_from_tag)
        -- local _pool, _pool_key = get_current_pool('Voucher')
        -- this pool contains strings
        local pseudorandom_element_ref=pseudorandom_element
        pseudorandom_element=pseudorandom_element_weighted
        local get_current_pool_ref=get_current_pool
        local ret
        if G.GAME.voucher_pack_name and G.GAME.voucher_pack_name:find('Uncommon') then
            get_current_pool=function(key)
                return get_specific_rarity_vouchers_pool(2)
            end
        elseif G.GAME.voucher_pack_name and G.GAME.voucher_pack_name=='Fusion Voucher Pack' then
            get_current_pool= function(key)
                return get_voucher_pool_with_filter_and_reqs(
                    function(card)
                        return card and card.requires and #card.requires>1
                    end
                )
            end
        end
        ret= get_next_voucher_key_ref(_from_tag)
        
        get_current_pool=get_current_pool_ref
        pseudorandom_element=pseudorandom_element_ref
        return ret
    end


do
    local name="Oversupply"
    local id="oversupply"
    local loc_txt = {
        name = name,
        text = {
            "Gain {C:attention}1{} {C:attention}Voucher Tag{}",
            "after defeating {C:attention}Boss Blind{}"
        }
    }
    --function SMODS.Voucher{name, slug, config, pos, loc_txt, cost, unlocked, discovered, available, requires, atlas)
    local v_oversupply = SMODS.Voucher{
        name=name, key=id,
        config={},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=10, unlocked=true,discovered=true, available=true,
    }
    local this_v=v_oversupply
    handle_atlas(id,this_v)
    this_v.loc_vars = function(self, info_queue, center)
        return {vars={}}
    end
    handle_register(this_v)
    -- SMODS.Sprite:new("v_oversupply", SMODS.findModByID("BetmmaVouchers").path, "v_oversupply.png", 71, 95, "asset_atli"):register();
    -- v_oversupply:register()
    
    local name="Oversupply Plus"
    local id="oversupply_plus"
    local loc_txt = {
        name = name,
        text = {
            "Gain {C:attention}1{} {C:attention}Voucher Tag{}",
            "after defeating each {C:attention}Blind{}"
            -- if you have both, after beating boss blind you gain only 1 voucher tag
        }
    }
    local v_oversupply_plus = SMODS.Voucher{
            name=name, key=id,
            config={},
            pos={x=0,y=0}, loc_txt=loc_txt,
            cost=10, unlocked=true,discovered=true, available=true, requires={MOD_PREFIX_V..'oversupply'}
    }
    local this_v=v_oversupply_plus
    handle_atlas(id,this_v)
    this_v.loc_vars = function(self, info_queue, center)
        return {vars={}}
    end
    handle_register(this_v)
    -- SMODS.Sprite:new("v_oversupply_plus", SMODS.findModByID("BetmmaVouchers").path, "v_oversupply_plus.png", 71, 95, "asset_atli"):register();
    -- v_oversupply_plus:register()
    -- The v.redeem function mentioned in voucher.lua of steamodded 0.9.5 is bugged when the voucher is given at the beginning of the game (such as challenge or some decks), and also it's not capable of making not one-time effects.
    local end_round_ref = end_round
    function end_round()
        if used_voucher('oversupply') and G.GAME.blind:get_type() == 'Boss' or used_voucher('oversupply_plus') then
            add_tag(Tag('tag_voucher'))
        end
        end_round_ref()
    end


end -- oversupply
do 
    local name="Gold Coin"
    local id="gold_coin"
    local loc_txt = {
        name = name,
        text = {
            "Earn {C:money}$#1#{} immediately",
            "{C:attention}Small Blind{} gives",
            "no reward money",
            -- yes it literally does nothing bad after white stake
        }
    }
    --function SMODS.Voucher{name, slug, config, pos, loc_txt, cost, unlocked, discovered, available, requires, atlas)
    local v_gold_coin = SMODS.Voucher{
        name=name, key=id,
        config={extra=11},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=1, unlocked=true, discovered=true, available=true
    }
    local this_v=v_gold_coin
    handle_atlas(id,this_v)
    -- SMODS.Sprite:new("v_"..id, SMODS.findModByID("BetmmaVouchers").path, "v_gold_coin.png", 71, 95, "asset_atli"):register();
    -- v_gold_coin:register()
    v_gold_coin.loc_vars = function(self, info_queue, center)
        return {vars={center.ability.extra}}
    end
    handle_register(this_v)

    
    local name="Gold Bar"
    local id="gold_bar"
    local loc_txt = {
        name = name,
        text = {
            "Earn {C:money}$#1#{} immediately",
            "{C:attention}Big Blind{} gives",
            "no reward money",
        }
    }
    --function SMODS.Voucher{name, slug, config, pos, loc_txt, cost, unlocked, discovered, available, requires, atlas)
    local v_gold_bar = SMODS.Voucher{
        name=name, key=id,
        config={extra=16},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=1, unlocked=true, discovered=true, available=true, requires={MOD_PREFIX_V..'gold_coin'}
    }
    local this_v=v_gold_bar
    handle_atlas(id,this_v)
    -- SMODS.Sprite:new("v_"..id, SMODS.findModByID("BetmmaVouchers").path, "v_gold_bar.png", 71, 95, "asset_atli"):register();
    -- v_gold_bar:register()
    v_gold_bar.loc_vars = function(self, info_queue, center)
        return {vars={center.ability.extra}}
    end
    handle_register(this_v)

    local Card_apply_to_run_ref = Card.apply_to_run
    function Card:apply_to_run(center)
        local center_table = {
            name = center and center.name or self and self.ability.name,
            extra = center and center.config.extra or self and self.ability.extra
        }
        if center_table.name == 'Gold Coin' or center_table.name == 'Gold Bar' then
            ease_dollars(center_table.extra)
        end
        if center_table.name == 'Gold Coin' then
            G.GAME.modifiers.no_blind_reward = G.GAME.modifiers.no_blind_reward or {}
            G.GAME.modifiers.no_blind_reward.Small = true
        end
        if center_table.name == 'Gold Bar' then
            G.GAME.modifiers.no_blind_reward = G.GAME.modifiers.no_blind_reward or {}
            G.GAME.modifiers.no_blind_reward.Big = true
        end
        Card_apply_to_run_ref(self, center)
    end



end -- gold coin
do 
    
    local name="Abstract Art"
    local id="abstract_art"
    local loc_txt = {
        name = name,
        text = {
            "{C:attention}+#1#{} Ante to win,",
            "{C:blue}+#1#{} hand and",
            "{C:red}+#1#{} discard per round"
        }
    }
    local this_v = SMODS.Voucher{
        name=name, key=id,
        config={extra=1,rarity=2},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=10, unlocked=true, discovered=true, available=true
    }
    handle_atlas(id,this_v)
    this_v.loc_vars = function(self, info_queue, center)
        return {vars={center.ability.extra}}
    end
    handle_register(this_v)

    
    local name="Mondrian"
    local id="mondrian"
    local loc_txt = {
        name = name,
        text = {
            "{C:attention}+#1#{} Ante to win,",
            "{C:attention}+#1#{} Joker slot"
        }
    }
    local this_v = SMODS.Voucher{
        name=name, key=id,
        config={extra=1,rarity=2},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=10, unlocked=true, discovered=true, available=true, requires={MOD_PREFIX_V..'abstract_art'}
    }
    handle_atlas(id,this_v)
    this_v.loc_vars = function(self, info_queue, center)
        return {vars={center.ability.extra}}
    end
    handle_register(this_v)

    local Card_apply_to_run_ref = Card.apply_to_run
    function Card:apply_to_run(center)
        local center_table = {
            name = center and center.name or self and self.ability.name,
            extra = center and center.config.extra or self and self.ability.extra
        }
        if center_table.name == 'Abstract Art' then
            ease_ante_to_win(center_table.extra)
            G.GAME.round_resets.hands = G.GAME.round_resets.hands + center_table.extra
            ease_hands_played(center_table.extra)
            G.GAME.round_resets.discards = G.GAME.round_resets.discards + center_table.extra
            ease_discard(center_table.extra)
        end
        if center_table.name == 'Mondrian' then
            ease_ante_to_win(center_table.extra)
            G.E_MANAGER:add_event(Event({func = function()
                if G.jokers then 
                    G.jokers.config.card_limit = G.jokers.config.card_limit + 1
                end
                return true end }))
        end
        Card_apply_to_run_ref(self, center)
    end


    function ease_ante_to_win(mod)
        G.E_MANAGER:add_event(Event({
          trigger = 'immediate',
          func = function()
              local ante_UI = G.hand_text_area.ante
              mod = mod or 0
              local text = '+'
              local col = G.C.IMPORTANT
              if mod < 0 then
                  text = '-'
                  col = G.C.RED
              end
              ante_UI.config.object:update()
              --If this line is written in the apply_to_run function above, the ante to win number will increase before the animation begins
              G.GAME.win_ante=G.GAME.win_ante+mod
              G.HUD:recalculate()
              --Popup text next to the chips in UI showing number of chips gained/lost
              attention_text({
                text = text..tostring(math.abs(mod)),
                scale = 1, 
                hold = 0.7,
                cover = ante_UI.parent,
                cover_colour = col,
                align = 'cm',
                })
              --Play a chip sound
              play_sound('highlight2', 0.685, 0.2)
              play_sound('generic1')
              return true
          end
        }))
    end

    
end -- abstract art
do 

    local name="Round Up"
    local id="round_up"
    local loc_txt = {
        name = name,
        text = {
            "{C:blue}Chips{} always round up",
            "to nearest 10",
        }
    }
    local this_v = SMODS.Voucher{
        name=name, key=id,
        config={},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=10, unlocked=true, discovered=true, available=true
    }
    handle_atlas(id,this_v)
    this_v.loc_vars = function(self, info_queue, center)
        return {vars={}}
    end
    handle_register(this_v)

    
    local name="Round Up Plus"
    local id="round_up_plus"
    local loc_txt = {
        name = name,
        text = {
            "{C:red}Mult{} always rounds up",
            "to nearest 10",
        }
    }
    local this_v = SMODS.Voucher{
        name=name, key=id,
        config={extra=5},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=10, unlocked=true, discovered=true, available=true, requires={MOD_PREFIX_V..'round_up'}
    }
    handle_atlas(id,this_v)
    this_v.loc_vars = function(self, info_queue, center)
        return {vars={center.ability.extra}}
    end
    handle_register(this_v)

    local mod_chips_ref=mod_chips
    function mod_chips(_chips)
        if used_voucher('round_up') then
          _chips = usingTalisman() and ((_chips+9.9999) / to_big(10)):floor() * to_big(10) or math.ceil(_chips/10)*10
        end
        return mod_chips_ref(_chips)
    end
    local mod_mult_ref=mod_mult
    function mod_mult(_mult)
        if used_voucher('round_up_plus') then
            _mult= usingTalisman() and ((_mult+9.9999) / to_big(10)):floor() * to_big(10) or math.ceil(_mult/10)*10
        end
        return mod_mult_ref(_mult)
    end
do 
end -- skip
do 
end -- scrawl
do 

    local name="Reserve Area"
    local id="reserve_area"
    local loc_txt = {
        name = name,
        text = {
            "You can reserve {C:tarot}Tarot{}",
            "cards instead of using them",
            "when opening an {C:tarot}Arcana Pack{}"
        }
    }
    local this_v = SMODS.Voucher{
        name=name, key=id,
        config={},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=10, unlocked=true, discovered=true, available=true
    }
    handle_atlas(id,this_v)
    this_v.loc_vars = function(self, info_queue, center)
        return {vars={}}--{center.ability.extra}
    end
    handle_register(this_v)

    
    local name="Reserve Area Plus"
    local id="reserve_area_plus"
    local loc_txt = {
        name = name,
        text = {
            "You can reserve {C:spectral}Spectral{}",
            "cards instead of using them",
            "when opening a {C:spectral}Spectral Pack{}",
            "Get an {C:attention}Ethereal Tag{} now"
        }
    }
    local this_v = SMODS.Voucher{
        name=name, key=id,
        config={},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=10, unlocked=true, discovered=true, available=true, requires={MOD_PREFIX_V..'reserve_area'}
    }
    handle_atlas(id,this_v)
    this_v.loc_vars = function(self, info_queue, center)
        return {vars={}}--{center.ability.extra}
    end
    handle_register(this_v)

    local Card_apply_to_run_ref = Card.apply_to_run
    function Card:apply_to_run(center)
        local center_table = {
            name = center and center.name or self and self.ability.name,
            extra = center and center.config.extra or self and self.ability.extra
        }
        if center_table.name == 'Reserve Area Plus' then
            
            add_tag(Tag('tag_ethereal'))
            -- G.E_MANAGER:add_event(Event({
            --     trigger = 'before',
            --     delay =  0,
            --     func = function() 
                    -- local key = 'p_spectral_mega_1'
                    -- local card = Card(G.play.T.x + G.play.T.w/2 - G.CARD_W*1.27/2,
                    -- G.play.T.y + G.play.T.h/2-G.CARD_H*1.27/2, G.CARD_W*1.27, G.CARD_H*1.27, G.P_CARDS.empty, G.P_CENTERS[key], {bypass_discovery_center = true, bypass_discovery_ui = true})
                    -- card.cost = 0
                    -- G.FUNCS.use_card({config = {ref_table = card}})
                    -- card:start_materialize()
                    -- return true
                -- end}))   
            
            -- Unfortunately I failed to directly open a spectral pack
        end
        Card_apply_to_run_ref(self, center)
    end

    local G_UIDEF_use_and_sell_buttons_ref=G.UIDEF.use_and_sell_buttons
    function G.UIDEF.use_and_sell_buttons(card)
        if (card.area == G.pack_cards and G.pack_cards) and card.ability.consumeable then --Add a use button
            if G.STATE == G.STATES.SMODS_BOOSTER_OPENED and SMODS.OPENED_BOOSTER and( SMODS.OPENED_BOOSTER.ability.name:find('Arcana') and used_voucher('reserve_area') or SMODS.OPENED_BOOSTER.ability.name:find('Spectral') and used_voucher('reserve_area_plus')) then
                return {
                    n=G.UIT.ROOT, config = {padding = -0.1,  colour = G.C.CLEAR}, nodes={
                      {n=G.UIT.R, config={ref_table = card, r = 0.08, padding = 0.1, align = "bm", minw = 0.5*card.T.w - 0.15, minh = 0.7*card.T.h, maxw = 0.7*card.T.w - 0.15, hover = true, shadow = true, colour = G.C.UI.BACKGROUND_INACTIVE, one_press = true, button = 'use_card', func = 'can_use_consumeable'}, nodes={
                        {n=G.UIT.T, config={text = localize('b_use'),colour = G.C.UI.TEXT_LIGHT, scale = 0.55, shadow = true}}
                      }},
                      {n=G.UIT.R, config={ref_table = card, r = 0.08, padding = 0.1, align = "bm", minw = 0.5*card.T.w - 0.15, maxw = 0.9*card.T.w - 0.15, minh = 0.1*card.T.h, hover = true, shadow = true, colour = G.C.UI.BACKGROUND_INACTIVE, one_press = true, button = 'Do you know that this parameter does nothing?', func = 'can_reserve_card'}, nodes={
                        {n=G.UIT.T, config={text = localize('b_reserve'),colour = G.C.UI.TEXT_LIGHT, scale = 0.45, shadow = true}}
                      }},
                      {n=G.UIT.R, config = {align = "bm", w=7.7*card.T.w}},
                      {n=G.UIT.R, config = {align = "bm", w=7.7*card.T.w}},
                      {n=G.UIT.R, config = {align = "bm", w=7.7*card.T.w}},
                      {n=G.UIT.R, config = {align = "bm", w=7.7*card.T.w}},
                      -- I can't explain it
                  }}
            end
        end
        return G_UIDEF_use_and_sell_buttons_ref(card)
    end
    G.FUNCS.can_reserve_card = function(e)
        if #G.consumeables.cards < G.consumeables.config.card_limit then 
            e.config.colour = G.C.GREEN
            e.config.button = 'reserve_card' 
        else
          e.config.colour = G.C.UI.BACKGROUND_INACTIVE
          e.config.button = nil
        end
    end
    G.FUNCS.reserve_card = function(e) -- only works for consumeables
        local c1 = e.config.ref_table
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.1,
            func = function()
              c1.area:remove_card(c1)
              c1:add_to_deck()
              if c1.children.price then c1.children.price:remove() end
              c1.children.price = nil
              if c1.children.buy_button then c1.children.buy_button:remove() end
              c1.children.buy_button = nil
              remove_nils(c1.children)
              G.consumeables:emplace(c1)
              G.GAME.pack_choices = G.GAME.pack_choices - 1
              if G.GAME.pack_choices <= 0 then
                G.FUNCS.end_consumeable(nil, delay_fac)
              end
              return true
            end
        }))
    end
    G.FUNCS.reserve_card_to_joker_slot = function(e) -- only works for consumeables
        local c1 = e.config.ref_table
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.1,
            func = function()
              c1.area:remove_card(c1)
              c1:add_to_deck()
              if c1.children.price then c1.children.price:remove() end
              c1.children.price = nil
              if c1.children.buy_button then c1.children.buy_button:remove() end
              c1.children.buy_button = nil
              remove_nils(c1.children)
              G.jokers:emplace(c1)
              G.GAME.pack_choices = G.GAME.pack_choices - 1
              if G.GAME.pack_choices <= 0 then
                G.FUNCS.end_consumeable(nil, delay_fac)
              end
              return true
            end
        }))
    end

    -- local G_UIDEF_card_focus_ui_ref=G.UIDEF.card_focus_ui
    -- function G.UIDEF.card_focus_ui(card)
    -- I suspect that this function does nothing too
    -- because replacing it with empty function seems do no harm
    -- no card_focus_ui and card_focus_button are for controller ui. lol

end -- reserve area
do 
end -- overkill
do 

    local name="3D Boosters"
    local id="3d_boosters"
    local loc_txt = {
        name = name,
        text = {
            "{C:attention}+1{} Booster Pack",
            "available in shop"
        }
    }
    local this_v = SMODS.Voucher{
        name=name, key=id,
        config={},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=10, unlocked=true, discovered=true, available=true
    }
    handle_atlas(id,this_v)
    this_v.loc_vars = function(self, info_queue, center)
        return {vars={}}--{center.ability.extra}
    end
    handle_register(this_v)
    
    local name="4D Boosters"
    local id="4d_boosters"
    local loc_txt = {
        name = name,
        text = {
            "Rerolls apply to {C:attention}Booster Packs{}",
            "Rerolled {C:attention}Booster Packs{}",
            "cost {C:attention}$#1#{} more"
        }
    }
    local this_v = SMODS.Voucher{
        name=name, key=id,
        config={extra=3,rarity=2},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=10, unlocked=true, discovered=true, available=true, requires={MOD_PREFIX_V..'3d_boosters'}
    }
    handle_atlas(id,this_v)
    this_v.loc_vars = function(self, info_queue, center)
        return {vars={center.ability.extra}}
    end
    handle_register(this_v)
    function get_booster_pack_max()
        return G.GAME.starting_params.boosters_in_shop + (G.GAME.modifiers.extra_boosters or 0)
    end
    
    local Card_apply_to_run_ref = Card.apply_to_run
    function Card:apply_to_run(center)
        local center_table = {
            name = center and center.name or self and self.ability.name,
            extra = center and center.config.extra or self and self.ability.extra
        }
        if center_table.name == '3D Boosters'then
            SMODS.change_booster_limit(1)
        end
        Card_apply_to_run_ref(self, center)
    end
    local G_FUNCS_reroll_shop_ref=G.FUNCS.reroll_shop
    function G.FUNCS.reroll_shop(e)
        G_FUNCS_reroll_shop_ref(e)
        if used_voucher('4d_boosters') then
            my_reroll_shop(get_booster_pack_max(),get_voucher('4d_boosters').config.extra)
        end
    end
    function my_reroll_shop(num,price_mod)
        G.E_MANAGER:add_event(Event({
            trigger = 'immediate',
            func = function()
                if not (G.GAME.current_round and G.GAME.current_round.used_packs and G.shop_booster and G.shop_booster.cards) then
                    return true
                end
                for i = #G.shop_booster.cards,1, -1 do
                    local c = G.shop_booster:remove_card(G.shop_booster.cards[i])
                    c:remove()
                    c = nil
                end
        
                --save_run()
        
                play_sound('coin2')
                play_sound('other1')
                
                for i = 1, num - #G.shop_booster.cards do
                    G.GAME.current_round.used_packs = G.GAME.current_round.used_packs or {}
                    G.GAME.current_round.used_packs[i] = get_pack('shop_pack').key 
                    local card = Card(G.shop_booster.T.x + G.shop_booster.T.w/2,
                    G.shop_booster.T.y, G.CARD_W*1.27, G.CARD_H*1.27, G.P_CARDS.empty, G.P_CENTERS[G.GAME.current_round.used_packs[i]], {bypass_discovery_center = true, bypass_discovery_ui = true})
                    create_shop_card_ui(card, 'Booster', G.shop_booster)
                    card.cost=card.cost+price_mod
                    card.ability.booster_pos = i
                    card:start_materialize()
                    G.shop_booster:emplace(card)
                end
            return true
            end
        }))
        G.E_MANAGER:add_event(Event({ func = function() save_run(); return true end}))
        
    end


end -- 3d boosters
do 
end -- b1g50
do 
end -- collector
do 

    local name="Flipped Card"
    local id="flipped_card"
    local loc_txt = {
        name = name,
        text = {
            "You can {C:attention}flip{} up to #1# cards",
            "once before playing each hand.",
            "{C:attention}Flipped{} cards will return",
            "to your hand after they are played"
        }
    }
    local this_v = SMODS.Voucher{
        name=name, key=id,
        config={extra=3,rarity=2},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=10, unlocked=true, discovered=true, available=true
    }
    handle_atlas(id,this_v)
    this_v.loc_vars = function(self, info_queue, center)
        return {vars={center.ability.extra}}
    end
    handle_register(this_v)
    
    local name="Double Flipped Card"
    local id="double_flipped_card"
    local loc_txt = {
        name = name,
        text = {
            "{C:attention}Flipped{} cards are",
            "held in hand when scoring and",
            "can trigger held-in-hand effects"
        }
    }
    local this_v = SMODS.Voucher{
        name=name, key=id,
        config={rarity=2},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=10, unlocked=true, discovered=true, available=true, requires={MOD_PREFIX_V..'flipped_card'}
    }
    handle_atlas(id,this_v)
    this_v.loc_vars = function(self, info_queue, center)
        return {vars={}}
    end
    handle_register(this_v)
    
    local create_UIBox_buttons_ref=create_UIBox_buttons
    function create_UIBox_buttons()
        local ret=create_UIBox_buttons_ref()
        local text_scale=0.45
        local button_height=1.3
        if (used_voucher('flipped_card') or used_voucher('double_flipped_card')) then
            local flip_button={n=G.UIT.C, config={id = 'flip_button', align = "tm", minw = 2.5, padding = 0.3, r = 0.1, hover = true, colour = G.C.PURPLE, button = "this is another useless parameter", one_press = true, shadow = true, func = 'can_flip'}, nodes={
                {n=G.UIT.R, config={align = "bcm", padding = 0}, nodes={
                {n=G.UIT.T, config={text = localize('b_flip_hand'), scale = text_scale, colour = G.C.UI.TEXT_LIGHT, focus_args = {button = 'x', orientation = 'bm'}, func = 'set_button_pip'}}
                }},
            }}
            table.insert(ret.nodes,flip_button)
        end
        return ret
    end

    local G_FUNCS_play_cards_from_highlighted_ref=G.FUNCS.play_cards_from_highlighted
    G.FUNCS.play_cards_from_highlighted=function(e)
        for i=1, #G.hand.highlighted do
            G.hand.highlighted[i].facing_ref=G.hand.highlighted[i].facing
        end
        -- when played all cards will be face up so its facing status before playing should be saved elsewhere
        G.GAME.current_round.flips_left=1
        local ret= G_FUNCS_play_cards_from_highlighted_ref(e)
        return ret
    end

    local new_round_ref=new_round
    function new_round()
        G.GAME.current_round.flips_left=1
        new_round_ref()
    end

    G.FUNCS.can_flip=function(e)
        if #G.hand.highlighted <= 0 or #G.hand.highlighted > get_voucher('flipped_card').config.extra or G.GAME.current_round.flips_left <= 0 then 
            e.config.colour = G.C.UI.BACKGROUND_INACTIVE
            e.config.button = nil
        else
            e.config.colour = G.C.PURPLE
            e.config.button = 'flip_cards_from_highlighted'
        end
    end
    
    G.FUNCS.flip_cards_from_highlighted=function(e)
        stop_use()
        G.CONTROLLER.interrupt.focus = true
        G.CONTROLLER:save_cardarea_focus('hand')
        for i=1, #G.hand.highlighted do
            G.hand.highlighted[i]:flip()
        end
        G.GAME.current_round.flips_left=(G.GAME.current_round.flips_left or 1)-1
    end


    local G_FUNCS_draw_from_play_to_discard_ref=G.FUNCS.draw_from_play_to_discard
    G.FUNCS.draw_from_play_to_discard = function(e)
        if (used_voucher('flipped_card') and not used_voucher('double_flipped_card')) then
            local play_count = #G.play.cards --G.GAME.scoring_hand --G.GAME.scoring_hand is stored in eval_hand by me
            local it = 1
            local flag=false
            for k, v in ipairs(G.play.cards) do
                if v.facing_ref=='back' and (not v.shattered) and (not v.destroyed) and (not v.debuff)then
                    draw_card(G.play,G.hand, it*100/play_count,'down', false, v)
                    v.facing_ref=v.facing
                    it = it + 1
                    flag=true
                end
            end
        end
        G.E_MANAGER:add_event(Event({
            trigger = 'immediate',
            func = (function()     
                G_FUNCS_draw_from_play_to_discard_ref(e)
            return true end)
          }))
       
    end

    -- local eval_card_ref=eval_card -- removing when looping caused some cards not placed to hand
    -- function eval_card(card, context) -- debuffed card won't call this
    --     local ret = {eval_card_ref(card,context)}
    --     G.GAME.scoring_hand=context.scoring_hand
    --     if context.cardarea == G.play and context.main_scoring and not context.repetition_only and (card.ability.set == 'Default' or card.ability.set == 'Enhanced') and used_voucher('double_flipped_card') and card.facing_ref=='back' then
    --         if (not card.shattered) and (not card.destroyed) then 
    --             draw_card_immediately(G.play,G.hand, 0.1,'down', false, card)
    --             card.facing_ref=card.facing
    --         end
    --     end
    --     return unpack(ret)
    -- end
    
    function draw_card_immediately(from, to, percent, dir, sort, card, delay, mute, stay_flipped, vol, discarded_only)
        -- the value of hand is calculated immediately, and the animation takes time. The vanilla draw_card includes add_event which isn't immediate, but in eval_card we need to immediately move the double_flipped_card to hand so that in following calculation G.hand will include these cards.
        percent = percent or 50
        delay = delay or 0.1 
        if dir == 'down' then 
            percent = 1-percent
        end
        sort = sort or false
        local drawn = nil
        if card then 
            if from then card = from:remove_card(card) end
            if card then drawn = true end
            local stay_flipped = G.GAME and G.GAME.blind and G.GAME.blind:stay_flipped(to, card)
            if G.GAME.modifiers.flipped_cards and to == G.hand then
                if pseudorandom(pseudoseed('flipped_card')) < 1/G.GAME.modifiers.flipped_cards then
                    stay_flipped = true
                end
            end
            to:emplace(card, nil, stay_flipped)
        else
            if to:draw_card_from(from, stay_flipped, discarded_only) then drawn = true end
        end
        if not mute and drawn then
            if from == G.deck or from == G.hand or from == G.play or from == G.jokers or from == G.consumeables or from == G.discard then
                G.VIBRATION = G.VIBRATION + 0.6
            end
            play_sound('card1', 0.85 + percent*0.2/100, 0.6*(vol or 1))
        end
        if sort then
            to:sort()
        end
        return true
    end


end -- flipped card
do 
end -- prologue
do 

    local name="Bonus+"
    local id="bonus_plus"
    local loc_txt = {
        name = name,
        text = {
            "Permanently increase",
            "{C:blue}Bonus Card{} bonus",
            "by {C:blue}+#1#{} extra chips",
            "{C:inactive}(+30 -> +#2#){}"
        }
    }
    local this_v = SMODS.Voucher{
        name=name, key=id,
        config={extra=30},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=10, unlocked=true, discovered=true, available=true
    }
    handle_atlas(id,this_v)
    this_v.loc_vars = function(self, info_queue, center)
        return {vars={center.ability.extra,center.ability.extra+30}}
    end
    handle_register(this_v)

    local name="Mult+"
    local id="mult_plus"
    local loc_txt = {
        name = name,
        text = {
            "Permanently increase",
            "{C:red}Mult Card{} bonus",
            "by {C:red}+#1#{} Mult",
            "{C:inactive}(+4 -> +#2#){}"
        }
    }
    local this_v = SMODS.Voucher{
        name=name, key=id,
        config={extra=8},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=10, unlocked=true, discovered=true, available=true, requires={MOD_PREFIX_V..'bonus_plus'}
    }
    handle_atlas(id,this_v)
    this_v.loc_vars = function(self, info_queue, center)
        return {vars={center.ability.extra,center.ability.extra+4}}
    end
    handle_register(this_v)

    local Card_apply_to_run_ref = Card.apply_to_run
    function Card:apply_to_run(center)
        local center_table = {
            name = center and center.name or self and self.ability.name,
            extra = center and center.config.extra or self and self.ability.extra
        }
        if center_table.name == 'Bonus+' then
            G.P_CENTERS.m_bonus.config.bonus=G.P_CENTERS.m_bonus.config.bonus+get_voucher('bonus_plus').config.extra
            for k, v in pairs(G.playing_cards) do
                if v.config.center_key == 'm_bonus' then
                    v.ability.bonus = v.ability.bonus + get_voucher('bonus_plus').config.extra
                end
            end
        
        end
        if center_table.name == 'Mult+' then
            G.P_CENTERS.m_mult.config.mult=G.P_CENTERS.m_mult.config.mult+get_voucher('mult_plus').config.extra
            for k, v in pairs(G.playing_cards) do
                if v.config.center_key == 'm_mult' then 
                    v.ability.mult = v.ability.mult + get_voucher('mult_plus').config.extra
                end
            end
        end
        Card_apply_to_run_ref(self, center)
    end

end -- bonus+
do 

    local name="Omnicard"
    local id="omnicard"
    local loc_txt = {
        name = name,
        text = {
            "{C:attention}Wild Cards{} can't be",
            "debuffed. Retrigger",
            "all {C:attention}Wild Cards{}"
        }
    }
    local this_v = SMODS.Voucher{
        name=name, key=id,
        config={},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=10, unlocked=true, discovered=true, available=true
    }
    handle_atlas(id,this_v)
    this_v.loc_vars = function(self, info_queue, center)
        return {vars={}}
    end
    handle_register(this_v)

    local name="Bulletproof"
    local id="bulletproof"
    local loc_txt = {
        name = name,
        text = {
            -- "{C:attention}Glass Cards{} can",
            -- "break #1# times"
            "{C:attention}Glass Cards{} lose {X:mult,C:white}X#1#{}",
            "instead of breaking",
            "They break when",
            "they reach {X:mult,C:white}X#2#{}"
        }
    }
    local this_v = SMODS.Voucher{
        name=name, key=id,
        config={extra={lose=0.1,lower_bound=1.5},rarity=2},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=10, unlocked=true, discovered=true, available=true, requires={MOD_PREFIX_V..'omnicard'}
    }
    handle_atlas(id,this_v)
    this_v.loc_vars = function(self, info_queue, center)
        return {vars={center.ability.extra.lose,center.ability.extra.lower_bound}}
    end
    handle_register(this_v)

    local Card_set_debuff=Card.set_debuff
    function Card:set_debuff(should_debuff)
        if used_voucher('omnicard') and self.config and self.config.center_key=='m_wild' or self.ability.heal_ability_temp_antidebuff then -- betmma heal ability
            self.debuff = false
            return
        end
        Card_set_debuff(self,should_debuff)
    end
    local Card_update_ref = Card.update
    function Card:update(dt)
        if self.area == G.jokers then
        end
        if self.ability.heal_ability_temp_antidebuff then -- betmma heal ability
            self.debuff = false
            self.debuffed_by_blind=false
        end
        Card_update_ref(self, dt)
    end

    -- implementation of omnicard is in lovely.toml

    local Card_shatter_ref=Card.shatter
    function Card:shatter()
        if used_voucher('bulletproof') and self.ability.name == 'Glass Card' and self.ability.x_mult-get_voucher('bulletproof').config.extra.lose>get_voucher('bulletproof').config.extra.lower_bound then
            self.ability.breaking_count=(self.ability.breaking_count or 0)+1
            self.ability.x_mult=self.ability.x_mult-get_voucher('bulletproof').config.extra.lose
            --print(G.P_CENTERS.m_glass.config.Xmult,self.ability.x_mult)
            self.shattered=false
            self.destroyed=false
            card_eval_status_text(self,'extra',nil,nil,nil,{message=localize('k_bulletproof')})
            card_eval_status_text(self,'extra',nil,nil,nil,{message=localize{type='variable',key='a_xmult_minus',vars={get_voucher('bulletproof').config.extra.lose}},colour=G.C.RED})
            Card_shatter_not_remove(self)
            return
        end
        Card_shatter_ref(self)
    end
    
    function Card_shatter_not_remove(self)
        local dissolve_time = 0.7
        -- self.dissolve = 0
        self.dissolve_colours = {{1,1,1,0.8}}
        -- self:juice_up()
        local childParts = Particles(0, 0, 0,0, {
            timer_type = 'TOTAL',
            timer = 0.007*dissolve_time,
            scale = 0.3,
            speed = 4,
            lifespan = 0.5*dissolve_time,
            attach = self,
            colours = self.dissolve_colours,
            fill = true
        })
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            blockable = false,
            delay =  0.5*dissolve_time,
            func = (function() childParts:fade(0.15*dissolve_time) return true end)
        }))
        G.E_MANAGER:add_event(Event({
            blockable = false,
            func = (function()
                    play_sound('glass'..math.random(1, 6), math.random()*0.2 + 0.9,0.5)
                    play_sound('generic1', math.random()*0.2 + 0.9,0.5)
                return true end)
        }))
        -- G.E_MANAGER:add_event(Event({
        --     trigger = 'ease',
        --     blockable = false,
        --     ref_table = self,
        --     ref_value = 'dissolve',
        --     ease_to = 1,
        --     delay =  0.5*dissolve_time,
        --     func = (function(t) return t end)
        -- }))
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            blockable = false,
            delay =  0.55*dissolve_time,
            func = (function()  return true end)
        }))
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            blockable = false,
            delay =  0.51*dissolve_time,
        }))
    end
end -- omnicard
do 
end -- Cash Clutch
do 

    local name="Eternity"
    local id="eternity"
    local loc_txt = {
        name = name,
        text = {
            "Shop can have {C:attention}Eternal{} Jokers",
            "{C:attention}Eternal{} Jokers have a {C:green}#1#%{}",
            "chance to be {C:dark_edition}Negative{}",
            "{C:inactive}(This chance can't be doubled){}"
        }
    }
    local this_v = SMODS.Voucher{
        name=name, key=id,
        config={extra=2.5,rarity=2},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=10, unlocked=true, discovered=true, available=true
    }
    handle_atlas(id,this_v)
    this_v.loc_vars = function(self, info_queue, center)
        if IN_SMOD1 then
            table.insert(info_queue, {key = 'eternal', set = 'Other'})
        end
        return {vars={100/center.ability.extra}}
    end
    handle_register(this_v)

    local name="Half-life"
    local id="half_life"
    local loc_txt = {
        name = name,
        text = {
            "Shop can have {C:attention}Perishable{} Jokers",
            "{C:attention}Perishable{} Jokers only",
            "take up {C:attention}#1#{} Joker slots",
        }
    }
    local this_v = SMODS.Voucher{
        name=name, key=id,
        config={extra=0.5,rarity=2},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=10, unlocked=true, discovered=true, available=true, requires={MOD_PREFIX_V..'eternity'}
    }
    handle_atlas(id,this_v)
    this_v.loc_vars = function(self, info_queue, center)
        if IN_SMOD1 then
            table.insert(info_queue, {key = 'perishable_no_debuff', set = 'Other', vars = {G.GAME.perishable_rounds}})
        end
        return {vars={center.ability.extra}}
    end
    handle_register(this_v)

    -- get the amount of extra joker slot by half-life jokers 
    -- WARNING: implement of half-life is NOT setting perishable jokers to only take up 0.5 joker slots, instead it's setting perishable jokers to add 0.5 joker slots like negative edition. With this the display of joker area UI will be like 5/5.5 which wasn't I want, so I modified the CardArea:update to reduce card count by the function value. At other situations the game always use #G.jokers.cards so this does no harm. For joker limit it's not practical to directly decrease it since it's the real value, so I stored the modified value in self.config.card_limit_ref and used a lovely patch to let the ui use this value if the cardarea is joker area and half_life has been redeemed.
    local function get_half_life_delta()
        if not G.jokers.cards or not used_voucher('half_life')then return 0 end
        local ret=0
        local delta_value=get_voucher('half_life').config.extra
        for i=1,#G.jokers.cards do
            if G.jokers.cards[i].ability.perishable and not G.jokers.cards[i].debuff then
                ret=ret+delta_value
            end
        end
        return ret
    end

    local Card_apply_to_run_ref = Card.apply_to_run
    function Card:apply_to_run(center)
        local center_table = {
            name = center and center.name or self and self.ability.name,
            extra = center and center.config.extra or self and self.ability.extra
        }
        if center_table.name == 'Eternity' then
            G.GAME.modifiers.enable_eternals_in_shop=true
        end
        if center_table.name == 'Half-life' then
            G.GAME.modifiers.enable_perishables_in_shop=true
            G.jokers.config.card_limit = G.jokers.config.card_limit +get_half_life_delta()
        end

        Card_apply_to_run_ref(self, center)
    end

    local create_card_ref=create_card
    function create_card(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append)
        local card=create_card_ref(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append)
        if used_voucher('eternity') and _type == 'Joker' and ((area == G.shop_jokers) or (area == G.pack_cards)) and card.ability.eternal then
            if pseudorandom('eternity')<1/get_voucher('eternity').config.extra then
                card:set_edition{negative=true}
            end
        end
        return card
    end

    local Card_add_to_deck_ref=Card.add_to_deck
    function Card:add_to_deck(from_debuff)
        if not self.added_to_deck and self.ability.perishable and used_voucher('half_life') and not self.ability.consumeable then
            G.jokers.config.card_limit = G.jokers.config.card_limit + get_voucher('half_life').config.extra
        end
        Card_add_to_deck_ref(self,from_debuff)
    end
    local Card_remove_from_deck_ref=Card.remove_from_deck
    function Card:remove_from_deck(from_debuff)
        if self.added_to_deck and self.ability.perishable and used_voucher('half_life') and not self.ability.consumeable then
            G.jokers.config.card_limit = G.jokers.config.card_limit - get_voucher('half_life').config.extra
        end
        Card_remove_from_deck_ref(self,from_debuff)
    end

    local CardArea_update_ref=CardArea.update
    function CardArea:update(dt)
        CardArea_update_ref(self,dt)
        if self==G.jokers and used_voucher('half_life')then
            local delta=get_half_life_delta()
            self.config.card_count=self.config.card_count-delta
            self.config.card_limit_ref=self.config.card_limit-delta
        end
    end

    local CardArea_draw_ref=CardArea.draw
    function CardArea:draw()
        CardArea_draw_ref(self)
    end
end -- eternity
do 
    local name="Debt Burden"
    local id="debt_burden"
    local loc_txt = {
        name = name,
        text = {
            "Shop can have {C:attention}Rental{} Jokers",
            "{C:attention}Rental{} Jokers don't cost money",
            "if you're in debt",
            "Each {C:attention}Rental{} Joker increases",
            "debt limit by {C:red}-$#1#{}"
        }
    }
    local this_v = SMODS.Voucher{
        name=name, key=id,
        config={extra=10,rarity=1},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=10, unlocked=true, discovered=true, available=true
    }
    handle_atlas(id,this_v)
    this_v.loc_vars = function(self, info_queue, center)
        if IN_SMOD1 then
            table.insert(info_queue, {key = 'rental', set = 'Other', vars = {G.GAME.rental_rate or 1}})
        end
        return {vars={center.ability.extra}}
    end
    handle_register(this_v)

    local name="Bobby Pin"
    local id="bobby_pin"
    local loc_txt = {
        name = name,
        text = {
            "Shop can have {C:attention}Pinned{} Jokers",
            "Each {C:attention}Pinned{} Joker copies",
            "ability of {C:attention}Joker{} to the right",
            "if itself {C:attention}isn't triggered{}"
        }
    }
    local this_v = SMODS.Voucher{
        name=name, key=id,
        config={rarity=3},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=10, unlocked=true, discovered=true, available=true, requires={MOD_PREFIX_V..'debt_burden'}
    }
    handle_atlas(id,this_v)
    this_v.loc_vars = function(self, info_queue, center)
        if IN_SMOD1 then
            table.insert(info_queue, {key = 'pinned_left', set = 'Other'})
        end
        return {vars={}}
    end
    handle_register(this_v)

    -- should change rental side ui

    local function get_debt_burden_delta()
        if not G.jokers.cards or not used_voucher('debt_burden')then return 0 end
        local ret=0
        local delta_value=get_voucher('debt_burden').config.extra
        for i=1,#G.jokers.cards do
            if G.jokers.cards[i].ability.rental and not G.jokers.cards[i].debuff then
                ret=ret+delta_value
            end
        end
        return ret
    end
    
    local Card_apply_to_run_ref = Card.apply_to_run
    function Card:apply_to_run(center)
        local center_table = {
            name = center and center.name or self and self.ability.name,
            extra = center and center.config.extra or self and self.ability.extra
        }
        if center_table.name == 'Debt Burden' then
            G.GAME.modifiers.enable_rentals_in_shop=true
            G.GAME.bankrupt_at = G.GAME.bankrupt_at - get_debt_burden_delta()
        end
        if center_table.name == 'Bobby Pin' then
            G.GAME.modifiers.cry_enable_pinned_in_shop=true
        end

        Card_apply_to_run_ref(self, center)
    end

    local Card_calculate_rental_ref=Card.calculate_rental
    function Card:calculate_rental()
        if used_voucher('debt_burden') and TalismanCompat(G.GAME.dollars)<TalismanCompat(0) then
            return
        end
        Card_calculate_rental_ref(self)
    end
    
    local Card_add_to_deck_ref=Card.add_to_deck
    function Card:add_to_deck(from_debuff)
        if not self.added_to_deck and self.ability.rental and used_voucher('debt_burden') and not self.ability.consumeable then
            G.GAME.bankrupt_at = G.GAME.bankrupt_at - get_voucher('debt_burden').config.extra
        end
        Card_add_to_deck_ref(self,from_debuff)
    end
    local Card_remove_from_deck_ref=Card.remove_from_deck
    function Card:remove_from_deck(from_debuff)
        if self.added_to_deck and self.ability.rental and used_voucher('debt_burden') and not self.ability.consumeable then
            G.GAME.bankrupt_at = G.GAME.bankrupt_at + get_voucher('debt_burden').config.extra
        end
        Card_remove_from_deck_ref(self,from_debuff)
    end

    local create_card_ref=create_card
    function create_card(_type, area, legendary, _rarity, 
        skip_materialize, soulable, forced_key, key_append)
        local card=create_card_ref(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append)
        if not usingCryptid and G.GAME.modifiers.cry_enable_pinned_in_shop then
            if _type == 'Joker' and ((area == G.shop_jokers) or (area == G.pack_cards)) and pseudorandom('cry_pin'..(key_append or '')..G.GAME.round_resets.ante) > 0.7 then
                card.pinned = true
            end
        end
        return card
    end

    local Card_calculate_joker_ref=Card.calculate_joker
    function Card:calculate_joker(context)
        local ret=Card_calculate_joker_ref(self,context)
        if self.ability.set=='Joker' and not self.debuff and self.pinned and used_voucher('bobby_pin') and ret==nil then
            local other_joker = nil
            for i = 1, #G.jokers.cards do
                if G.jokers.cards[i] == self then other_joker = G.jokers.cards[i+1] end
            end
            if other_joker and other_joker ~= self then
                context.blueprint = (context.blueprint and (context.blueprint + 1)) or 1
                context.blueprint_card = context.blueprint_card or self
                if context.blueprint > #G.jokers.cards + 1 then return end
                local other_joker_ret = other_joker:calculate_joker(context)
                if other_joker_ret then 
                    other_joker_ret.card = context.blueprint_card or self
                    other_joker_ret.colour = G.C.BLUE
                    return other_joker_ret
                end
            end
        end
        return ret
    end




end -- debt burden
do 
end -- stow
do 
end -- undying
do 
    local name="Bargain Aisle"
    local id="bargain_aisle"
    local loc_txt = {
        name = name,
        text = {
            "First item in shop is {C:attention}free{}",
        }
    }
    local this_v = SMODS.Voucher{
        name=name, key=id,
        config={rarity=1},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=10, unlocked=true, discovered=true, available=true
    }
    handle_atlas(id,this_v)
    this_v.loc_vars = function(self, info_queue, center)
        return {vars={}}
    end
    handle_register(this_v)

    local name="Clearance Aisle"
    local id="clearance_aisle"
    local loc_txt = {
        name = name,
        text = {
            "First {C:attention}Booster Pack{} in shop is {C:attention}free{}",
        }
    }
    local this_v = SMODS.Voucher{
        name=name, key=id,
        config={rarity=1},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=10, unlocked=true, discovered=true, available=true, requires={MOD_PREFIX_V..'bargain_aisle'}
    }
    handle_atlas(id,this_v)
    this_v.loc_vars = function(self, info_queue, center)
        return {vars={}}
    end
    handle_register(this_v)

    function bargain_aisle_effect()
        G.E_MANAGER:add_event(Event({func = function()
            if G.shop_jokers and G.shop_jokers.cards and G.shop_jokers.cards[1]~=nil then 
                G.shop_jokers.cards[1].ability.couponed=true
                G.shop_jokers.cards[1]:set_cost()
            end
            return true end }))
    end
    function clearance_aisle_effect()
        G.E_MANAGER:add_event(Event({func = function()
            if G.shop_booster and G.shop_booster.cards and G.shop_booster.cards[1]~=nil then 
                G.shop_booster.cards[1].ability.couponed=true
                G.shop_booster.cards[1]:set_cost()
            end
            return true end }))
    end

    local Card_apply_to_run_ref = Card.apply_to_run
    function Card:apply_to_run(center)
        local center_table = {
            name = center and center.name or self and self.ability.name,
            extra = center and center.config.extra or self and self.ability.extra
        }
        if center_table.name == 'Bargain Aisle' and G.shop_jokers then
            bargain_aisle_effect()
        end
        if center_table.name == 'Clearance Aisle' and G.shop_booster then
            clearance_aisle_effect()
        end

        Card_apply_to_run_ref(self, center)
    end

    -- I add the effects in lovely patch
   

end -- bargain aisle
do 
    local name="Rich Boss"
    local id="rich_boss"
    local loc_txt = {
        name = name,
        text = {
            "Boss Blinds give {C:money}$#1#{} more",
        }
    }
    local this_v = SMODS.Voucher{
        name=name, key=id,
        config={rarity=1,extra=8},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=10, unlocked=true, discovered=true, available=true
    }
    handle_atlas(id,this_v)
    this_v.loc_vars = function(self, info_queue, center)
        return {vars={center.ability.extra}}
    end
    handle_register(this_v)

    local name="Richer Boss"
    local id="richer_boss"
    local loc_txt = {
        name = name,
        text = {
            "Boss Blinds give {C:money}$#1#{} more per ante",
        }
    }
    local this_v = SMODS.Voucher{
        name=name, key=id,
        config={rarity=1,extra=4},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=10, unlocked=true, discovered=true, available=true, requires={MOD_PREFIX_V..'rich_boss'}
    }
    handle_atlas(id,this_v)
    this_v.loc_vars = function(self, info_queue, center)
        return {vars={center.ability.extra}}
    end
    handle_register(this_v)

    function betmma_rich_boss_bonus(ante_mod)
        local ans=0
        if used_voucher('rich_boss') then
            ans=ans+get_voucher('rich_boss').config.extra
        end
        if used_voucher('richer_boss') then
            ans=ans+get_voucher('richer_boss').config.extra*(G.GAME.round_resets.ante+(ante_mod or 0))
        end
        return ans
    end 

    -- other visual effects are in lovely.toml

    local G_FUNCS_evaluate_round_ref=G.FUNCS.evaluate_round
    G.FUNCS.evaluate_round=function()
        local money_bonus=0
        if G.GAME.blind:get_type()=='Boss' then
            money_bonus=money_bonus+betmma_rich_boss_bonus(-1)--ante has been risen one
        end
        G.GAME.blind.dollars=G.GAME.blind.dollars+money_bonus
        G_FUNCS_evaluate_round_ref()
        G.GAME.blind.dollars=G.GAME.blind.dollars-money_bonus

    end
   

end -- rich boss
do 
    local name="Gravity Assist"
    local id="gravity_assist"
    local loc_txt = {
        name = name,
        text = {
            "When upgrading a poker hand,",
            "also upgrade {C:attention}adjacent{} poker hands",
        }
    }
    local this_v = SMODS.Voucher{
        name=name, key=id,
        config={rarity=1,extra=8},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=10, unlocked=true, discovered=true, available=true
    }
    handle_atlas(id,this_v)
    this_v.loc_vars = function(self, info_queue, center)
        return {vars={center.ability.extra}}
    end
    handle_register(this_v)

    local name="Gravitational Wave"
    local id="gravitational_wave"
    local loc_txt = {
        name = name,
        text = {
            "When upgrading a poker hand, also upgrade",
            "non-adjacent poker hands by {C:attention}#1#{} levels",
        }
    }
    local this_v = SMODS.Voucher{
        name=name, key=id,
        config={rarity=1,extra=0.2},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=10, unlocked=true, discovered=true, available=true, requires={MOD_PREFIX_V..'gravity_assist'}
    }
    handle_atlas(id,this_v)
    this_v.loc_vars = function(self, info_queue, center)
        return {vars={center.ability.extra}}
    end
    handle_register(this_v)
    local level_up_hand_ref=level_up_hand
    local function upgrade_hand_and_display(card, hand, immediate, amount, delaydiv)
        local delaydiv=(G.betmma_solar_system_times or 1)+(delaydiv or 0)
        update_hand_text({sound = 'button', volume = 0.7, pitch = 0.8+delaydiv/10, delay = 0.1/delaydiv}, {handname=localize(hand, 'poker_hands'),chips = G.GAME.hands[hand].chips, mult = G.GAME.hands[hand].mult, level=G.GAME.hands[hand].level})
        level_up_hand_ref(card, hand, immediate, amount)
    end
    function level_up_hand(card, hand, instant, amount)
        level_up_hand_ref(card, hand, instant, amount)
        if (used_voucher('gravity_assist') or used_voucher('gravitational_wave')) and not G.betmma_gravity_voucher_rep then --this doesn't seem to work. maybe it's because repeated calls are after events so must call _ref
            G.betmma_gravity_voucher_rep=true
            local last=nil
            local next=nil
            local find=false
            for _,k in pairs(G.handlist) do -- only G.handlist is the same order as hand list in game
                local v=G.GAME.hands[k]
                -- print(k,last,next,find)
                if find==true and v.visible == true then
                    next=k;break
                end
                if k==hand then
                    find=true
                end
                if find==false and v.visible == true then
                    last=k
                end
            end
            if used_voucher('gravity_assist') then 
                if last~=nil then
                    upgrade_hand_and_display(card,last,true,amount)
                end
                if next~=nil then
                    upgrade_hand_and_display(card,next,true,amount)
                end
            end
            if used_voucher('gravitational_wave') then 
                local cnt=0
                for _,k in pairs(G.handlist) do
                    if k~=hand and k~=last and k~=next and G.GAME.hands[k] then
                        cnt=cnt+1
                        upgrade_hand_and_display(card,k,true,(amount or 1)*get_voucher('gravitational_wave').config.extra,cnt)
                    end
                end
            end
            G.betmma_gravity_voucher_rep=false
            local delaydiv=G.betmma_solar_system_times or 1
            update_hand_text({sound = 'button', volume = 0.7, pitch = 0.8, delay = 0.1/delaydiv}, {handname=localize(hand, 'poker_hands'),chips = G.GAME.hands[hand].chips, mult = G.GAME.hands[hand].mult, level=G.GAME.hands[hand].level})
        end
    end
    
    local UIElement_draw_self_ref=UIElement.draw_self
    -- prevent crash when upgrading a decimal level hand (i think it's because its color is nil)
    function UIElement:draw_self()
        if not self.config.colour then
            self.config.colour=G.C.UI.BACKGROUND_DARK
        end
        UIElement_draw_self_ref(self)
    end

end -- gravity assist
do 
end -- garbage bag
do 
    local name="Echo Wall"
    local id="echo_wall"
    local loc_txt = {
        name = name,
        text = {
            "{C:red}Discarding{} a card triggers",
            "its {C:attention}end of round{} effect",
        }
    }
    local this_v = SMODS.Voucher{
        name=name, key=id,
        config={rarity=1,extra=3},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=10, unlocked=true, discovered=true, available=true
    }
    handle_atlas(id,this_v)
    this_v.loc_vars = function(self, info_queue, center)
        return {vars={center.ability.extra}}
    end
    handle_register(this_v)

    local name="Echo Chamber"
    local id="echo_chamber"
    local loc_txt = {
        name = name,
        text = {
            "{C:attention}Holding{} a card in each hand triggers",
            "its {C:attention}end of round{} effect",
        }
    }
    local this_v = SMODS.Voucher{
        name=name, key=id,
        config={rarity=2,extra=3},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=10, unlocked=true, discovered=true, available=true, requires={MOD_PREFIX_V..'echo_wall'}
    }
    handle_atlas(id,this_v)
    this_v.loc_vars = function(self, info_queue, center)
        return {vars={center.ability.extra}}
    end
    handle_register(this_v)


    -- echo wall triggering end of round effect on discarded card is in lovely.toml
    -- echo chamber triggering end of round effect on held card is in lovely.toml

    

end -- echo wall
do 
end -- laminator


    -- ################
    -- fusion vouchers!
do
    if not G.ARGS.LOC_COLOURS then loc_colour() end
    if not G.ARGS.LOC_COLOURS["fusion"] then G.ARGS.LOC_COLOURS["fusion"] = HEX("F7D762") end
    local card_h_popupref = G.UIDEF.card_h_popup
    function G.UIDEF.card_h_popup(card)
        local retval = card_h_popupref(card)
        if not card.config.center or -- no center
        (card.config.center.unlocked == false and not card.bypass_lock) or -- locked card
        card.debuff or -- debuffed card
        (not card.config.center.discovered and ((card.area ~= G.jokers and card.area ~= G.consumeables and card.area) or not card.area)) -- undiscovered card
        then return retval end
        
        if card.ability.set=='Voucher' then
            local index=1
            if SMODS.Mods and SMODS.Mods["CelesteCardCollection"]then
                index=2--CelesteCardsCollection mod compat
            end

            if not retval or not retval.nodes or not retval.nodes[index] or not retval.nodes[index].nodes or not retval.nodes[index].nodes[1] or not retval.nodes[index].nodes[1].nodes or not retval.nodes[index].nodes[1].nodes[1] or not retval.nodes[index].nodes[1].nodes[1].nodes then 
                return retval
            end
            local ret=retval.nodes[index].nodes[1].nodes[1].nodes

            local index=card.config and card.config.center and card.config.center.config and card.config.center.config.rarity or 1
            index=normalize_rarity(index)
            local card_type=({localize('k_common'), localize('k_uncommon'), localize('k_rare'), localize('k_legendary')})[index]
            table.insert(ret[#ret].nodes,2,create_badge(card_type,G.C.RARITY[index],nil,1.2)) -- add voucher rarity badge
            
            if card.config.center.mod_name=='Betmma Vouchers' and card.config.center.requires and #card.config.center.requires>1 then
                if not ret[#ret] or not ret[#ret].nodes or not ret[#ret].nodes[1] or not ret[#ret].nodes[1].nodes or not ret[#ret].nodes[1].nodes[1] or not ret[#ret].nodes[1].nodes[1].nodes or not ret[#ret].nodes[1].nodes[1].nodes[2] or not ret[#ret].nodes[1].nodes[1].nodes[2].config or not ret[#ret].nodes[1].nodes[1].nodes[2].config.object or not ret[#ret].nodes[1].nodes[1].nodes[2].config.object.remove then 
                    return retval
                end
                ret[#ret].nodes[1].nodes[1].nodes[2].config.object:remove()
                ret[#ret].nodes[1] = create_badge(localize('k_fusion_voucher'), loc_colour("fusion", nil), nil, 1.2) -- add Fusion Voucher badge
            end

        end

        return retval
    end
end -- add Fusion Voucher badge for fusions and rarity badge for all vouchers

do 
end -- gold round up
do 
end -- overshopping
do 
    local name="Reroll Cut"
    local id="reroll_cut"
    local loc_txt = {
        name = name,
        text = {
            "Rerolling {C:attention}Boss Blind{}",
            "also rerolls tags, and",
            "gives a random tag",
            "{C:inactive}(Director's Cut + Reroll Surplus)"
        }
    }
    local this_v = SMODS.Voucher{
        name=name, key=id,
        config={},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=10, unlocked=true, discovered=true, available=true, requires={'v_directors_cut','v_reroll_surplus'}
    }
    handle_atlas(id,this_v)
    this_v.loc_vars = function(self, info_queue, center)
        return {vars={}}
    end
    handle_register(this_v)

    local G_FUNC_reroll_boss_ref =  G.FUNCS.reroll_boss
    G.FUNCS.reroll_boss = function(e) 
        if G.STATE~=G.STATES.BLIND_SELECT then return end
        G_FUNC_reroll_boss_ref(e)
        
        if used_voucher('reroll_cut') then -- adding a pack tag when in a pack causes double pack and will crash
            stop_use()
            if G.GAME.round_resets.blind_states.Small ~= 'Defeated' then 
                G.GAME.round_resets.blind_tags.Small = get_next_tag_key()
                --create_UIBox_blind_choice('Small', true)
            end
            if G.GAME.round_resets.blind_states.Big ~= 'Defeated' then 
                G.GAME.round_resets.blind_tags.Big = get_next_tag_key()
                --create_UIBox_blind_choice('Big', true)
            end
            local random_tag_key = get_next_tag_key()
            while random_tag_key == 'tag_boss' do -- reroll boss tag will cause double blind select box
                random_tag_key = get_next_tag_key()
            end
            if not G.GAME.orbital_choices[G.GAME.round_resets.ante][type] then -- orbital tag
                local _poker_hands = {}
                for k, v in pairs(G.GAME.hands) do
                    if v.visible then _poker_hands[#_poker_hands+1] = k end
                end
            
                G.GAME.orbital_choices[G.GAME.round_resets.ante]['Small'] = pseudorandom_element(_poker_hands, pseudoseed('orbital'))
              end
            local random_tag=Tag(random_tag_key,false,'Small')
        
            if G.blind_select then G.blind_select:remove()end
            G.blind_prompt_box:remove()
            G.blind_select = nil
            G.STATE_COMPLETE=false
            
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                func = (function() 
                    
                add_tag(random_tag)
                    return true end)
            }))
            --create_UIBox_blind_select()
        end
    end
end -- reroll cut
do 
end -- vanish magic
do 
end -- darkness
do
end -- double planet
do
end -- trash picker
do
end -- money target
do
end -- art gallery
do
end -- b1ginf
do
    local name="Slate"
    local id="slate"
    local loc_txt = {
        name = name,
        text = {
            "Permanently increase {C:attention}Stone Card{}",
            "bonus by {C:blue}+#1#{} Chips",
            "Select any number of {C:attention}Stone Cards{}", 
            "when playing a hand",
            "{C:inactive}(Petroglyph + Bonus+){}"
        }
    }
    local this_v = SMODS.Voucher{
        name=name, key=id,
        config={extra=100},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=10, unlocked=true, discovered=true, available=true, requires={'v_petroglyph',MOD_PREFIX_V..'bonus_plus'}
    }
    handle_atlas(id,this_v)
    this_v.loc_vars = function(self, info_queue, center)
        return {vars={center.ability.extra}}
    end
    handle_register(this_v)

    local Card_apply_to_run_ref = Card.apply_to_run
    function Card:apply_to_run(center)
        local center_table = {
            name = center and center.name or self and self.ability.name,
            extra = center and center.config.extra or self and self.ability.extra
        }
        if center_table.name == 'Slate' then
            G.P_CENTERS.m_stone.config.bonus=G.P_CENTERS.m_stone.config.bonus+get_voucher('slate').config.extra
            for k, v in pairs(G.playing_cards) do
                if v.config.center_key == 'm_stone' then
                    v.ability.bonus = v.ability.bonus + get_voucher('slate').config.extra
                end
            end
        end
        Card_apply_to_run_ref(self, center)
    end

    local G_FUNCS_can_play_ref=G.FUNCS.can_play
    G.FUNCS.can_play = function(e)
        G_FUNCS_can_play_ref(e)
        if used_voucher('slate') then
            local stone=0
            for k, val in ipairs(G.hand.highlighted) do
                if val.ability.name == 'Stone Card' then stone=stone + 1 end
            end
            if not G.GAME.blind.block_play and #G.hand.highlighted >0 and #G.hand.highlighted<=5+stone then
                e.config.colour = G.C.BLUE
                e.config.button = 'play_cards_from_highlighted'
            end
        end
    end

    local CardArea_add_to_highlighted_ref=CardArea.add_to_highlighted
    function CardArea:add_to_highlighted(card, silent)
        if used_voucher('slate') and self.config.type ~='shop' and self.config.type ~='joker' and self.config.type ~='consumeable' then
            local stone=0
            for k, val in ipairs(self.highlighted) do
                if val.ability.name == 'Stone Card' then stone=stone + 1 end
            end
            if #self.highlighted < stone+self.config.highlighted_limit or card.ability.name=='Stone Card' then
                self.highlighted[#self.highlighted+1] = card
                card:highlight(true)
                if not silent then play_sound('cardSlide1') end
                self:parse_highlighted()
                return
            end
        end
        CardArea_add_to_highlighted_ref(self,card,silent)
    end

    -- local G_FUNCS_draw_from_deck_to_hand_ref=G.FUNCS.draw_from_deck_to_hand
    -- G.FUNCS.draw_from_deck_to_hand = function(e) -- failed :(
        
    --     G_FUNCS_draw_from_deck_to_hand_ref(e)
    --     if used_voucher('slate') then
    --         delay(1.51)
    --         local stone=0
    --         for k, val in ipairs(G.hand.cards) do
    --             if val.ability.name == 'Stone Card' then stone=stone + 1 end
    --         end
    --         print('fhkkc',#G.hand.cards)
    --         local deck_cards=#G.deck.cards
    --         local hand_cards=#G.hand.cards
    --         while deck_cards>0 and G.hand.config.card_limit+stone - hand_cards>0 do
    --             draw_card(G.deck,G.hand, 0,'up', true)
    --             hand_cards=hand_cards+1
    --             deck_cards=deck_cards-1
    --         end
    --     end
    -- end

end -- slate
do
end -- gilded glider
do
end -- mirror
do
end -- real random
do
end -- 4d vouchers
do
    local name="Recycle Area"
    local id="recycle_area"
    local loc_txt = {
        name = name,
        text = {
            "You can {C:red}discard",
            "your hand once when",
            "opening a {C:tarot}Tarot Pack{}",
            "or {C:spectral}Spectral Pack{}",
            "{C:inactive}(Reserve Area + Wasteful){}"
        }
    }
    local this_v = SMODS.Voucher{
        name=name, key=id,
        config={},
        pos={x=0,y=0}, loc_txt=loc_txt,
        cost=10, unlocked=true, discovered=true, available=true, requires={MOD_PREFIX_V..'reserve_area','v_wasteful'}
    }
    handle_atlas(id,this_v)
    this_v.loc_vars = function(self, info_queue, center)
        return {vars={}}
    end
    handle_register(this_v)

    -- below 2 injections are useless in latest SMOD due to it taking ownership of vanilla packs and no longer calling create_UIBox series. A lovely patch is used in lovely.toml.
    local create_UIBox_spectral_pack_ref=create_UIBox_spectral_pack
    function create_UIBox_spectral_pack()
        local t=create_UIBox_spectral_pack_ref()
        if used_voucher('recycle_area') then
            local new={n=G.UIT.C,config={align = "tm",padding = 0.2, minh = 1.2, minw = 1.8, r=0.15,colour = G.C.RED, one_press = true, button = 'uselessLOL discard_booster', hover = true,shadow = true, func = 'can_discard_booster'}, nodes = {
                {n=G.UIT.T, config={text = localize('b_discard'), scale = 0.5, colour = G.C.WHITE, shadow = true, focus_args = {button = 'y', orientation = 'bm'}, func = 'set_button_pip'}}
              }}
            table.insert(t.nodes[1].nodes[3].nodes[3].nodes,2,new)
        end
        return t
    end
    local create_UIBox_arcana_pack_ref=create_UIBox_arcana_pack
    function create_UIBox_arcana_pack()
        local t=create_UIBox_arcana_pack_ref()
        if used_voucher('recycle_area') then
            local new={n=G.UIT.C,config={align = "tm",padding = 0.2, minh = 1.2, minw = 1.8, r=0.15,colour = G.C.RED, one_press = true, button = 'uselessLOL discard_booster', hover = true,shadow = true, func = 'can_discard_booster'}, nodes = {
                {n=G.UIT.T, config={text = localize('b_discard'), scale = 0.5, colour = G.C.WHITE, shadow = true, focus_args = {button = 'y', orientation = 'bm'}, func = 'set_button_pip'}}
              }}
            table.insert(t.nodes[1].nodes[3].nodes[3].nodes,2,new)
        end
        return t
    end

    G.FUNCS.discard_booster=function()
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay =  0,
            func = function() 
                G.FUNCS.draw_from_hand_to_discard()
                return true
            end}))  
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay =  0,
            func = function() 
                local hand_space = math.min(#G.deck.cards, G.hand.config.card_limit)
                
                for i=1, hand_space do --draw cards from deckL
                    draw_card(G.deck,G.hand, i*100/hand_space,'up',true)
                end
                return true
            end}))  
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay =  0,
            func = function() 
                G.FUNCS.draw_from_discard_to_deck()
                return true
            end}))  
        return true
        
    end

    G.FUNCS.can_discard_booster=function(e)
        if #G.hand.cards>0 and #G.deck.cards>0 then
            e.config.colour = G.C.RED
            e.config.button='discard_booster'
        else
            e.config.colour = G.C.UI.BACKGROUND_INACTIVE
            e.config.button = nil
        end
    end


end -- recycle area
do
end -- chaos
do
end -- heat death
do
end -- deep roots
do
end -- solar system
do
end -- forbidden area
do
end -- voucher tycoon
do
end -- cryptozoology
do
end -- reroll aisle
function copy_table(O)
    local O_type = type(O)
    local copy
    if O_type == 'table' then
        copy = {}
        for k, v in next, O, nil do
            copy[copy_table(k)] = copy_table(v)
        end
        setmetatable(copy, getmetatable(O))
    else
        copy = O
    end
    return copy
end
    BETMMA_DEBUGGING=0
    local PATH=GET_PATH_COMPAT()
    if not NFS.load(PATH .. "debug_on") then
        BETMMA_DEBUGGING=false
    end
    -- this challenge is only for test
    if BETMMA_DEBUGGING then
        
        table.insert(G.CHALLENGES,1,{
            name = "TestVoucher",
            id = 'c_mod_testvoucher',
            rules = {
                custom = {
                },
                modifiers = {
                    {id = 'dollars', value = 2000},
                }
            },
            jokers = {
                --{id = 'j_jjookkeerr'},
                -- {id = 'j_ascension'},
                -- {id = 'j_sock_and_buskin'},
                -- {id = 'j_sock_and_buskin'},
                {id = 'j_oops'},
                {id = 'j_oops'},
                -- {id = 'j_baron',  edition='phantom'},
                -- {id = 'j_brainstorm', edition='phantom'},
                -- {id = JOKER_MOD_PREFIX..'j_gameplay_update', edition='phantom'},
                -- {id = JOKER_MOD_PREFIX..'j_friends_of_jimbo', },
                {id = 'j_mmc_harp_seal', },
                -- {id = 'j_madness', eternal = true},
                {id = JOKER_MOD_PREFIX..'j_balatro_mobile'},
                -- {id = 'j_lobc_happy_teddy_bear'}--, pinned = true},
            },
            consumeables = {
                -- {id = 'c_cryptid'},
                -- {id = 'c_cry_Klubi'},
                -- {id = 'c_cry_Klubi'},
                -- {id = 'c_cry_Klubi'},
                -- {id = 'c_cry_Klubi'},
                -- {id = 'c_cry_Klubi'},
                -- {id = 'c_cry_Klubi'},
                {id = 'c_incantation'},
                {id = 'c_hanged_man'},
                {id='c_betm_abilities_enhancer',negative=true},
                -- {id='c_betm_abilities_enhancer'},
                -- {id='c_betm_abilities_enhancer'},
                -- {id='c_betm_abilities_enhancer'},
                -- {id='c_betm_abilities_endoplasm'},
            },
            vouchers = {
                {id = MOD_PREFIX_V.. '3d_boosters'},
                {id = MOD_PREFIX_V.. '4d_boosters'},
                {id = 'v_crystal_ball'},
                -- -- {id = 'v_liquidation'},
                {id = 'v_overstock_norm'},
                {id = 'v_overstock_plus'},
                {id = 'v_overstock_plus'},
                {id = 'v_overstock_plus'},
                {id = MOD_PREFIX_V.. 'omnicard'},
                -- {id = MOD_PREFIX_V.. 'flipped_card'},
                {id = 'v_betm_spells_magic_scroll'},
                {id = 'v_betm_spells_magic_wheel'},
                {id = MOD_PREFIX_V.. 'flipped_card'},
                {id = MOD_PREFIX_V.. 'double_flipped_card'},
                {id = MOD_PREFIX_V.. 'recycle_area'},
                -- {id = 'v_retcon'},
                
            },
            deck = {
                type = 'Challenge Deck',
                cards = {{s='D',r='2',g='Red'},{s='D',r='3',e='m_glass',g='Red'},{s='D',r='4',g='Blue'},{s='D',r='5',g='Red'},{s='D',r='6',g='Red'},{s='D',r='7',e='m_lucky',},{s='D',r='7',e='m_lucky',},{s='D',r='7',e='m_lucky',},{s='D',r='8',e='m_gold',},{s='D',r='9',e='m_lucky',},{s='D',r='T',e='m_wild',},{s='D',r='J',e='m_lucky',},{s='D',r='Q',e='m_lucky',g='Red'},{s='D',r='Q',e='m_wild',g='Red'},{s='D',r='K',e='m_wild'},{s='D',r='Q',e='m_steel',g='Red'},{s='D',r='K',e='m_steel',g='Red'},{s='D',r='K',e='m_steel',g='Red'},{s='D',r='A',e='m_steel',g='Red',d='negative'},}
            },
            restrictions = {
                banned_cards = {
                },
                banned_tags = {
                },
                banned_other = {
                }
            }
        })
    end
    init_localization()
end

if LoopVoucher and LoopVoucher.AddLoopableVoucher then -- loop mod compatibility
    AddLoopableVoucher=LoopVoucher.AddLoopableVoucher
	AddLoopableVoucher('v_betm_vouchers_gold_coin')
	AddLoopableVoucher('v_betm_vouchers_gold_bar')
	AddLoopableVoucher('v_betm_vouchers_abstract_art')
	AddLoopableVoucher('v_betm_vouchers_mondrian')
	AddLoopableVoucher('v_betm_vouchers_bonus_plus')
	AddLoopableVoucher('v_betm_vouchers_mult_plus')
end


if IN_SMOD1 then
    INIT()
else
    SMODS['INIT']=SMODS['INIT'] or {}
    SMODS['INIT']['BetmmaVouchers']=function()
        SMODS.Voucher=SMODS_Voucher_fake
        INIT()
        SMODS.Voucher=SMODS_Voucher_ref
        SMODS.current_mod.process_loc_text()
    end
    
end
----------------------------------------------
------------MOD CODE END----------------------
end
