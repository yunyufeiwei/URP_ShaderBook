using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class DepthNormalsPass : ScriptableRenderPass
{
    //声明一个标签，用来在FrameDebug中显示插入的额外pass名称
    private static readonly string ProfilerTag = "CustomDepthNormalPassEvent";

    static readonly int TempID = Shader.PropertyToID("_CustomDepthNormalTexture");
    RenderTargetIdentifier tempTex = new RenderTargetIdentifier(TempID);

    private RenderTextureDescriptor textureDescriptor;  //创建具有纹理属性的对象
    private RTHandle textureHandle;

    private Filters _filters;        //声明一个继承至DepthNormalFeature脚本中FiLters类的变量
    private Material _material;     //声明一个材质，用来在pass中计算，这个材质从Feature中传递过来
    private FilteringSettings _filteringSettings;   //声明一个继承引擎内置的过滤器变量
    
    public DepthNormalsPass(RenderPassEvent renderPassEvent ,Shader shader,Filters filteringSettings)
    {
        //将Feature中设置的渲染事件时机传递过来，在pass执行中计算
        this.renderPassEvent = renderPassEvent;
        //将Feature中通过shader创建的材质传递过来，在pass中用于计算
        this._material = CoreUtils.CreateEngineMaterial(shader);
        //将继承至引擎内置的过滤器变量，使用自定义的结构进行填充
        this._filteringSettings = new FilteringSettings(DepthNormalsFeature.GetQueueRange(filteringSettings.queue),filteringSettings.layerMask);
    }

    //配置
    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
        //配置声明纹理对象的属性
        int rtWidth = renderingData.cameraData.camera.pixelWidth;
        int rtHeight = renderingData.cameraData.camera.pixelHeight;

        textureDescriptor = new RenderTextureDescriptor(rtWidth, rtHeight);
        textureDescriptor.colorFormat = RenderTextureFormat.ARGB32;
        textureDescriptor.depthBufferBits = 32;
        //检查描述符是否已经更改，必要时重新分配RTHandle
        // RenderingUtils.ReAllocateIfNeeded(ref textureHandle, textureDescriptor);
        
        //GetTemporaryRT添加一个临时渲染纹理的命令，第一个参数是ShaderProperty
        cmd.GetTemporaryRT(TempID, textureDescriptor, FilterMode.Trilinear);

        // ConfigureClear(ClearFlag.All, Color.black);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        //将
        ref CameraData cameraData = ref renderingData.cameraData;
        Camera camera = cameraData.camera;
        
        //如果相机的类型不是场景视图，并且相机的名称不是Main Camera，则不显示，直接返回
        if (!cameraData.isSceneViewCamera && camera.name != "Main Camera") return;
        //如果相机的postProcessEnabled没有启用，则直接返回
        if(!renderingData.cameraData.postProcessEnabled) return;
        
        //获取新的命令缓存区并指定其名称(这里用的是开始声明好的ProfilerTag名称，如果用别的string字符串替换，则在FrameDebug里面会显示该字符串)
        CommandBuffer cmd = CommandBufferPool.Get(ProfilerTag);

        using (new ProfilingScope(cmd, new ProfilingSampler(ProfilerTag)))
        {
            var shaderTagId = new ShaderTagId("UniversalForward");
            var sortFlags = renderingData.cameraData.defaultOpaqueSortFlags;
            var drawSettings = CreateDrawingSettings(shaderTagId, ref renderingData, sortFlags);
            drawSettings.overrideMaterial = _material;
            drawSettings.perObjectData = PerObjectData.None;
            
            OnRenderImage();
            
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            context.DrawRenderers(renderingData.cullResults, ref drawSettings, ref _filteringSettings);
            cmd.SetGlobalTexture(TempID, tempTex);
        }
        
        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }

    public override void FrameCleanup(CommandBuffer cmd)
    {
        cmd.ReleaseTemporaryRT(TempID);
    }
    
    private void OnRenderImage()
    {
        
    }
    
}
