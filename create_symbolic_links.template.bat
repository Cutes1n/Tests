:: It seems required to run this script as administrator because that seems required from symlinking.

set "path=C:\Program Files (x86)\World of Warcraft"

if exist "%path%\_retail_" (
  if not exist "%path%\_retail_\Interface" mkdir "%path%\_retail_\Interface"
  if not exist "%path%\_retail_\Interface\AddOns" mkdir "%path%\_retail_\Interface\AddOns"
  mklink /D "%path%\_retail_\Interface\AddOns\ActionSequenceDoer" "%~dp0\AddOns\ActionSequenceDoer"
  mklink /D "%path%\_retail_\Interface\AddOns\APICallLogging" "%~dp0\AddOns\APICallLogging"
  mklink /D "%path%\_retail_\Interface\AddOns\APIDumper" "%~dp0\AddOns\APIDumper"
  mklink /D "%path%\_retail_\Interface\AddOns\Array" "%~dp0\AddOns\Array"
  mklink /D "%path%\_retail_\Interface\AddOns\AutoCombat" "%~dp0\AddOns\AutoCombat"
  mklink /D "%path%\_retail_\Interface\AddOns\Bags" "%~dp0\AddOns\Bags"
  mklink /D "%path%\_retail_\Interface\AddOns\BinaryHeap" "%~dp0\AddOns\BinaryHeap"
  mklink /D "%path%\_retail_\Interface\AddOns\Boolean" "%~dp0\AddOns\Boolean"
  mklink /D "%path%\_retail_\Interface\AddOns\Bot" "%~dp0\AddOns\Bot"
  mklink /D "%path%\_retail_\Interface\AddOns\Caching" "%~dp0\AddOns\Caching"
  mklink /D "%path%\_retail_\Interface\AddOns\CommunityFeastHandler" "%~dp0\AddOns\CommunityFeastHandler"
  mklink /D "%path%\_retail_\Interface\AddOns\CommunityFeastHandlerFullyAutomated" "%~dp0\AddOns\CommunityFeastHandlerFullyAutomated"
  mklink /D "%path%\_retail_\Interface\AddOns\Compatibility" "%~dp0\AddOns\Compatibility"
  mklink /D "%path%\_retail_\Interface\AddOns\Conditionals" "%~dp0\AddOns\Conditionals"
  mklink /D "%path%\_retail_\Interface\AddOns\Core" "%~dp0\AddOns\Core"
  mklink /D "%path%\_retail_\Interface\AddOns\Coroutine" "%~dp0\AddOns\Coroutine"
  mklink /D "%path%\_retail_\Interface\AddOns\Development" "%~dp0\AddOns\Development"
  mklink /D "%path%\_retail_\Interface\AddOns\DisableGMR" "%~dp0\AddOns\DisableGMR"
  mklink /D "%path%\_retail_\Interface\AddOns\Draw" "%~dp0\AddOns\Draw"
  mklink /D "%path%\_retail_\Interface\AddOns\Events" "%~dp0\AddOns\Events"
  mklink /D "%path%\_retail_\Interface\AddOns\Fishing" "%~dp0\AddOns\Fishing"
  mklink /D "%path%\_retail_\Interface\AddOns\Float" "%~dp0\AddOns\Float"
  mklink /D "%path%\_retail_\Interface\AddOns\FreeUpSpace" "%~dp0\AddOns\FreeUpSpace"
  mklink /D "%path%\_retail_\Interface\AddOns\Function" "%~dp0\AddOns\Function"
  mklink /D "%path%\_retail_\Interface\AddOns\GMR" "%~dp0\AddOns\GMR"
  mklink /D "%path%\_retail_\Interface\AddOns\Hook" "%~dp0\AddOns\Hook"
  mklink /D "%path%\_retail_\Interface\AddOns\Hooking" "%~dp0\AddOns\Hooking"
  mklink /D "%path%\_retail_\Interface\AddOns\HWT" "%~dp0\AddOns\HWT"
  mklink /D "%path%\_retail_\Interface\AddOns\HWTRetriever" "%~dp0\AddOns\HWTRetriever"
  mklink /D "%path%\_retail_\Interface\AddOns\InitializableTogglable" "%~dp0\AddOns\InitializableTogglable"
  mklink /D "%path%\_retail_\Interface\AddOns\Library" "%~dp0\AddOns\Library"
  mklink /D "%path%\_retail_\Interface\AddOns\Logging" "%~dp0\AddOns\Logging"
  mklink /D "%path%\_retail_\Interface\AddOns\Lua" "%~dp0\AddOns\Lua"
  mklink /D "%path%\_retail_\Interface\AddOns\Math" "%~dp0\AddOns\Math"
  mklink /D "%path%\_retail_\Interface\AddOns\MeshNet" "%~dp0\AddOns\MeshNet"
  mklink /D "%path%\_retail_\Interface\AddOns\Movement" "%~dp0\AddOns\Movement"
  mklink /D "%path%\_retail_\Interface\AddOns\Object" "%~dp0\AddOns\Object"
  mklink /D "%path%\_retail_\Interface\AddOns\ObjectQuests" "%~dp0\AddOns\ObjectQuests"
  mklink /D "%path%\_retail_\Interface\AddOns\ObjectToValueLookup" "%~dp0\AddOns\ObjectToValueLookup"
  mklink /D "%path%\_retail_\Interface\AddOns\Pausable" "%~dp0\AddOns\Pausable"
  mklink /D "%path%\_retail_\Interface\AddOns\Resolvable" "%~dp0\AddOns\Resolvable"
  mklink /D "%path%\_retail_\Interface\AddOns\Questing" "%~dp0\AddOns\Questing"
  mklink /D "%path%\_retail_\Interface\AddOns\RecommendedSpellCaster" "%~dp0\AddOns\RecommendedSpellCaster"
  mklink /D "%path%\_retail_\Interface\AddOns\SavedVariables" "%~dp0\AddOns\SavedVariables"
  mklink /D "%path%\_retail_\Interface\AddOns\Scheduling" "%~dp0\AddOns\Scheduling"
  mklink /D "%path%\_retail_\Interface\AddOns\Serialization" "%~dp0\AddOns\Serialization"
  mklink /D "%path%\_retail_\Interface\AddOns\Set" "%~dp0\AddOns\Set"
  mklink /D "%path%\_retail_\Interface\AddOns\SpellCasting" "%~dp0\AddOns\SpellCasting"
  mklink /D "%path%\_retail_\Interface\AddOns\Stoppable" "%~dp0\AddOns\Stoppable"
  mklink /D "%path%\_retail_\Interface\AddOns\String" "%~dp0\AddOns\String"
  mklink /D "%path%\_retail_\Interface\AddOns\Togglable" "%~dp0\AddOns\Togglable"
  mklink /D "%path%\_retail_\Interface\AddOns\Tooltips" "%~dp0\AddOns\Tooltips"
  mklink /D "%path%\_retail_\Interface\AddOns\Unlocker" "%~dp0\AddOns\Unlocker"
  mklink /D "%path%\_retail_\Interface\AddOns\Vector" "%~dp0\AddOns\Vector"
  mklink /D "%path%\_retail_\Interface\AddOns\Yielder" "%~dp0\AddOns\Yielder"
)

