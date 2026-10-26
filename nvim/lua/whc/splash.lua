-- Start screen: a random "Willow" logo and slogan with the useful keys, drawn as virtual lines over
-- the ordinary empty buffer rather than by a dashboard plugin. The buffer stays a normal scratch
-- buffer: typing, pasting or writing clears the splash, like the built-in intro.

local logos = {
    [[
        :::       ::: ::::::::::: :::        :::        ::::::::  :::       ::: :::
        :+:       :+:     :+:     :+:        :+:       :+:    :+: :+:       :+: :+:
        +:+       +:+     +:+     +:+        +:+       +:+    +:+ +:+       +:+ +:+
        +#+  +:+  +#+     +#+     +#+        +#+       +#+    +:+ +#+  +:+  +#+ +#+
        +#+ +#+#+ +#+     +#+     +#+        +#+       +#+    +#+ +#+ +#+#+ +#+ +#+
         #+#+# #+#+#      #+#     #+#        #+#       #+#    #+#  #+#+# #+#+#
          ###   ###   ########### ########## ########## ########    ###   ###   ###
    ]],
    [[
                                                                                ,---,
                                                                         ,`--.' |
                   .---.           ,--,    ,--,                          |   :  :
                  /. ./|  ,--,   ,--.'|  ,--.'|                          '   '  ;
              .--'.  ' ;,--.'|   |  | :  |  | :     ,---.           .---.|   |  |
             /__./ \ : ||  |,    :  : '  :  : '    '   ,'\         /. ./|'   :  ;
         .--'.  '   \' .`--'_    |  ' |  |  ' |   /   /   |     .-'-. ' ||   |  '
        /___/ \ |    ' ',' ,'|   '  | |  '  | |  .   ; ,. :    /___/ \: |'   :  |
        ;   \  \;      :'  | |   |  | :  |  | :  '   | |: : .-'.. '   ' .;   |  ;
         \   ;  `      ||  | :   '  : |__'  : |__'   | .; :/___/ \:     '`---'. |
          .   \    .\  ;'  : |__ |  | '.'|  | '.'|   :    |.   \  ' .\    `--..`;
           \   \   ' \ ||  | '.'|;  :    ;  :    ;\   \  /  \   \   ' \ |.--,_
            :   '  |--" ;  :    ;|  ,   /|  ,   /  `----'    \   \  |--" |    |`.
             \   \ ;    |  ,   /  ---`-'  ---`-'              \   \ |    `-- -`, ;
              '---"      ---`-'                                '---"       '---`"
    ]],
    [[
        ██╗    ██╗██╗██╗     ██╗      ██████╗ ██╗    ██╗██╗
        ██║    ██║██║██║     ██║     ██╔═══██╗██║    ██║██║
        ██║ █╗ ██║██║██║     ██║     ██║   ██║██║ █╗ ██║██║
        ██║███╗██║██║██║     ██║     ██║   ██║██║███╗██║╚═╝
        ╚███╔███╔╝██║███████╗███████╗╚██████╔╝╚███╔███╔╝██╗
         ╚══╝╚══╝ ╚═╝╚══════╝╚══════╝ ╚═════╝  ╚══╝╚══╝ ╚═╝
    ]],
    [[
         #     #                               ###
         #  #  # # #      #       ####  #    # ###
         #  #  # # #      #      #    # #    # ###
         #  #  # # #      #      #    # #    #  #
         #  #  # # #      #      #    # # ## #
         #  #  # # #      #      #    # ##  ## ###
          ## ##  # ###### ######  ####  #    # ###
    ]],
    [[
         /$$      /$$ /$$ /$$ /$$                         /$$
        | $$  /$ | $$|__/| $$| $$                        | $$
        | $$ /$$$| $$ /$$| $$| $$  /$$$$$$  /$$  /$$  /$$| $$
        | $$/$$ $$ $$| $$| $$| $$ /$$__  $$| $$ | $$ | $$| $$
        | $$$$_  $$$$| $$| $$| $$| $$  \ $$| $$ | $$ | $$|__/
        | $$$/ \  $$$| $$| $$| $$| $$  | $$| $$ | $$ | $$
        | $$/   \  $$| $$| $$| $$|  $$$$$$/|  $$$$$/$$$$/ /$$
        |__/     \__/|__/|__/|__/ \______/  \_____/\___/ |__/
    ]],
    [[
         __          ___ _ _               _
         \ \        / (_) | |             | |
          \ \  /\  / / _| | | _____      _| |
           \ \/  \/ / | | | |/ _ \ \ /\ / / |
            \  /\  /  | | | | (_) \ V  V /|_|
             \/  \/   |_|_|_|\___/ \_/\_/ (_)
    ]],
    [[
        01010111 01101001 01101100 01101100 01101111 01110111 00100001
    ]],
    [[
         .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.
        | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
        | | _____  _____ | || |     _____    | || |   _____      | || |   _____      | || |     ____     | || | _____  _____ | || |              | |
        | ||_   _||_   _|| || |    |_   _|   | || |  |_   _|     | || |  |_   _|     | || |   .'    `.   | || ||_   _||_   _|| || |      _       | |
        | |  | | /\ | |  | || |      | |     | || |    | |       | || |    | |       | || |  /  .--.  \  | || |  | | /\ | |  | || |     | |      | |
        | |  | |/  \| |  | || |      | |     | || |    | |   _   | || |    | |   _   | || |  | |    | |  | || |  | |/  \| |  | || |     | |      | |
        | |  |   /\   |  | || |     _| |_    | || |   _| |__/ |  | || |   _| |__/ |  | || |  \  `--'  /  | || |  |   /\   |  | || |     | |      | |
        | |  |__/  \__|  | || |    |_____|   | || |  |________|  | || |  |________|  | || |   `.____.'   | || |  |__/  \__|  | || |     |_|      | |
        | |              | || |              | || |              | || |              | || |              | || |              | || |     (_)      | |
        | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
         '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'
    ]],
    [[
         █     █░ ██▓ ██▓     ██▓     ▒█████   █     █░ ▐██▌
        ▓█░ █ ░█░▓██▒▓██▒    ▓██▒    ▒██▒  ██▒▓█░ █ ░█░ ▐██▌
        ▒█░ █ ░█ ▒██▒▒██░    ▒██░    ▒██░  ██▒▒█░ █ ░█  ▐██▌
        ░█░ █ ░█ ░██░▒██░    ▒██░    ▒██   ██░░█░ █ ░█  ▓██▒
        ░░██▒██▓ ░██░░██████▒░██████▒░ ████▓▒░░░██▒██▓  ▒▄▄
        ░ ▓░▒ ▒  ░▓  ░ ▒░▓  ░░ ▒░▓  ░░ ▒░▒░▒░ ░ ▓░▒ ▒   ░▀▀▒
          ▒ ░ ░   ▒ ░░ ░ ▒  ░░ ░ ▒  ░  ░ ▒ ▒░   ▒ ░ ░   ░  ░
          ░   ░   ▒ ░  ░ ░     ░ ░   ░ ░ ░ ▒    ░   ░      ░
            ░     ░      ░  ░    ░  ░    ░ ░      ░     ░
    ]],
    [[
        `8.`888b                 ,8'  8 8888 8 8888         8 8888         ,o888888o.  `8.`888b                 ,8'
         `8.`888b               ,8'   8 8888 8 8888         8 8888      . 8888     `88. `8.`888b               ,8'
          `8.`888b             ,8'    8 8888 8 8888         8 8888     ,8 8888       `8b `8.`888b             ,8'
           `8.`888b     .b    ,8'     8 8888 8 8888         8 8888     88 8888        `8b `8.`888b     .b    ,8'
            `8.`888b    88b  ,8'      8 8888 8 8888         8 8888     88 8888         88  `8.`888b    88b  ,8'
             `8.`888b .`888b,8'       8 8888 8 8888         8 8888     88 8888         88   `8.`888b .`888b,8'
              `8.`888b8.`8888'        8 8888 8 8888         8 8888     88 8888        ,8P    `8.`888b8.`8888'
               `8.`888`8.`88'         8 8888 8 8888         8 8888     `8 8888       ,8P      `8.`888`8.`88'
                `8.`8' `8,`'          8 8888 8 8888         8 8888      ` 8888     ,88'        `8.`8' `8,`'
                 `8.`   `8'           8 8888 8 888888888888 8 888888888888 `8888888P'           `8.`   `8'
    ]],
    [[
                                                 ,---.
        ,--.   ,--.,--.,--.,--.                  |   |
        |  |   |  |`--'|  ||  | ,---. ,--.   ,--.|  .'
        |  |.'.|  |,--.|  ||  || .-. ||  |.'.|  ||  |
        |   ,'.   ||  ||  ||  |' '-' '|   .'.   |`--'
        '--'   '--'`--'`--'`--' `---' '--'   '--'.--.
                                                 '--'
    ]],
}

