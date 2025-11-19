graph TB
    %% 用户交互层
    subgraph UI["用户交互层"]
        CLI["CLI接口"]
        VSCode["VSCode插件"]
        Web["Web界面"]
    end

    %% Agent核心调度层
    subgraph Core["核心调度层"]
        AgentLoop["AgentLoop"]
        MsgQueue["AsyncQueue"]
        StreamGen["StreamGen"]
        Compressor["Compressor"]
    end

    %% 工具执行与管理层
    subgraph Tools["工具管理层"]
        ToolEngine["ToolEngine"]
        Scheduler["Scheduler"]
        TaskAgent["TaskAgent"]
        PermGW["PermissionGW"]
    end

    %% 存储与持久化层
    subgraph Storage["存储层"]
        ShortMem["短期记忆"]
        MidMem["中期压缩历史"]
        LongMem["长期存储"]
        StateCache["状态缓存"]
    end

    %% 主连接关系（简化）
    CLI --> AgentLoop
    VSCode --> AgentLoop
    Web --> AgentLoop
    
    AgentLoop --> MsgQueue
    AgentLoop --> StreamGen
    AgentLoop --> Compressor
    
    AgentLoop --> ToolEngine
    AgentLoop --> Scheduler
    AgentLoop --> TaskAgent
    AgentLoop --> PermGW
    
    ToolEngine --> ShortMem
    Compressor --> MidMem
    AgentLoop --> LongMem
    Scheduler --> StateCache

    %% 样式定义
    classDef uiLayer fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef coreLayer fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef toolLayer fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef storageLayer fill:#fff3e0,stroke:#e65100,stroke-width:2px
    
    class CLI,VSCode,Web uiLayer
    class AgentLoop,MsgQueue,StreamGen,Compressor coreLayer
    class ToolEngine,Scheduler,TaskAgent,PermGW toolLayer
    class ShortMem,MidMem,LongMem,StateCache storageLayer
