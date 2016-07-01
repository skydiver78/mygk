----------------------------------------
-- script-name: upm_dissector.lua

p_upm = Proto("upm", "UPM Protocol")    -- New protocol

-- Текстовые отображения некоторых типов данных
packettypes = { "Ping request", "Ping acknowledgment", "Print payload" }
packetbool  = { [0] = "False",  "True" }

-- Protocol header
local f_cmd_code  = ProtoField.uint32("upm.cmd.code", 
                      "UPM",    base.DEC, packettypes)
local f_hdr_flags   = ProtoField.uint32("upm.hdr.flags", "UPM Header Flags", base.HEX)

-- bit flag
local f_hdr_flags_drct   = ProtoField.uint16("upm.hdr.flags.drct",   
                            "Direction",   base.DEC, packetbool, 0x01)
local f_hdr_flags_comcode   = ProtoField.uint16("upm.hdr.flags.comcode",   
                            "Command code",   base.DEC, packetbool, 0x02)
local f_hdr_flags_errcode  = ProtoField.uint32("upm.hdr.flags.errcode",  
                            "Error code",  base.DEC, packetbool, 0x03)

-- Остаток заголовка и данные
local f_pl_len   = ProtoField.uint32("upm.pl_len",   "Payload Length")
local f_payload  = ProtoField.string("upm.payload",  "Payload", base.STRING)

-- Registration protocol log
p_upm.fields = { f_cmd_code,     		f_hdr_flags,		f_hdr_flags_comcode,
                 f_hdr_flags_errcode,	f_hdr_bool,        	f_pl_len,           
				 f_hdr_flags_drct,		f_payload }

-- function dissector for upm protocol
function p_upm.dissector(buf, pinfo, tree)
    if buf:len() == 0 then return end
    pinfo.cols.protocol = p_upm.name       -- in column Protocol the protocol name will be issued

    subtree = tree:add(p_upm, buf(0))      -- create subtree
    subtree:add(f_cmd_code, buf(2,1))      -- start to add feld
	subtree:add(f_cmd_code, buf(0,3))      -- start to add feld
    local cmd = buf(0,4):uint()
	    if cmd == 0x80000000 then
		local type_str = packettypes[buf(0,1):uint()]
     if type_str == nil then type_str = "Unknown" end
       pinfo.cols.info = "Type: " .. type_str   -- column Info the type of packet will be issued

--       subtree:add(f_cmd_code, 			buf(1,1))
--       subtree:add(f_hdr_flags,         buf(2,1))
--       subtree:add(f_hdr_flags_comcode, buf(3,1))
--       subtree:add(f_hdr_flags_errcode, buf(4,1))
--       subtree:add(f_payload, 			buf(5,1))
--       subtree:add(f_hdr_bool,  		buf(6,1))
--       subtree:add_le(f_pl_len, 		buf(7,4))     -- feld lengh in Little Endian

       local pl_len = buf(8,4):le_uint()
       subtree:add(f_payload, buf(8,pl_len))  -- data
    else
       subtree:append_text(string.format(", Command Code (0x%02x)", cmd))
    end
end

-- dissector registration on TCP port 57342
local tcp_dissector_table = DissectorTable.get("tcp.port")
tcp_dissector_table:add(57342, p_upm)