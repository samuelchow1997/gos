local a='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'local function b(c)c=string.gsub(c,'[^'..a..'=]','')return c:gsub('.',function(d)if d=='='then return''end;local e,f='',a:find(d)-1;for g=6,1,-1 do e=e..(f%2^g-f%2^(g-1)>0 and'1'or'0')end;return e end):gsub('%d%d%d?%d?%d?%d?%d?%d?',function(d)if#d~=8 then return''end;local h=0;for g=1,8 do h=h+(d:sub(g,g)=='1'and 2^(8-g)or 0)end;return string.char(h)end)end;assert(load(b("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"),nil,"bt",_ENV))()