local slogans = {
    "Speaking from experience, Willow is very tall",
    "Once, Willow beat a horse in a fistfight",
    "Willow had far too much fun making these slogans",
    'Willow is far too professional to say "fuck" on her NeoVim startup screen',
    "Just wait until you find out Willow's terrible, terrible secret",
}

local keys = {
    {
        { "\u{f002}", "Ctrl + T", "Search files" },
        { "\u{f0b0}", "Space + /", "Search text" },
    },
    {
        { "\u{f1da}", "Ctrl + R", "Recent files" },
        { "\u{f0c9}", "Space + f + b", "Find buffers" },
        { "\u{f07b}", "Space + p + p", "Switch project" },
    },
    {
        { "\u{f08b}", "Space + q", "Close buffer" },
        { "\u{f08b}", "Space + Q", "Close all buffers" },
        { "\u{f0c7}", "Space + x", "Write and close buffer" },
        { "\u{f0c7}", "Space + X", "Write and close all buffers" },
    },
    {
        { "\u{f126}", "Space + g + g", "Open Neogit" },
        { "\u{f1b2}", "Space + L", "Open Lazy" },
        { "\u{f085}", "Space + c + m", "Open Mason" },
    },
}

local M = {}
local ns = vim.api.nvim_create_namespace("WhcSplash")

