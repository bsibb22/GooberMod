# Development Guidelines
Below is a list of guidelines, template code, etc. for creating custom Jokers.

# Environment
To begin development, you will need to have Steamodded and Lovely installed: https://github.com/Steamodded/smods/wiki
I also recommend installing the DebugPlus mod for easier testing: https://github.com/WilsontheWolf/DebugPlus

Then, place this entire repository into your Balatro\Mods folder and restart the game.

# Joker Outline
```
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
```