if exist "%path%\_classic_" (
  if not exist "%path%\_classic_\Interface" mkdir "%path%\_classic_\Interface"
  if not exist "%path%\_classic_\Interface\AddOns" mkdir "%path%\_classic_\Interface\AddOns"
  mklink /D "%path%\_classic_\Interface\AddOns\ActionSequenceDoer" "%~dp0\AddOns\ActionSequenceDoer"
  mklink /D "%path%\_classic_\Interface\AddOns\APICallLogging" "%~dp0\AddOns\APICallLogging"
  mklink /D "%path%\_classic_\Interface\AddOns\APIDumper" "%~dp0\AddOns\APIDumper"
  mklink /D "%path%\_classic_\Interface\AddOns\Array" "%~dp0\AddOns\Array"
  mklink /D "%path%\_classic_\Interface\AddOns\AutoCombat" "%~dp0\AddOns\AutoCombat"
  mklink /D "%path%\_classic_\Interface\AddOns\Bags" "%~dp0\AddOns\Bags"
  mklink /D "%path%\_classic_\Interface\AddOns\BinaryHeap" "%~dp0\AddOns\BinaryHeap"
  mklink /D "%path%\_classic_\Interface\AddOns\Boolean" "%~dp0\AddOns\Boolean"
  mklink /D "%path%\_classic_\Interface\AddOns\Bot" "%~dp0\AddOns\Bot"
  mklink /D "%path%\_classic_\Interface\AddOns\Caching" "%~dp0\AddOns\Caching"
  mklink /D "%path%\_classic_\Interface\AddOns\CommunityFeastHandler" "%~dp0\AddOns\CommunityFeastHandler"
  mklink /D "%path%\_classic_\Interface\AddOns\CommunityFeastHandlerFullyAutomated" "%~dp0\AddOns\CommunityFeastHandlerFullyAutomated"
  mklink /D "%path%\_classic_\Interface\AddOns\Compatibility" "%~dp0\AddOns\Compatibility"
  mklink /D "%path%\_classic_\Interface\AddOns\Conditionals" "%~dp0\AddOns\Conditionals"
  mklink /D "%path%\_classic_\Interface\AddOns\Core" "%~dp0\AddOns\Core"
  mklink /D "%path%\_classic_\Interface\AddOns\Coroutine" "%~dp0\AddOns\Coroutine"
  mklink /D "%path%\_classic_\Interface\AddOns\Development" "%~dp0\AddOns\Development"
  mklink /D "%path%\_classic_\Interface\AddOns\DisableGMR" "%~dp0\AddOns\DisableGMR"
  mklink /D "%path%\_classic_\Interface\AddOns\Draw" "%~dp0\AddOns\Draw"
  mklink /D "%path%\_classic_\Interface\AddOns\Events" "%~dp0\AddOns\Events"
  mklink /D "%path%\_classic_\Interface\AddOns\Fishing" "%~dp0\AddOns\Fishing"
  mklink /D "%path%\_classic_\Interface\AddOns\Float" "%~dp0\AddOns\Float"
  mklink /D "%path%\_classic_\Interface\AddOns\FreeUpSpace" "%~dp0\AddOns\FreeUpSpace"
  mklink /D "%path%\_classic_\Interface\AddOns\Function" "%~dp0\AddOns\Function"
  mklink /D "%path%\_classic_\Interface\AddOns\GMR" "%~dp0\AddOns\GMR"
  mklink /D "%path%\_classic_\Interface\AddOns\Hook" "%~dp0\AddOns\Hook"
  mklink /D "%path%\_classic_\Interface\AddOns\Hooking" "%~dp0\AddOns\Hooking"
  mklink /D "%path%\_classic_\Interface\AddOns\HWT" "%~dp0\AddOns\HWT"
  mklink /D "%path%\_classic_\Interface\AddOns\HWTRetriever" "%~dp0\AddOns\HWTRetriever"
  mklink /D "%path%\_classic_\Interface\AddOns\InitializableTogglable" "%~dp0\AddOns\InitializableTogglable"
  mklink /D "%path%\_classic_\Interface\AddOns\Library" "%~dp0\AddOns\Library"
  mklink /D "%path%\_classic_\Interface\AddOns\Logging" "%~dp0\AddOns\Logging"
  mklink /D "%path%\_classic_\Interface\AddOns\Lua" "%~dp0\AddOns\Lua"
  mklink /D "%path%\_classic_\Interface\AddOns\Math" "%~dp0\AddOns\Math"
  mklink /D "%path%\_classic_\Interface\AddOns\MeshNet" "%~dp0\AddOns\MeshNet"
  mklink /D "%path%\_classic_\Interface\AddOns\Movement" "%~dp0\AddOns\Movement"
  mklink /D "%path%\_classic_\Interface\AddOns\Object" "%~dp0\AddOns\Object"
  mklink /D "%path%\_classic_\Interface\AddOns\ObjectQuests" "%~dp0\AddOns\ObjectQuests"
  mklink /D "%path%\_classic_\Interface\AddOns\ObjectToValueLookup" "%~dp0\AddOns\ObjectToValueLookup"
  mklink /D "%path%\_classic_\Interface\AddOns\Pausable" "%~dp0\AddOns\Pausable"
  mklink /D "%path%\_classic_\Interface\AddOns\Resolvable" "%~dp0\AddOns\Resolvable"
  mklink /D "%path%\_classic_\Interface\AddOns\Questing" "%~dp0\AddOns\Questing"
  mklink /D "%path%\_classic_\Interface\AddOns\SavedVariables" "%~dp0\AddOns\SavedVariables"
  mklink /D "%path%\_classic_\Interface\AddOns\Scheduling" "%~dp0\AddOns\Scheduling"
  mklink /D "%path%\_classic_\Interface\AddOns\Serialization" "%~dp0\AddOns\Serialization"
  mklink /D "%path%\_classic_\Interface\AddOns\Set" "%~dp0\AddOns\Set"
  mklink /D "%path%\_classic_\Interface\AddOns\SpellCasting" "%~dp0\AddOns\SpellCasting"
  mklink /D "%path%\_classic_\Interface\AddOns\Stoppable" "%~dp0\AddOns\Stoppable"
  mklink /D "%path%\_classic_\Interface\AddOns\String" "%~dp0\AddOns\String"
  mklink /D "%path%\_classic_\Interface\AddOns\Togglable" "%~dp0\AddOns\Togglable"
  mklink /D "%path%\_classic_\Interface\AddOns\Tooltips" "%~dp0\AddOns\Tooltips"
  mklink /D "%path%\_classic_\Interface\AddOns\Unlocker" "%~dp0\AddOns\Unlocker"
  mklink /D "%path%\_classic_\Interface\AddOns\Vector" "%~dp0\AddOns\Vector"
  mklink /D "%path%\_classic_\Interface\AddOns\Yielder" "%~dp0\AddOns\Yielder"
)

