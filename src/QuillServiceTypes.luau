-- // TYPES // --

-- ## BASE ## --

export type QuillBaseDisconnect = () -> ()
export type QuillBaseOnceCallback<T = any> = ( prev_value: T, value: T, replicate: boolean ) -> ()
export type QuillBaseConnectCallback<T = any> = ( disconnect: QuillBaseDisconnect, prev_value: T, value: T, replicate: boolean ) -> ()

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
    id: PlayerDataID,
    mock: boolean,
    reset: boolean,
    environment: string?,
    
    templates: {
        old_templates: {
            {
                id: PlayerDataID,
                
                template: PlayerData
            }
        },
        
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