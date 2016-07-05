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

local command_code = {
		[1]    = "DB_RESERVE_REQ 1",
		[2]    = "DB_RESERVE_CON 2",
		[3]    = "DB_RELEASE_REQ 3",
		[4]    = "DB_RELEASE_CON 4",
		[5]    = "DB_STATUS_REQ 5",
		[6]    = "DB_STATUS_CON 6",
		[7]    = "DB_RELEASE_ALL_REQ 7",
		[8]    = "DB_RELEASE_ALL_CON 8",
		[9]    = "DB_PING_REQ 9",
		[10]   = "DB_PING_CON 10",
		[11]   = "DB_RESTART_ALL_REQ 11",
		[12]   = "DB_RESTART_ALL_CON 12",
		[13]   = "DB_SET_IMEI_REQ 13",
		[14]   = "DB_SET_IMEI_CON 14",
		[11]   = "DB_BOOT_IND 0x11",
		[8011] = "DB_BOOT_RESP 0x8011",
		[12]   = "DB_LIMIT_ALARM_IND 0x12",
		[8012] = "DB_LIMIT_ALARM_RESP 0x8012",
		[13]   = "DB_BROKEN_SIM_IND 0x13",
		[8013] = "DB_BROKEN_SIM_RESP 0x8013",
		[14]   = "DB_REMOTE_ALARM_IND 0x14",
		[15]   = "DB_PING_IND 0x15",
		[8015] = "DB_PING_RESP 0x8015",
		[16]   = "DB_MESSAGE_IND 0x16",
		[17]   = "DB_BLOCKPORT_REQ 0x17",
		[8017] = "DB_BLOCKPORT_CON 0x8017",
		[18]   = "DB_UNBLOCKPORT_REQ 0x18",
		[8018] = "DB_UNBLOCKPORT_CON 0x8018",
		[19]   = "DB_RESTART_REQ 0x19",
		[1a]   = "DB_RESTART_CON 0x1a",
		[1c]   = "DB_STATISTIK_REQ 0x1c",
		[801c] = "DB_STATISTIK_CON 0x801c",
		[1d]   = "DB_LIMIT_MAXCALL_IND 0x1d",
		[801d] = "DB_LIMIT_MAXCALL_RESP 0x801d",
		[1e]   = "DB_LIMIT_MAXSMS_IND 0x1e",
		[801e] = "DB_LIMIT_MAXSMS_RESP 0x801e",
		[1f]   = "DB_ALARM_REQ 0x1f",
		[801f] = "DB_ALARM_CON 0x801f",
		[20]   = "DB_CALLS_REQ 0x20",
		[8020] = "DB_CALLS_CON 0x8020",
		[21]   = "DB_RSSI_IND 0x21",
		[22]   = "DB_INCOMING_IND 0x22",
		[8022] = "DB_INCOMING_RESP 0x8022",
		[23]   = "DB_BALANCE_CHECK_FAILED_IND 0x23",
		[24]   = "DB_LIMIT_MAXINCOMINGCALL_IND 0x24",
		[8024] = "DB_LIMIT_MAXINCOMINGCALL_RESP 0x8024",
		[25]   = "DB_SENDCALL_REQ 0x25",
		[8025] = "DB_SENDCALL_CONF 0x8025",
		[26]   = "DB_CANCELCALL_REQ 0x26",
		[8026] = "DB_CANCELCALL_CONF 0x8026",
		[27]   = "DB_ENDCALL_IND 0x27",
		[8027] = "DB_ENDCALL_RESP 0x8027",
		[28]   = "DB_LIMIT_MAXUCALL_IND 0x28",
		[8028] = "DB_LIMIT_MAXUCALL_RESP 0x8028",
		[29]   = "DB_DATA_QUALITY_IND 0x29",
		[8029] = "DB_DATA_QUALITY_RESP 0x8029",
		[30]   = "DB_SIMDB_REQ 0x30",
		[8030] = "DB_SIMDB_CON 0x8030",
		[31]   = "DB_NIGHT_IND 0x31",
		[8031] = "DB_NIGHT_RESP 0x8031",
		[32]   = "DB_WRONGVGATE_IND 0x32",
		[33]   = "DB_STATUS_IND 0x33",
		[34]   = "DB_USAGE_IND 0x34",
		[8034] = "DB_USAGE_RESP 0x8034",
		[35]   = "DB_CONNECT_IND 0x35",
		[36]   = "DB_MMS_MESSAGE_IND 0x36",
		[37]   = "DB_SETLIMIT_REQ 0x37",
		[38]   = "DB_SERVICE_REQ 0x38",
		[39]   = "DB_OPERATOR_LIST_IND 0x39",
		[3a]   = "DB_FTPPUT_IND 0x3a",
		[40]   = "DB_CONTROLLER_INFO_IND 0x40",
		[41]   = "DB_USE_CHADDR_REQ 0x41",
		[42]   = "DB_USE_CHADDR_CONF 0x8041",
}

-- Registration protocol log
p_upm.fields = { f_cmd_code,     		f_hdr_flags,		f_hdr_flags_comcode,
                 f_hdr_flags_errcode,	f_hdr_bool,        	f_pl_len,           
				 f_hdr_flags_drct,		f_payload, 			command_code}

-- function dissector for upm protocol
function p_upm.dissector(buf, pinfo, tree)
    if buf:len() == 0 then return end
    pinfo.cols.protocol = p_upm.name       -- in column Protocol the protocol name will be issued
    subtree = tree:add(p_upm, buf(0))      -- create subtree
	--subtree:append_text(string.format(", Command Code (0x%02x)", cmd))
    subtree:add(f_hdr_flags_drct, buf(0,2))      -- start to add feld
	subtree:add(f_hdr_flags_comcode, buf(2,2))      -- start to add feld
--	local cmd = buf(0,4):uint()
	if cmd == 0x80000000 then
		local type_str = packettypes[buf(0,1):uint()]
    if type_str == nil then type_str = "Unknown" end
       pinfo.cols.info = "Type: " .. type_str   -- column Info the type of packet will be issued
    local pl_len = buf(8,4):le_uint()
       subtree:add(f_payload, buf(8,pl_len))  -- data
    else
 --      subtree:append_text(string.format(", Command Code (0x%02x)", cmd))
    end
end

--       subtree:add(f_cmd_code, 		buf(0,4))
--       subtree:add(f_hdr_flags,         buf(2,1))
--       subtree:add(f_hdr_flags_comcode, buf(0,1))
--       subtree:add(f_hdr_flags_errcode, buf(2,1))
--       subtree:add(f_payload, 		buf(2,1))
--       subtree:add(f_hdr_bool,  		buf(2,1))
--       subtree:add_le(f_pl_len, 		buf(4,4))     -- feld lengh in Little Endian

-- dissector registration on TCP port 57342
local tcp_dissector_table = DissectorTable.get("tcp.port")
tcp_dissector_table:add(57342, p_upm)