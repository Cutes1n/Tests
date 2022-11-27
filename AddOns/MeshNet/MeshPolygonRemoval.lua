local addOnName, AddOn, exports, imports = ...
local Modules = imports and imports.Modules or _G.Modules
local MeshNet = Modules.determineExportsVariable(addOnName, exports)
local Core, Function, HWT, Array, Draw = Modules.determineImportVariables('Core', 'Function', 'HWT', 'Array', 'Draw', imports)

local _ = {}

-- TODO: Make variable non-global
polygon = nil

function MeshNet.showClosestMeshPolygonToPointToShow()
  polygon = Core.retrieveClosestMeshPolygon(Core.createWorldPositionFromPosition(Core.retrieveCurrentContinentID(),
    QuestingPointToShow), 1000, 1000, 1000)
  return polygon
end

function MeshNet.removeClosestMeshPolygonToPointToShow()
  _.removeClosestMeshPolygonTo(Core.createWorldPositionFromPosition(Core.retrieveCurrentContinentID(),
    QuestingPointToShow))
end

function MeshNet.showClosestMeshPolygonToCharacter()
  polygon = Core.retrieveClosestMeshPolygon(Core.retrieveCharacterPosition(), 1000, 1000, 1000)
  return polygon
end

function MeshNet.removeClosestMeshPolygonToCharacter()
  _.removeClosestMeshPolygonTo(Core.retrieveCharacterPosition())
end

function _.removeClosestMeshPolygonTo(position)
  _.removeClosestMeshPolygonToPositionFromMeshNet(position, function ()
    _.writeRemovedMeshPolygonToFile(position)
  end)
  polygon = nil
end

function _.removeClosestMeshPolygonToPositionFromMeshNet(position, doBeforeRemoval)
  doBeforeRemoval = doBeforeRemoval or Function.noOperation

  local polygon = Core.retrieveClosestMeshPolygon(position, 1000, 1000, 1000)
  if polygon then
    doBeforeRemoval()
    _.removeMeshPolygon(polygon)
  end
end

function _.removeMeshPolygon(polygon)
  return HWT.SetMeshPolygonFlags(Core.retrieveCurrentContinentID(), polygon, 0)
end

function _.writeRemovedMeshPolygonToFile(position)
  local removedMeshPolygon = {
    position = Object.copy(position)
  }
  table.insert(AddOn.removedMeshPolygons, removedMeshPolygon)
  _.writeRemovedMeshPolygonsToFile()
end

function _.writeRemovedMeshPolygonsToFile()
  local filePath = HWT.GetWoWDirectory() .. '/Interface/AddOns/MeshNet/RemovedMeshPolygonsDatabase.lua'
  HWT.WriteFile(filePath,
    'local addOnName, AddOn = ...\n\nAddOn.removedMeshPolygons = ' .. Serialization.valueToString(AddOn.removedMeshPolygons) .. '\n')
end

HWT.doWhenHWTIsLoaded(function()
  local appSessionToken = HWT.GetAppSessionToken()
  if appSessionToken ~= MeshNetLastPolygonRemovalAppSessionToken then
    MeshNetLastPolygonRemovalAppSessionToken = appSessionToken
    Array.forEach(AddOn.removedMeshPolygons, function (removedMeshPolygon)
      _.removeClosestMeshPolygonToPositionFromMeshNet(removedMeshPolygon.position)
    end)
  end

  Draw.Sync(function()
    if polygon then
      MeshNet.visualizePolygon(
        polygon,
        {
          color = { 0, 0, 1, 1 },
          fillColor = { 0, 0, 1, 0.2 }
        }
      )
    end
  end)
end)
