local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local helpers   = require("ui.helpers")
local beautiful = require("beautiful")
local dpi       = beautiful.xresources.apply_dpi

local popup_height = dpi(75)
local popup_width  = dpi(300)

local popup = wibox {
    x       = 50, -- Junk values
    y       = 50, -- Will be set later
    width   = popup_width,
    height  = popup_height,
    bg      = "#00000000", -- for anti-aliasing
    type    = "notification",
    visible = false,
    ontop   = true
}

-- {{{ Prompt
local myprompt = awful.widget.prompt {
    prompt = "",
    font   = beautiful.font_family.." 10",
    fg     = beautiful.theme[theme_name].fg,
    bg_cursor     = beautiful.theme[theme_name].fg.."90",
    fg_cursor     = beautiful.theme[theme_name].bg.."90",
    with_shell    = true,
    done_callback = function()
        popup.visible = false
    end
}

-- Change theme
awesome.connect_signal("theme_change", function(theme)
    myprompt.fg = beautiful.theme[theme].fg
    myprompt.bg_cursor = beautiful.theme[theme].fg.."90"
    myprompt.fg_cursor = beautiful.theme[theme].bg.."90"
    myprompt:emit_signal("widget::redraw_needed")
end)
-- }}}

-- {{{ Search icon
local icon_path = beautiful.icon_path.."taglist/search.svg"
local icon = helpers.svg(icon_path, nil, nil, "progressbar_fg")
-- }}}

-- {{{ Setup
local prompt = wibox.widget {
    helpers.equal_padded(icon, dpi(20)),
    myprompt,
    layout = wibox.layout.fixed.horizontal
}

popup:setup {
    helpers.themed(prompt, "bg"),
    shape  = gears.shape.rounded_rect,
    widget = wibox.container.background(),
    border_width = beautiful.border_width,
    border_color = beautiful.border_normal
}
-- }}}

-- Show the spotlight
function popup:run()
    -- show on the correct screen
    local geometry = awful.screen.focused().geometry
    popup:geometry {
        x = geometry.x + geometry.width/2  - popup_width/2,
        y = geometry.y + geometry.height/2 - popup_height/2
    }
    popup.visible = true
    myprompt:run()
end

awesome.connect_signal("spotlight_show", popup.run)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