if exist "%path%\_classic_era_" (
  if not exist "%path%\_classic_era_\Interface" mkdir "%path%\_classic_era_\Interface"
  if not exist "%path%\_classic_era_\Interface\AddOns" mkdir "%path%\_classic_era_\Interface\AddOns"
  mklink /D "%path%\_classic_era_\Interface\AddOns\ActionSequenceDoer" "%~dp0\AddOns\ActionSequenceDoer"
  mklink /D "%path%\_classic_era_\Interface\AddOns\APICallLogging" "%~dp0\AddOns\APICallLogging"
  mklink /D "%path%\_classic_era_\Interface\AddOns\APIDumper" "%~dp0\AddOns\APIDumper"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Array" "%~dp0\AddOns\Array"
  mklink /D "%path%\_classic_era_\Interface\AddOns\AutoCombat" "%~dp0\AddOns\AutoCombat"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Bags" "%~dp0\AddOns\Bags"
  mklink /D "%path%\_classic_era_\Interface\AddOns\BinaryHeap" "%~dp0\AddOns\BinaryHeap"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Boolean" "%~dp0\AddOns\Boolean"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Bot" "%~dp0\AddOns\Bot"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Caching" "%~dp0\AddOns\Caching"
  mklink /D "%path%\_classic_era_\Interface\AddOns\CommunityFeastHandler" "%~dp0\AddOns\CommunityFeastHandler"
  mklink /D "%path%\_classic_era_\Interface\AddOns\CommunityFeastHandlerFullyAutomated" "%~dp0\AddOns\CommunityFeastHandlerFullyAutomated"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Compatibility" "%~dp0\AddOns\Compatibility"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Conditionals" "%~dp0\AddOns\Conditionals"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Core" "%~dp0\AddOns\Core"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Coroutine" "%~dp0\AddOns\Coroutine"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Development" "%~dp0\AddOns\Development"
  mklink /D "%path%\_classic_era_\Interface\AddOns\DisableGMR" "%~dp0\AddOns\DisableGMR"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Draw" "%~dp0\AddOns\Draw"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Events" "%~dp0\AddOns\Events"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Fishing" "%~dp0\AddOns\Fishing"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Float" "%~dp0\AddOns\Float"
  mklink /D "%path%\_classic_era_\Interface\AddOns\FreeUpSpace" "%~dp0\AddOns\FreeUpSpace"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Function" "%~dp0\AddOns\Function"
  mklink /D "%path%\_classic_era_\Interface\AddOns\GMR" "%~dp0\AddOns\GMR"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Hook" "%~dp0\AddOns\Hook"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Hooking" "%~dp0\AddOns\Hooking"
  mklink /D "%path%\_classic_era_\Interface\AddOns\HWT" "%~dp0\AddOns\HWT"
  mklink /D "%path%\_classic_era_\Interface\AddOns\HWTRetriever" "%~dp0\AddOns\HWTRetriever"
  mklink /D "%path%\_classic_era_\Interface\AddOns\InitializableTogglable" "%~dp0\AddOns\InitializableTogglable"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Library" "%~dp0\AddOns\Library"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Logging" "%~dp0\AddOns\Logging"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Lua" "%~dp0\AddOns\Lua"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Math" "%~dp0\AddOns\Math"
  mklink /D "%path%\_classic_era_\Interface\AddOns\MeshNet" "%~dp0\AddOns\MeshNet"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Movement" "%~dp0\AddOns\Movement"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Object" "%~dp0\AddOns\Object"
  mklink /D "%path%\_classic_era_\Interface\AddOns\ObjectQuests" "%~dp0\AddOns\ObjectQuests"
  mklink /D "%path%\_classic_era_\Interface\AddOns\ObjectToValueLookup" "%~dp0\AddOns\ObjectToValueLookup"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Pausable" "%~dp0\AddOns\Pausable"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Resolvable" "%~dp0\AddOns\Resolvable"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Questing" "%~dp0\AddOns\Questing"
  mklink /D "%path%\_classic_era_\Interface\AddOns\SavedVariables" "%~dp0\AddOns\SavedVariables"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Scheduling" "%~dp0\AddOns\Scheduling"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Serialization" "%~dp0\AddOns\Serialization"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Set" "%~dp0\AddOns\Set"
  mklink /D "%path%\_classic_era_\Interface\AddOns\SpellCasting" "%~dp0\AddOns\SpellCasting"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Stoppable" "%~dp0\AddOns\Stoppable"
  mklink /D "%path%\_classic_era_\Interface\AddOns\String" "%~dp0\AddOns\String"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Togglable" "%~dp0\AddOns\Togglable"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Tooltips" "%~dp0\AddOns\Tooltips"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Unlocker" "%~dp0\AddOns\Unlocker"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Vector" "%~dp0\AddOns\Vector"
  mklink /D "%path%\_classic_era_\Interface\AddOns\Yielder" "%~dp0\AddOns\Yielder"
)
