# Quill

Quill is a schema-based player data system that wraps ProfileStore. It includes serializing, deserializing, built-in data replication and more. It shines when dealing with large data.

#### Quill relies on Components that are made by Bases, which are types custom to Quill.
#### It's encouraged to make your own Bases for complex Components/data types.

## Fundamental usage

```lua title="Indexing with Player"
local Data = require(PATH.TO.DATA)

local data = Data[player] -- Gets the player's data

local rank = data.rank() -- Gets the rank (returns 2 for example)
local new_rank = data.rank(rank + 1) -- Sets the rank, returning the newly set rank (now our rank is 3!)

print(rank) -- Prints 2!
print(new_rank) -- Prints 3!
print(data.rank()) -- Prints 3!
```

:::warning
If the player data hasn't loaded yet, a default template will be created and returned, once the player data is fully loaded, it'll replace the values with the loaded ones.
:::

:::note
When the player data fully loads in and the values get replaced with the stored ones, this WILL trigger a changed event.
:::

## What does it do?

- Compresses player data to reduce its size
- Replicates data changes between the server and clients as you wish
- Converts outdated player data to match the new one
- It requires a template for player data, it'll serve as both a default player data and a schema

## Installation

Add `Quill` to your `wally.toml`:

```toml title="wally.toml"
[dependencies]
Quill = "qullzz/quill@0.0.0"
```

Then run the bash command:

```bash
wally install
```

:::important
Make sure you're getting the latest version at `wally.run`
:::

## Data

Data should exist in one single module accessible from anywhere. Create a shared data module, preferably directly under `ReplicatedStorage`, name it `Data.luau`:

```lua title="Data.luau"
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Quill = require(ReplicatedStorage.Packages.Quill)

return Quill.Init({
    mock = false,
    reset = false,
    
    templates = {
        previous_templates = {
            {
                level = Quill.Number.New() -- By default, numbers are unsigned 8-bit integers
            },
            
            {
                level = Quill.Number.New("u16", 0, nil, nil, function(value)
                    return value -- This will convert the old values (from the previous templates) to a new ones
                end)
            }
        },
        
        current_template = {
            rank = Quill.Number("u16", 1) -- Specify it's a u8 and it defaults to 1,
            groupName = Quill.String("some group"),
            inventory = Quill.Array(Quill.Number(), 0) -- This will hold an array of Numbers that'll default to 0
            config = Quill.Map({ -- Simply a dictionary
                graphics = Quill.Map({
                    level = Quill.Number() -- Not paramaters passed, will default to unsigned 8-bit integer
                }),
                keybinds = Quill.Map({
                    openMenu = Quill.Enum(Enum.KeyCode.M) -- This will ONLY hold Enum.KeyCode EnumItems
                }),
                volume = Quill.Map({
                    global = Quill.Number(),
                    sfx = Quill.Number(),
                    music = Quill.Number()
                })
            })
        }
    }
})
```

:::warning
Templates must have `keys` that are strings and `values` that are Components.

They do NOT accept values that are NOT Components.
:::

## Usage

`Data.luau` has identical usage in both `Server` and `Client`:

```lua
local Data = require(PATH.TO.DATA)

local rank = Data[player].rank() -- Gets rank (assuming the data hasn't loaded yet, it'll return the default)
local new_rank = Data[player].rank(50) -- Sets rank and returns the new value (assuming the data hasn't loaded yet, the value set here will overwrite the data when it fully loads)
```

# Syntax

This section explains the syntax of `Quill`.

## Waiting for data

The player's data might not be available right away, therefore you have to wait for it to load:

### `:Do(callback)`

Receives a callback and calls it once the player data is fully loaded!
If already loaded, it'll be called right away!

```lua title=":Do()"
local Data = require(PATH.TO.DATA)

Data[player]:Do(function(data) -- Calls the callback once the player data has loaded
    local rank = data.rank()
    local new_rank = data.rank(rank + 1)
    
    print(rank) -- Prints 2!
    print(new_rank) -- Prints 3!
    print(data.rank()) -- Prints 3!
end)
```

### `:Wait()`

Yields the current thread until the data is fully loaded, returning the data after!
If already loaded, it returns the player data right away!

```lua title=":Wait()"
local Data = require(PATH.TO.DATA)

local data = Data[player]:Wait() -- Yields/Waits until the player data is fully loaded, returning it after

if not data then return end

local rank = data.rank()
local new_rank = data.rank(rank + 1)

print(rank) -- Prints 2!
print(new_rank) -- Prints 3!
print(data.rank()) -- Prints 3!
```

:::important
If the player leaves before the data is loaded, :Wait() will return nil.
:::

## Set value

Setting values for `Components` varies for each Base, but most simple `Components` (eg. numbers, strings...) can be set by calling them and passing the new value:

```lua
Data[player].rank(50)
```
:::important
When setting the value of a `Component`, you can optionally pass a `boolean` as a second paramater to specify whether you want the change to replicate or not, if left empty, it'll `default` to the Component's `.auto_replicate`
:::

## Get value

Like with setting, getting values of `Components` varies for each Base, most simple `Components` like numbers, strings, etc... can be fetched by calling them passing no paramaters:

```lua
local rank = Data[player].rank() -- Simply call it
local inventory = Data[player]:At(-1) -- Arrays hold many Components, you must specify which one you need. In this case, -1 will give us the last Component in the array
```

## Changes

Components expose methods to listen for changes that occur to them:

`:Connect(value, previous_value, disconnect)` listens for changes until disconnected manually.

`:Once(value, previous_value)` listens for changes one time, disconnecting immediately after.

```lua title=":Connect()"
local Data = require(PATH.TO.DATA)

local data = Data[player]

local disconnect = data.rank:Connect(function(rank, prev_rank, disconnect)
    if rank > 5 then -- For some reason, we want to stop tracking rank changes after rank 5
        disconnect()
        
        return
    end
    
    print(`Rank changed from {prev_rank} to {rank}`)
end)

if data.rank() == 0 then
    disconnect()
end

```

```lua title=":Once()"
local Data = require(PATH.TO.DATA)

local data = Data[player]

local disconnect = data.rank:Once(function(rank, prev_rank)
    print(`Rank changed from {prev_rank} to {rank}`)
    
    received = true
end)

task.wait(5)

if not received then
    disconnect()
end

```

## Quill Properties

### auto_replicate: `boolean`

Determines whether changes should be automatically replicated if they weren't explicitly unallowed to.

 - `true`: Will automatically replicate if allowed to.
 - `false`: Won't automatically replicate unless.

### authority: `string`

Determines who has the authority over the Component.

 - `Server`: Only modifications from it will be saved and replicated.
 - `Client`: The client will be able to modify the Component locally and replicate changes to the server, replicating to other clients afterwards.

### convert: `(any) -> T?`

Used to convert an already existing value of a Component to fit the current Component.

 - `Returned type T`: If a value was returned, that values will be used.
 - `Returned type nil`: If nothing was returned, it'll default to the value set by the template's Component.

## Templates

`Templates` are a string-keyed dictionaries with Components as values.

## Properties

| Option | Description |
| --- | --- |
| `mock` | Whether to use mock storage, suggested for testing. |
| `reset` | Whether to reset the player's data upon joining. |
| `environment` | The name of the ProfileStore. Defaults to "Dev" or "Live" depending if the server is running in studio or not. |
| `templates` | Holds the current_template and previous_templates. |