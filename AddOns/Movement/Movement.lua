-- FIXME: Generation of neighbor points seems to be defect when the character flies as ghost.
-- FIXME: Seems to fail to jump with small obstacles (seems to kinda become stuck on small objects).
-- FIXME: Pathfinding with the trace line method seems currently too slow to be practical (at least in some cases where it takes more than 30 seconds).
-- FIXME: When flying (while ghost, on ghost mount), the mount seems to regularly stop for short amount of times.

local addOnName, AddOn = ...
--- @class Movement
Movement = Movement or {}
Movement.__ = AddOn

local _ = {}

local points = {}

-- Movement_ = _

-- TODO: Remove globals
aStarPoints = nil
aStarPoints2 = nil

local DEVELOPMENT = true
local zOffset = 1.6
local MAXIMUM_FALL_HEIGHT = 30
local MAXIMUM_WATER_DEPTH = 1000
local GRID_LENGTH = 2
local MINIMUM_LIFT_HEIGHT = 0.25 -- Minimum flying lift height seems to be ~ 0.25 yards.
local TOLERANCE_RANGE = 0.5
local TARGET_LIFT_HEIGHT = TOLERANCE_RANGE
Movement.MAXIMUM_AIR_HEIGHT = 5000
local walkToPoint = nil
local MAXIMUM_WATER_DEPTH_FOR_WALKING = 1.4872055053711
canBeStoodOnPointCache = Movement.PointToValueMap:new()
local canBeStoodWithMountOnPointCache = Movement.PointToValueMap:new()
local DISTANCE = GRID_LENGTH
local FEMALE_HUMAN_CHARACTER_HEIGHT = 1.970519900322
local MAXIMUM_DISTANCE_FOR_STOPPING_WHEN_FACING_WHILE_MOVING_ON_GROUND_SWIMMING_OR_FLYING = 6
local MAXIMUM_DISTANCE_FOR_STOPPING_WHEN_FACING_WHILE_DRAGONRIDING = 8
lines = {}

local cache = {}

local run = nil
local pathFinder = nil

function Movement.retrieveCharacterHeight()
  return HWT.ObjectHeight('player')
end

function Movement.retrieveUnmountedCharacterHeight()
  if IsMounted() then
    return AddOn.savedVariables.perCharacter.MovementCharacterHeight
  else
    AddOn.savedVariables.perCharacter.MovementCharacterHeight = Movement.retrieveCharacterHeight()
    return AddOn.savedVariables.perCharacter.MovementCharacterHeight
  end
end

function Movement.retrieveUnmountedCharacterHeightBestEffort()
  return Movement.retrieveUnmountedCharacterHeight() or FEMALE_HUMAN_CHARACTER_HEIGHT
end

function Movement.addPointToCache(fromX, fromY, fromZ, toX, toY, toZ)
  local a = cache[fromX]
  if not a then
    cache[fromX] = {}
  end
  if not cache[fromX][fromY] then
    cache[fromX][fromY] = {}
  end
  cache[fromX][fromY][fromZ] = { toX, toY, toZ }
end

function Movement.retrievePointFromCache(x, y, z)
  local a = cache[x]
  if a then
    local b = a[y]
    if b then
      local c = b[z]
      if c then
        return unpack(c)
      end
    end
  end
end

function drawLine(from, to)
  Draw.Line(from.x, from.y, from.z, to.x, to.y, to.z)
end

function Movement.savePosition1()
  AddOn.savedVariables.perCharacter.position1 = Core.retrieveCharacterPosition()
end

function Movement.savePosition2()
  AddOn.savedVariables.perCharacter.position2 = Core.retrieveCharacterPosition()
end

function Movement.savePosition()
  local playerPosition = Core.retrieveCharacterPosition()
  AddOn.savedVariables.accountWide.savedPosition = Movement.createPoint(playerPosition.x, playerPosition.y,
    playerPosition.z)
end

function Movement.positionInFrontOfPlayer(distance, deltaZ)
  local playerPosition = Core.retrieveCharacterPosition()
  return Core.retrievePositionFromPosition(
    Movement.createPointWithZOffset(playerPosition, deltaZ or 0),
    distance,
    HWT.ObjectFacing('player'),
    HWT.UnitPitch('player')
  )
end

function Movement.positionInFrontOfPlayer2(distance, deltaZ)
  local playerPosition = Core.retrieveCharacterPosition()
  return Core.retrievePositionFromPosition(
    Movement.createPointWithZOffset(playerPosition, deltaZ or 0),
    distance,
    HWT.ObjectFacing('player'),
    0
  )
end

function Movement.calculateIsObstacleInFrontToPosition(position, distance)
  return Core.retrievePositionFromPosition(position, distance or 5, HWT.ObjectFacing('player'), 0)
end

function Movement.calculateIsObstacleInFlyingDirectionToPosition(position, distance)
  return Core.retrievePositionFromPosition(position, distance or 5, HWT.ObjectFacing('player'), HWT.UnitPitch('player'))
end

function Movement.isObstacleInFront(position, distance)
  local position1 = Movement.createPoint(
    position.x,
    position.y,
    position.z + zOffset
  )
  local position2 = Movement.calculateIsObstacleInFrontToPosition(position1, distance)
  lines = {
    {
      position1,
      position2
    }
  }
  return not Movement.thereAreZeroCollisions(position1, position2)
end

function Movement.isObstacleInFlyingDirection(position, distance)
  local position1 = Movement.createPoint(
    position.x,
    position.y,
    position.z + zOffset
  )
  local position2 = Movement.calculateIsObstacleInFlyingDirectionToPosition(position1, distance)
  lines = {
    {
      position1,
      position2
    }
  }
  return not Movement.thereAreZeroCollisions(position1, position2)
end

function Movement.canWalkTo(position)
  local playerPosition = Core.retrieveCharacterPosition()
  local fromPosition = Movement.createPoint(
    playerPosition.x,
    playerPosition.y,
    playerPosition.z + zOffset
  )
  return Movement.thereAreZeroCollisions(fromPosition, position)
end

function Movement.canBeMovedFromPointToPoint(from, to)
  local a = Movement.canBeWalkedOrSwamFromPointToPoint(from, to)
  local b = Movement.canBeJumpedFromPointToPoint(from, to)
  local c = Movement.canBeFlownFromPointToPoint(from, to)
  return a or b or c
end

function Movement.isEnoughSpaceOnTop(from, to)
  local offset = 0.1
  local characterHeight = Movement.retrieveCharacterHeightForHeightCheck()
  local a = Movement.thereAreZeroCollisions(
    Movement.createPointWithZOffset(from, offset),
    Movement.createPointWithZOffset(from, characterHeight)
  )
  local b = Movement.thereAreZeroCollisions(
    Movement.createPointWithZOffset(to, offset),
    Movement.createPointWithZOffset(to, characterHeight)
  )

  local c = Movement.thereAreZeroCollisions2(Movement.createPointWithZOffset(from, offset),
    Movement.createPointWithZOffset(to, offset), characterHeight - offset)
  return a and b and c
end

function Movement.thereAreZeroCollisions2(from, to, zHeight, track)
  local function thereAreZeroCollisions(zOffset)
    return Movement.thereAreZeroCollisions(
      Movement.createPointWithZOffset(from, zOffset),
      Movement.createPointWithZOffset(to, zOffset),
      track
    )
  end
  local interval = 1
  return Array.isTrueForAllInInterval(0, zHeight, interval, thereAreZeroCollisions) and
    (zHeight % interval == 0 or thereAreZeroCollisions(zHeight))
end

function Movement.thereAreZeroCollisions3(from, to, zHeight)
  return (
    Movement.thereAreZeroCollisions2(from, to, zHeight, true) and
      Movement.thereAreZeroCollisions4(from, to, zHeight, true) and
      Movement.thereAreZeroCollisions5(from, to, zHeight, true)
  )
end

function Movement.thereAreZeroCollisions4(from, to, zHeight)
  local from2 = Core.retrievePositionFromPosition(
    from,
    Core.retrieveCharacterBoundingRadius(),
    Core.calculateAnglesBetweenTwoPoints(from, to) + 0.5 * PI,
    0
  )
  local to2 = Core.retrievePositionFromPosition(
    to,
    Core.retrieveCharacterBoundingRadius(),
    Core.calculateAnglesBetweenTwoPoints(from, to) + 0.5 * PI,
    0
  )
  return Movement.thereAreZeroCollisions2(from2, to2, zHeight, true)
end

function Movement.thereAreZeroCollisions5(from, to, zHeight)
  local from2 = Core.retrievePositionFromPosition(
    from,
    Core.retrieveCharacterBoundingRadius(),
    Core.calculateAnglesBetweenTwoPoints(from, to) - 0.5 * PI,
    0
  )
  local to2 = Core.retrievePositionFromPosition(
    to,
    Core.retrieveCharacterBoundingRadius(),
    Core.calculateAnglesBetweenTwoPoints(from, to) - 0.5 * PI,
    0
  )
  return Movement.thereAreZeroCollisions2(from2, to2, zHeight, true)
end

Movement.MAXIMUM_WALK_UP_TO_HEIGHT = 0.97314453125
Movement.JUMP_DETECTION_HEIGHT = Movement.MAXIMUM_WALK_UP_TO_HEIGHT + 0.01
Movement.MAXIMUM_JUMP_HEIGHT = 1.675

function Movement.canBeWalkedOrSwamFromPointToPoint(from, to)
  return (
    (Movement.isPointInDeepWater(to) or Movement.canPlayerStandOnPoint(to) or Movement.canPlayerSwimOnPoint(to)) and
      Movement.canBeMovedFromPointToPointCheckingSubSteps(from, to)
  )
end

function Movement.canPlayerSwimOnPoint(point)
  return Movement.isPointInDeepWater(point)
end

