--load credentials
--SID and PASSWORD should be saved according wireless router in use
dofile("credentials.lua")

function startup()
    if file.open("init.lua") == nil then
      print("init.lua deleted")
    else
      print("Running")
      file.close("init.lua")
      dofile("estufa.lua")
    end
end

--init.lua
wifi.sta.disconnect()
print("set up wifi mode")
wifi.setmode(wifi.STATION)
wifi.sta.config(WIFI_SSID,WIFI_PASSWORD)

tmr.create():alarm(1000, tmr.ALARM_AUTO, function(cb_timer)
    if wifi.sta.getip() == nil then
        print("Waiting for IP address...")
    else
        cb_timer:unregister()
        print("WiFi connection established, IP address: " .. wifi.sta.getip())
        print("You have 3 seconds to abort")
        print("Waiting...")
        tmr.create():alarm(3000, tmr.ALARM_SINGLE, startup)
    end
end)
