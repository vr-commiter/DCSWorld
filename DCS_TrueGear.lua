local TrueGear = {}
local weaponShellsCount = {}
local data = {
    G = 0,
    AngularVelocityX = 0
}
local default_output_file = nil
local sendTime = {
    G = 0,
    Tilt = 0,
    Pitch = 0
}
local canDeath = false
function TrueGear.onSimulationStart()
    package.path = package.path..";.\\LuaSocket\\?.lua"
    package.cpath = package.cpath..";.\\LuaSocket\\?.dll"
    socket = require("socket")
    host = "localhost"
    port = 12138
    c = socket.try(socket.connect(host, port)) -- connect to the listener
    c:setoption("tcp-nodelay",true) -- set immediate transmission mode
end

function CheckAcceleration(acceleration)
    if acceleration then
        local value = acceleration.y        -- G
        if data["G"] == value then
            return
        end
        data["G"] = value
        canDeath = true        
        if value > 1.5 then
            local power = math.floor(value / 1)
            power = math.min(power, 5)
            if os.clock() - sendTime["G"] > 0.15 then
                sendTime["G"] = os.clock()
                socket.try(c:send("G" .. power))
            end
            
        elseif value < -0.2 then
            local power = math.floor(value / -0.2)
            power = math.min(power, 5)
            if os.clock() - sendTime["G"] > 0.15 then
                sendTime["G"] = os.clock()
                socket.try(c:send("NegativeG" .. power))
            end            
        end
    else
        if canDeath then
            canDeath = false
            socket.try(c:send("PlayerDeath"))
        end
    end
    
end

function CheckAngularVelocity(angularVelocity)
    if angularVelocity then
        local x = angularVelocity.x     -- 倾斜速度 负的左正的右
        local z = angularVelocity.z     -- 俯仰速度 负的下正的上
        if data["AngularVelocityX"] == x then
            return
        end
        data["AngularVelocityX"] = x
        if x > 0.2 then
            local power = math.floor(x / 0.2)
            power = math.min(power, 5)
            if os.clock() - sendTime["Tilt"] > 0.12 then
                sendTime["Tilt"] = os.clock()
                socket.try(c:send("RightTilt" .. power))
            end
        elseif x < -0.2 then
            local power = math.floor(x / -0.2)
            power = math.min(power, 5)
            if os.clock() - sendTime["Tilt"] > 0.12 then
                sendTime["Tilt"] = os.clock()
                socket.try(c:send("LeftTilt" .. power))
            end            
        end
        if z > 0.02 then
            local power = math.floor(z / 0.02)
            power = math.min(power, 5)
            if os.clock() - sendTime["Tilt"] > 0.12 then
                sendTime["Tilt"] = os.clock()
                socket.try(c:send("PitchUp" .. power))
            end
        elseif z < -0.02 then
            local power = math.floor(z / -0.02)
            power = math.min(power, 5)
            if os.clock() - sendTime["Tilt"] > 0.12 then
                sendTime["Tilt"] = os.clock()
                socket.try(c:send("PitchDown" .. power))
            end            
        end
    end
    
    
end

local canopyOnce = true
local parachuteOnce = true
local lastLandingGear = 0

function CheckMechInfo(mechInfo)
    if mechInfo then
        local gear = mechInfo.gear.value
        local parachute = mechInfo.parachute.value
        local canopy = mechInfo.canopy.value
        if gear > 0 and lastLandingGear == 0 then
            socket.try(c:send("LangGearOpening"))
        elseif gear < 1 and lastLandingGear == 1 then
            socket.try(c:send("LangGearClosed"))
        end
        if parachute > 0 then
            if parachuteOnce then
                socket.try(c:send("ParachuteOpening"))
            end
            parachuteOnce = false       
        else
            parachuteOnce = true  
        end
        if canopy == 1 then
            if canopyOnce then
                socket.try(c:send("CanopyClosed"))
            end
            canopyOnce = false       
        else
            canopyOnce = true  
        end
    end

end

function CheckPayloadInfo(payloadInfo)
    if payloadInfo then
        for i_st,st in pairs (payloadInfo.Stations) do
            local name = Export.LoGetNameByType(st.weapon.level1,st.weapon.level2,st.weapon.level3,st.weapon.level4);
            if name then
                if weaponShellsCount[name] then
                    if weaponShellsCount[name] > st.count then
                        socket.try(c:send("Fire"))
                    end
                end
                weaponShellsCount[name] = st.count
            end
        end
        if weaponShellsCount["Shell"] then
            if weaponShellsCount["Shell"] > payloadInfo.Cannon.shells then
                socket.try(c:send("Fire"))
            end
        end
        weaponShellsCount["Shell"] = payloadInfo.Cannon.shells
    end
end

function TrueGear.onSimulationFrame()
    CheckAcceleration(Export.LoGetAccelerationUnits())
    CheckAngularVelocity(Export.LoGetAngularVelocity())
    CheckPayloadInfo(Export.LoGetPayloadInfo())
    CheckMechInfo(Export.LoGetMechInfo())
end

function TrueGear.onSimulationStop()
    c:close()
end

DCS.setUserCallbacks(TrueGear)