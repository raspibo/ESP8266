for n,s in pairs(file.list()) do print(n.." size: "..s) end           -- Lista dei files presenti in memoria
print("Vcc="..(node.readvdd33()/1000).."V")
wifi.setmode(wifi.STATION)                                            -- Setup wifi in modalità client
wifi.sta.config("NinuxBO","")                                         -- Connessione alla rete Ninux, il parametro lasciato vuoto corrisponde alla password
cfg = {ip="10.51.0.24",netmask="255.255.0.0",gateway="10.51.0.1"}     -- Definizione dei parametri di rete, per dhcp wifi.sta.getip() senza dichirazione dei parametri
wifi.sta.setip(cfg)                                                   -- Settaggio dei parametri di connessione
wifi.sta.autoconnect(1)                                               -- Setup di autoconnessione, non so se sia necessario
led1 = 3                                                              -- I due GPIO porati sul connettore corrispondono ai pin 3 e 4
led2 = 4
ora=tmr.now();                                                        -- Mi segno l'ora di startup (uptime)
gpio.mode(led1, gpio.OUTPUT)                                          -- Setup dei pin in output
gpio.mode(led2, gpio.OUTPUT)
gpio.write(led1, gpio.LOW)
gpio.write(led2, gpio.LOW)

tmr.alarm(0, 10000, 1, function()                                     -- Setup del timer 0 ogni 10000msecondi si ripete (1) quando il timer scatta viene eseguita la funzione di seguito
if ( tmr.now() >  ora + 60000000 )then                                -- Se sono passati 60 secondi dall'ultimo comando via web entrambi i GPIO vengono settati a zero
     gpio.write(led1, gpio.LOW);                                      -- questo serve per evitare che le valvole rimangano aperte se la connettività wifi viene cade
     gpio.write(led2, gpio.LOW);
     print "Timeout -  OFF all relays."                                -- Messaggio di avviso su connessione seriale quando scatta il timer       
end
wifi_status=wifi.sta.status()                                         -- Controllo lo stato della connessione wifi e in base al valore stampo su seriale le info
if (wifi_status==0) then
     print "STATION_IDLE: OK"
elseif (wifi_status==1) then
     print "STATION_CONNECTING...."
elseif (wifi_status==2) then
     print "STATION_WRONG_PASSWORD: KO"
elseif (wifi_status==3) then
     print "STATION_NO_AP_FOUND: KO"
elseif (wifi_status==4) then
     print "STATION_CONNECT_FAIL: KO"
elseif (wifi_status==5) then
     print "STATION_GOT_IP: OK"
end
end)
     
srv=net.createServer(net.TCP)                                         -- Creo un server TCP
srv:listen(80,function(conn)                                          -- Metto in ascolto il server sulla porta 80 (web)
    conn:on("receive", function(client,request)                       -- Attendo richiesta dati da un client web
        local buf = "";
        local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
        if(method == nil)then
            _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
        end
        local _GET = {}
        if (vars ~= nil)then
            for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
                _GET[k] = v
            end
        end
        buf = buf.."<h1> Irrigazione </h1>";                          -- Invio al client una semplice pagina web con due pulsanti per accendere o spegnere le elettrovalvole
        buf = buf.."<p>Zona1 <a href=\"?pin=ON1\"><button>ON</button></a>&nbsp;<a href=\"?pin=OFF1\"><button>OFF</button></a></p>";
        buf = buf.."<p>Zona2 <a href=\"?pin=ON2\"><button>ON</button></a>&nbsp;<a href=\"?pin=OFF2\"><button>OFF</button></a></p>";
        local _on,_off = "",""
        if(_GET.pin == "ON1")then                                     -- Gestione dei request inviati dal client quando vengono premuti i pulsanti sulla pagina web
             gpio.write(led1, gpio.HIGH);
             ora=tmr.now();
        elseif(_GET.pin == "OFF1")then
             gpio.write(led1, gpio.LOW);
        elseif(_GET.pin == "ON2")then
             gpio.write(led2, gpio.HIGH);
             ora=tmr.now();
             print(ora);
        elseif(_GET.pin == "OFF2")then
             gpio.write(led2, gpio.LOW);
        end
        client:send(buf);                                             -- Invio al client della variabile buf che contiene la pagina web
        client:close();
        collectgarbage();
    end)
end)