function Movement.canBeMovedFromPointToPointCheckingSubSteps(from, to)
  if from.x == to.x and from.y == to.y then
    return (
      (to.z - from.z <= Movement.MAXIMUM_WALK_UP_TO_HEIGHT or (Movement.isPointInDeepWater(from) and Movement.isPointInDeepWater(to))) and
        Movement.thereAreZeroCollisions(Movement.createPointWithZOffset(from, 0.1), to)
    )
  end

  local totalDistance = Math.euclideanDistance(from, to)

  local point1 = from
  local stepSize = 1
  local distance = stepSize
  while distance < totalDistance do
    --table.insert(points, point1)
    local point2 = Core.retrievePositionBetweenPositions(from, to, distance)
    local x, y, z = point2.x, point2.y, point2.z

    if not (Movement.isPointInDeepWater(point1) and Movement.isPointInDeepWater(point2)) then
      local z = Movement.retrieveGroundZ(Movement.createPoint(point2.x, point2.y, point1.z))

      if not z then
        return false
      end

      point2 = Movement.createPoint(x, y, z)

      local maximumDeltaZ = _.determineMaximumDeltaZ(point1, point2)

      if point1.x == x and point1.y == y then
        return z - point1.z <= maximumDeltaZ
      end

      if not (z - point1.z <= maximumDeltaZ) then
        return false
      end
    end

    if not Movement.thereAreZeroCollisions3(
      Movement.createPointWithZOffset(point1, Movement.MAXIMUM_WALK_UP_TO_HEIGHT),
      Movement.createPointWithZOffset(point2, Movement.MAXIMUM_WALK_UP_TO_HEIGHT),
      Movement.retrieveUnmountedCharacterHeightBestEffort() - Movement.MAXIMUM_WALK_UP_TO_HEIGHT
    ) then
      return false
    end

    point1 = point2
    distance = distance + stepSize
  end

  local maximumDeltaZ = _.determineMaximumDeltaZ(point1, to)
  AddOn.savedVariables.perCharacter.position1 = point1
  AddOn.savedVariables.perCharacter.position2 = to
  if not (to.z - point1.z <= maximumDeltaZ or (Movement.isPointInDeepWater(point1) and Movement.isPointInDeepWater(to))) then
    return false
  end

  if not Movement.thereAreZeroCollisions3(
    Movement.createPointWithZOffset(point1, Movement.MAXIMUM_WALK_UP_TO_HEIGHT),
    Movement.createPointWithZOffset(to, Movement.MAXIMUM_WALK_UP_TO_HEIGHT),
    Movement.retrieveUnmountedCharacterHeightBestEffort() - Movement.MAXIMUM_WALK_UP_TO_HEIGHT
  ) then
    return false
  end

  return true
end

function _.determineMaximumDeltaZ(from, to)
  local maximumDeltaZ
  if Movement.isPointInOrSlightlyAboveWater(from) and Movement.isPointInOrSlightlyAboveWater(to) then
    maximumDeltaZ = Movement.retrieveCharacterHeight()
  else
    maximumDeltaZ = Movement.MAXIMUM_WALK_UP_TO_HEIGHT
  end
  return maximumDeltaZ
end

function Movement.canBeJumpedFromPointToPoint(from, to)
  return (
    Movement.isPointCloseToGround(from) and
      (Movement.isPointInDeepWater(to) or (Movement.isPointCloseToGround(to) and Movement.canPlayerStandOnPoint(to))) and
      to.z - from.z <= Movement.MAXIMUM_JUMP_HEIGHT and
      not _.thereAreCollisions2(
        Movement.createPointWithZOffset(from, Movement.MAXIMUM_JUMP_HEIGHT),
        Movement.createPointWithZOffset(to, Movement.MAXIMUM_JUMP_HEIGHT)
      )
  )
end

function Movement.canBeFlownFromPointToPoint(from, to)
  local playerPosition = Core.retrieveCharacterPosition()
  if playerPosition == from then
    if IsIndoors() then
      return false
    end
  end
  if playerPosition == to then
    if IsIndoors() then
      return false
    end
  end
  local a = Movement.isFlyingAvailableInZone() and Movement.canCharacterFlyOrDragonride()
  local b = Movement.isEnoughSpaceOnTop(from, to)
  local c = Movement.canPlayerBeOnPoint(to, { withMount = true })
  return a and b and c
end

function Movement.canPlayerBeOnPoint(point, options)
  options = options or {}

  local pointALittleBitOver = Movement.createPointWithZOffset(point, 0.1)
  local pointOnMaximumWalkUpToHeight = Movement.createPointWithZOffset(
    point,
    Movement.MAXIMUM_WALK_UP_TO_HEIGHT
  )
  local pointALittleBitOverMaximumWalkUpToHeight = Movement.createPointWithZOffset(pointOnMaximumWalkUpToHeight, 0.1)
  local pointOnCharacterHeight = Movement.createPointWithZOffset(point,
    Movement.retrieveUnmountedCharacterHeightBestEffort())

  local function areThereZeroCollisionsAround()
    local points = Movement.generatePointsAround(pointALittleBitOverMaximumWalkUpToHeight,
      Core.retrieveCharacterBoundingRadius(), 8)
    return Array.all(points, function(point)
      return Movement.thereAreZeroCollisions(pointALittleBitOverMaximumWalkUpToHeight, point)
    end)
  end

  local result = (
    Movement.thereAreZeroCollisions(pointOnMaximumWalkUpToHeight, pointALittleBitOver) and
      Movement.thereAreZeroCollisions(pointALittleBitOverMaximumWalkUpToHeight, pointOnCharacterHeight) and
      areThereZeroCollisionsAround()
  )

  return result
end

function _.canPlayerBeOnPoint2(point, options)
  options = options or {}

  if Core.isPositionInRangeForTraceLineChecks(point) then
    local pointALittleBitAbove = Movement.traceLineCollisionWithFallback(
      Movement.createPointWithZOffset(point, TOLERANCE_RANGE),
      point
    )
    if pointALittleBitAbove and pointALittleBitAbove.z > point.z then
      point = pointALittleBitAbove
    end

    local pointOnMaximumWalkUpToHeight = Movement.createPointWithZOffset(
      point,
      Movement.MAXIMUM_WALK_UP_TO_HEIGHT
    )
    local pointALittleBitOverMaximumWalkUpToHeight = Movement.createPointWithZOffset(pointOnMaximumWalkUpToHeight, 0.1)
    local pointOnCharacterHeight = Movement.createPointWithZOffset(point,
      Movement.retrieveUnmountedCharacterHeightBestEffort())

    local function areThereZeroCollisionsAround()
      local points = Movement.generatePointsAround(pointALittleBitOverMaximumWalkUpToHeight,
        Core.retrieveCharacterBoundingRadius(), 8)
      return Array.all(points, function(point)
        return Movement.thereAreZeroCollisions(pointALittleBitOverMaximumWalkUpToHeight, point)
      end)
    end

    local result = (
      Movement.thereAreZeroCollisions(pointALittleBitOverMaximumWalkUpToHeight, pointOnCharacterHeight) and
        areThereZeroCollisionsAround()
    )

    return result
  else
    local closestPointOnMesh = Core.retrieveClosestPositionOnMesh(Core.createWorldPosition(Movement.retrieveContinentID(),
      point.x, point.y, point.z))
    if closestPointOnMesh and Float.seemsCloseBy(closestPointOnMesh.x,
      point.x) and Float.seemsCloseBy(closestPointOnMesh.y, point.y) then
      return math.abs(closestPointOnMesh.z - point.z) <= TOLERANCE_RANGE
    end
  end

  return nil
end

function Movement.retrieveContinentID()
  local continentID = select(8, GetInstanceInfo())
  return continentID
end

function Movement.canPlayerStandOnPoint(point, options)
  options = options or {}

  if Core.isPositionInRangeForTraceLineChecks(point) then
    if options.withMount then
      local value = canBeStoodWithMountOnPointCache:retrieveValue(point)
      if value ~= nil then
        return value
      end
    else
      local value = canBeStoodOnPointCache:retrieveValue(point)
      if value ~= nil then
        return value
      end
    end

    local pointOnMaximumWalkUpToHeight = Movement.createPointWithZOffset(
      point,
      Movement.MAXIMUM_WALK_UP_TO_HEIGHT
    )
    local pointALittleBitOverMaximumWalkUpToHeight = Movement.createPointWithZOffset(pointOnMaximumWalkUpToHeight, 0.1)

    local function canFallOff()
      local pointALittleBitUnderPoint = Movement.createPointWithZOffset(point, -0.1)
      local standOnPoint = Movement.traceLineCollisionWithFallback(
        pointALittleBitOverMaximumWalkUpToHeight,
        pointALittleBitUnderPoint
      )
      if standOnPoint then
        local MAXIMUM_STEEPNESS_HEIGHT = 0.55436325073242
        local points = Movement.generatePointsAround(standOnPoint, 0, 1, 8)
        return not Array.all(points, function(point)
          local point1 = Movement.createPointWithZOffset(point, Movement.MAXIMUM_WALK_UP_TO_HEIGHT)
          return Movement.thereAreCollisions(
            point1,
            Movement.createPointWithZOffset(
              point1,
              -(MAXIMUM_STEEPNESS_HEIGHT + 0.00000000000001 + Movement.MAXIMUM_WALK_UP_TO_HEIGHT)
            )
          )
        end)
      else
        return false
      end
    end

    local result = (
      _.canPlayerBeOnPoint2(point, options) and
        not canFallOff() and
        not Movement.isPointInDeepWater(point)
    )

    if options.withMount then
      canBeStoodWithMountOnPointCache:setValue(point, result)
    else
      canBeStoodOnPointCache:setValue(point, result)
    end

    return result
  else
    return nil
  end
end

function Movement.isFlyingAvailableInZone()
  return IsFlyableArea()
end

function Movement.receiveAvailableMountIDs()
  local mountIDs = C_MountJournal.GetMountIDs()
  return Array.filter(mountIDs, function(mountID)
    local isUsable = select(5, C_MountJournal.GetMountInfoByID(mountID))
    return isUsable
  end)
end

function Movement.isADragonridingMountAvailable()
  local mountIDs = Movement.receiveAvailableMountIDs()
  return Array.any(mountIDs, Movement.isDragonridingMount)
end

function Movement.isAFlyingMountAvailable()
  local mountIDs = Movement.receiveAvailableMountIDs()
  return Array.any(mountIDs, Movement.isFlyingMount)
end

function Movement.isAGroundMountAvailable()
  local mountIDs = Movement.receiveAvailableMountIDs()
  return Array.any(mountIDs, Movement.isGroundMount)
end

function Movement.receiveAnAvailableFlyingMount()
  local mountIDs = Movement.receiveAvailableMountIDs()
  local mountID = Array.find(mountIDs, Movement.isFlyingMount)
  return mountID
end

local RENEWED_PROTO_DRAKE_MOUNT_ID = 1589

function Movement.receiveAnAvailableDragonridingMount()
  return RENEWED_PROTO_DRAKE_MOUNT_ID
end

function Movement.receiveAnAvailableGroundMount()
  local isUsable = select(5, C_MountJournal.GetMountInfoByID(1434))
  if isUsable then
    return 1434 -- This one is also faster in water
  end

  local mountIDs = Movement.receiveAvailableMountIDs()
  local mountID = Array.find(mountIDs, Movement.isGroundMount)
  return mountID
