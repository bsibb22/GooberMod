-- values that should be consistent throughout the whole game
global = {
	timestable_rank = 14,
	timestable_reset = false,
	wordsearch_ranks = {3, 4, 5},
	wordsearch_reset = false,
	foods = {
		"j_egg", "j_ice_cream", "j_gros_michel", "j_cavendish", "j_turtle_bean", "j_diet_cola", "j_popcorn", "j_ramen", "j_selzer"
	},
	nim_tags = {
		'uncommon', 'rare', 'negative', 'foil', 'holo', 'polychrome', 'investment', 'voucher', 'boss', 'standard',
		'charm', 'meteor', 'buffoon', 'handy', 'garbage', 'ethereal', 'coupon', 'juggle', 'd_six', 'top_up', 'skip',
		'orbital', 'economy'
	},
	uno_suit = 'Spades',
	uno_color = G.C.SUITS.Spades
}

-- UTILITY FUNCTIONS --
function id_to_rank(base_id)
	if base_id >= 2 and base_id <= 10 then
		return base_id
	elseif base_id == 11 then
		return 'Jack'
	elseif base_id == 12 then
		return 'Queen'
	elseif base_id == 13 then
		return 'King'
	elseif base_id == 14 then
		return 'Ace'
	else
		return 0
	end
end

-- used for changing the suit for the uno wildcard
local function change_suit()
	local uno_card = pseudorandom_element(G.playing_cards, pseudoseed('uno'))
	if uno_card then
		global.uno_suit = uno_card.base.suit

		if global.uno_suit == 'Spades' then
			global.uno_color = G.C.SUITS.Spades
		elseif global.uno_suit == 'Hearts' then
			global.uno_color = G.C.SUITS.Hearts
		elseif global.uno_suit == 'Clubs' then
			global.uno_color = G.C.SUITS.Clubs
		elseif global.uno_suit == 'Diamonds' then
			global.uno_color = G.C.SUITS.Diamonds
		end
	end

	for _, c in pairs(G.playing_cards) do
		if c.base.suit ~= global.uno_suit then
			SMODS.debuff_card(c, true, 'uno')
		else
			SMODS.debuff_card(c, 'reset', 'uno')
		end
	end
end

