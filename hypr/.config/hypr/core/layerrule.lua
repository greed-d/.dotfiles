-- Layer rules also return a handle.
local overlayLayerRule = hl.layer_rule({
	name = "no-anim-overlay",
	match = { namespace = "^my-overlay$" },
	no_anim = true,
})
overlayLayerRule:set_enabled(false)

-- ============================================
-- LAYER RULES
-- ============================================

local function layer_rule(namespace, props)
	local spec = { match = { namespace = namespace } }
	for k, v in pairs(props) do
		spec[k] = v
	end
	hl.layer_rule(spec)
end

layer_rule("rofi", { blur = true })

layer_rule("notifications", { blur = true })

layer_rule("quickshell:overview", { blur = true, ignore_alpha = 0.5 })

layer_rule("kitty-quick-access", { dim_around = true })