end

-- TODO: Water mounts. See https://wowpedia.fandom.com/wiki/API_C_MountJournal.GetMountInfoExtraByID (mountTypeID).

local underWaterMountTypeIDs = Set.create({
  231,
  232,
  254,
  407
})

local onWaterMountTypeIDs = Set.create({
  269
})

local flyingMountTypeIDs = Set.create({
  242,
  247,
  248,
  407
})

function Movement.isDragonridingMount(mountID)
  local isForDragonriding = select(13, C_MountJournal.GetMountInfoByID(mountID))
  return isForDragonriding
end

function Movement.isFlyingMount(mountID)
  local mountTypeID = select(5, C_MountJournal.GetMountInfoExtraByID(mountID))
  return Set.contains(flyingMountTypeIDs, mountTypeID)
end

local groundMountTypeIDs = Set.create({
  230,
  247,
  248,
  269,
  284,
  398,
  407,
  408
})

function Movement.isGroundMount(mountID)
  local mountTypeID = select(5, C_MountJournal.GetMountInfoExtraByID(mountID))
  return Set.contains(groundMountTypeIDs, mountTypeID)
end

function Movement.retrieveGroundZ(position)
  return Movement.retrieveZ(position, Core.TraceLineHitFlags.COLLISION)
end

function Movement.receiveSurfaceZ(position)
  return Movement.retrieveZ(position, bit.bor(Core.TraceLineHitFlags.COLLISION, Core.TraceLineHitFlags.WATER))
end

function Movement.retrieveZ(position, traceLineHitFlags)
  local position1 = Movement.createPoint(position.x, position.y, position.z + Movement.MAXIMUM_JUMP_HEIGHT)
  local position2 = Movement.createPoint(position.x, position.y, position.z - 10)
  local collisionPoint = Movement.traceLineWithFallback(position1, position2, traceLineHitFlags)
  if not collisionPoint then
    -- There seemed to be one case where no z was returned at a position, even though it looked like that there was
    -- a surface.
    local offset = 0.6
    position1 = Movement.createPoint(position1.x + offset, position1.y + offset, position.z)
    position2 = Movement.createPoint(position2.x + offset, position2.y + offset, position2.z)
    collisionPoint = Movement.traceLineWithFallback(position1, position2, traceLineHitFlags)
  end

  if collisionPoint then
    return collisionPoint.z
  else
    return nil
  end
end

function Movement.isPositionFarerAwayThanMaxiumRangeForTraceLineChecks(position)
  return not Core.isPositionInRangeForTraceLineChecks(position)
end

function Movement.retrieveGroundZ2(position)
  local collisionPoint = Movement.traceLineCollisionWithFallback(position,
    Movement.createPointWithZOffset(position, -Movement.MAXIMUM_AIR_HEIGHT))
  if collisionPoint then
    return collisionPoint.z
  else
    return nil
  end
end

function Movement.thereAreCollisions(a, b, track)
  if track then
    table.insert(lines, { a, b })
  end
  local collisionPoint = Movement.traceLineCollisionWithFallback(a, b)
  return Boolean.toBoolean(collisionPoint)
end

function Movement.thereAreZeroCollisions(a, b, track)
  if track then
    -- table.insert(lines, {a, b})
  end
  return not Movement.thereAreCollisions(a, b)
end

function Movement.isObstacleInFrontOfCharacter(distance)
  local characterPosition = Core.retrieveCharacterPosition()
  return Movement.isObstacleInFront(characterPosition, distance)
end

function Movement.isObstacleInFlyingDirectionOfCharacter(distance)
  local characterPosition = Core.retrieveCharacterPosition()
  return Movement.isObstacleInFlyingDirection(characterPosition, distance)
end

function Movement.generateWaypoint()
  local playerPosition = Core.retrieveCharacterPosition()
  return Core.retrievePositionFromPosition(playerPosition, 5, HWT.ObjectFacing('player'), 0)
end

function Movement.generateAngles(numberOfAngles)
  local angles = {}
  local angle = 0
  local delta = 2 * PI / numberOfAngles
  for i = 1, numberOfAngles do
    table.insert(angles, angle)
    angle = angle + delta
  end
  return angles
end

function Movement.generatePoints(fromPosition, distance, angles)
  return Array.map(angles, function(angle)
    return Movement.generatePoint(fromPosition, distance, angle)
  end)
end

function Movement.generateMiddlePointsAround(fromPosition, distance)
  return Array.selectTrue(Movement.generatePointsAroundOnGrid(fromPosition, distance, Movement.generateMiddlePoint))
end

function Movement.generateAbovePointsAround(fromPosition, distance)
  local points = {}
  local abovePoint = Movement.closestPointOnGrid(Movement.createPointWithZOffset(fromPosition, distance))
  table.insert(points, abovePoint)
  Array.append(points,
    Array.selectTrue(Movement.generatePointsAroundOnGrid(abovePoint, distance, Movement.generateAbovePoint)))
  return points
end

function Movement.generateBelowPointsAround(fromPosition, distance)
  local points = {}
  local belowPoint = Movement.closestPointOnGrid(Movement.createPointWithZOffset(fromPosition, -distance))
  table.insert(points, belowPoint)
  Array.append(points,
    Array.selectTrue(Movement.generatePointsAroundOnGrid(belowPoint, distance, Movement.generateBelowPoint)))
  return points
end

function Movement.generatePointsAroundOnGrid(fromPosition, distance, generatePoint)
  return {
    generatePoint(fromPosition, -distance, distance),
    generatePoint(fromPosition, 0, distance),
    generatePoint(fromPosition, distance, distance),
    generatePoint(fromPosition, -distance, 0),
    generatePoint(fromPosition, distance, 0),
    generatePoint(fromPosition, -distance, -distance),
    generatePoint(fromPosition, 0, -distance),
    generatePoint(fromPosition, distance, -distance)
  }
end

function Movement.generateMiddlePoint(fromPosition, offsetX, offsetY)
  local point2 = Movement.closestPointOnGrid(
    Movement.createPoint(fromPosition.x + offsetX, fromPosition.y + offsetY, fromPosition.z)
  )
  local isInAir = Movement.isPointInAir(point2)
  if isInAir and Movement.canCharacterFlyOrDragonride() then
    local point3 = {
      x = point2.x,
      y = point2.y,
      z = point2.z,
      isInAir = isInAir
    }
    return point3
  elseif Movement.isPointInDeepWater(point2) then
    return point2
  else
    local point = Movement.closestPointOnGridWithZLeft(
      Movement.createPoint(fromPosition.x + offsetX, fromPosition.y + offsetY, fromPosition.z)
    )
    local z2 = Movement.retrieveGroundZ(point)
    if z2 == nil then
      return nil
    end
    return Movement.createPoint(point.x, point.y, z2)
  end
end

function Movement.generateAbovePoint(fromPosition, offsetX, offsetY)
  local point = Movement.createPoint(fromPosition.x + offsetX, fromPosition.y + offsetY, fromPosition.z)
  return {
    x = point.x,
    y = point.y,
    z = point.z,
    isInAir = Movement.isPointInAir(point)
  }
end

function Movement.generateBelowPoint(fromPosition, offsetX, offsetY)
  local point = Movement.createPoint(fromPosition.x + offsetX, fromPosition.y + offsetY, fromPosition.z)
  return {
    x = point.x,
    y = point.y,
    z = point.z,
    isInAir = Movement.isPointInAir(point)
  }
end

function Movement.generatePoint(fromPosition, distance, angle)
  return Core.retrievePositionFromPosition(fromPosition, distance, angle, 0)
end

function Movement.receiveWaterSurfacePoint(point)
  local waterSurfacePoint = Core.traceLineWater(Movement.createPointWithZOffset(point, MAXIMUM_WATER_DEPTH), point)
  if waterSurfacePoint then
    return waterSurfacePoint
  else
    return Core.traceLineWater(point, Movement.createPointWithZOffset(point, -Movement.MAXIMUM_AIR_HEIGHT))
  end
end

function Movement.isPointInWater(point)
  local waterSurfacePoint = Movement.receiveWaterSurfacePoint(point)
  return Boolean.toBoolean(waterSurfacePoint and waterSurfacePoint.z >= point.z)
end

function Movement.isPointInOrSlightlyAboveWater(point)
  return Movement.isPointInWater(point) or Movement.isPointSlightlyAboveWater(point)
end

function Movement.isPointSlightlyAboveWater(point)
  local waterSurfacePoint = Movement.receiveWaterSurfacePoint(point)
  return waterSurfacePoint and point.z - waterSurfacePoint.z <= 1
end

function Movement.isPointInDeepWater(point)
  return Movement.isPointInWater(point) and Movement.isWaterDeepAt(point)
end

function Movement.isWaterDeepAt(point)
  local waterDepth = Movement.determineWaterDepth(point)
  if waterDepth then
    return waterDepth > MAXIMUM_WATER_DEPTH_FOR_WALKING
  else
    return nil
  end
end

function Movement.determineWaterDepth(point)
  local waterSurfacePoint = Movement.receiveWaterSurfacePoint(point)
  if waterSurfacePoint then
    local groundPoint = Movement.retrieveGroundPointInWater(waterSurfacePoint)
    if groundPoint then
      return Math.euclideanDistance(waterSurfacePoint, groundPoint)
    end
  end

  return nil
end

function Movement.retrieveGroundPointInWater(point)
  local deepPoint = Movement.createPointWithZOffset(point, -MAXIMUM_WATER_DEPTH)
  local collisionPoint = Core.traceLineCollision(point, deepPoint)
  if collisionPoint then
    return collisionPoint
  else
    return deepPoint
  end
end

function Movement.generateNeighborPoints(fromPosition, distance)
  local points = Movement.generateNeighborPointsAround(fromPosition, distance)
  -- aStarPoints = points
  return Array.filter(points, function(point)
    return Movement.canBeMovedFromPointToPoint(fromPosition, point)
  end)
end

function Movement.generateNeighborPointsBasedOnNavMesh(fromPosition, distance)
  local points = Movement.generateMiddlePointsAround(fromPosition, distance)
  local continentID = select(8, GetInstanceInfo())
  local maxDistance = math.sqrt(2 * math.pow(distance, 2))
  return Array.selectTrue(Array.map(points, function(point)
    local point = Core.retrieveClosestPositionOnMesh(Core.createWorldPositionFromPosition(continentID, point))
    if point then
      if Math.euclideanDistance2D(fromPosition, point) <= maxDistance and Movement.canBeMovedFromAToB(fromPosition,
        point) then
        return point
      end
    end

    return nil
  end))
