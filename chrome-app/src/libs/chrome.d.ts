﻿// Type definitions for Chrome packaged application development
// Project: http://developer.chrome.com/apps/
// Definitions by: Adam Lay <https://github.com/AdamLay>, MIZUNE Pine <https://github.com/pine613>, MIZUSHIMA Junki <https://github.com/mzsm>
// Definitions: https://github.com/borisyankov/DefinitelyTyped

/// <reference path='./filesystem.d.ts'/>

////////////////////
// App Runtime
////////////////////
declare module chrome.app.runtime {
    interface LaunchData {
        id?: string;
        items?: LaunchDataItem[];
        url?: string;
        referrerUrl?: string;
        isKioskSession?: boolean;
    }

    interface LaunchDataItem {
        entry: FileEntry;
        type: string;
    }

    interface LaunchedEvent {
        addListener(callback: (launchData: LaunchData) => void): void;
    }

    interface RestartedEvent {
        addListener(callback: () => void): void;
    }

    var onLaunched: LaunchedEvent;
    var onRestarted: RestartedEvent;
}

////////////////////
// App Window
////////////////////
declare module chrome.app.window {
    interface ContentBounds {
        left?: number;
        top?: number;
        width?: number;
        height?: number;
    }

    interface BoundsSpecification {
        left?: number;
        top?: number;
        width?: number;
        height?: number;
        minWidth?: number;
        minHeight?: number;
        maxWidth?: number;
        maxHeight?: number;
    }

    interface Bounds {
        left: number;
        top: number;
        width: number;
        height: number;
        minWidth?: number;
        minHeight?: number;
        maxWidth?: number;
        maxHeight?: number;
        setPosition(left: number, top: number): void;
        setSize(width: number, height: number): void;
        setMinimumSize(minWidth: number, minHeight: number): void;
        setMaximumSize(maxWidth: number, maxHeight: number): void;
    }
    interface FrameOptions {
        type?: string;
        color?: string;
        activeColor?: string;
        inactiveColor?: string;
    }

    interface CreateWindowOptions {
        id?: string;
        innerBounds?: BoundsSpecification;
        outerBounds?: BoundsSpecification;
        minWidth?: number;
        minHeight?: number;
        maxWidth?: number;
        maxHeight?: number;
        frame?: any; // string ("none", "chrome") or FrameOptions
        bounds?: ContentBounds;
        alphaEnabled?: boolean;
        state?: string; // "normal", "fullscreen", "maximized", "minimized"
        hidden?: boolean;
        resizable?: boolean;
        singleton?: boolean;
        alwaysOnTop?: boolean;
        focused?: boolean;
        visibleOnAllWorkspaces?: boolean;
    }

    interface AppWindow {
        focus: () => void;
        fullscreen: () => void;
        isFullscreen: () => boolean;
        minimize: () => void;
        isMinimized: () => boolean;
        maximize: () => void;
        isMaximized: () => boolean;
        restore: () => void;
        moveTo: (left: number, top: number) => void;
        resizeTo: (width: number, height: number) => void;
        drawAttention: () => void;
        clearAttention: () => void;
        close: () => void;
        show: () => void;
        hide: () => void;
        getBounds: () => ContentBounds;
        setBounds: (bounds: ContentBounds) => void;
        isAlwaysOnTop: () => boolean;
        setAlwaysOnTop: (alwaysOnTop: boolean) => void;
        setVisibleOnAllWorkspaces: (alwaysVisible: boolean) => void;
        contentWindow: Window;
        id: string;
        innerBounds: Bounds;
        outerBounds: Bounds;
    }

    export function create(url: string, options?: CreateWindowOptions, callback?: (created_window: AppWindow) => void): void;
    export function current(): AppWindow;
    export function get(id : string) : AppWindow;
    export function getAll() : AppWindow[];
    export function canSetVisibleOnAllWorkspaces() : boolean;

    interface WindowEvent {
        addListener(callback: () => void): void;
    }

    var onBoundsChanged: WindowEvent;
    var onClosed: WindowEvent;
    var onFullscreened: WindowEvent;
    var onMaximized: WindowEvent;
    var onMinimized: WindowEvent;
    var onRestored: WindowEvent;
}

////////////////////
// fileSystem
////////////////////
declare module chrome.fileSystem {

    interface ChildChangeInfo {
        entry: Entry;
        type: string;
    }

    interface EntryChangedEvent {
        target: Entry;
        childChanges?: ChildChangeInfo[];
    }

    interface EntryRemovedEvent {
        target: Entry;
    }

    interface AcceptOptions {
        description?: string;
        mimeTypes?: string[];
        extensions?: string[];
    }

    interface ChooseEntryOptions {
        type?: string;
        suggestedName?: string;
        accepts?: AcceptOptions[];
        acceptsAllTypes?: boolean;
        acceptsMultiple?: boolean;
    }

