name="VDS stats"
sample="VDS CPU 100% | RAM 100% | RX 100.00 KB/s | TX 100.00 KB/s"
interval=3

-- Kurulum notundaki kimlik bilgilerini buraya yaz.
local username="YOUR_TM_WIDGET_USERNAME"
local password="YOUR_TM_WIDGET_PASSWORD"
local endpoint="https://45.136.7.49/tm-vds/metrics"

function onUpdate()

    local command = 'curl.exe --silent --show-error --max-time 2 --user "'
        .. username .. ':' .. password .. '" "' .. endpoint .. '"'
    local output = tf.runCmdLine(command)
    if output == nil or output == "" then
        return "VDS offline"
    end
    return output:gsub("[\r\n]+", " ")
end

function onClick()
end