end

function Movement.canBeMovedFromAToB(from, to)
  return (
    to.z - from.z <= Movement.MAXIMUM_JUMP_HEIGHT and
      Movement.thereAreZeroCollisions(
        Movement.createPointWithZOffset(from, Movement.MAXIMUM_WALK_UP_TO_HEIGHT + 0.1),
        Movement.createPointWithZOffset(to, Movement.MAXIMUM_WALK_UP_TO_HEIGHT + 0.1)
      )
  )
end

function Movement.generatePointsAround(position, distance, numberOfAngles)
  local angles = Movement.generateAngles(numberOfAngles)
  local points = Movement.generatePoints(position, distance, angles)
  return points
end

function Movement.createPointWithZOffset(point, zOffset)
  return Movement.createPoint(point.x, point.y, point.z + zOffset)
end

function Movement.generateNeighborPointsAround(position, distance)
  local a = Movement.generateMiddlePointsAround(position, distance)
  local b = Movement.generateAbovePointsAround(position, distance)
  local c = Movement.generateBelowPointsAround(position, distance)
  -- aStarPoints = a
  return Array.concat(
    a,
    b,
    c
  )
end

function Movement.isPositionInTheAir(position)
  return Movement.isPointInAir(position)
end

function Movement.isPositionLessOffGroundThanTheMaximum(position, maximumOffGroundDistance)
  local groundZ = Movement.retrieveGroundZ(position)
  return not groundZ or position.z - groundZ <= maximumOffGroundDistance
end

function Movement.isPositionInTheAirWhereAFlyingMountSeemsRequired(position)
  local z = Movement.receiveSurfaceZ(position)
  return not z or position.z - z > Movement.MAXIMUM_WALK_UP_TO_HEIGHT
end

function Movement.isPointInAir(point)
  local z = Movement.retrieveGroundZ(Movement.createPointWithZOffset(point, 0.25))
  return not z or point.z - z >= MINIMUM_LIFT_HEIGHT
end

function Movement.isPointCloseToGround(point)
  local z = Movement.retrieveGroundZ(Movement.createPointWithZOffset(point, 0.25))
  if z then
    local difference = math.abs(z - point.z)
    return difference <= 0.15
  else
    return false
  end
end

local DRAGON_ISLES_CONTINENT_ID = 2444

function Movement.isDragonridingAvailableInZone()
  return Core.retrieveCurrentContinentID() == DRAGON_ISLES_CONTINENT_ID
end

local DRAGONRIDING_BASICS_SPELL_ID = 376777

function Movement.canCharacterRideDragon()
  return Movement.canCharacterMount() and IsSpellKnown(DRAGONRIDING_BASICS_SPELL_ID) and Movement.isDragonridingAvailableInZone() and Movement.isADragonridingMountAvailable()
end

function Movement.canCharacterMount()
  -- TODO: Maybe improve Movement.canPlayerStandOnPoint(Core.retrieveCharacterPosition(), { withMount = true }) to consider different mounts.
  return Core.isCharacterAlive() and not Core.isCharacterInCombat() and IsOutdoors() and not UnitInVehicle('player') and Movement.canPlayerStandOnPoint(Core.retrieveCharacterPosition(),
    { withMount = true })
end

local APPRENTICE_RIDING = 33388
local JOURNEYMAN_RIDING = 33391
local EXPERT_RIDING = 34092
local MASTER_RIDING = 90265

function Movement.canCharacterFlyOrDragonride()
  return Movement.canCharacterFly() or Movement.canCharacterRideDragon()
end

function Movement.canCharacterFly()
  return (
    (Movement.canCharacterMount() and (IsSpellKnown(EXPERT_RIDING) or IsSpellKnown(MASTER_RIDING)) and Movement.isFlyingAvailableInZone() and Movement.isAFlyingMountAvailable()) or
      Movement.canCharacterFlyAsGhost()
  )
end

function Movement.canCharacterFlyAsGhost()
  -- TODO: All zones where can be flown as ghost.
  return Core.isCharacterGhost() and Core.retrieveCurrentContinentID() == DRAGON_ISLES_CONTINENT_ID
end

function Movement.canCharacterMountOnGroundMount()
  -- TODO: Is ground mounting available in all zones?
  return Movement.canCharacterMount() and (IsSpellKnown(APPRENTICE_RIDING) or IsSpellKnown(JOURNEYMAN_RIDING) or IsSpellKnown(EXPERT_RIDING) or IsSpellKnown(MASTER_RIDING)) and Movement.isAGroundMountAvailable()
end

function Movement.distanceOfPointToLine(point, line)
  local A = line[1]
  local B = line[2]

  local BA = Vector.Vector:new(
    point.x - A.x,
    point.y - A.y,
    point.z - A.z
  )

  local BC = Vector.Vector:new(
    B.x - A.x,
    B.y - A.y,
    B.z - A.z
  )

  return BA:cross(BC):magnitude() / BC:magnitude()
end

function Movement.calculate2DDistanceOfPointToLine(point, line)
  -- source: https://en.wikipedia.org/w/index.php?title=Distance_from_a_point_to_a_line&oldid=1122418293#Line_defined_by_two_points

  local P1 = line[1]
  local P2 = line[2]

  local x1 = P1.x
  local y1 = P1.y

  local x2 = P2.x
  local y2 = P2.y

  local x0 = point.x
  local y0 = point.y

  return math.abs((x2 - x1) * (y1 - y0) - (x1 - x0) * (y2 - y1)) / math.sqrt(math.pow(x2 - x1, 2), math.pow(y2 - y1, 2))
end

function Movement.isMissingWaypointWithCurrentMovementDirection(waypoint)
  local playerPosition = Core.retrieveCharacterPosition()
  local yaw = HWT.ObjectFacing('player')
  local pitch = HWT.UnitPitch('player')
  local movementVector = {
    x = math.cos(yaw) * math.cos(pitch),
    y = math.sin(yaw) * math.cos(pitch),
    z = math.sin(pitch),
  }
  local positionB = {
    x = playerPosition.x + movementVector.x,
    y = playerPosition.y + movementVector.y,
    z = playerPosition.z + movementVector.z
  }

  if IsFlying() or Core.isCharacterSwimming() then
    return Movement.distanceOfPointToLine(waypoint, { playerPosition, positionB }) > TOLERANCE_RANGE
  else
    local distance = Movement.calculate2DDistanceOfPointToLine(waypoint, { playerPosition, positionB })
    return distance > TOLERANCE_RANGE
  end
end

function Movement.isCharacterFlying()
  return Movement.isMountedOnFlyingMount() and Movement.isCharacterInTheAir()
end

function Movement.isCharacterInTheAir()
  local playerPosition = Core.retrieveCharacterPosition()
  return Movement.isPositionInTheAir(playerPosition)
end

function Movement.createMoveToAction3(waypoint, a, totalDistance, isLastWaypoint, waypointIndex, path)
  local firstRun = true
  local initialDistance = nil
  local lastJumpTime = nil

  local function runForGroundAndFlying(action, actionSequenceDoer, remainingDistance)
    local characterPosition = Core.retrieveCharacterPosition()

    local liftUpWithFlyingMount = (
      Movement.canCharacterFly() and
        Movement.isMountedOnFlyingMount() and
        (remainingDistance > 10 or Movement.isPositionInTheAir(waypoint)) and
        (Movement.isPointCloseToGround(characterPosition) or (Movement.isPointInDeepWater(characterPosition) and not Movement.isPointInDeepWater(waypoint))) and
        (not isLastWaypoint or Movement.isPositionInTheAir(waypoint))
    )

    local liftUpWithDragonridingMount = (
      Movement.canCharacterRideDragon() and
        Movement.isMountedOnDragonridingMount() and
        Movement.Dragonriding.areConditionsMetForFlyingHigher(waypoint)
    )

    print('liftUpWithDragonridingMount', liftUpWithDragonridingMount)

    if liftUpWithFlyingMount then
      Movement.liftUp()
    elseif liftUpWithDragonridingMount then
      Core.stopMovingForward()
      Movement.liftUp()
      return -- transition to dragonriding
    end

    if Movement.Flying.areConditionsMetForFlyingHigher(waypoint) then
      Core.stopMovingForward()
      Movement.Flying.flyHigher(waypoint)
    end

    if _.areConditionsMetForFacingWaypoint(waypoint) then
      _.faceWaypoint(action, waypoint, isLastWaypoint)
    end

    if not Core.isCharacterMoving() then
      Core.startMovingForward()
    end

    if Movement.isSituationWhereCharacterMightOnlyFitThroughDismounted() and (not IsFlying() or Movement.isPositionLessOffGroundThanTheMaximum(characterPosition,
      10)) then
      Movement.dismount()
      actionSequenceDoer.lastTimeDismounted = GetTime()
    end

    if not lastJumpTime or GetTime() - lastJumpTime > 1 then
      if (Movement.isJumpSituation(waypoint)) then
        lastJumpTime = GetTime()
        Core.jumpOrStartAscend()
      end
    end
  end

  local function runForDragonriding(action, actionSequenceDoer, remainingDistance)
    Movement.Dragonriding.updateFacing(waypoint, action)

    if Movement.Dragonriding.areConditionsMetForFlyingHigher(waypoint) then
      print('Movement.Dragonriding.areConditionsMetForFlyingHigher', 'ja')
      Movement.Dragonriding.flyHigher()
    end

    if Movement.Dragonriding.areConditionsMetForWhirlingSurge() then
      Movement.Dragonriding.whirlingSurge()
    end

    if Movement.Dragonriding.areConditionsMetForSurgeForward() then
      Movement.Dragonriding.surgeForward()
    end
  end

  return {
    run = function(action, actionSequenceDoer)
      action.hasFlown = action.hasFlown or IsFlying()
      action.hasLanded = action.hasLanded or (action.hasFlown and not IsFlying())

      if not actionSequenceDoer.mounter then
        actionSequenceDoer.mounter = _.Mounter:new()
      end

      if firstRun then
        -- log('waypoint', waypoint.x, waypoint.y, waypoint.z)
        initialDistance = Core.calculateDistanceFromCharacterToPosition(waypoint)
      end

      local remainingDistance = Movement.calculateRemainingPathDistance(path, waypointIndex)

      if remainingDistance > 10 and (not actionSequenceDoer.lastTimeDismounted or GetTime() - actionSequenceDoer.lastTimeDismounted >= 3) then
        actionSequenceDoer.mounter:mount()
      end

      if (
        IsFlying() and
          Movement.isMountedOnDragonridingMount()
      ) then
        runForDragonriding(action, actionSequenceDoer, remainingDistance)
      else
        runForGroundAndFlying(action, actionSequenceDoer, remainingDistance)
      end

      firstRun = false
    end,
    isDone = function()
      return (
        Core.isCharacterCloseToPosition(waypoint, TOLERANCE_RANGE) or
          _.isPointCloseToCharacterWithZTolerance(waypoint)
      )
    end,
    shouldCancel = function(action)
      return (
        a.shouldStop(action) or
          Core.calculateDistanceFromCharacterToPosition(waypoint) > math.max(initialDistance + 5,
            Movement.retrieveCharacterHeight()) or
          _.isPositionUnreachable(waypoint)
      )
    end
  }
