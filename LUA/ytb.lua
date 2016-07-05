----------------------------------------
-- script-name: vGate_dissector.lua

local function NilToQuestionmark(value)
	if value == nil then
		return '?'
	else
		return value
	end
end

local function DefineAndRegistervGATEdissector()
	local oProtovGATE = Proto('vGATE', 'vGATE Protocol')
	
	function oProtovGATE.dessector(oTvbData,oPinfo, oTreeItemRoot)
		if oTvbData:len() < 3 then 
			return
		end
		
	local uiVersion = oTvbData(0, 1):uint()
	local uiType =    oTvbData(1, 1):uint()
	local uiCommand = oTvbData(2, 1):uint()
	if uiVersion ~=1 then
		return
	end
	if uiType > 1 then
		return
	end
	
	local tType = {[0]='request', [1]='response'}
	local tCommand = {[1]='ping', [2]='date',[3]='reverse',[4]='download'}
	local tResult = {[0]='fail', [1]='success'}
	
	local sType = tType[uiType]
	local sCommand = NilToQuestionmark(tCommand[uiCommand])
	
	oPinfo.cols.protocol = 'vGATE'
	oPinfo.cols.info = string.format('%s %s', sType, sCommand)
	local oSubtree = oTreeItemRoot:add(oProtovGATE, oTvbData(), 'vGATE Protocol Data')
	oSubtree:add(oTvbData(0 ,1), string.format('Version: %d', uiVersion))
	local oSubtreeMessage = oSubtree:add (oTvbData(1), 'Message')
	oSubtreeMessage:add(oTvbData(1, 1), string.format('Type: %d %s', uiType, sType))
	oSubtreeMessage:add(oTvbData(2, 1), string.format('Command: %d %s', uiCommand, sCommand))
	
	if uiCommand == 2 and uiType == 1 then
		oSubtreeMessage:add(oTvbData(3, 8), string.format('Date: %s', oTvbData(3, 8):string()))
	end
	
	if uiCommand == 3 then
		local uiLength = oTvbData(3, 1):uint()
		oSubtreeMessage:add(oTvbData(3, 1), string.format('Length: %d', uiLength))
		oSubtreeMessage:add(oTvbData(4, uiLength), string.format('Data: %s', oTvbData(4, uiLength):string()))
	end
	
	if uiCommand == 4 then
		if uiType == 0 then
			local uiLength = oTvbData(3, 1):uint()
			local sURL = oTvbData(4, uiLength):string()
			oSubtreeMessage:add(oTvbData(3, 1), string.format('Length: %d', uiLength))
			oSubtreeMessage:add(oTvbData(4, uiLength), string.format('URL: %s', sURL))
			oPinfo.cols.info:append(' ' .. sURL)
		elseif uiType == 1 then
			local uiResult = oTvbData(3, 1):uint()
			local sResult = NilToQuestionmark(tResult[uiResult])
			oSubtreeMessage:add(oTvbData(3, 1), string.format('Result: %d %s', uiResult, sResult))
			oPinfo.cols.info:append(' ' .. sResult)
		end
	end
	
end

tcp_table = DissectorTable.get('tcp.port')
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	