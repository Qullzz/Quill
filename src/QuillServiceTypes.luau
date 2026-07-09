-- // TYPES // --

-- ## BASE ## --

export type QuillBaseDisconnect = () -> ()
export type QuillBaseOnceCallback<T = any> = ( value: T, prev_value: T, replicate: boolean? ) -> ()
export type QuillBaseConnectCallback<T = any> = ( value: T, prev_value: T, disconnect: QuillBaseDisconnect, replicate: boolean? ) -> ()

export type QuillBase<T = any, M = any> = {
    New: ( auto_replicate: QuillAutoReplicate, authority: QuillAuthority, meta_data: M, value: T ) -> Quill<T, M>,
    Clone: ( self: Quill<T, M> ) -> Quill<T, M>,
    Once: ( self: Quill<T, M>, callback: QuillBaseOnceCallback<T> ) -> QuillBaseDisconnect,
    Connect: ( self: Quill<T, M>, callback: QuillBaseConnectCallback<T> ) -> QuillBaseDisconnect,
    TypeEqual: ( quill1: Quill<T, M>, quill2: Quill<T, M> ) -> boolean,
    Serialize: ( self: Quill<T, M> ) -> buffer,
    Deserialize: ( self: Quill<T, M>, buff: buffer ) -> Quill<T, M>,
    
    __eq: ( quill1: Quill<T, M>, quill2: Quill<T, M> ) -> boolean,
    __call: ( self: Quill<T, M>, value: T?, replicate: boolean? ) -> T,
    __index: QuillBase<T, M>?
}

-- ## QUILL ## --

export type QuillAutoReplicate = boolean
export type QuillAuthority = "server" | "client"

export type Quill<T = any, M = any> = typeof(setmetatable({} :: {
    auto_replicate: QuillAutoReplicate,
    authority: QuillAuthority,
    meta_data: M,
    value: T,
    
    _callbacks: {
        {
            callback: QuillBaseOnceCallback<T> | QuillBaseConnectCallback<T>,
            disconnect: QuillBaseDisconnect,
            once: boolean
        }
    }
}, {} :: QuillBase<T, M>)) & QuillBase<T, M> & (( value: T?, replicate: boolean? ) -> T)

-- ## PROPERTIES ## --

export type Properties<T = {}> = {
    mock: boolean,
    reset: boolean,
    environment: string?,
    
    templates: {
        previous_templates: { PlayerData },
        
        current_template: T
    }
}

-- ## PLAYER ## --

export type PlayerDataID = number
export type PlayerDataKey = string
export type PlayerDataValue = Quill

export type PlayerData<T = { [PlayerDataKey]: PlayerDataValue }> = T
export type PlayersData<T = { [PlayerDataKey]: PlayerDataValue }> = { [Player]: PlayerData<T> }

-- // MAIN // --

return nil