    export function getDisplayPath(entry: Entry, callback: (displayPath: string) => void): void;
    export function getWritableEntry(entry: Entry, callback: (entry: Entry) => void): void;
    export function isWritableEntry(entry: Entry, callback: (isWritable: boolean) => void): void;
    export function chooseEntry(callback: (entry: Entry) => void): void;
    export function chooseEntry(callback: (fileEntries: FileEntry[]) => void): void;
    export function chooseEntry(options: ChooseEntryOptions, callback: (entry: Entry) => void): void;
    export function chooseEntry(options: ChooseEntryOptions, callback: (fileEntries: FileEntry[]) => void): void;
    export function restoreEntry(id: string, callback: (entry: Entry) => void): void;
    export function isRestorable(id: string, callback: (isRestorable: boolean) => void): void;
    export function retainEntry(entry: Entry): string;
}

////////////////////
// Runtime TODO
////////////////////

declare module chrome.runtime {
    interface MessageSender {
        id? : string;
        url? : string;
        tlsChannelId? : string;
    }

    interface Port {
        name : string;
        disconnect : (any) => void;     // FIXME
        onDisconnect : any;             // FIXME
        onMessage : any;                // FIXME
        postMessage : (any) => void;    // FIXME
        sender? : MessageSender;
    }

    interface PlatformInfo {
        os : string;
        arch : string;
        nacl_arch : string;
    }

    interface Event {
        addListener(callback : () => boolean|void) : void;
    }

    interface Event1<T> {
        addListener(callback : (info : T) => boolean|void) : void;
    }

    interface Event3<T1, T2, T3> {
        addListener(callback : (a:T1, b:T2, c:T3) => boolean|void) : void;
    }

    var lastError : { message? : string; };
    var id : string;

    export function getBackgroundPage(callback : (Window?) => void) : void;
    export function openOptionsPage(callback? : () => void) : void;
    export function getManifest() : any;
    export function getURL(path : string) : string;
    export function setUninstallURL(url : string) : void;
    export function reload() : void;
    export function requestUpdateCheck(callback : (status : string, details? : any) => void) : void;
    export function restart() : void;
    export function connect(extensionId? : string, connectInfo? : { name? : string; includeTlsChannelId? : boolean }) : Port;
    export function connectNative(application : string) : Port;

    // type overloads for sendMessage: optional first parameter (extensionId), optional this parameter (options?)
    export function sendMessage(message : any, responseCallback? : (any) => void) : void;
    export function sendMessage(message : any, options? : { includeTlsChannelId? : boolean }, responseCallback? : (any) => void) : void;
    export function sendMessage(extensionId : string, message : any, options? : { includeTlsChannelId? : boolean }, responseCallback? : (any) => void) : void;

    export function sendNativeMessage(application : string, message : Object, responseCallback : (any) => void) : void;
    export function getPlatformInfo(callback : (PlatformInfo) => void) : void;
    export function getPackageDirectoryEntry(callback : (DirectoryEntry) => void) : void;

    var onStartup                   : Event;
    var onInstalled                 : Event1<{ details : { reason : string; previousVersion? : string; id? : string } }>;
    var onSuspend                   : Event;
    var onSuspendCanceled           : Event;
    var onUpdateAvailable           : Event1<{ details : { version : string } }>;
    var onConnect                   : Event1<Port>;
    var onConnectExternal           : Event1<Port>;
    var onMessage                   : Event3<any, MessageSender, () => void>;
    var onMessageExternal           : Event3<any, MessageSender, () => void>;
    var onRestartRequired           : Event1<string>;
}

////////////////////
// Sockets
////////////////////
declare module chrome.sockets.tcp {
    interface CreateInfo {
        socketId: number;
    }

    interface SendInfo {
        resultCode: number;
        bytesSent?: number;
    }

    interface Event<T> {
        addListener(callback: (info: T) => void): void;
        removeListener(callback: (info: T) => void): void;
    }

    interface ReceiveEventArgs {
        socketId: number;
        data: ArrayBuffer;
    }

    interface ReceiveErrorEventArgs {
        socketId: number;
        resultCode: number;
    }

    interface SocketProperties {
        persistent?: boolean;
        name?: string;
        bufferSize?: number;
    }

    interface SocketInfo {
        socketId: number;
        persistent: boolean;
        name?: string;
        bufferSize?: number;
        paused: boolean;
        connected: boolean;
        localAddress?: string;
        localPort?: number;
        peerAddress?: string;
        peerPort?: number;
    }

    export function create(callback: (createInfo: CreateInfo) => void): void;
    export function create(properties: SocketProperties, callback: (createInfo: CreateInfo) => void): void;

