# Character Sounds
A replacement implementation of the `RbxCharacterSounds` script that is typically loaded into players by default.

Get it here:

* [Wally](https://wally.run/package/egomoose/character-sounds)
* [Releases](https://github.com/EgoMoose/character-sounds/releases)

## API

```Lua
--[=[
Creates a new sound listener

@param director Model -- The character model used to track state for playing sounds
@param performer Model? -- The character model the sounds will play on. Defaults to `director` if nil
@return SoundController: {
	cleanup: () -> (), -- stops sounds from playing and cleans them up
}
--]=]
function module.listen(director: Model, performer: Model?): SoundController

--[=[
Creates a new sound listener

@param performer Model -- The character model the sounds will play on
@return ManualSoundController: {
	cleanup: () -> (), -- stops sounds from playing and cleans them up
	fireState: (Enum.HumanoidStateType, ...any) -> (), -- fire a humanoid state for a reactive sound transition
	setVelocity: (Vector3) -> (), -- set the root part velocity
}
--]=]
function module.manual(performer: Model): ManualSoundController
```

An example of using this package to replicate the standard `RbxCharacterSounds` script can be found [here.](test/RbxCharacterSounds.client.lua)