-- pulls the rank of _n unique, random cards from your overall deck and returns them in a table
function get_rank(rank_pool, _n)
	_n = _n or 1
	rank_pool = rank_pool or {2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14}
	local resulting_ranks = {}
	local valid_cards = {}
	
	-- initialize return table to return all Aces
	for i = 1, _n do
		resulting_ranks[#resulting_ranks + 1] = 14
	end
	
	for k, v in ipairs(G.playing_cards) do
		for i = 1, #rank_pool do
			if v.ability.effect ~= 'Stone Card' and v.base.id == rank_pool[i] then
				valid_cards[#valid_cards + 1] = v
				break
			end
		end
	end
	
	-- was a valid card found?
	if valid_cards[_n] then
		local valids_copy = {}
		for k,v in ipairs(valid_cards) do
			valids_copy[k] = v
		end
		for i = 1, _n do
			local chosen = pseudorandom_element(valids_copy, pseudoseed('selecting_rank'..G.GAME.round_resets.ante))
			for a,b in ipairs(valids_copy) do
				if valids_copy[a] == v then
					valids_copy[a] = nil
					break
				end
			end
			resulting_ranks[i] = chosen.base.id
		end
	end
	return resulting_ranks
end

-- sprite stuff
SMODS.Atlas{
	key = 'GooberAtlas',
	path = 'goober_sprites.png',
	px = 71,
	py = 95
}

-- audio stuff
SMODS.Sound{
	key = 'curse_reveal',
	path = 'curse_reveal.ogg'
}

SMODS.Sound{
	key = 'stamp',
	path = 'trad_stamp.ogg'
}

SMODS.Sound{
	key = 'thunder',
	path = 'thunder.ogg'
}

-- JOKER TEMPLATE --
--[[

SMODS.Joker {
	key = 'some unique identifier',
	loc_txt = {
		name = 'in-game name of joker',
		text = {
			'Each line of the card's description'
				{X:mult} <- colors background to be red (mult colro)!
				{C:chips}
				#1# <- first value in config.extra
				#2# <- second value in config.extra, etc.
		}
	},
	atlas = "GooberAtlas",
	pos = {x = 0, y = 0}, -- position in spritesheet
	rarity = 1 -- 1 for common, 2 for uncommon, 3 fo rrare, 4 for legendary
	cost = 6,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	unlocked = true,
	discovered = true,
	config = {
		extra = {
			--- joker-specific values (Xmult, +chips, anything else that is important to the joker's state)
		}
	},
	loc_vars = function(self, info_queue, center)
		return {vars = {center.ability.extra.[whatever properties]}}
	end,
	calculate = function(self, card, context)
		--- scoring calculations
	end
}

]]--

-- Times Table
SMODS.Joker{
	key = 'mult-flashcard',
	loc_txt = {
		name = 'Times Table',
		text = {
			'Gain {X:mult,C:white}X#1#{} Mult if scoring',
			'hand only contains {C:attention}#3#{}s',
			'{C:inactive}(rank changes every round,',
			'{C:inactive}excludes face cards){}'
		}
	},
	atlas = 'GooberAtlas',
	pos = {x = 0, y = 0},
	rarity = 2,
	cost = 6,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	unlocked = true,
	discovered = true,
	config = {
		extra = {
			Xmult = 4,
			desired_rank = global.timestable_rank,
			rank_text = id_to_rank(global.timestable_rank)
		}
	},
	loc_vars = function(self, info_queue, center)
		return {vars = {center.ability.extra.Xmult, center.ability.extra.desired_rank, center.ability.extra.rank_text}}
	end,
	calculate = function(self,card,context)
		-- determine next blind's rank at blind start
		if context.setting_blind and not context.blueprint then
			global.timestable_reset = false
		end
		
		-- this scoring effect occurs during the regular scoring sequence
		if context.joker_main then
			local should_score = true
			-- check if any card in the scored hand's rank is not equal to the specified rank
			for i = 1, #context.scoring_hand do
				local c = context.scoring_hand[i]
				if c.base.id ~= card.ability.extra.desired_rank then
					should_score = false
				end
			end
			
			-- otherwise, set the Xmult modifier to the joker's inherent value
			if should_score then
				return {
					card = card,
					Xmult_mod = card.ability.extra.Xmult,
					message = 'X' .. card.ability.extra.Xmult .. ' Mult',
					colour = G.C.MULT
				}
			end
		end
		
		-- at end of round, change the expected rank
		if context.end_of_round and not context.blueprint then
			if not global.timestable_reset then
				global.timestable_rank = get_rank({2, 3, 4, 5, 6, 7, 8, 9, 10, 14})[1]
				card.ability.extra.desired_rank = global.timestable_rank
				card.ability.extra.rank_text = id_to_rank(global.timestable_rank)
				global.timestable_reset = true
			end
		end
	end
}

-- Time Card
SMODS.Joker{
	key = 'timecard',
	loc_txt = {
		name = 'Time Card',
		text = {
			'{C:mult}+#1#{} Mult per hand played',
			'Resets after {C:attention}#2#{} hands',
			'{C:inactive}(#3# remaining){}',
			'{C:inactive}(Currently {C:mult}+#4#{} Mult){}'
		}
	},
	atlas = 'GooberAtlas',
	pos = {x = 1, y = 0},
	rarity = 1,
	cost = 5,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	unlocked = true,
	discovered = true,
	config = {
		extra = {
			mult_per_hand = 2,
			reset_after = 5,
			hand_counter = 5,
			mult_bonus = 0
		}
	},
	loc_vars = function(self, info_queue, center) 
		return {vars = {center.ability.extra.mult_per_hand, center.ability.extra.reset_after, center.ability.extra.hand_counter, center.ability.extra.mult_bonus}}
	end,
	calculate = function(self, card, context)
		if context.before and not context.blueprint then
			card.ability.extra.mult_bonus = card.ability.extra.mult_bonus + card.ability.extra.mult_per_hand
			card.ability.extra.hand_counter = card.ability.extra.hand_counter - 1
			return {
				card = card,
				message = 'Upgrade!',
				colour = G.C.ORANGE
			}
		end
		
		if context.joker_main then
			return {
				card = card,
				mult = card.ability.extra.mult_bonus
			}
		end
		
		if context.final_scoring_step and not context.blueprint then
			if card.ability.extra.hand_counter == 0 then
				card.ability.extra.mult_bonus = 0
				card.ability.extra.hand_counter = card.ability.extra.reset_after
				return {
					message = 'Reset!',
					colour = G.C.ORANGE
				}
			end
		end
	end
}

-- New Year's Envelope (Otoshidama)
SMODS.Joker{
	key = 'otoshidama',
	loc_txt = {
		name = "New Year's Envelope",
		text = {
			"Every {C:attention}#3#{} played hands or",
			"used discards, earn {C:attention}$#1#{}",
			"{C:inactive}(#2# remaining){}"
		}
	},
	atlas = "GooberAtlas",
	pos = {x = 2, y = 0},
	rarity = 2,
	cost = 6,
	blueprint_compat = false,
	eternal_compat = false,
	perishable_compat = true,
	unlocked = true,
	discovered = true,
	config = {
		extra = {
			payout = 7,
			counter = 12,
			reset_to = 12
		}
	},
	loc_vars = function(self, info_queue, center)
		return {vars = {center.ability.extra.payout, center.ability.extra.counter, center.ability.extra.reset_to}}
	end,
	calculate = function(self, card, context)
		if (context.before or context.pre_discard) and not context.blueprint then
			card.ability.extra.counter = card.ability.extra.counter - 1
			if card.ability.extra.counter == 0 then
				card.ability.extra.counter = card.ability.extra.reset_to
				return {
					card = card,
					dollars = card.ability.extra.payout
				}
			end
			return {
				message = "+1 Month"
			}
		end
	end
}

-- Counterfeit
SMODS.Joker{
	key = 'counterfeit',
	loc_txt = {
		name = "Counterfeit",
		text = {
			'Played cards give {C:chips}+#1#{} Chips',
			'and {C:mult}+#2#{} Mult when scored',
			'{C:green,E:2}#3# in #4#{} chance to {C:red,E:2}self',
			'{C:red,E:2}destruct{} after hand scores'
		}
	},
	atlas = 'GooberAtlas',
	pos = {x = 3, y = 0},
	rarity = 2,
	cost = 1,
	blueprint_compat = true,
	eternal_compat = false,
	perishable_compat = true,
	unlocked = true,
	discovered = true,
	config = {
		extra = {
			chip_bonus = 10,
			mult_bonus = 1,
			destroy_odds = 6
		}
	},
	loc_vars = function(self, info_queue, center)
		return {vars = {center.ability.extra.chip_bonus, center.ability.extra.mult_bonus, G.GAME.probabilities.normal, center.ability.extra.destroy_odds}}
	end,
	calculate = function(self, card, context)
		if context.individual and context.cardarea == G.play then
			return {
				card = card,
				chips = card.ability.extra.chip_bonus,
				mult = card.ability.extra.mult_bonus
			}
		end
		
		if context.final_scoring_step and not context.blueprint then
			if pseudorandom('counterfeit_destroy') < G.GAME.probabilities.normal / card.ability.extra.destroy_odds then
				G.E_MANAGER:add_event(Event({
				func = function()
					play_sound('tarot1')
					G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.3, blockable = false,
					func = function()
						G.jokers:remove_card(card)
						card:remove()
						card = nil
						return true; end}))
					return true
				end}))
				card.gone = true
				return {
					message = 'Destroyed!'
				}
			end
			return {
				message = 'Safe!'
			}
		end
	end
}

