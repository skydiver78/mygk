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
	
	local sType = tType[uiType]
	local sCommand = NilToQuestionmark(tCommand[uiCommand])
	
	oPinfo.cols.protocol = 'vGATE'
	oPinfo.cols.info = string.format('%s %s', sType, sCommand)
	local oSubtree = oTreeItemRoot:add(oProtovGATE, oTvbData(), 'vGATE Protocol Data')
	oSubtree:add(oTvbData(0 ,1), string.format('Version: %d', uiVersion))
	local oSubtreeMessage = oSubtree:add (oTvbData(1), 'Message')
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	