end

function Movement.calculateRemainingPathDistance(path, nextWaypointIndex)
  return (
    Core.calculateDistanceFromCharacterToPosition(path[nextWaypointIndex]) +
      Core.calculatePathLength(Array.slice(path, nextWaypointIndex))
  )
end

function _.isPositionUnreachable(position)
  return Movement.isPositionInTheAirWhereAFlyingMountSeemsRequired(position) and not Movement.canCharacterFlyOrDragonride()
end

function _.isPointCloseToCharacterWithZTolerance(point)
  local playerPosition = Core.retrieveCharacterPosition()
  return (
    Math.euclideanDistance2D(playerPosition, point) <= TOLERANCE_RANGE and
      playerPosition.z >= point.z - 0.5 and
      playerPosition.z <= point.z + Movement.retrieveCharacterHeight()
  )
end

function Movement.isSituationWhereCharacterMightOnlyFitThroughDismounted()
  return IsMounted() and _.thereSeemsToBeSomethingInFrontOfTheCharacterForWhichTheCharacterSeemsToHigh()
end

function _.thereSeemsToBeSomethingInFrontOfTheCharacterForWhichTheCharacterSeemsToHigh()
  local characterHeight = Movement.retrieveCharacterHeightForHeightCheck()
  local positionA = Movement.positionInFrontOfPlayer2(-1, characterHeight)
  local positionB = Movement.positionInFrontOfPlayer2(0.5, characterHeight)
  return _.thereAreCollisions2(positionA, positionB)
end

function Movement.retrieveCharacterHeightForHeightCheck()
  if Movement.isMountedOn(1434) then
    return 3.5
  else
    return Movement.retrieveCharacterHeight()
  end
end

function Movement.dismount()
  Dismount()
  Movement.waitForDismounted()
end

function _.areConditionsMetForFacingWaypoint(waypoint)
  return Movement.isMissingWaypointWithCurrentMovementDirection(waypoint)
end

function Movement.thereAreZeroCollisionsBetweenTheCharacterAndThePoint(point)
  local characterPosition = Core.retrieveCharacterPosition()
  return Movement.thereAreZeroCollisions(characterPosition, point)
end

function Movement.isCharacterDragonriding()
  return IsFlying() and Movement.isCharacterMountedOnDragonridingMount()
end

function Movement.isCharacterMountedOnDragonridingMount()
  return Movement.isDragonridingMount(Movement.receiveActiveMountID())
end

function Movement.isCharacterMovingOnGroundSwimmingOrFlying()
  return Movement.isCharacterMovingOnGround() or IsSwimming() or IsFlying()
end

function Movement.isCharacterMovingOnGround()
  return not IsFlying() and not IsSwimming()
end

function Movement.isFlying()
  return IsFlying() and Movement.isCharacterMountedOnFlyingMount()
end

function Movement.isCharacterMountedOnFlyingMount()
  return Movement.isFlyingMount(Movement.receiveActiveMountID())
end

function _.faceWaypoint(action, waypoint, isLastWaypoint)
  local maximumDistance
  if Movement.isCharacterDragonriding() then
    maximumDistance = MAXIMUM_DISTANCE_FOR_STOPPING_WHEN_FACING_WHILE_DRAGONRIDING
  elseif Movement.isCharacterMovingOnGroundSwimmingOrFlying() then
    maximumDistance = MAXIMUM_DISTANCE_FOR_STOPPING_WHEN_FACING_WHILE_MOVING_ON_GROUND_SWIMMING_OR_FLYING
  end
  if Core.calculateDistanceFromCharacterToPosition(waypoint) <= maximumDistance then
    Core.stopMovingForward()
  end
  local facingPoint
  if not isLastWaypoint then
    if Movement.isPointCloseToGround(waypoint) and Movement.isMountedOnFlyingMount() and Movement.canCharacterFlyOrDragonride() then
      facingPoint = Movement.createPointWithZOffset(waypoint, TARGET_LIFT_HEIGHT)
    else
      facingPoint = waypoint
    end
    if Movement.isMountedOnFlyingMount() and Movement.canCharacterFlyOrDragonride() then
      local pointInAir = Movement.determinePointHighEnoughToStayInAir(waypoint)
      if pointInAir and Core.calculateDistanceFromCharacterToPosition(waypoint) > 5 then
        facingPoint = pointInAir
      end
    end
  else
    facingPoint = waypoint
  end
  Movement.facePoint(facingPoint, function()
    return action.isDone() or action.shouldCancel()
  end)
end

function Movement.retrieveMaximumDistanceForStoppingWhenFacing()
  local maximumDistance
  if Movement.isCharacterDragonriding() then
    maximumDistance = MAXIMUM_DISTANCE_FOR_STOPPING_WHEN_FACING_WHILE_DRAGONRIDING
  elseif Movement.isCharacterMovingOnGroundSwimmingOrFlying() then
    maximumDistance = MAXIMUM_DISTANCE_FOR_STOPPING_WHEN_FACING_WHILE_MOVING_ON_GROUND_SWIMMING_OR_FLYING
  end
  return maximumDistance
end

function _.stopForwardMovement()
  Core.stopMovingForward()
  Movement.waitForPlayerStandingStill()
end

_.Mounter = {}

function _.Mounter:new()
  local mounter = {
    positionWhereFailedToMountLastTime = nil
  }
  setmetatable(mounter, { __index = _.Mounter })
  return mounter
end

function _.Mounter:mount()
  if not self:stopTryingToMount() and _.canCharacterMountOnBetterMount() then
    _.stopForwardMovement()
    local hasTriedToMount = false
    local wasAbleToMount = nil
    if Movement.canCharacterRideDragon() then
      hasTriedToMount = true
      wasAbleToMount = Movement.mountOnDragonridingMount()
    elseif Movement.canCharacterFly() then
      hasTriedToMount = true
      wasAbleToMount = Movement.mountOnFlyingMount()
    elseif Movement.canCharacterMountOnGroundMount() then
      hasTriedToMount = true
      wasAbleToMount = Movement.mountOnGroundMount()
    end
    if hasTriedToMount then
      if wasAbleToMount then
        self.positionWhereFailedToMountLastTime = nil
      else
        self.positionWhereFailedToMountLastTime = Core.retrieveCharacterPosition()
      end
    end
  end
end

function _.Mounter:stopTryingToMount()
  return self.positionWhereFailedToMountLastTime and Core.isCharacterCloseToPosition(self.positionWhereFailedToMountLastTime,
    10)
end

function _.isCharacterAlreadyOnBestMount()
  -- TODO: Dragonriding
  return Movement.isMountedOnFlyingMount() or (not Movement.canCharacterFly() and IsMounted())
end

function _.canCharacterMountOnBetterMount()
  return not _.isCharacterAlreadyOnBestMount() and (Movement.canCharacterFly() or Movement.canCharacterMountOnGroundMount())
end

function Movement.determinePointHighEnoughToStayInAir(waypoint)
  local playerPosition = Core.retrieveCharacterPosition()
  local length = Math.euclideanDistance(playerPosition, waypoint)
  local traceLineTargetPoint = Movement.positionInFrontOfPlayer(length, 0)
  local point = Core.traceLineCollision(playerPosition, traceLineTargetPoint)
  if point then
    return Movement.createPointWithZOffset(point, TARGET_LIFT_HEIGHT)
  else
    return nil
  end
end

function _.thereAreCollisions2(from, to)
  local from2 = Core.retrievePositionFromPosition(
    from,
    Core.retrieveCharacterBoundingRadius(),
    Core.calculateAnglesBetweenTwoPoints(from, to) + 0.5 * PI,
    0
  )
  local to2 = Core.retrievePositionFromPosition(
    to,
    Core.retrieveCharacterBoundingRadius(),
    Core.calculateAnglesBetweenTwoPoints(from, to) + 0.5 * PI,
    0
  )
  local from3 = Core.retrievePositionFromPosition(
    from,
    Core.retrieveCharacterBoundingRadius(),
    Core.calculateAnglesBetweenTwoPoints(from, to) - 0.5 * PI,
    0
  )
  local to3 = Core.retrievePositionFromPosition(
    to,
    Core.retrieveCharacterBoundingRadius(),
    Core.calculateAnglesBetweenTwoPoints(from, to) - 0.5 * PI,
    0
  )
  local a = Movement.thereAreCollisions(
    from,
    to
  )
  local b = Movement.thereAreCollisions(
    from2,
    to2
  )
  local c = Movement.thereAreCollisions(
    from3,
    to3
  )
  return a or b or c
end

function Movement.isJumpSituation(to)
  if Movement.isMountedOnFlyingMount() and Movement.canCharacterFly() then
    return false
  end

  local playerPosition = Core.retrieveCharacterPosition()
  local positionA = Movement.createPointWithZOffset(playerPosition, Movement.JUMP_DETECTION_HEIGHT)
  local positionB = Movement.positionInFrontOfPlayer2(0.5, Movement.JUMP_DETECTION_HEIGHT)
  lines = {
    { positionA, positionB }
  }

  return _.thereAreCollisions2(positionA, positionB)
end

local function findPathToSavedPosition2()
  local from = Core.retrieveCharacterPosition()
  local to = AddOn.savedVariables.accountWide.savedPosition
  pathFinder = Movement.createPathFinder()
  local path = pathFinder.start(from, to)
  Movement.path = path
  AddOn.savedVariables.perCharacter.MovementPath = Movement.path
  return path
end

function Movement.findPathToSavedPosition()
  local thread = coroutine.create(function()
    Movement.path = findPathToSavedPosition2()
    AddOn.savedVariables.perCharacter.MovementPath = Movement.path
  end)
  return Coroutine.resumeWithShowingError(thread)
end

function Movement.findPathToQuestingPointToMove()
  local thread = coroutine.create(function()
    Movement.path = _.findPathToSavedPosition3()
    AddOn.savedVariables.perCharacter.MovementPath = Movement.path
  end)
  return Coroutine.resumeWithShowingError(thread)