-- Vending Machine
SMODS.Joker{
	key = 'vending_machine',
	loc_txt = {
		name = 'Vending Machine',
		text = {
			'Every {C:attention}3{} rounds ({C:attention}#1#{}/3),',
			'create {C:attention}2{} random {C:attention}Food{}',
			'{C:attention}Jokers{}',
			'{C:inactive}(Must have room)'
		}
	},
	atlas = "GooberAtlas",
	pos = {x = 4, y = 0},
	rarity = 3,
	cost = 9,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	unlocked = true,
	discovered = true,
	config = {
		extra = {
			round_counter = 3,
			incremented = false
		}
	},
	loc_vars = function(self, info_queue, center)
		return {vars = {center.ability.extra.round_counter}}
	end,
	-- code mostly ripped from Riff-Raff
	calculate = function(self, card, context)
		if context.setting_blind then
			card.ability.extra.incremented = false
			if card.ability.extra.round_counter >= 3 and #G.jokers.cards + G.GAME.joker_buffer < G.jokers.config.card_limit then
				local num_foods = math.min(2, G.jokers.config.card_limit - (#G.jokers.cards + G.GAME.joker_buffer))
				G.GAME.joker_buffer = G.GAME.joker_buffer + num_foods
				G.E_MANAGER:add_event(Event({
                    func = function() 
                        for i = 1, num_foods do
                            local card = create_card('Joker', G.jokers, nil, nil, nil, nil, pseudorandom_element(global.foods, pseudoseed("vending_machine")))
                            card:add_to_deck()
                            G.jokers:emplace(card)
                            card:start_materialize()
                            G.GAME.joker_buffer = 0
                        end
                        return true
                    end}))
				card.ability.extra.round_counter = 0
				return {
					message = "Dispensed!"
				}
			end
		end
			
		if context.end_of_round and not context.blueprint and not card.ability.extra.incremented then
			card.ability.extra.round_counter = card.ability.extra.round_counter + 1
			card.ability.extra.incremented = true
		end
	end
}

-- Word Search
SMODS.Joker{
	key = 'word_search',
	loc_txt = {
		name = "Word Search",
		text = {
			'If ranks of played hand',
			'contain the sequence',
			'{C:attention}#5#{}, {C:attention}#6#{}, {C:attention}#7#{}, earn {C:attention}$#4#{}',
			'{C:inactive,s:0.8}(Ranks change every round)'
		}
	},
	atlas = "GooberAtlas",
	pos = {x = 5, y = 0},
	rarity = 1,
	cost = 6,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	unlocked = true,
	discovered = true,
	config = {
		extra = {
			rank1 = global.wordsearch_ranks[1],
			rank2 = global.wordsearch_ranks[2],
			rank3 = global.wordsearch_ranks[3],
			payout = 7,
			rank_text1 = id_to_rank(global.wordsearch_ranks[1]),
			rank_text2 = id_to_rank(global.wordsearch_ranks[2]),
			rank_text3 = id_to_rank(global.wordsearch_ranks[3])
		}
	},
	loc_vars = function(self, info_queue, center)
		return {vars = {center.ability.extra.rank1, center.ability.extra.rank2, center.ability.extra.rank3, center.ability.extra.payout, center.ability.extra.rank_text1, center.ability.extra.rank_text2, center.ability.extra.rank_text3}}
	end,
	calculate = function(self, card, context)
		-- reset ranks
		if context.setting_blind and not context.blueprint then
			global.wordsearch_reset = false
		end
	
		if context.before then
			if #context.full_hand < 3 then
				return true
			end
			for i = 1, #context.full_hand - 2 do
				if context.full_hand[i].base.id == card.ability.extra.rank1 then
					if context.full_hand[i + 1].base.id == card.ability.extra.rank2 then
						if context.full_hand[i + 2].base.id == card.ability.extra.rank3 then
							return {
								card = card,
								dollars = card.ability.extra.payout
							}
						end
					end
				end
			end
		end
		
		if context.end_of_round and not context.blueprint then
			if not global.wordsearch_reset then
				global.wordsearch_ranks = get_rank({2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14}, 3)
				card.ability.extra.rank1 = global.wordsearch_ranks[1]
				card.ability.extra.rank2 = global.wordsearch_ranks[2]
				card.ability.extra.rank3 = global.wordsearch_ranks[3]
				card.ability.extra.rank_text1 = id_to_rank(global.wordsearch_ranks[1])
				card.ability.extra.rank_text2 = id_to_rank(global.wordsearch_ranks[2])
				card.ability.extra.rank_text3 = id_to_rank(global.wordsearch_ranks[3])
				global.wordsearch_reset = true
			end
		end
	end
}

-- Slot Machine
SMODS.Joker{
	key = "slot_machine",
	loc_txt = {
		name = "Slot Machine",
		text = {
			"Retrigger all played",
			"{C:attention}Lucky Cards{}"
		}
	},
	atlas = "GooberAtlas",
	pos = {x = 6, y = 0},
	rarity = 2,
	cost = 6,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	unlocked = true,
	discovered = true,
	config = {
		extra = {
			retriggers = 1,
		}
	},
	loc_vars = function(self, info_queue, center)
		return {vars = {center.ability.extra.retriggers}}
	end,
	calculate = function(self, card, context)
		if context.repetition and context.cardarea == G.play then
			if context.other_card.ability.effect == "Lucky Card" then
				return {
					message = "Again!",
					repetitions = card.ability.extra.retriggers
				}
			end
		end
	end
}

--- Jokette
SMODS.Joker{
	key = 'jokette',
	loc_txt = {
		name = 'Jokette',
		text = {
			'{C:chips} +#1#{} Chips'
		}
	},
	atlas = 'GooberAtlas',
	pos = {x = 1, y = 0}, --- Just a placeholder
	rarity = 1,
	cost = 2,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	unlocked = true,
	discovered = true,
	config = {
		extra = {
			bonus_chips = 30
		}
	},
	loc_vars = function (self, info_queue, center)
		return {vars = {center.ability.extra.bonus_chips}}	
	end,
	calculate = function(self, card, context)
		if context.joker_main then
			return {
				card = card,
				chips = card.ability.extra.bonus_chips
			}
		end
	end
}

-- Manila Folder
SMODS.Joker{
	key = "joker_folder",
	loc_txt = {
		name = "Manila Folder",
		text = {
			"Draw {C:attention}#1#{} additional",
			"cards when {C:attention}first{}",
			"hand drawn"
		}
	},
	atlas = "GooberAtlas",
	pos = {x = 2, y = 1},
	rarity = 1,
	cost = 3,
	blueprint_compat = false,
	eternal_compat = true,
	perishable_compat = true,
	unlocked = true,
	discovered = true,
	config = {
		extra = {
			h_increase = 2
		}
	},
	loc_vars = function(self, info_queue, center)
		return {vars = {center.ability.extra.h_increase}}
	end,
	calculate = function(self, card, context)
		if context.first_hand_drawn then
			for i = 1, card.ability.extra.h_increase do
				draw_card(G.deck, G.hand, 1, 'up', false, nil, nil, false)
			end
			return {
				message = "Draw "..card.ability.extra.h_increase.."!",
			}
		end
	end
}

-- Cursed Joker
SMODS.Joker{
	key = "joker_cursed",
	loc_txt = {
		name = "Cursed Joker",
		text = {}
	},
	atlas = "GooberAtlas",
	pos = {x = 0, y = 1},
	rarity = 3,
	cost = 8,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	unlocked = true,
	discovered = false,
	config = {
		extra = {
			h_reduction = 2,
			xmult = 1,
			xmult_mod = 0.5,
			side = 0,
			flipped = false
		}
	},
	loc_vars = function(self, info_queue, center)
		local vars = {center.ability.extra.h_reduction, center.ability.extra.xmult_mod, center.ability.extra.xmult}
		local side_nodes = {}
		localize{type = 'descriptions', set = 'Joker', key = 'j_goob_joker_cursed_'..(center.ability.extra.side), nodes = side_nodes, vars = vars, scale = 1.0}
		
		local main_end = {
			{n = G.UIT.R, config = {align = "cm"}, nodes = side_nodes[1]},
			{n = G.UIT.R, config = {align = "cm"}, nodes = side_nodes[2]},
			{n = G.UIT.R, config = {align = "cm"}, nodes = side_nodes[3]},
			{n = G.UIT.R, config = {align = "cm"}, nodes = side_nodes[4]},
		}
		return {vars = {center.ability.extra.h_reduction, center.ability.extra.xmult_mod, center.ability.extra.xmult}, main_end = main_end}
	end,
	add_to_deck = function(self, card, from_debuff)
		G.hand:change_size(-card.ability.extra.h_reduction)
	end,
	calculate = function(self, card, context)
		if context.setting_blind and G.GAME.blind:get_type() == 'Boss' then
			play_sound('card1')
			card:flip()
			card.ability.extra.flipped = true
			delay(0.4)
			G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.4, func = function()
				card.children.center:set_sprite_pos({x = 1, y = 1})
				card.ability.extra.side = 1
				play_sound('card3')
				G.hand:change_size(card.ability.extra.h_reduction)
				card:flip()
				delay(0.4)
				play_sound('goob_curse_reveal')
			return true end }))
		end
		
		if context.using_consumeable and card.ability.extra.side == 1 then
			card.ability.extra.xmult = card.ability.extra.xmult + card.ability.extra.xmult_mod
			play_sound('card1')
			return {
				message = 'Upgrade!'
			}
		end
		
		if context.joker_main and card.ability.extra.side == 1 then
			return {
				card = card,
				Xmult_mod = card.ability.extra.xmult,
				message = 'X' .. card.ability.extra.xmult .. ' Mult',
				colour = G.C.MULT
			}
		end
		
		if context.end_of_round and G.GAME.blind:get_type() == 'Boss' and card.ability.extra.flipped then
			play_sound('card1')
			card:flip()
			card.ability.extra.flipped = false
			delay(0.4)
			G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.4, func = function()
				card.children.center:set_sprite_pos({x = 0, y = 1})
				card.ability.extra.side = 0
				play_sound('card3')
				G.hand:change_size(-card.ability.extra.h_reduction)
				card:flip()
			return true end }))
		end
		
		if context.selling_self and card.ability.extra.side == 0 and not context.blueprint then
			G.hand:change_size(card.ability.extra.h_reduction)
		end
	end
}