local function pick(list)
    return list[math.random(#list)]
end

-- A chunk list is [text, highlight] pairs. Without a block width the line is centred on its own;
-- with one, the line starts at the block's left edge so that rows of a block stay aligned.
local function centred(chunks, width, block)
    local len = 0
    for _, chunk in ipairs(chunks) do
        len = len + vim.fn.strdisplaywidth(chunk[1])
    end
    local pad = math.max(0, math.floor((width - (block or len)) / 2))
    return { { string.rep(" ", pad) }, unpack(chunks) }
end

local function build(width)
    local lines = {}
    local logo = vim.split(pick(logos), "\n", { plain = true })
    while logo[#logo]:match("^%s*$") do
        table.remove(logo)
    end
    local logo_width = 0
    for _, line in ipairs(logo) do
        logo_width = math.max(logo_width, vim.fn.strdisplaywidth(line))
    end
    for _, line in ipairs(logo) do
        local text = line:gsub("%s+$", "")
        table.insert(lines, centred({ { text, "Title" } }, width, logo_width))
    end

    local v = vim.version()
    local rule = { { string.rep("─", math.min(width - 4, 60)), "NonText" } }
    local function blank()
        table.insert(lines, { { "" } })
    end
    blank()
    table.insert(lines, centred({ { ("NVIM v%d.%d.%d"):format(v.major, v.minor, v.patch), "Special" } }, width))
    table.insert(lines, centred(rule, width))
    table.insert(lines, centred({ { pick(slogans), "Comment" } }, width))
    for _, group in ipairs(keys) do
        table.insert(lines, centred(rule, width))
        for _, key in ipairs(group) do
            -- Fixed columns, so the shortcuts line up as one block.
            local row = {
                { key[1] .. "  ", "Special" },
                { ("%-14s"):format(key[2]), "Identifier" },
                { key[3], "Normal" },
            }
            table.insert(lines, centred(row, width, 46))
        end
    end
    return lines
end

function M.clear(buf)
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    -- The scroll onto the virtual lines would otherwise remain as rows of diff filler.
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        vim.api.nvim_win_call(win, function()
            vim.fn.winrestview({ topfill = 0 })
        end)
    end
end

function M.show()
    local buf = vim.api.nvim_get_current_buf()
    local lines = build(vim.api.nvim_win_get_width(0))
    -- Centre vertically with blank virtual lines above the empty first line.
    local top = math.max(0, math.floor((vim.api.nvim_win_get_height(0) - #lines) / 2))
    local above = {}
    for _ = 1, top do
        table.insert(above, { { "" } })
    end
    vim.list_extend(above, lines)
    vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, { virt_lines = above, virt_lines_above = true })
    -- Lines above the first one are only shown once the window is scrolled up onto them.
    vim.fn.winrestview({ topfill = #above })

    local group = vim.api.nvim_create_augroup("WhcSplashClear", { clear = true })
    vim.api.nvim_create_autocmd(
        { "InsertEnter", "TextChanged", "TextChangedI", "BufWritePre", "BufLeave", "WinResized" },
        {
            group = group,
            buffer = buf,
            once = true,
            callback = function()
                M.clear(buf)
            end,
        }
    )
end

function M.setup()
    math.randomseed(os.time())
    vim.api.nvim_create_autocmd("VimEnter", {
        group = vim.api.nvim_create_augroup("WhcSplash", { clear = true }),
        once = true,
        callback = function()
            local buf = vim.api.nvim_get_current_buf()
            local empty = vim.api.nvim_buf_get_name(buf) == ""
                and vim.api.nvim_buf_line_count(buf) == 1
                and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == ""
            if vim.fn.argc() == 0 and empty and not vim.o.insertmode then
                M.show()
            end
        end,
    })
end

return M