end

function _.findPathToSavedPosition3()
  local from = Core.retrieveCharacterPosition()
  local to = Questing.savedVariables.perCharacter.Questing.savedVariables.perCharacter.QuestingPointToMove
  pathFinder = Movement.createPathFinder()
  local path = pathFinder.start(from, to)
  Movement.path = path
  AddOn.savedVariables.perCharacter.MovementPath = Movement.path
  return path
end

function Movement.moveToSavedPosition()
  Coroutine.runAsCoroutine(function()
    local path = findPathToSavedPosition2()
    Movement.path = path
    AddOn.savedVariables.perCharacter.MovementPath = Movement.path
    if path then
      Movement.movePath(path)
    end
  end)
end

function Movement.moveCloserTo(x, y, z)
  local playerPosition = Core.retrieveCharacterPosition()
  local px = playerPosition.x
  local py = playerPosition.y
  local pz = playerPosition.z
  local to = Core.createPosition(x, y, z)
  local distance = Core.calculateDistanceBetweenPositions(playerPosition, to)
  for a = 0, distance, 1 do
    local moveTo = Core.retrievePositionBetweenPositions(playerPosition, to, a)
    if Core.doesPathExistFromCharacterTo(moveTo) then
      Questing.Coroutine.moveTo(moveTo)
      return
    end
  end
end

function Movement.determineStartPosition()
  local playerPosition = Core.retrieveCharacterPosition()
  return Movement.createPoint(playerPosition.x, playerPosition.y, playerPosition.z)
end

local pathMover = nil

function Movement.receiveActiveMount()
  local mountIDs = C_MountJournal.GetMountIDs()
  for _, mountID in ipairs(mountIDs) do
    local mountInfo = { C_MountJournal.GetMountInfoByID(mountID) }
    if mountInfo[4] then
      return unpack(mountInfo)
    end
  end
  return nil
end

function Movement.isMountedOnFlyingMount()
  if IsMounted() then
    local mountID = select(12, Movement.receiveActiveMount())
    if mountID then
      return Movement.isFlyingMount(mountID)
    end
  end
  return false
end

function Movement.isMountedOnDragonridingMount()
  if IsMounted() then
    return Movement.isDragonridingMount(select(12, Movement.receiveActiveMount()))
  end
  return false
end

function Movement.isDismounted()
  return not IsMounted()
end

function Movement.isMountedOn(mountID)
  return Movement.receiveActiveMountID() == mountID
end

function Movement.receiveActiveMountID()
  local activeMountID = select(12, Movement.receiveActiveMount())
  return activeMountID
end

function Movement.waitForDismounted()
  return Coroutine.waitFor(Movement.isDismounted)
end

function Movement.waitForMounted()
  Coroutine.waitFor(function()
    return IsMounted()
  end)
end

function Movement.isSpellNameForFlyingMount(spellName)
  if spellName then
    local spellID = select(7, GetSpellInfo(spellName))
    if spellID then
      local mountID = C_MountJournal.GetMountFromSpell(spellID)
      if mountID then
        return Movement.isFlyingMount(mountID)
      end
    end
  end

  return false
end

function Movement.receiveGroundMountID()
  return Movement.receiveAnAvailableGroundMount()
end

function Movement.receiveFlyingMountID()
  return Movement.receiveAnAvailableFlyingMount()
end

function Movement.receiveDragonridingMountID()
  return Movement.receiveAnAvailableDragonridingMount()
end

function Movement.mountOnGroundMount()
  if not IsMounted() then
    local mountID = Movement.receiveGroundMountID()
    if mountID then
      Movement.mountOnMount(mountID)
    end
  end
end

function Movement.mountOnFlyingMount()
  if not Movement.isMountedOnFlyingMount() then
    local mountID = Movement.receiveFlyingMountID()
    if mountID then
      Movement.mountOnMount(mountID)
    end
  end
end

function Movement.mountOnDragonridingMount()
  if not Movement.isMountedOnDragonridingMount() then
    local mountID = Movement.receiveDragonridingMountID()
    if mountID then
      Movement.mountOnMount(mountID)
    end
  end
end

function Movement.mountOnMount(mountID)
  if not Movement.isMountedOn(mountID) then
    local spellName = C_MountJournal.GetMountInfoByID(mountID)
    if spellName then
      Core.castSpellByName(spellName)
      -- There seems to be some buildings where `IsOutdoors()` returns `true` and there cannot be flown (one found in Bastion).
      Coroutine.waitForDuration(1)
      -- With this check we check if the casting works.
      local isCasting = Boolean.toBoolean(UnitCastingInfo('player'))
      if isCasting then
        Movement.waitForMounted()
      end
    end
  end
end

function Movement.waitForIsInAir()
  return Coroutine.waitFor(Movement.isCharacterInTheAir)
end

function Movement.waitForIsInAirOrDismounted(timeout)
  return Coroutine.waitFor(function()
    return Movement.isCharacterInTheAir() or Movement.isDismounted()
  end, timeout)
end

function Movement.liftUp()
  if Movement.isMountedOnFlyingMount() then
    Movement.liftUpWithFlyingMount()
  elseif Movement.isMountedOnDragonridingMount() then
    Movement.Dragonriding.liftUp()
  end
end

function Movement.liftUpWithFlyingMount()
  Core.jumpOrStartAscend()
  Movement.waitForIsInAirOrDismounted(3)
  Core.stopAscending()
end

function Movement.createPathFinder()
  local shouldStop2 = false

  local a = {
    shouldStop = function()
      return shouldStop2
    end
  }

  return {
    start = function(from, to, toleranceDistance)
      Core.loadMapForCurrentContinentIfNotLoaded()

      return Movement.findPath2(from, to, toleranceDistance, a)
    end,
    stop = function()
      shouldStop2 = true
    end
  }
end

function Movement.waitForPlayerStandingStill()
  return Coroutine.waitFor(function()
    return not Core.isCharacterMoving()
  end)
end

function Movement.findPath2(from, to, toleranceDistance, a)
  return Movement.findPathInner(from, to, toleranceDistance, a)
end

function Movement.retrievePointIndex(point)
  return MovementSavedVariables.pointIndexes:retrieveValue(point)
end

function Movement.createPointIndex(point)
  local pointIndex = MovementSavedVariables.nextPointIndex
  MovementSavedVariables.pointIndexes:setValue(point, pointIndex)
  MovementSavedVariables.points[pointIndex] = point
  MovementSavedVariables.nextPointIndex = MovementSavedVariables.nextPointIndex + 1
  return pointIndex
end

local function retrievePoint(pointIndex)
  local point = MovementSavedVariables.points[pointIndex]
  return Movement.createPoint(point.x, point.y, point.z)
end

local function _retrieveNeighbor(pointIndex)
  return retrievePoint(pointIndex)
end

function Movement.retrieveConnections(pointIndex)
  local connections2 = MovementSavedVariables.connections[pointIndex]
  if connections2 then
    return Array.map(connections2, function(connection)
      local point = retrievePoint(connection[1])
      if connection[2] then
        if connection[3] then
          return Movement.createPointWithPathToAndObjectID(point.x, point.y, point.z, connection[2], connection[3])
        else
          return Movement.createPointWithPathTo(point.x, point.y, point.z, connection[2])
        end
      end
    end)
  else
    return {}
  end
end

function Movement.retrieveNeighbors(pointIndex)
  local neighborPointIndexes = MovementSavedVariables.neighbors[pointIndex]
  if neighborPointIndexes then
    local neighborPoints = Array.map(neighborPointIndexes, _retrieveNeighbor)
    return neighborPoints
  else
    return nil
  end
end

local function _storeNeighbor(pointIndex, neighbor)
  local neighborIndex = Movement.retrieveOrCreatePointIndex(neighbor)
  table.insert(MovementSavedVariables.neighbors[pointIndex], neighborIndex)
end

function Movement.retrieveOrCreatePointIndex(point)
  return Movement.retrievePointIndex(point) or Movement.createPointIndex(point)
end

function Movement.storeNeighbors(pointIndex, neighbors2)
  MovementSavedVariables.neighbors[pointIndex] = {}
  Array.forEach(neighbors2, Function.partial(_storeNeighbor, pointIndex))
end

local function isPoint(value)
  return value.x
end

function Movement.createPathIndex(path)
  local pathIndex = MovementSavedVariables.nextPathIndex
  MovementSavedVariables.paths[pathIndex] = Array.map(path, function(value)
    if isPoint(value) then
      return Movement.retrieveOrCreatePointIndex(value)
    else
      return value
    end
  end)
  MovementSavedVariables.nextPathIndex = MovementSavedVariables.nextPathIndex + 1
  return pathIndex
end

function Movement.retrievePathIndexFromPathReference(pathReference)
  return pathReference[1]
end

function Movement.retrievePath(pathIndex)
  return Array.flatMap(MovementSavedVariables.paths[pathIndex], function(value)
    if type(value) == 'table' then
      return Movement.retrievePath(Movement.retrievePathIndexFromPathReference(value))
    else
      return retrievePoint(value)
    end
  end)
end

local function createPathReference(pathIndex)
  return { pathIndex }
end

function Movement.addConnection(pointIndex, connection)
  if not MovementSavedVariables.connections[pointIndex] then
    MovementSavedVariables.connections[pointIndex] = {}
  end
  table.insert(MovementSavedVariables.connections[pointIndex], connection)
end

function Movement.addConnectionFromTo(closestPointOnGridFromFromPoint, from, to)
  Movement.addConnectionFromToWithInteractable(closestPointOnGridFromFromPoint, from, to, nil)
end

function Movement.addConnectionFromToWithInteractable(closestPointOnGridFromFromPoint, from, to, objectID)
  local closestPointOnGridIndexFromFromPoint = Movement.retrieveOrCreatePointIndex(closestPointOnGridFromFromPoint)
  local toPointIndex = Movement.retrieveOrCreatePointIndex(to)
  local pathIndex = Movement.createPathIndex({ from })
  local connection = {
    toPointIndex,
    pathIndex,
    objectID
  }
  Movement.addConnection(closestPointOnGridIndexFromFromPoint, connection)
end