-- Engineer
SMODS.Joker{
	key = 'engineer',
	loc_txt = {
		name = 'Engineer',
		text = {
			'{C:green} #1# in #2#{} cards are drawn',
			'face down. Face down',
			'cards give {X:mult,C:white} X 1 . 5 {} Mult when',
			'scored'
		}
	},
	atlas = 'GooberAtlas',
	pos = {x = 1, y = 0}, -- Placeholder art
	rarity = 2,
	cost = 6,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	unlocked = true,
	discovered = true,
	config = {
		extra = {
			odds = 4,
			Xmult = 1.5
		}
	},
	loc_vars = function(self, info_queue, center)
		return {vars = {G.GAME.probabilities.normal or 1, center.ability.extra.odds, center.ability.extra.Xmult}}
	end,
	add_to_deck = function(self, card, from_debuff)
		G.GAME.modifiers.flipped_cards = 4
	end,
	remove_from_deck = function (self, card, from_debuff)
		G.GAME.modifiers.flipped_cards = nil
	end,
	calculate = function (self, card, context)
		if (context.setting_blind or context.hand_drawn) and not context.blueprint then
			global.flipped_cards = {}
			global.engineer_ret_mult = 1
			for _, c in pairs(G.hand.cards) do
				if c.facing == 'back' then
					global.flipped_cards[_] = true
					c.id = _
				end
			end
		end

		if context.individual and context.cardarea == G.play then
			if context.other_card.id ~= nil then
				if global.flipped_cards[context.other_card.id] then
					return {
						xmult = card.ability.extra.Xmult
					}
				end
			end
		end
	end
}

