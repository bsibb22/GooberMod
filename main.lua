--- STEAMODDED HEADER
--- MOD_NAME: GOOBER_MOD
--- MOD_ID: GOOBTEST
--- MOD_AUTHOR: [the_goobers]
--- MOD_DESCRIPTION: The Goober Mod, for Goobers, by Goobers.
--- PREFIX: xmpl
-----------------------------------------------------
--------------------- MOD CODE ----------------------

-- values that should be consistent throughout the whole game
global = {
	timestable_rank = math.random(2, 10),
	timestable_reset = false
}

-- UTILITY FUNCTIONS --


-- sprite stuff
SMODS.Atlas{
	key = 'GooberAtlas',
	path = 'goober_sprites.png',
	px = 71,
	py = 95
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
			'hand only contains {C:attention}#2#{}s',
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
			desired_rank = global.timestable_rank
		}
	},
	loc_vars = function(self, info_queue, center)
		return {vars = {center.ability.extra.Xmult, center.ability.extra.desired_rank}}
	end,
	calculate = function(self,card,context)
		-- determine next blind's rank at blind start
		if context.setting_blind and not context.blueprint then
			if global.timestable_reset ~= true then
				global.timestable_rank = math.random(2, 10)
				global.timestable_reset = true
			end
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
			card.ability.extra.desired_rank = global.timestable_rank
			global.timestable_reset = false
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

SMODS.Joker{
	key = 'counterfeit',
	loc_txt = {
		name = "Counterfeit",
		text = {
			'Played cards give {C:chips}+#1#{} Chips',
			'and {C:mult}+#2#{} Mult when scored',
			'{C:green}#3# in #4#{} chance to {C:red,E:2}self',
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