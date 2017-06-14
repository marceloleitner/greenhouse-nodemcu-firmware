require("sntp")
require("rtctime")
require("cron")
dofile("telnet.lua")

mqtt_connected = false

-- greenery
gpio_greenery = 0
gpio.mode(gpio_greenery, gpio.OUTPUT)
gpio.write(gpio_greenery, gpio.LOW)
-- perennials
gpio_perennials = 1
gpio.mode(gpio_perennials, gpio.OUTPUT)
gpio.write(gpio_perennials, gpio.LOW)
-- nursery
gpio_nursery = 2
gpio.mode(gpio_nursery, gpio.OUTPUT)
gpio.write(gpio_nursery, gpio.LOW)
-- empty
gpio.mode(5, gpio.OUTPUT)
gpio.write(5, gpio.LOW)
-- led
gpio_led = 4
gpio.mode(gpio_led, gpio.OUTPUT)
gpio.write(gpio_led, gpio.LOW)
-- ds18b20 sensors
gpio_ds18b20 = 6
-- dht
gpio_dht = 7

function tstamp()
	tm = rtctime.epoch2cal(rtctime.get())
	return string.format("%04d/%02d/%02d %02d:%02d:%02d",
			     tm["year"], tm["mon"], tm["day"],
			     tm["hour"], tm["min"], tm["sec"])
end

function log(msg)
	print(tstamp().." "..msg)
end

log("Starting!")

function safe_publish(subject, value, qos, persist, cb)
	if m and mqtt_connected then
		return m:publish(subject, value, qos, persist, cb)
	end
	return false
end

function set_greenery(s)
	if s == 1 then
		log("Greenery on")
		greenery_state = 1
		gpio.write(gpio_greenery, gpio.HIGH)
	else
		log("Greenery off")
		greenery_state = 0
		gpio.write(gpio_greenery, gpio.LOW)
	end
	safe_publish("greenhouse/greenery/pump",greenery_state,0,0, nil)
end

function toggle_greenery()
	set_greenery(greenery_state == 1 and 0 or 1)
end

function set_nursery(s)
	if s == 1 then
		log("Nursery on")
		nursery_state = 1
		gpio.write(gpio_nursery, gpio.HIGH)
	else
		log("Nursery off")
		nursery_state = 0
		gpio.write(gpio_nursery, gpio.LOW)
	end
	safe_publish("greenhouse/nursery/pump",nursery_state,1,0, nil)
end

set_greenery(0)
set_nursery(0)

-- Use the nodemcu specific pool servers and keep the time synced
-- forever (this has the autorepeat flag set).
sntp.sync(nil, function(s, us, server, info)
		log('SNTP synced')
	end, function (err, msg)
		log("SNTP failed: "..msg)
	end, 1)

-- Init mqtt stuff
m = mqtt.Client(MQTT_CLIENTID, 120, MQTT_USER, MQTT_PASS)
-- setup Last Will and Testament (optional)
-- Broker will publish a message with qos = 0, retain = 0, data = "offline"
-- to topic "/lwt" if client don't send keepalive packet
m:lwt("greenhouse/greenery/status", 0, 0, 1)
m:on("offline",
     function(client)
	log("MQTT offline")
	mqtt_connected=false
     end)

m:connect("192.168.254.2", 1883, 0, 1,
	  function(c)
		mqtt_connected=true
		c:publish("greenhouse/greenery/status",1,0,1, nil)
		c:publish("greenhouse/greenery/pump",greenery_state,1,0, nil)
		c:publish("greenhouse/nursery/pump",nursery_state,1,0, nil)
	  	log("MQTT connected")
	  end,
          function(client, reason)
	  	log("MQTT connect failed reason: "..reason)
	  end)

-- on publish message receive event
--[[
m:on("message", function(client, topic, data)
  print(topic .. ":" )
  if data ~= nil then
    print(data)
  end
end)
]]

-- Init cron timers

cron.schedule("*/15 * * * *", function(e)
	toggle_greenery()
end)

cron.schedule("0 */1 * * *", function(e)
	set_nursery(1)
	tmr.create():alarm(5*60*1000, tmr.ALARM_SINGLE, function(cb_timer)
		set_nursery(0)
	end)
end)

cron.schedule("*/5 * * * *", function(e)
	status, temp, humi, temp_dec, humi_dec = dht.read(gpio_dht)
	if status == dht.OK then
	    log(string.format("Greenhouse Temperature:%d Humidity:%d",
		  temp,
		  humi
	    ))
	    safe_publish("greenhouse/temperature", temp, 1, 1)
	    safe_publish("greenhouse/humidity", humi, 1, 1)

	elseif status == dht.ERROR_CHECKSUM then
	    log("DHT Checksum error.")
	elseif status == dht.ERROR_TIMEOUT then
	    log("DHT timed out.")
	end
end)

tmr.create():alarm(5000, tmr.ALARM_AUTO, function(cb_timer)
	gpio.write(gpio_led, gpio.LOW)
	tmr.create():alarm(1000, tmr.ALARM_SINGLE, function(cb_timer)
		gpio.write(gpio_led, gpio.HIGH)
	end)
end)

temp_solucao = dofile("yet-another-ds18b20.lua")
cron.schedule("*/5 * * * *", function(e)
	temp_solucao.read(gpio_ds18b20, function(r)
		for k, v in pairs(r) do
			local t = v/10000.0
			log("Greenery solution temperature:"..t)
			safe_publish("greenhouse/greenery/solution_temperature",
				     t, 1, 1)
		end
	end)
end)