-- Stampbook
SMODS.Joker{
	key = 'stampbook',
	loc_txt = {
		name = 'Stampbook',
		text = {
			'If {C:attention}first hand{} of round',
			'has only {C:attention}1{} card, add',
			'a random {C:attention}seal{} to it'
		}
	},
	atlas = 'GooberAtlas', -- Placeholder art
	pos = {x = 1, y = 0},
	rarity = 3,
	cost = 7,
	blueprint_compat = false,
	perishable_compat = true,
	unlocked = true,
	discovered = true,
	config = {},
	loc_vars = function (self, info_queue, center) return {vars = {}} end,
	calculate = function(self, card, context)
		if context.first_hand_drawn and not context.blueprint then
			local eval = function() return G.GAME.current_round.hands_played == 0 and not G.RESET_JIGGLES end
			juice_card_until(card, eval, true)
		end

		if context.before and not context.blueprint and G.GAME.current_round.hands_played == 0 and #context.full_hand == 1 then
			local played_card = context.scoring_hand[1]
			return {
				message = 'Stamp!',
				message_card = played_card,
				colour = G.C.EDITION,
				func = function()
					G.E_MANAGER:add_event(Event({
						func = function ()
							play_sound('goob_stamp', 1, 1.5)
							played_card:set_seal(SMODS.poll_seal({ guaranteed = true, type_key = 'gungaga' }))
							played_card:juice_up(0.3, 0.4)
							return true
						end
					}))
				end
			}
		end
	end
}

-- Cowboy
SMODS.Joker{
	key = 'cowboy',
	loc_txt = {
		name = 'Cowboy',
		text = {
			'{X:mult,C:white} X #1# {} Mult on first',
			'hand of round'
		}
	},
	atlas = 'GooberAtlas',
	pos = {x = 1, y = 0}, -- Placeholder art
	rarity = 2,
	cost = 6,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	unlocked = true,
	discovered = true,
	config = {
		extra = {
			Xmult = 2
		}
	},
	loc_vars = function (self, info_queue, center)
		return {vars = { center.ability.extra.Xmult }}
	end,
	calculate = function (self, card, context)
		if context.joker_main and G.GAME.current_round.hands_played == 0 then
			return {
				xmult = card.ability.extra.Xmult
			}
		end
	end
}

-- Pythagoras
SMODS.Joker{
	key = 'pythagoras',
	loc_txt = {
		name = 'Pythagoras',
		text = {
			'{X:mult,C:white} X #1# {} Mult if {C:attention}played hand{}',
			'contains a scoring {C:attention}3{}, {C:attention}4{}, and {C:attention}5'
		}
	},
	atlas = 'GooberAtlas',
	pos = {x = 3, y = 1},
	rarity = 2,
	cost = 6,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	unlocked = true,
	discovered = true,
	config = {
		extra = {
			Xmult = 3
		}
	},
	loc_vars = function (self, info_queue, center)
		return {vars = { center.ability.extra.Xmult }}
	end,
	calculate = function (self, card, context)
		if context.joker_main then
			local has_3, has_4, has_5
			for _, c in pairs(context.scoring_hand) do
				if c:get_id() == 3 then
					has_3 = true
				elseif c:get_id() == 4 then
					has_4 = true
				elseif c:get_id() == 5 then
					has_5 = true
				end
			end
			if has_3 and has_4 and has_5 then
				return {
					xmult = card.ability.extra.Xmult
				}
			end
		end
	end
}

-- +4/uno wildcard
SMODS.Joker{
	key = '+4',
	loc_txt = {
		name = '+4',
		text = {
			'{C:attention}+#1#{} hand size. All cards',
			'except {V:1}#2#{}',
			'are {C:red,E:1}debuffed{}, suit',
			'changes every round'
		}
	},
	atlas = 'GooberAtlas',
	pos = {x = 4, y = 1},
	rarity = 2,
	cost = 6,
	blueprint_compat = false,
	eternal_compat = true,
	perishable_compat = true,
	unlocked = true,
	discovered = true,
	config = {
		extra = {
			change_size = 4
		}
	},
	loc_vars = function (self, info_queue, center)
		return {vars = { center.ability.extra.change_size, global.uno_suit, colours = { global.uno_color } }}
	end,
	add_to_deck = function (self, card, from_debuff)
		change_suit();
		G.hand:change_size(card.ability.extra.change_size)
	end,
	remove_from_deck = function (self, card, from_debuff)
		G.hand:change_size(-card.ability.extra.change_size)
		for _, c in pairs(G.playing_cards) do
			SMODS.debuff_card(c, 'reset', 'uno')
		end
	end,
	calculate = function (self, card, context)
		if context.end_of_round then
			change_suit()
		end
	end
}

