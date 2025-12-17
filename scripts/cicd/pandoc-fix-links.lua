-- see if the file exists
function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

-- 1. Replaces .md with .html
-- 2. Replaces absolute paths with relative ones
-- 3. Replaces folder links with links to their index / readme
function fix_link (url) 
  -- Replace md with html
  fixed_url = url:gsub("%.md", ".html")
  -- Replace project-root-relative (i.e. /path/to/thing.md) paths with relative ones
  fixed_url = fixed_url:gsub("^/", (
    function(s)
      basedir = io.popen("realpath --relative-to=\"$(dirname \"" .. s:sub(2) .. "\")\" .", 'r'):read('*a')
      return basedir:gsub("%s", "") .. "/" .. s:sub(2)
    end
  ))
  -- Allowed readme / index names
  dir_name = {} -- values are functions that return the path to the new link
  dir_name["index.md"] = (function(s) return s:gsub("/?$", "/index.html") end)
  dir_name["INDEX.md"] = (function(s) return s:gsub("/?$", "/INDEX.html") end)
  dir_name["readme.md"] = (function(s) return s:gsub("/?$", "/readme.html") end)
  dir_name["README.md"] = (function(s) return s:gsub("/?$", "/README.html") end)
  -- Is the url pointing to a folder?
  file_or_folder = io.popen("[ -d '" .. fixed_url .. "' ] && echo 'folder'", 'r'):read('*a')
  -- If it's a folder, find the readme / index and replace the link with that. 
  if file_or_folder:gsub("%s", "") == "folder" then
    for index,mk_path in pairs(dir_name) do
      if file_exists(fixed_url .. "/" .. index) then
        fixed_url = mk_path(fixed_url)
        break
      end
    end
  end
  return fixed_url
end


function Link(link) link.target = fix_link(link.target); return link end
function Image(img) img.src = fix_link(img.src); return src end
-- return {{Meta = Meta}, {Link = Link, Image = Image}}