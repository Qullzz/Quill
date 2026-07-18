/* eslint-disable @typescript-eslint/no-explicit-any */

declare class packet<T extends CallNetType<any>> {
  // can't have server and client overloads while keeping dot access to methods because of how typescript works
  listen: (callback: (data: T["value"], player?: Player) => void) => void;
  wait: () => T["value"];

  /** @client */
  send: (data: T["value"]) => void;

  /** @server */
  sendToAll: (data: T["value"]) => void;
  /** @server */
  sendTo: (data: T["value"], player: Player) => void;
  /** @server */
  sendToList: (data: T["value"], players: Player[]) => void;
  /** @server */
  sendToAllExcept: (data: T["value"], exception: Player) => void;
  /** @server */
  sendFiltered: (data: T["value"], predicate: (player: Player) => boolean) => void;
}

type CallNetType<T> = {
  value: T;
};

declare type array<T extends CallNetType<any>> = CallNetType<T["value"][]>;
declare type struct<T extends { [index: string]: CallNetType<any> }> =
  CallNetType<{
    [valueName in keyof T]: T[valueName]["value"];
  }>;
declare type optional<T extends CallNetType<any>> = CallNetType<
  T["value"] | undefined
>;
declare type map<
  K extends CallNetType<any>,
  V extends CallNetType<any>,
> = CallNetType<Map<K["value"], V["value"]>>;

declare namespace CallNet {
  export function definePacket<T extends CallNetType<any>>(packetProps: {
    value: T;
    reliabilityType?: "reliable" | "unreliable";
  }): packet<T>;

  export function defineNamespace<
    T extends {
      [packetName: string]: packet<CallNetType<any>>;
    },
  >(
    name: string,
    namespaceDefine: () => T,
  ): {
    [packetName in keyof T]: T[packetName];
  };

  // Primitive types
  export const int8: CallNetType<number>;
  export const int16: CallNetType<number>;
  export const int32: CallNetType<number>;
  export const uint8: CallNetType<number>;
  export const uint16: CallNetType<number>;
  export const uint32: CallNetType<number>;
  export const float32: CallNetType<number>;
  export const float64: CallNetType<number>;
  export const string: CallNetType<string>;
  export const bool: CallNetType<boolean>;
  export const buff: CallNetType<buffer>;
  export const inst: CallNetType<Instance>;
  export const cframe: CallNetType<CFrame>;
  export const vec3: CallNetType<Vector3>;
  export const vec2: CallNetType<Vector2>;
  export const nothing: CallNetType<void>;
  export const unknown: CallNetType<unknown>;

  // Special types
  export function array<T extends CallNetType<any>>(type: T): array<T>;
  export function struct<T extends { [index: string]: CallNetType<any> }>(
    struct: T,
  ): struct<T>;
  export function optional<T extends CallNetType<any>>(type: T): optional<T>;
  export function map<K extends CallNetType<any>, V extends CallNetType<any>>(
    key: K,
    value: V,
  ): map<K, V>;
}

export = CallNet;