SMODS.Joker{
	key = "nimbo",
	loc_txt = {
		name = "Nimbo",
		text = {
			"If {C:attention}final hand{} of round",
			"beats the {C:attention}Blind{}, generate",
			"a random {C:attention}Tag{}"
		}
	},
	atlas = "GooberAtlas",
	pos = {x = 5, y = 1},
	rarity = 1,
	cost = 5,
	blueprint_compat = false,
	eternal_compat = true,
	perishable_compat = true,
	discovered = true,
	config = {
		extra = {
			tag_generated = false
		}
	},
	loc_vars = function(self, info_queue, center)
		return {vars = {center.ability.extra.tag_generated}}
	end,
	calculate = function(self, card, context)
		if context.setting_blind then
			card.ability.extra.tag_generated = false
		end
		
		if context.end_of_round and G.GAME.current_round.hands_left == 0 and not card.ability.extra.tag_generated then
			local n_tag = "tag_"..(pseudorandom_element(global.nim_tags, pseudoseed("nimtag")))
			G.E_MANAGER:add_event(Event({
                func = (function()
                    add_tag(Tag(n_tag))
                    play_sound('generic1', 0.9 + math.random()*0.1, 0.8)
                    play_sound('holo1', 1.2 + math.random()*0.1, 0.4)
                    return true
				end)
            }))
			card.ability.extra.tag_generated = true
			return {
				message = "Tagged!",
				colour = G.C.BLUE
			}
		end
	end
}

SMODS.Joker{
	key = 'gambler',
	loc_txt = {
		name = 'Gambler',
		text = {
			'{C:attention}Lucky{} card triggers give',
			'{X:mult,C:white}X #1#{} Mult in addition'
		}
	},
	atlas = 'GooberAtlas',
	pos = {x = 1, y = 0},
	rarity = 3,
	cost = 8,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	unlocked = true,
	discovered = true,
	config = {
		extra = {
			Xmult = 2
		}
	},
	loc_vars = function (self, info_queue, center)
		return {vars = { center.ability.extra.Xmult }}
	end,
	calculate = function (self, card, context)
		if context.individual and context.cardarea == G.play and context.other_card.lucky_trigger then
			return {
				xmult = card.ability.extra.Xmult
			}
		end
	end
}

SMODS.Joker{
	key = 'the_daus',
	loc_txt = {
		name = 'The Daus',
		text = {
			'{C:attention}Retrigger{} the {C:attention}highest{}',
			'ranked card(s) scored',
			'in played hand'
		}
	},
	atlas = 'GooberAtlas',
	pos = {x = 1, y = 0}, -- Placeholder art
	rarity = 3,
	cost = 7,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	unlocked = true,
	discovered = true,
	config = {
		extra = {
			repetitions = 1
		}
	},
	loc_vars = function (self, info_queue, center)
		return {vars = { center.ability.extra.center }}
	end,
	calculate = function (self, card, context)
		if context.repetition and context.cardarea == G.play then
			local highest_rank = 2
			for _, c in pairs(context.scoring_hand) do
				if highest_rank <= c.base.id and not SMODS.has_no_rank(c) then highest_rank = c.base.id end
			end
			if context.other_card.base.id == highest_rank and not SMODS.has_no_rank(context.other_card) then
				return {
					repetitions = card.ability.extra.repetitions
				}
			end
		end
	end
}

SMODS.Joker{
	key = 'rolling_stone',
	loc_txt = {
		name = 'Rolling Stone',
		text = {
			'This Joker gains {X:mult,C:white}X #1#{}',
			'Mult per {C:attention}reroll{} in the shop,',
			'resets at the {C:attention}end of round{}',
			'{C:inactive} (Currently{} {X:mult,C:white}X #2#{} {C:inactive}Mult){}'
		}
	},
	atlas = 'GooberAtlas',
	pos = {x = 1, y = 0}, -- Placeholder art
	rarity = 2,
	cost = 7,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	unlocked = true,
	discovered = true,
	config = {
		extra = {
			Xmult_mod = 0.25,
			Xmult_bonus = 1
		}
	},
	loc_vars = function (self, info_queue, center)
		return {vars = {center.ability.extra.Xmult_mod, center.ability.extra.Xmult_bonus}}
	end,
	calculate = function (self, card, context)
		if context.reroll_shop and not context.blueprint then
			card.ability.extra.Xmult_bonus = card.ability.extra.Xmult_bonus + card.ability.extra.Xmult_mod
			return {
				message = 'Upgrade!'
			}
		end

		if context.joker_main then
			return {
				xmult = card.ability.extra.Xmult_bonus
			}
		end

		if context.end_of_round and context.cardarea == G.jokers and not context.blueprint then
			card.ability.extra.Xmult_bonus = 1
			return {
				message = 'Reset!',
				colour = G.C.RED
			}
		end
	end
}

