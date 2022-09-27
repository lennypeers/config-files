local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")
local dpi = require("beautiful.xresources").apply_dpi
local beautiful = require("beautiful")
local helpers = require("ui.helpers")
local spawn_media = require("tools.media").spawn_media

-- WMCLASS widget
-- {{{
local class_txt = wibox.widget({
    widget = wibox.widget.textbox,
    buttons = {
        awful.button({
            button = 1,
            on_press = function()
                awesome.emit_signal("control_center::toggle")
            end,
        }),
    },
})

local window_class = wibox.widget({
    class_txt,
    right = dpi(10),
    layout = wibox.layout.margin,
    -- user defined
    class = "No name",
    name = nil,
})

client.connect_signal("unfocus", function(_)
    class_txt.visible = false
end)

client.connect_signal("focus", function(c)
    local class = c.class and c.class:gsub("^%l", string.upper) or "No name"
    class_txt:set_markup_silently(class)
    class_txt.visible = true
    window_class.class = class
    window_class.name = c.name
end)

window_class.tooltip = helpers.tooltip(window_class, function()
    local tail = window_class.name and " - " .. window_class.name or ""
    return window_class.class .. tail
end)
-- }}}

-- {{{ Notifications
local notif_svg = beautiful.icon_path .. "notification/bell_thick.svg"
local notif_buttons = {
    awful.button({
        button = 1,
        on_press = function()
            awesome.emit_signal("notification::mode_toggle")
        end,
    }),
}
local notif_icon = helpers.svg(notif_svg, nil, nil, "bar_fg", notif_buttons)
local notifications = wibox.widget({
    notif_icon,
    top = beautiful.icon_v_padding,
    bottom = beautiful.icon_v_padding,
    right = beautiful.wibar_spacing,
    layout = wibox.container.margin,
    visible = false,
    silent = false,
    new = 0,
})
-- Tooltip
notifications.tooltip = helpers.tooltip(notifications, function()
    local mode = notifications.silent and "silent" or "normal"
    local number = notifications.new > 0
            and " (" .. tostring(notifications.new) .. " new)"
        or ""
    return "In " .. mode .. " mode" .. number
end)
-- Update symbols
awesome.connect_signal("notification::new", function(silent)
    if not silent then
        notif_icon:update(
            nil,
            beautiful.icon_path .. "notification/bell_thick_new.svg"
        )
    end
end)

awesome.connect_signal("notification::mode", function(silent, new)
    local status = new > 0 and "_new" or ""
    local mode = silent and "_off" or "_on"
    -- Update visibility
    if not silent and new <= 0 then
        notifications.visible = false
        return
    else
        notifications.visible = true
    end
    -- Updating tooltip data
    notifications.silent = silent
    notifications.new = new
    -- Changing icons
    notif_icon:update(
        nil,
        beautiful.icon_path
            .. "notification/notification"
            .. mode
            .. status
            .. ".svg"
    )
end)
-- }}

-- {{{ Battery widget
local battery_icon = helpers.svg(nil, nil, nil, "bar_fg")
battery_icon.current_icon = 10

local battery_level = wibox.widget({
    markup = "50<b>%</b>",
    widget = wibox.widget.textbox,
})

local bat = wibox.widget({
    {
        battery_icon,
        battery_level,
        spacing = dpi(5),
        layout = wibox.layout.fixed.horizontal,
    },
    top = beautiful.icon_v_padding,
    bottom = beautiful.icon_v_padding,
    right = dpi(20),
    layout = wibox.container.margin,
})

function bat:update_meta(charging, capacity_str)
    local capacity = tonumber(capacity_str)
    local image

    battery_level:set_markup_silently(capacity_str .. "%")

    if capacity == 100 then
        -- Full
        image = beautiful.icon_path .. "battery/battery-100.svg"
        battery_level:set_markup_silently("")
    elseif charging then
        -- Charging
        image = beautiful.icon_path
            .. "battery/battery-charging-"
            .. tostring(battery_icon.current_icon)
            .. ".svg"
        battery_icon.current_icon = battery_icon.current_icon > 90 and 10
            or (battery_icon.current_icon + 10)
    else
        -- Discharging
        image = beautiful.icon_path
            .. "battery/battery-"
            .. tostring(math.ceil(capacity / 10) * 10)
            .. ".svg"
    end

    battery_icon.image = image
end

local battery = awful.widget.watch(
    "cat /sys/class/power_supply/BAT0/capacity "
        .. "/sys/class/power_supply/BAT0/status",
    1,
    function(widget, stdout)
        local capacity_str, status, charging

        capacity_str = stdout:match("(%d+)")
        status = stdout:match("([a-zA-Z]+)")
        charging = status == "Charging" and true or false
        widget:update_meta(charging, capacity_str)
    end,
    bat
)
-- }}}

-- {{{ Volume widget
local volume_buttons = {
    awful.button({
        button = 1,
        on_press = function()
            awful.util.spawn(script_path .. "volume -t")
        end,
    }),
    awful.button({
        button = 4,
        on_press = function()
            awful.util.spawn(script_path .. "volume -d 5")
        end,
    }),
    awful.button({
        button = 5,
        on_press = function()
            awful.util.spawn(script_path .. "volume -i 5")
        end,
    }),
}

local icon_path = beautiful.icon_path .. "volume/volume-low.svg"
local volume_icon =
    helpers.svg(icon_path, nil, nil, "bar_fg", volume_buttons, nil)
volume_icon.level = 0
volume_icon.muted = true
local tooltip_func = function()
    local muted = volume_icon.muted and " (muted)" or ""
    return "Volume at " .. tostring(volume_icon.level) .. "%" .. muted
end
volume_icon.tooltip = helpers.tooltip(volume_icon, tooltip_func)

function volume_icon:update_volume(volume_level, muted)
    if volume_level == nil then
        return -- bad initialization
    end
    volume_icon.level = volume_level
    volume_icon.muted = muted

    if muted then
        volume_icon:update(nil, beautiful.icon_path .. "/volume/volume-off.svg")
    elseif volume_level < 10 then
        volume_icon:update(nil, beautiful.icon_path .. "/volume/volume-low.svg")
    elseif volume_level < 60 then
        volume_icon:update(
            nil,
            beautiful.icon_path .. "/volume/volume-medium.svg"
        )
    else
        volume_icon:update(
            nil,
            beautiful.icon_path .. "/volume/volume-high.svg"
        )
    end
end

local volume = {
    volume_icon,
    top = beautiful.icon_v_padding,
    bottom = beautiful.icon_v_padding,
    right = beautiful.wibar_spacing,
    layout = wibox.container.margin,
}

awesome.connect_signal("volume_change", function(volume_level, muted)
    volume_icon:update_volume(volume_level, muted)
end)
-- }}}

-- {{{ Brightness widget

-- Blue light on laptop
local bluelevel_laptop = 100 -- init
local temp_min, temp_max = 4500, 6500 --

local function update_bluelevel_laptop(percentage_inc)
    -- Update the percentage
    bluelevel_laptop =
        math.min(100, math.max(0, bluelevel_laptop + percentage_inc))

    local inc = (temp_max - temp_min) / 100
    local val = tostring(4500 + bluelevel_laptop * inc)

    -- Update + events
    awful.util.spawn("redshift -m randr:crtc=0 -P -O " .. val)
    awesome.emit_signal("screen_bluelight_change", bluelevel_laptop)
end

-- Monitor test
local function is_builtin_output()
    local out = awful.screen.focused().outputs
    return out["LVDS"] or out["LVDS1"] or out["eDP"]
end

local brightness_buttons = {
    awful.button({
        button = 5,
        on_press = function()
            if not is_builtin_output() then
                spawn_media(
                    script_path .. "backlight -m -d 5%",
                    "screen_backlight_change"
                )
            else
                spawn_media(
                    script_path .. "backlight -l -d 1%",
                    "screen_backlight_change"
                )
            end
        end,
    }),
    awful.button({
        button = 4,
        on_press = function()
            if not is_builtin_output() then
                spawn_media(
                    script_path .. "backlight -m -i 5%",
                    "screen_backlight_change"
                )
            else
                spawn_media(
                    script_path .. "backlight -l -i 1%",
                    "screen_backlight_change"
                )
            end
        end,
    }),
    awful.button({
        button = 3,
        on_press = function()
            if not is_builtin_output() then
                spawn_media(
                    script_path .. "backlight -b -i 5%",
                    "screen_bluelight_change"
                )
            else -- Laptop blue light
                update_bluelevel_laptop(5)
            end
        end,
    }),
    awful.button({
        button = 2,
        on_press = function()
            awful.util.spawn(script_path .. "color")
        end,
    }),
    awful.button({
        button = 1,
        on_press = function()
            if not is_builtin_output() then
                spawn_media(
                    script_path .. "backlight -b -d 5%",
                    "screen_bluelight_change"
                )
            else -- Laptop blue light
                update_bluelevel_laptop(-5)
            end
        end,
    }),
}

local pre_update = function(self, theme, _)
    local tail = theme == "day" and ".svg" or "-night.svg"
    self.svg_path = beautiful.icon_path .. "backlight/screen" .. tail
end
local brightness_icon =
    helpers.svg(nil, nil, nil, "bar_fg", brightness_buttons, pre_update)

local brightness = wibox.widget({
    brightness_icon,
    top = beautiful.icon_v_padding,
    bottom = beautiful.icon_v_padding,
    right = beautiful.wibar_spacing,
    layout = wibox.container.margin,
})

brightness.tooltip = helpers.tooltip(brightness, function()
    return "Using " .. theme_name .. " theme"
end)
-- }}}

-- {{{ hwmon
local hwmon_widget = awful.widget.watch(
    "cat /sys/devices/platform/applesmc.768/temp13_input"
        .. " /sys/bus/platform/drivers/dell_smm_hwmon/dell_smm_hwmon/hwmon/hwmon5/temp2_input"
        .. " /sys/devices/platform/applesmc.768/fan1_input"
        .. " /sys/bus/platform/drivers/dell_smm_hwmon/dell_smm_hwmon/hwmon/hwmon5/fan1_input",
    5,
    function(widget, stdout)
        local out = stdout:gsub("[\n\r]", " ")
        local temp, fan = out:match("(.+)[\n\r ]+(.+)")
        local temp_str, fan_str

        if fan ~= "0 " then
            fan_str = "   " .. fan .. "<span weight='bold'>rpm</span>"
        else
            fan_str = ""
        end
        temp_str = tostring(math.floor(tonumber(temp) / 1000))
            .. "<span weight='bold'>°c</span>"

        widget:set_markup_silently(temp_str .. fan_str)
    end,
    wibox.widget.textbox()
)

local hwmon = {
    hwmon_widget,
    top = beautiful.icon_v_padding,
    bottom = beautiful.icon_v_padding,
    right = beautiful.wibar_spacing,
    layout = wibox.container.margin,
}
-- }}}

-- {{{ systray
local systray_widget = wibox.widget.systray()

local systray = wibox.widget({
    systray_widget,
    draw_empty = false,
    top = beautiful.icon_v_padding,
    bottom = beautiful.icon_v_padding,
    right = beautiful.wibar_spacing,
    layout = wibox.container.margin,
})

-- Themed colors
awesome.connect_signal("theme_change", function(theme)
    beautiful.bg_systray = beautiful.theme[theme].bg
end)
-- }}}

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
    awful.button({}, 1, function(t)
        t:view_only()
    end),
    awful.button({ modkey }, 1, function(t)
        if client.focus then
            client.focus:move_to_tag(t)
        end
    end),
    awful.button({}, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t)
        if client.focus then
            client.focus:toggle_tag(t)
        end
    end)
)

