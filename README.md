# Character Sounds
A replacement implementation of the `RbxCharacterSounds` script that is typically loaded into players by default.

Get it here:

* [Wally]()
* [Releases]()

## API

```Lua
--[=[
Creates a new sound listener

@param director Model -- The character model used to track state for playing sounds
@param performer Model? -- The character model the sounds will play on. Defaults to `director` if nil
@return () -> (), -- callback that terminates the listener and cleans up the sounds
--]=]
function module.listen(director: Model, performer: Model?): AnimateController
```

An example of using this package to replicate the standard `RbxCharacterSounds` script can be found [here.](test/RbxCharacterSounds.client.lua)