    export function update(socketId: number, properties: SocketProperties, callback?: () => void): void;
    export function setPaused(socketId: number, paused: boolean, callback?: () => void): void;

    export function setKeepAlive(socketId: number,
        enable: boolean, callback: (result: number) => void): void;
    export function setKeepAlive(socketId: number,
        enable: boolean, delay: number, callback: (result: number) => void): void;

    export function setNoDelay(socketId: number, noDelay: boolean, callback: (result: number) => void): void;
    export function connect(socketId: number,
        peerAddress: string, peerPort: number, callback: (result: number) => void): void;
    export function disconnect(socketId: number, callback?: () => void): void;
    export function send(socketId: number, data: ArrayBuffer, callback: (sendInfo: SendInfo) => void): void;
    export function close(socketId: number, callback?: () => void): void;
    export function getInfo(socketId: number, callback: (socketInfo: SocketInfo) => void): void;
    export function getSockets(socketId: number, callback: (socketInfos: SocketInfo[]) => void): void;

    var onReceive: Event<ReceiveEventArgs>;
    var onReceiveError: Event<ReceiveErrorEventArgs>;
}

declare module chrome.sockets.udp {
    interface CreateInfo {
        socketId: number;
    }

    interface SendInfo {
        resultCode: number;
        bytesSent?: number;
    }

    interface Event<T> {
        addListener(callback: (info: T) => void): void;
    }

    interface ReceiveEventArgs {
        socketId: number;
        data: ArrayBuffer;
        remoteAddress: string;
        remotePort: number;
    }

    interface ReceiveErrorEventArgs {
        socketId: number;
        resultCode: number;
    }

    interface SocketProperties {
        persistent?: boolean;
        name?: string;
        bufferSize?: number;
    }

    interface SocketInfo {
        socketId: number;
        persistent: boolean;
        name?: string;
        bufferSize?: number;
        paused: boolean;
        localAddress?: string;
        localPort?: number;
    }

    export function create(callback: (createInfo: CreateInfo) => void): void;
    export function create(properties: SocketProperties,
        callback: (createInfo: CreateInfo) => void): void;

    export function update(socketId: number, properties: SocketProperties, callback?: () => void): void;
    export function setPaused(socketId: number, paused: boolean, callback?: () => void): void;
    export function bind(socketId: number, address: string, port: number, callback: (result: number) => void): void;
    export function send(socketId: number, data: ArrayBuffer, address: string, port: number, callback: (sendInfo: SendInfo) => void): void;
    export function close(socketId: number, callback?: () => void): void;
    export function getInfo(socketId: number, callback: (socketInfo: SocketInfo) => void): void;
    export function getSockets(callback: (socketInfos: SocketInfo[]) => void): void;
    export function joinGroup(socketId: number, address: string, callback: (result: number) => void): void;
    export function leaveGroup(socketId: number, address: string, callback: (result: number) => void): void;
    export function setMulticastTimeToLive(socketId: number, ttl: number, callback: (result: number) => void): void;
    export function setMulticastLoopbackMode(socketId: number, enabled: boolean, callback: (result: number) => void): void;
    export function getJoinedGroups(socketId: number, callback: (groups: string[]) => void): void;

    var onReceive: Event<ReceiveEventArgs>;
    var onReceiveError: Event<ReceiveErrorEventArgs>;
}

declare module chrome.sockets.tcpServer {
    interface CreateInfo {
        socketId: number;
    }

    interface Event<T> {
        addListener(callback: (info: T) => void): void;
    }

    interface AcceptEventArgs {
        socketId: number;
        clientSocketId: number;
    }

    interface AcceptErrorEventArgs {
        socketId: number;
        resultCode: number;
    }

    interface SocketProperties {
        persistent?: boolean;
        name?: string;
    }

    interface SocketInfo {
        socketId: number;
        persistent: boolean;
        name?: string;
        paused: boolean;
        localAddress?: string;
        localPort?: number;
    }

    export function create(callback: (createInfo: CreateInfo) => void): void;
    export function create(properties: SocketProperties, callback: (createInfo: CreateInfo) => void): void;

    export function update(socketId: number, properties: SocketProperties, callback?: () => void): void;
    export function setPaused(socketId: number, paused: boolean, callback?: () => void): void;

    export function listen(socketId: number, address: string,
        port: number, backlog: number, callback: (result: number) => void): void;
    export function listen(socketId: number, address: string,
        port: number, callback: (result: number) => void): void;

    export function disconnect(socketId: number, callback?: () => void): void;
    export function close(socketId: number, callback?: () => void): void;
    export function getInfo(socketId: number, callback: (socketInfos: SocketInfo[]) => void): void;

    var onAccept: Event<AcceptEventArgs>;
    var onAcceptError: Event<AcceptErrorEventArgs>;
}