SMODS.Joker{
	key = 'peasant_slapping_the_pond',
	loc_txt = {
		name = 'Peasant Slapping the Pond',
		text = {
			'Each {C:attention}Jack{} held in',
			'hand gives {C:chips}+#1#{} Chips'
		}
	},
	atlas = 'GooberAtlas',
	pos = {x = 1, y = 0},
	rarity = 1,
	cost = 4,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	unlocked = true,
	discovered = true,
	config = {
		extra = {
			chips = 50
		}
	},
	loc_vars = function (self, info_queue, center)
		return {vars = { center.ability.extra.chips }}
	end,
	calculate = function (self, card, context)
		if context.individual and context.cardarea == G.hand and not context.end_of_round and context.other_card:get_id() == 11 then
			if context.other_card.debuff then
				return {
					message = 'Debuffed!',
					colour = G.C.RED
				}
			else
				return {
					chips = card.ability.extra.chips
				}
			end
		end
	end
}

SMODS.Joker{
	key = 'conduit',
	loc_txt = {
		name = 'The Conduit',
		text = {
			'At end of round, Joker to the',
			'{C:attention}right{} copies the {C:enhanced}Edition{} of', 
			'this Joker, then this Joker',
			'copies the {C:enhanced}Edition{} to the {C:attention}left{}',
			'{C:inactive}(Excludes{} {C:dark_edition}Negative{} {C:inactive}Jokers){}'
		}
	},
	atlas = 'GooberAtlas',
	pos = {x = 1, y = 0},
	rarity = 3,
	cost = 8,
	blueprint_compat = false,
	eternal_compat = true,
	perishable_compat = true,
	unlocked = true,
	discovered = true,
	calculate = function (self, card, context)
		if context.end_of_round and not context.blueprint and context.cardarea == G.jokers then
			-- Determine which Jokers are to the left and right of the Conduit
			local left_joker, right_joker
			local num_jokers = #G.jokers.cards
			local ret_bool = false

			for i = 1, num_jokers do
				if G.jokers.cards[i] == card then
					if i ~= 1 then
						left_joker = G.jokers.cards[i - 1]
					end

					if i ~= num_jokers then
						right_joker = G.jokers.cards[i + 1]
					end
				end
			end

			-- Copy edition from this joker to the joker right of it
			if right_joker then
				if card.edition then
					if not card.edition.negative then
						right_joker:set_edition(card.edition, true, true)
						card:juice_up(0.3, 0.4)
						right_joker:juice_up(0.3, 0.4)
						ret_bool = true
					end
				else
					right_joker:set_edition(card.edition, true, true)
					card:juice_up(0.3, 0.4)
					right_joker:juice_up(0.3, 0.4)
					ret_bool = true
				end
			end

			-- Copy the edition from the joker left of the conduit to the conduit
			if left_joker then
				if left_joker.edition then
					if not left_joker.edition.negative then
						card:set_edition(left_joker.edition, true, true)
						left_joker:juice_up(0.3, 0.4)
						card:juice_up(0.3, 0.4)
						ret_bool = true
					end
				else
					card:set_edition(left_joker.edition, true, true)
					left_joker:juice_up(0.3, 0.4)
					card:juice_up(0.3, 0.4)
					ret_bool = true
				end
				
			end

			-- If editions changed, give a little message
			if ret_bool then
				return {
					message = 'Bazinga!',
					colour = G.C.SECONDARY_SET.Enhanced,
					sound = 'goob_thunder',
					volume = 1.5
				}
			end
			
		end
	end
}

SMODS.Joker{
	key = 'professor',
	loc_txt = {
		name = 'The Professor',
		text = {
			'If {C:attention}discard{} has only {C:attention}1{}',
			'card, draw up to {C:attention}2{} cards',
			'of the same rank from',
			'your deck'
		}
	},
	atlas = 'GooberAtlas',
	pos = {x = 1, y = 0}, -- Placeholder art
	rarity = 3,
	cost = 7,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	unlocked = true,
	discovered = true,
	calculate = function (self, card, context)
		if context.discard and #context.full_hand == 1 then
			local num_draws = 2
			for _, c in pairs(G.deck.cards) do
				if c:get_id() == context.other_card:get_id() and num_draws > 0 then
					draw_card(G.deck, G.hand, 50, 'up', true, c)
					num_draws = num_draws - 1
				end
			end
		end
	end
}

SMODS.Joker{
	key = 'virus',
	loc_txt = {
		name = 'Virus',
		text = {
			'On {C:attention}first hand{} played, copy',
			'{C:enhanced}enhancement{} from leftmost',
			'scored card to scored card',
			'directly right of it'
		}
	},
	atlas = 'GooberAtlas',
	pos = {x = 1, y = 0}, -- Placeholder art
	rarity = 3,
	cost = 8,
	blueprint_compat = false,
	eternal_compat = true,
	perishable_compat = true,
	unlocked = true,
	discovered = true,
	calculate = function (self, card, context)
		if context.before and not context.blueprint and G.GAME.current_round.hands_played == 0 and #context.scoring_hand > 1 and context.main_eval then
			local enhancement = SMODS.get_enhancements(context.scoring_hand[1], false)
			local infected_card = context.scoring_hand[2]

			for k, p in pairs(enhancement) do			
				if p then
					infected_card:set_ability(k, nil, true)
					
					G.E_MANAGER:add_event(Event({
						func = function ()
							infected_card:juice_up(0.3, 0.4)
							return true
						end
					}))
				end
			end
		end
	end
}