function Movement.storeConnection(path)
  local destinationPointIndex = Movement.retrieveOrCreatePointIndex(path[#path])

  local index = #path - 1

  local subPath = Array.slice(path, index)
  local startPointIndex = Movement.retrieveOrCreatePointIndex(subPath[1])
  local pathIndex = Movement.createPathIndex(subPath)
  local connection = {
    destinationPointIndex,
    pathIndex
  }
  Movement.addConnection(startPointIndex, connection)

  for index = #path - 2, 1, -1 do
    local subPath = { path[index], createPathReference(pathIndex) }
    local startPointIndex = Movement.retrieveOrCreatePointIndex(subPath[1])
    pathIndex = Movement.createPathIndex(subPath)
    local connection = {
      destinationPointIndex,
      pathIndex
    }
    Movement.addConnection(startPointIndex, connection)
  end
end

function Movement.findPathInner(from, to, toleranceDistance, a)
  local path = Core.findPath(from, to)

  Movement.path = path
  AddOn.savedVariables.perCharacter.MovementPath = Movement.path

  return path
end

function Movement.receiveNeighborPoints(point, distance)
  local pointIndex = Movement.retrieveOrCreatePointIndex(point)
  local connections2 = Movement.retrieveConnections(pointIndex)
  local neighborPoints = connections2

  local neighborPointsRetrievedFromInGameMesh = Movement.retrieveNeighbors(pointIndex)
  if not neighborPointsRetrievedFromInGameMesh then
    neighborPointsRetrievedFromInGameMesh = Movement.generateNeighborPoints(point, distance)
    Movement.storeNeighbors(pointIndex, neighborPointsRetrievedFromInGameMesh)
  end
  local pointToConnectionPoint = Movement.PointToValueMap:new()
  Array.forEach(connections2, function(point)
    pointToConnectionPoint:setValue(point, point)
  end)
  neighborPointsRetrievedFromInGameMesh = Array.map(neighborPointsRetrievedFromInGameMesh, function(point)
    local connectionPoint = pointToConnectionPoint:retrieveValue(point)
    if connectionPoint then
      return connectionPoint
    else
      return point
    end
  end)
  Array.append(neighborPoints, neighborPointsRetrievedFromInGameMesh)

  return neighborPoints
end

function Movement.movePath(path, options)
  options = options or {}

  if not options.continueMoving then
    Movement.stopMoving()
  end
  local a = {
    shouldStop = options.stop or Function.alwaysFalse
  }
  local pathLength = #path
  local totalDistance = Core.calculatePathLength(path)
  pathMover = ActionSequenceDoer.createActionSequenceDoer2(
    Array.map(path, function(waypoint, index)
      return Movement.createMoveToAction3(waypoint, a, totalDistance, index == pathLength, index,
        path)
    end),
    {
      onStop = function()
        if not options.continueMoving then
          Core.stopMovingForward()
        end
      end
    }
  )
  return pathMover.run(), pathMover
end

local function cleanUpPathFinding()
  pathFinder = nil
  run = nil
  aStarPoints = nil
  -- Movement.path = nil
  -- AddOn.savedVariables.perCharacter.MovementPath = Movement.path
end

local function cleanUpPathMoving()
  pathMover = nil
  if not pathFinder then
    run = nil
  end
end

local function cleanUpPathFindingAndMoving()
  cleanUpPathFinding()
  cleanUpPathMoving()
end

local function stopPathFinding()
  if pathFinder then
    pathFinder.stop()
    cleanUpPathFinding()
  end
end

Movement.stopPathFinding = stopPathFinding

function Movement.stopPathMoving()
  if pathMover then
    pathMover.stop()
    cleanUpPathMoving()
  end
end

function Movement.stopPathFindingAndMoving()
  stopPathFinding()
  Movement.stopPathMoving()
end

local function isPathFinding()
  return Boolean.toBoolean(pathFinder)
end

local function isDifferentPathFindingRequestThanRun(to)
  return not run or to ~= run.to
end

function Movement.moveTo(to, options)
  print('Movement.moveTo')
  options = options or {}
  local stop = options.stop or Function.alwaysFalse

  local function hasArrived()
    local toleranceDistance = options.toleranceDistance or 0
    return Core.calculateDistanceFromCharacterToPosition(to) <= toleranceDistance
  end

  local hasLanded = false

  while not stop() and not hasArrived() do
    local from = Core.retrieveCharacterPosition()

    if not hasLanded and (Movement.canCharacterRideDragon() or Movement.canCharacterFly()) then
      hasLanded = Movement.moveToViaDragonridingOrFlying(from, to, options, hasArrived)
    elseif Movement.isThereAPathOnTheGround(from, to, options) then
      Movement.moveToOnTheGround(from, to, options)
    else
      print('break')
      break
    end

    Coroutine.yieldAndResume()
  end

  print(3)
end

function Movement.isThereAPathOnTheGround(from, to, options)
  local closestPointOnMeshToFrom = Core.retrieveClosestPositionOnMesh(from)
  if closestPointOnMeshToFrom then
    local path = Core.findPath(closestPointOnMeshToFrom, to)
    return Boolean.toBoolean(path)
  else
    return false
  end
end

function Movement.moveToViaDragonridingOrFlying(from, to, options, hasArrived)
  print(1)
  Movement.stopPathFindingAndMoving()

  local path = {
    from,
    to
  }
  Movement.path = path
  AddOn.savedVariables.perCharacter.MovementPath = Movement.path

  local resolvable
  local hasLanded = false
  resolvable, pathMover = Movement.movePath(Array.slice(path, 2), {
    stop = function(context)
      hasLanded = context.hasLanded
      return (stop and stop()) or hasArrived() or Core.isCharacterDead() or context.hasLanded
    end,
    continueMoving = options.continueMoving
  })
  await(resolvable)
  print('has landed', hasLanded)
  return hasLanded
end

function Movement.moveToOnTheGround(from, to, options)
  print(2)
  local closestPositionOnMesh = Core.retrieveClosestPositionOnMesh(from)
  if closestPositionOnMesh then
    from = closestPositionOnMesh
  end

  local closestPositionOnMesh = Core.retrieveClosestPositionOnMesh(to)
  if closestPositionOnMesh then
    to = closestPositionOnMesh
  end

  print('isDifferentPathFindingRequestThanRun(to)', isDifferentPathFindingRequestThanRun(to))
  if isDifferentPathFindingRequestThanRun(to) then
    Movement.stopPathFindingAndMoving()
    local path = _.findPath(from, to, options)
    print('path', path)
    AddOn.savedVariables.perCharacter.MovementPath = Movement.path
    if path then
      local resolvable
      resolvable, pathMover = Movement.movePath(path, {
        stop = function()
          local result = (stop and stop()) or (options.toleranceDistance and Core.calculateDistanceFromCharacterToPosition(to) <= options.toleranceDistance)
          print('stop result', result)
          return result
        end,
        continueMoving = options.continueMoving
      })
      await(resolvable)
      cleanUpPathFindingAndMoving()
    end
  end
end

function _.findPath(from, to, options)
  run = {
    from = from,
    to = to
  }
  pathFinder = Movement.createPathFinder()
  local path = pathFinder.start(from, to, options.toleranceDistance)
  pathFinder = nil
  Movement.path = path
  return path
end

local function moveToFromNonCoroutine(x, y, z)
  Coroutine.runAsCoroutine(function()
    Movement.moveTo(Movement.createPoint(x, y, z))
  end)
end

-- view distance = 5: 625
-- view distance = 10: 975

function Movement.waitForPlayerToBeOnPosition(position, radius)
  radius = radius or 3
  Coroutine.waitFor(function()
    return Core.isCharacterCloseToPosition(position, radius)
  end)
end

function Movement.facePoint(point, stop)
  Movement.face(
    function()
      return Movement.calculateAnglesFromCharacterToPoint(point)
    end,
    stop
  )
end

function Movement.faceObject(object, stop)
  local point = Core.retrieveObjectPosition(object)
  if point then
    Movement.facePoint(point, stop)
  end
end

function Movement.faceDirection(yaw, pitch, stop)
  Movement.face(
    function()
      return yaw, pitch
    end,
    stop
  )
end

function Movement.calculateAnglesFromCharacterToPoint(point)
  local characterPosition = Core.retrieveCharacterPosition()
  return Core.calculateAnglesBetweenTwoPoints(characterPosition, point)
end

function Movement.isCharacterFacingPoint(point)
  local yaw, pitch = Movement.calculateAnglesFromCharacterToPoint(point)
  return Movement.isCharacterFacingWithAngles(yaw, pitch)
end

local TOLERANCE_DIFFERENCE = 0.00000006

function Movement.isCharacterFacingWithAngles(yaw, pitch)
  local characterYaw = HWT.ObjectFacing('player')
  local characterPitch = HWT.UnitPitch('player')
  return (
    math.abs(yaw - characterYaw) <= TOLERANCE_DIFFERENCE and
      math.abs(pitch - characterPitch) <= TOLERANCE_DIFFERENCE
  )
end

function Movement.isCharacterFacingObject(object)
  local position = Core.retrieveObjectPosition(object)
  return Movement.isCharacterFacingPoint(position)
end

local ANGLE_PER_SECOND = math.rad(180)

function Movement.face(retrieveTargetAngles, stop)
  local yaw, pitch = retrieveTargetAngles()
  local characterYaw = HWT.ObjectFacing('player')
  local yawDelta = Core.normalizeAngle(characterYaw - yaw)
  if yawDelta > math.rad(180) then
    yawDelta = math.rad(360) - yawDelta
  end
  local isFacing = false
  if yawDelta > 0 then
    local duration = yawDelta / ANGLE_PER_SECOND
    HWT.FaceDirectionSmoothly(yaw, duration)
    isFacing = true
  end

  local characterPitch = HWT.UnitPitch('player')
  if pitch ~= characterPitch and (Core.isCharacterFlying() or Core.isCharacterSwimming()) then
    HWT.SetPitch(pitch)
    isFacing = true
  end

  if isFacing then
    Coroutine.waitUntil(function()
      return not HWT.IsFacingSmoothly()
    end)
  end
end

function _.waitForCharacterToHaveStoppedRotating()
  local previousCharacterYaw = nil
  local previousCharacterPitch = nil
  Coroutine.waitFor(function()
    local characterYaw = HWT.ObjectFacing('player')
    local characterPitch = HWT.UnitPitch('player')

    if previousCharacterYaw and previousCharacterPitch and Float.seemsCloseBy(previousCharacterYaw,
      characterYaw) and Float.seemsCloseBy(previousCharacterPitch, characterPitch) then
      return true
    else
      previousCharacterYaw = characterYaw
      previousCharacterPitch = characterPitch
      return false
    end
  end)
end

function Movement.closestPointOnGrid(point)
  return Movement.createPoint(
    Movement.closestCoordinateOnGrid(point.x),
    Movement.closestCoordinateOnGrid(point.y),
    Movement.closestCoordinateOnGrid(point.z)
  )
end

function Movement.closestPointOnGridWithZLeft(point)
  return Movement.createPoint(
    Movement.closestCoordinateOnGrid(point.x),
    Movement.closestCoordinateOnGrid(point.y),
    point.z
  )
end

function Movement.closestPointOnGridWithZOnGround(point)
  point = Movement.closestPointOnGridWithZLeft(point)
  return Movement.createPoint(
    point.x,
    point.y,
    Movement.retrieveGroundZ(point)
  )
end

function Movement.closestCoordinateOnGrid(coordinate)
  return Math.round(coordinate / GRID_LENGTH) * GRID_LENGTH
end

function Movement.convertPointToArray(point)
  return { point.x, point.y, point.z }
end

function Movement.convertPathToGMRPath(path)
  return Array.map(path, Movement.convertPointToArray)
end

function Movement.moveToSavedPath()
  return Coroutine.runAsCoroutine(function()
    Movement.movePath(path)
  end)
end

function Movement.traceLineCollisionWithFallback(from, to)
  return Movement.traceLineWithFallback(from, to, Core.TraceLineHitFlags.COLLISION)
end

function Movement.traceLineWithFallback(from, to, traceLineHitFlags)
  if Core.isPositionInRangeForTraceLineChecks(from) and Core.isPositionInRangeForTraceLineChecks(from) then
    return Core.traceLine(from, to, traceLineHitFlags)
  elseif Float.seemsCloseBy(from.x, to.x) and Float.seemsCloseBy(from.y, to.y) then
    local x = from.x
    local y = from.y
    local includeWater = Core.areFlagsSet(traceLineHitFlags,
      Core.TraceLineHitFlags.WATER) or Core.areFlagsSet(traceLineHitFlags, Core.TraceLineHitFlags.WATER2)
    local closestPointOnMesh = Core.retrieveClosestPositionOnMesh(
      Core.createWorldPosition(Movement.retrieveContinentID(), from.x, from.y, from.z),
      includeWater
    )
    local minZ = math.min(from.z, to.z)
    local maxZ = math.max(from.z, to.z)
    if (
      closestPointOnMesh and
        Float.seemsCloseBy(closestPointOnMesh.x, x) and
        Float.seemsCloseBy(closestPointOnMesh.y, y) and
        closestPointOnMesh.z >= minZ and closestPointOnMesh.z <= maxZ
    ) then
      return closestPointOnMesh
    end
  else
    return nil
  end
end

function Movement.createPositionFromPoint(continentID, point)
  return {
    continentID = continentID,
    x = point.x,
    y = point.y,
    z = point.z
  }
end

function Movement.retrievePositionBetweenPositions(a, b, distanceFromA)
  return Core.retrievePositionBetweenPositions(a, b, distanceFromA)
end

function Movement.generateWalkToPointFromCollisionPoint(from, collisionPoint)
  local pointWithDistanceToCollisionPoint = Movement.retrievePositionBetweenPositions(collisionPoint, from,
    Core.retrieveCharacterBoundingRadius())
  local z = Movement.retrieveGroundZ(pointWithDistanceToCollisionPoint)
  return Movement.createPoint(pointWithDistanceToCollisionPoint.x, pointWithDistanceToCollisionPoint.y, z)
end

function Movement.isFirstPointCloserToThanSecond(fromA, fromB, to)
  return Math.euclideanDistance(fromA, to) < Math.euclideanDistance(fromB, to)
end

function Movement.findClosestPointThatCanBeWalkedTo(from, to)
  local walkToPoint = from
  while true do
    local pointOnMaximumWalkUpToHeight = Movement.createPointWithZOffset(walkToPoint,
      Movement.MAXIMUM_WALK_UP_TO_HEIGHT)
    local destinationOnMaximumWalkUpToHeight = Movement.createPointWithZOffset(to, Movement.MAXIMUM_WALK_UP_TO_HEIGHT)
    local collisionPoint = Core.traceLineCollision(pointOnMaximumWalkUpToHeight, destinationOnMaximumWalkUpToHeight)
    if collisionPoint then
      local potentialWalkToPoint = Movement.generateWalkToPointFromCollisionPoint(pointOnMaximumWalkUpToHeight,
        collisionPoint)
      if not walkToPoint or Movement.isFirstPointCloserToThanSecond(potentialWalkToPoint, walkToPoint, to) then
        walkToPoint = potentialWalkToPoint
      else
        break
      end
    else
      walkToPoint = to
      break
    end
  end

  return walkToPoint
end

function Movement.havePointsSameCoordinates(a, b)
  return a.x == b.x and a.y == b.y and a.z == b.z
end

function Movement.stopMoving()
  if pathMover then
    pathMover.stop()
    pathMover = nil
    Movement.path = nil
    AddOn.savedVariables.perCharacter.MovementPath = Movement.path
  end
end

function Movement.initializeSavedVariables()
  if not MovementSavedVariables then
    MovementSavedVariables = {}
  end
  if not MovementSavedVariables.connections then
    MovementSavedVariables.connections = {}
  end
  if not MovementSavedVariables.points then
    MovementSavedVariables.points = {}
  end
  if not MovementSavedVariables.pointIndexes then
    MovementSavedVariables.pointIndexes = Movement.PointToValueMap:new()
  else
    local pointIndexes = MovementSavedVariables.pointIndexes
    MovementSavedVariables.pointIndexes = Movement.PointToValueMap:new()
    MovementSavedVariables.pointIndexes._values = pointIndexes._values
  end
  if not MovementSavedVariables.nextPointIndex then
    MovementSavedVariables.nextPointIndex = 1
  end
  if not MovementSavedVariables.neighbors then
    MovementSavedVariables.neighbors = {}
  end
  if not MovementSavedVariables.paths then
    MovementSavedVariables.paths = {}
  end
  if not MovementSavedVariables.nextPathIndex then
    MovementSavedVariables.nextPathIndex = 1
  end
end

function findPathE()
  Movement.path = Core.findPathFromCharacterTo(AddOn.savedVariables.accountWide.savedPosition)
  AddOn.savedVariables.perCharacter.MovementPath = Movement.path
end

function findPathE2()
  local playerPosition = Core.retrieveCharacterPosition()
  Movement.path = Core.findPath(playerPosition, AddOn.savedVariables.accountWide.savedPosition)
  AddOn.savedVariables.perCharacter.MovementPath = Movement.path
end

function findPathE4()
  local path = Core.findPathFromCharacterTo(Questing.savedVariables.perCharacter.QuestingPointToMove)
  Movement.path = path
  AddOn.savedVariables.perCharacter.MovementPath = Movement.path
end

function findPathE6()
  local path = Core.findPathFromCharacterTo(AddOn.savedVariables.accountWide.savedPosition)
  Movement.path = path
  AddOn.savedVariables.perCharacter.MovementPath = Movement.path
  print('path')
  DevTools_Dump(path)
end

function _.doWhenAddOnHasBeenLoaded()
  -- TODO: Continent ID

  Movement.addConnectionFromTo(
    Movement.createPoint(
      -1728,
      1284,
      5451.509765625
    ),
    Movement.createPoint(
      -1728.5428466797,
      1283.0802001953,
      5451.509765625
    ),
    Movement.createPoint(
      -4357.6801757812,
      800.40002441406,
      -40.990001678467
    )
  )

  Movement.addConnectionFromToWithInteractable(
    Movement.createPoint(
      -4366,
      814,
      -40.849704742432
    ),
    Movement.createPoint(
      -4366.2514648438,
      813.20324707031,
      -40.817531585693
    ),
    Movement.createPoint(
      -4357.6801757812,
      800.40002441406,
      -40.990001678467
    ),
    373592
  )
end

HWT.doWhenHWTIsLoaded(function()
  AddOn.savedVariables = SavedVariables.loadSavedVariablesOfAddOn(addOnName)
  Movement.savedVariables = AddOn.savedVariables

  SavedVariables.registerAccountWideSavedVariables(
    addOnName,
    AddOn.savedVariables.accountWide
  )

  SavedVariables.registerSavedVariablesPerCharacter(
    addOnName,
    AddOn.savedVariables.perCharacter
  )

  Movement.initializeSavedVariables()
  _.doWhenAddOnHasBeenLoaded()
end)

function Movement.enableVisualization()
  HWT.doWhenHWTIsLoaded(function()
    Draw.Sync(function()
      Draw.SetColorRaw(0, 0, 1, 1)
      Array.forEach(points, function(point)
        Draw.Circle(point.x, point.y, point.z, Core.retrieveCharacterBoundingRadius())
      end)

      Draw.SetColorRaw(0, 0, 1, 1)
      Array.forEach(lines, function(line)
        local a = line[1]
        local b = line[2]
        Draw.Line(a.x, a.y, a.z, b.x, b.y, b.z)
      end)

      if DEVELOPMENT then
        if AddOn.savedVariables.accountWide.savedPosition then
          Draw.SetColorRaw(0, 0, 1, 1)
          Draw.Circle(AddOn.savedVariables.accountWide.savedPosition.x,
            AddOn.savedVariables.accountWide.savedPosition.y,
            AddOn.savedVariables.accountWide.savedPosition.z, 0.5)
        end
      end
      --      --if walkToPoint then
      --      --  Draw.Circle(walkToPoint.x, walkToPoint.y, walkToPoint.z, 0.5)
      --      --end
      if DEVELOPMENT then
        if AddOn.savedVariables.perCharacter.position1 and AddOn.savedVariables.perCharacter.position2 then
          Draw.SetColorRaw(0, 0, 1, 1)
          Draw.Line(
            AddOn.savedVariables.perCharacter.position1.x,
            AddOn.savedVariables.perCharacter.position1.y,
            AddOn.savedVariables.perCharacter.position1.z,
            AddOn.savedVariables.perCharacter.position2.x,
            AddOn.savedVariables.perCharacter.position2.y,
            AddOn.savedVariables.perCharacter.position2.z
          )
        end
      end

      local path = AddOn.savedVariables.perCharacter.MovementPath
      if path then
        Draw.SetColorRaw(0, 0, 1, 1)
        Core.drawPath(path)
      end

      if DEVELOPMENT then
        if aStarPoints then
          Draw.SetColorRaw(0, 0, 1, 1)
          local radius = GRID_LENGTH / 2
          Array.forEach(aStarPoints, function(point)
            Draw.Circle(point.x, point.y, point.z, radius)
          end)
        end
      end
    end)
  end)
end

function Movement.canOnlyBeMovedOnGround()
  return not Movement.canCharacterFlyOrDragonride()
end

Movement.enableVisualization()
