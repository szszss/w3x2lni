local w2l = w3x2lni()

w2l:set_config
{
    mode = 'obj',
}

function w2l:map_load(path)
    return read(path)
end

local ok
function w2l:map_save(name, buf)
    if name ~= 'war3map.w3q' then
        return
    end
    ok = true
    local upgrade = w2l:frontend_obj('upgrade', buf)
    assert(upgrade.R000.gnam[1] == nil)
    assert(upgrade.R000.gnam[2] == '铁甲')
    assert(upgrade.R000.gnam[3] == '铁甲')
    assert(upgrade.R000.gnam[4] == '铁甲')
    assert(upgrade.R000.gnam[5] == '钢甲')
    assert(upgrade.R000.gnam[6] == '钢甲')
    assert(upgrade.R000.gnam[7] == '钢甲')
    assert(upgrade.R000.gnam[8] == '重金甲')
    assert(upgrade.R000.gnam[9] == nil)
    assert(upgrade.R000.gnam[10] == nil)

    assert(upgrade.R002.greq[1] == nil)
    assert(upgrade.R002.greq[2] == '')
    assert(upgrade.R002.greq[3] == '')
    assert(upgrade.R002.greq[4] == nil)
    assert(upgrade.R002.greq[5] == nil)
    assert(upgrade.R002.greq[6] == nil)
    assert(upgrade.R002.greq[7] == nil)
    assert(upgrade.R002.greq[8] == nil)
    assert(upgrade.R002.greq[9] == nil)
    assert(upgrade.R002.greq[10] == nil)
end

local slk = {}
w2l:frontend(slk)

assert(slk.upgrade.R001.name[1] == '1')
assert(slk.upgrade.R001.name[2] == '钢甲')
assert(slk.upgrade.R001.name[3] == '重金甲')
assert(slk.upgrade.R001.name[4] == '')
assert(slk.upgrade.R001.name[5] == '2')
assert(slk.upgrade.R001.name[6] == '')
assert(slk.upgrade.R001.name[7] == '')
assert(slk.upgrade.R001.name[8] == '3')
assert(slk.upgrade.R001.name[9] == '3')
assert(slk.upgrade.R001.name[10] == '3')

assert(slk.upgrade.R002.requires[1] == '')
assert(slk.upgrade.R002.requires[2] == '')
assert(slk.upgrade.R002.requires[3] == '')
assert(slk.upgrade.R002.requires[4] == '')
assert(slk.upgrade.R002.requires[5] == '')
assert(slk.upgrade.R002.requires[6] == '')
assert(slk.upgrade.R002.requires[7] == '')
assert(slk.upgrade.R002.requires[8] == '')
assert(slk.upgrade.R002.requires[9] == '')
assert(slk.upgrade.R002.requires[10] == '')

w2l:backend(slk)
assert(ok)
