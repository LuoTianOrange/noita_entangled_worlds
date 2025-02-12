local rpc = net.new_rpc_namespace()
local tele = {}
local who_has_tele = {}
local is_holding

rpc.opts_reliable()
function rpc.end_tele()
    local com = EntityGetFirstComponent(ctx.rpc_player_data.entity, "TelekinesisComponent")
    if com ~= nil and ComponentGetValue2(com, "mState") ~= 0 then
        ComponentSetValue2(com, "mInteract", true)
    end
    for i, p in ipairs(who_has_tele) do
        if p == ctx.rpc_peer_id then
            table.remove(who_has_tele, i)
            break
        end
    end
end

rpc.opts_reliable()
function rpc.send_tele(body_gid, n, extent, aimangle, bodyangle, distance, mindistance)
    local com = EntityGetFirstComponent(ctx.rpc_player_data.entity, "TelekinesisComponent")
    if com ~= nil then
        local ent = ewext.find_by_gid(body_gid)
        if ent ~= nil then
            local body_id = PhysicsBodyIDGetFromEntity(ent)[n]
            if body_id == nil then
                return
            end
            if not table.contains(who_has_tele, ctx.rpc_peer_id) then
                table.insert(who_has_tele, ctx.rpc_peer_id)
                ComponentSetValue2(com, "mState", 1)
                if is_holding == ent then
                    local mycom = EntityGetFirstComponent(ctx.my_player.entity, "TelekinesisComponent")
                    if mycom ~= nil then
                        ComponentSetValue2(mycom, "mState", 0)
                    end
                end
            end
            ComponentSetValue(com, "mBodyID", body_id)
            ComponentSetValue2(com, "mStartBodyMaxExtent", extent)
            ComponentSetValue2(com, "mStartAimAngle", aimangle)
            ComponentSetValue2(com, "mStartBodyAngle", bodyangle)
            ComponentSetValue2(com, "mStartBodyDistance", distance)
            ComponentSetValue2(com, "mMinBodyDistance", mindistance)
        end
    end
end

local has_tele = false

local last = 1

local ent_to_body = {}

local function body_to_ent(id)
    for ent, lst in pairs(ent_to_body) do
        for i, bid in ipairs(lst) do
            if bid == id then
                return ent, i
            end
        end
    end
end

local sent_track_req = {}

function tele.on_world_update()
    local n = EntitiesGetMaxID()
    for ent = last + 1, n do
        if EntityGetIsAlive(ent) then
            local lst = PhysicsBodyIDGetFromEntity(ent)
            if lst ~= nil and #lst ~= 0 then
                ent_to_body[ent] = lst
            end
        end
    end
    last = n

    if GameGetFrameNum() % 60 == 23 then
        for ent, _ in pairs(ent_to_body) do
            if not EntityGetIsAlive(ent) then
                ent_to_body[ent] = nil
            end
        end
    end

    local com = EntityGetFirstComponent(ctx.my_player.entity, "TelekinesisComponent")
    if com ~= nil then
        if ComponentGetValue2(com, "mState") ~= 0 then
            local body = ComponentGetValue(com, "mBodyID")
            local ent, num = body_to_ent(tonumber(body))
            if ent ~= nil then
                local gid
                for _, v in ipairs(EntityGetComponent(ent, "VariableStorageComponent") or {}) do
                    if ComponentGetValue2(v, "name") == "ew_gid_lid" then
                        gid = v
                        break
                    end
                end
                if gid ~= nil then
                    is_holding = ent
                    has_tele = true
                    rpc.send_tele(
                        ComponentGetValue2(gid, "value_string"),
                        num,
                        ComponentGetValue2(com, "mStartBodyMaxExtent"),
                        ComponentGetValue2(com, "mStartAimAngle"),
                        ComponentGetValue2(com, "mStartBodyAngle"),
                        ComponentGetValue2(com, "mStartBodyDistance"),
                        ComponentGetValue2(com, "mMinBodyDistance")
                    )
                elseif not table.contains(sent_track_req, ent) then
                    table.insert(sent_track_req, ent)
                    ewext.track(ent)
                end
            end
        elseif has_tele then
            has_tele = false
            rpc.end_tele()
        end
    end
end

return tele
