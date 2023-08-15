local defaultNotePos = {};
local shake = false
local sway = false

function onUpdate()
  if shake == true then
    shakeNotes(-4, 4)
  elseif sway == true then
    swayNotes(30)
  else
    return
  end
end

function shakeNotes(min, max)
  for i = 0, 7 do
    setPropertyFromGroup('strumLineNotes', i, 'x', defaultNotePos[i + 1][1] +  math.random(min, max))
    setPropertyFromGroup('strumLineNotes', i, 'y', defaultNotePos[i + 1][2] +  math.random(min, max))
  end
end

function swayNotes(x)
  for i = 0, 7 do
    setPropertyFromGroup('strumLineNotes', i, 'x', defaultNotePos[i + 1][1] + x * math.sin((currentBeat + i*0.25) * math.pi))
  end
end

function onSongStart()
    for i = 0,7 do
        x = getPropertyFromGroup('strumLineNotes', i, 'x')
        y = getPropertyFromGroup('strumLineNotes', i, 'y')

        table.insert(defaultNotePos, {x, y})
    

        -- debugPrint("{" .. x .. "," .. y .. "}" .. "i:" .. i)
    end
end

function onStepHit()
  if curStep == 800 or curStep == 1312 or curStep == 2544 or curStep == 3888 or curStep == 4144 then
    shake = true
  end
  if curStep == 906 or curStep == 1536 or curStep == 2928 or curStep == 4000 or curStep == 4352 then
    shake = false
  end
  if curStep == 3184 then
    sway = true
  end
  if curStep == 3440 then
    sway = false
  end
end

function noteMiss(direction)
  setProperty('health', getProperty('health') + 0.0025)
end

function noteMissPress(direction)
  setProperty('health', getProperty('health') + 0.0025)
end