SMODS.Joker{
	key = 'harlequin',
	loc_txt = {
		name = 'Harlequin',
		text = {
			'Converts all scored cards',
			'to {C:diamonds}Diamonds{}, gains {X:mult,C:white}X #1#{} Mult',
			'for each card {C:attention}converted{}',
			'{C:inactive}(Currently{} {X:mult,C:white}X #2#{} {C:inactive}Mult){}'
		}
	},
	atlas = 'GooberAtlas',
	pos = {x = 1, y = 0}, -- Placeholder art
	rarity = 3,
	cost = 8,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	unlocked = true,
	discovered = true,
	config = {
		extra = {
			Xmult_mod = 0.2,
			Xmult_bonus = 1
		}
	},
	loc_vars = function (self, info_queue, center)
		return {vars = { center.ability.extra.Xmult_mod, center.ability.extra.Xmult_bonus }}
	end,
	calculate = function (self, card, context)
		if context.before and context.main_eval and not context.blueprint then
			local display_message = false
			for _, c in pairs(context.scoring_hand) do
				if not c:is_suit('Diamonds') then
					card.ability.extra.Xmult_bonus = card.ability.extra.Xmult_bonus + card.ability.extra.Xmult_mod
					display_message = true
					G.E_MANAGER:add_event(Event({
						func = function ()
							SMODS.change_base(c, 'Diamonds')
							c:juice_up(0.3, 0.4)
							return true
						end
					}))
				end
			end
			if display_message then
				return {
					message = 'X'..tostring(card.ability.extra.Xmult_bonus)..' Mult',
					colour = G.C.RED
				}
			end
		end

		if context.using_consumeable and not context.blueprint then
			if context.consumeable.label == 'The Star' then
				for i = 1, #G.hand.highlighted do
					card.ability.extra.Xmult_bonus = card.ability.extra.Xmult_bonus + card.ability.extra.Xmult_mod
				end
				return {
					message = 'X'..tostring(card.ability.extra.Xmult_bonus)..' Mult',
					colour = G.C.RED
				}
			end
		end

		if context.joker_main then
			return {
				xmult = card.ability.extra.Xmult_bonus
			}
		end
	end
}

-- Example Joker
SMODS.Joker{
	key = 'ex_joker',                        -- key for the Joker used in the game; not super relevant
	loc_txt = {                              
		name = 'Example Joker',                -- name of the Joker in game
		text = {                               -- the Joker's description, line-by-line (read https://github.com/Steamodded/smods/wiki/Text-Styling for more info on text styling)
      'Gain {X:chips}+#1# chips{}, {X:mult}+#2# Mult{},',
      '{C:attention}$#3#{}, and {X:mult}X#4# Mult{}',
      'All values increas by {C:attention}#5#{} at end of round'
		}
	},
	atlas = 'GooberAtlas',                   -- name of the sprite atlas used (shouldn't change)
	pos = {x = 1, y = 0},                    -- position of the Joker's sprite on the atlas (in terms of individual Joker sprites)
	rarity = 1,                              -- Joker's rarity (1 -> common, 2 -> uncommon, 3 -> rare, 4 -> legendary)
	cost = 5,                                -- Joker's cost (in dollars)
	blueprint_compat = true,                 -- is the Joker compatible with Blueprint? (purely cosmetic)
	eternal_compat = true,                   -- can the Joker be eternal?
	perishable_compat = true,                -- can the Joker be perishable? (scaling Jokers generally cannot be Perishable)
	unlocked = true,                         -- is the Joker unlocked?
	discovered = true,                       -- is the Joker discovered?
	config = {                               -- contains any values used for the Joker's scoring, etc.
		extra = {
			bonus_chips = 10,
      bonus_mult = 2,
      payout_amount = 3,
      Xmult = 1.5,
      custom_property = 1
		}
	},
  -- map config.extra properties to actual values
	loc_vars = function(self, info_queue, center)
		return {vars = {center.ability.extra.bonus_chips, center.ability.extra.bonus_mult, center.ability.extra.payout_amount, center.ability.extra.Xmult, center.ability.extra.custom_property}}
	end,
  -- the calculate() function handles all Joker behavior
	calculate = function(self, card, context)
    -- context.blueprint -> flag if effect is being copied by blueprint 
    -- context.before -> happens AFTER hand is played but BEFORE scoring begins
    -- context.individual -> triggers whenever an individual playing card is scored
    -- context.joker_main -> occurs during the normal Joker scoring loop
    -- context.other_joker -> triggers effects on all other Jokers + consumeables
    -- context.final_scoring_step -> triggers AFTER all other scoring effects calculated by before score is totaled
    -- context.after -> triggers after scoring has completed
    -- context.debuffed_hand -> triggers when hand contains a debuffed card
    -- context.end_of_round -> triggers when round ends (blind is won)
    -- context.setting_blind -> triggers at start of blind
    -- context.pre_discard -> used when discard initially triggered
    -- context.discard -> triggers on each discarded card
		if context.before and not context.blueprint then
			card.ability.extra.bonus_chips = card.ability.extra.bonus_chips + card.ability.extra.custom_property
      card.ability.extra.bonus_mult = card.ability.extra.bonus_mult + card.ability.extra.custom_property
      card.ability.extra.payout_amount = card.ability.extra.payout_amount + card.ability.extra.custom_property
      card.ability.extra.Xmult = card.ability.extra.Xmult + card.ability.extra.custom_property

      -- returns a Table with scoring information, etc.
      return {
				card = card,
        -- emit a message
				message = 'Upgrade!',
				colour = G.C.ORANGE
			}
		end

    -- returns the table with chip bonus, mult bonus, payout, and Xmult
		if context.joker_main then
			return {
				card = card,
				mult = card.ability.extra.bonus_mult,
				chips = card.ability.extra.bonus_chips,
				xmult = card.ability.extra.Xmult,
				dollars = card.ability.extra.payout_amount
			}
		end
	end
}

-----------------------------------------------------
------------------- MOD CODE END --------------------