-- {{{
screen.connect_signal("request::desktop_decoration", function(s)
    -- {{{ tags
    awful.tag.add("1", {
        icon = "web.svg",
        layout = awful.layout.suit.tile,
        --      master_fill_policy = "masterwidthfactor",
        screen = s,
        selected = true,
    })

    for key, name in ipairs({
        "search.svg",
        "console.svg",
        "doc.svg",
        "chat.svg",
        "video.svg",
        "misc.svg",
        "office.svg",
        "music.svg",
        "download.svg",
    }) do
        awful.tag.add(tostring(key + 1), {
            icon = name,
            layout = awful.layout.suit.tile,
            screen = s,
        })
    end
    -- }}}

    -- {{{ textclock
    local clock = wibox.widget({
        refresh = 1,
        format_normal = "%r",
        format_alt = "%A %d %b, %r",
        widget = wibox.widget.textclock,
    })
    clock.next_state = function()
        if clock.format == clock.format_normal then
            clock.format = clock.format_alt
        else
            clock.format = clock.format_normal
        end
    end
    clock:next_state() -- init
    clock:add_button(awful.button({}, 1, clock.next_state))
    s.mytextclock = clock
    -- }}}

    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
        awful.button({}, 1, function()
            awful.layout.inc(1)
        end),
        awful.button({}, 3, function()
            awful.layout.inc(-1)
        end),
        awful.button({}, 4, function()
            awful.layout.inc(1)
        end),
        awful.button({}, 5, function()
            awful.layout.inc(-1)
        end)
    ))

    local layoutbox = {
        s.mylayoutbox,
        top = beautiful.icon_v_padding,
        bottom = beautiful.icon_v_padding,
        right = beautiful.wibar_spacing,
        widget = wibox.layout.margin,
    }

    -- luacheck: push ignore index tags
    local update_tag = function(widget, tag, index, tags)
        local icon = widget:get_children_by_id("svg_role")[1]
        local underline = widget:get_children_by_id("underline_role")[1]

        -- Reinit for new items
        icon.image = beautiful.icon_path .. "taglist/" .. tag.icon
        icon.stylesheet = "*{fill:"
            .. beautiful.theme[theme_name].bar_fg
            .. ";}"

        if tag.urgent then
            icon.stylesheet = "*{fill:"
                .. beautiful.theme[theme_name].hover
                .. ";}"
            underline.bg = beautiful.theme[theme_name].hover
        else
            icon.stylesheet = "*{fill:"
                .. beautiful.theme[theme_name].bar_fg
                .. ";}"
            underline.bg = beautiful.theme[theme_name].bar_bg
        end

        if tag.selected then
            underline.bg = beautiful.theme[theme_name].bar_fg
        end
    end -- luacheck: pop

    local init_tag = function(widget, tag, index, tags)
        local icon = widget:get_children_by_id("svg_role")[1]

        -- Icon init
        icon.image = beautiful.icon_path .. "taglist/" .. tag.icon
        icon.stylesheet = "*{fill:"
            .. beautiful.theme[theme_name].bar_fg
            .. ";}"

        -- Underline init
        local underline = widget:get_children_by_id("underline_role")[1]
        underline.bg = beautiful.theme[theme_name].bar_fg

        widget:connect_signal("mouse::enter", function()
            -- Hover support pt.1
            icon.stylesheet = "*{fill:"
                .. beautiful.theme[theme_name].hover
                .. ";}"
            -- Tag preview
            -- awesome.emit_signal("preview_update", tag)
            -- awesome.emit_signal("preview_show", s, true)
        end)

        widget:connect_signal("mouse::leave", function()
            -- Hover support pt.2
            icon.stylesheet = "*{fill:"
                .. beautiful.theme[theme_name].bar_fg
                .. ";}"
            -- Tag preview
            -- awesome.emit_signal("preview_show", s, false)
        end)

        -- Theme change support
        awesome.connect_signal("theme_change", function(_)
            update_tag(widget, tag, index, tags)
        end)

        -- Update the tag
        update_tag(widget, tag, index, tags)
    end

    -- {{{ Create a taglist widget
    s.mytaglist = awful.widget.taglist({
        screen = s,
        filter = awful.widget.taglist.filter.noempty,
        buttons = taglist_buttons,
        widget_template = {
            {
                {
                    id = "svg_role",
                    widget = wibox.widget.imagebox,
                },
                left = 2 * beautiful.icon_h_padding,
                right = 2 * beautiful.icon_h_padding,
                top = beautiful.icon_v_padding,
                bottom = beautiful.icon_v_padding,
                widget = wibox.container.margin,
            },
            {
                {
                    wibox.widget.base.make_widget(),
                    id = "underline_role",
                    shape = gears.shape.rounded_rect,
                    widget = wibox.container.background,
                },
                top = dpi(22),
                left = dpi(1),
                right = dpi(1),
                widget = wibox.container.margin,
            },
            layout = wibox.layout.stack,
            create_callback = init_tag,
            update_callback = update_tag,
        },
    })
    -- }}}

    -- {{{ Create a tasklist widget
    -- luacheck: push ignore i o
    local init_task = function(widget, c, i, o)
        local class = c.class or "None"
        local name = c.name or "None"
        -- Add a tooltip
        widget.tooltip = helpers.tooltip(widget, function()
            return class .. " - " .. name
        end)
        -- Updating the text
        widget:get_children_by_id("custom_text_role")[1].text = class
    end -- luacheck: pop

    s.mytasklist = awful.widget.tasklist({
        screen = s,
        filter = awful.widget.tasklist.filter.minimizedcurrenttags,
        buttons = gears.table.join(awful.button({}, 1, function(c)
            c:emit_signal("request::activate", "tasklist", { raise = true })
        end)),
        layout = {
            spacing = dpi(20),
            layout = wibox.layout.flex.horizontal,
        },
        widget_template = {
            {
                {
                    {
                        id = "icon_role",
                        widget = wibox.widget.imagebox,
                    },
                    left = beautiful.icon_h_padding,
                    right = beautiful.icon_h_padding * 2,
                    top = dpi(4),
                    bottom = dpi(4),
                    widget = wibox.container.margin,
                },
                {
                    id = "custom_text_role",
                    widget = wibox.widget.textbox,
                },
                layout = wibox.layout.fixed.horizontal,
            },
            widget = helpers.custom_container_bg("bar_bg", "bar_fg", true),
            create_callback = init_task,
        },
    })
    -- }}}

    -- {{{ Create the wibox
    s.mywibox = awful.wibar({
        position = "top",
        screen = s,
    })

    -- Add widgets to the wibox
    s.mywibox:setup({
        {
            {
                { -- Left widgets
                    {
                        s.mytaglist,
                        window_class,
                        s.mytasklist,
                        spacing = dpi(20),
                        layout = wibox.layout.fixed.horizontal,
                    },
                    left = dpi(20),
                    layout = wibox.layout.margin,
                },
                { -- Middle widget
                    s.mytextclock,
                    layout = wibox.layout.fixed.horizontal,
                },
                {
                    { -- Right widgets
                        layoutbox,
                        hwmon,
                        notifications,
                        systray,
                        brightness,
                        volume,
                        battery,
                        layout = wibox.layout.fixed.horizontal,
                    },
                    right = dpi(20),
                    layout = wibox.layout.margin,
                },
                layout = wibox.layout.align.horizontal,
                expand = "none",
            },
            -- Dynamic theme wrapper
            widget = helpers.custom_container_bg("bar_bg", "bar_fg"),
        },
        color = beautiful.border_normal,
        bottom = beautiful.border_width,
        widget = wibox.container.margin,
    })
    -- }}}
end)

-- }}}
-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
