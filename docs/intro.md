# Quill

Quill is a schema-based player data system that wraps ProfileStore. It includes serializing, deserializing, built-in data replication and more. It shines when dealing with a large data.

#### Quill relies on `Quills` that are made by `QuillComponents`, which are custom types to Quill.
#### It's encouraged to make your own `QuillComponent` for complex data types.

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

Data should exist in one single module accessible from anywhere. Create a shared data module, preferably somewhere under `ReplicatedStorage` and name it `Data.luau`:

```lua title="Data.luau"
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Quill = require(ReplicatedStorage.Packages.Quill)

return Quill.Init({
    mock = false,
    reset = false,
    
    templates = {
        previous_templates = {
            {
                level = Quill.Number.New(false, "server", "u8", 0)
            },
            
            {
                level = Quill.Number.New(false, "server", "u16", 0)
            }
        },
        
        current_template = {
            rank = Quill.Number.New(true, "server", "u8", 0)
        }
    }
})
```

:::warning
Templates must have `keys` that are strings and `values` that are Quills.

they do NOT accept values that are NOT Quills.
:::

:::note
It's suggested to have the `id`s as integers. They also should be incremented by 1's to avoid confusion
:::

## Usage

`Data.luau` is used similarly in both `Server` and `Client`:

```lua
local Data = require(PATH.TO.DATA)

local rank = Data[player].rank() -- Gets rank
local new_rank = Data[player].rank(50) -- Sets rank and returns the new value
```

# Syntax

This section explains the syntax `Quill`.

## Waiting for data

The player's data might not be available right away, therefore you have to wait for it to load:

### `:Do(callback)`

Receives a callback and calls it once the player data is fully loaded!

```lua title=":Do()"
local Data = require(PATH.TO.DATA)

local data = Data[player]:Do(function() -- Calls the callback once the player data is fully loaded
    local rank = data.rank()
    local new_rank = data.rank(rank + 1)
    
    print(rank) -- Prints 2!
    print(new_rank) -- Prints 3!
    print(data.rank()) -- Prints 3!
end)
```

### `:Wait()`

Yields the current thread until the data is fully loaded!

```lua title=":Wait()"
local Data = require(PATH.TO.DATA)

local data = Data[player]:Wait() -- Yields/Waits until the player data is fully loaded!

local rank = data.rank()
local new_rank = data.rank(rank + 1)

print(rank) -- Prints 2!
print(new_rank) -- Prints 3!
print(data.rank()) -- Prints 3!
```

## Set value

Simply call a `Quill` with the new value, it must match type:

```lua
Data[player].rank(50)
```
:::important
When setting the value of a Quill, you can optionally pass a `boolean` as a second paramater to specify whether you want the change to replicate or not, if left empty, it'll `default` to the Quill's `.auto_replicate`
:::

## Get value

Simply call a `Quill` passing no paramaters:

```lua
local rank = Data[player].rank()
```

## Changes

Quills expose methods to listen for changes that occur to them:

`:Connect(value, previous_value, disconnect)` listens for changes untill disconnected manually.

`:Once(value, previous_value)` listens for changes one time, disconnecting immediately after.

```lua title=":Connect()"
local Data = require(PATH.TO.DATA)

local data = Data[player]

local disconnect = data.rank:Connect(function(rank, prev_rank, disconnect)
    print(`Rank changed from {prev_rank} to {rank}`)
    
    if rank > 5 then
        disconnect()
    end
end)

if data.rank() == 0 then
    disconnect()
end

```

```lua title=":Once()"
local Data = require(PATH.TO.DATA)

local data = Data[player]

local received = false

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

Determines who has the authority over the Quill

 - `Server`: Only modifications from it will be saved and replicated.
 - `Client`: The client will be able to modify the Quill locally and replicate changes to the server, replicating to other clients afterwards.

## Templates

`Templates` are a string-keyed dictionaries with Quills as values.

## Properties

| Option | Description |
| --- | --- |
| `id` | A number that's a unique identifier to the current_template. |
| `mock` | Whether to use mock storage, suggested for testing. |
| `reset` | Whether to reset the player's data upon joining. |
| `environment` | The name of the ProfileStore. Defaults to "Dev" or "Live" depending if the server is running in studio or not. |
| `templates` | Holds the current_template and previous_templates. |