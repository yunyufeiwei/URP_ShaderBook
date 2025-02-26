using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class EdgeDetectNormalsAndDepthPass : ScriptableRenderPass
{
    //声明一个在FrameDebug里面用来显示Pass的名称
    private static readonly string ProfilerTag = "EnemyEdgeDetect";
    
    private EdgeDetectNormalsAndDepthFeature.Settings _settings;
    private Material _material;
    private FilteringSettings _filteringSettings;
    
    //声明volume相关
    private EdgeDetectNormalsAndDepthVolume _volume;
    
    //声明RT相关
    static readonly int tempID = Shader.PropertyToID("_TempTex");
    private RenderTargetIdentifier temp = new RenderTargetIdentifier(tempID);
    
    public EdgeDetectNormalsAndDepthPass(EdgeDetectNormalsAndDepthFeature.Settings settings)
    {
        this._settings = settings;
        this.renderPassEvent = settings.RenderPassEvent;
        settings.shader = Shader.Find("URP/Chapter 13/EdgeDetectNormalsAndDepth");
        this._material = CoreUtils.CreateEngineMaterial(settings.shader);
    }

    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
        //实例化VolumeComponent并获取VolumeComponent参数
        var stack = VolumeManager.instance.stack;
        _volume = stack.GetComponent<EdgeDetectNormalsAndDepthVolume>();

        int rtWidth = renderingData.cameraData.camera.scaledPixelWidth;
        int rtHeight = renderingData.cameraData.camera.scaledPixelHeight;
        RenderTextureDescriptor descriptor = new RenderTextureDescriptor(rtWidth, rtHeight);
        cmd.GetTemporaryRT(tempID,descriptor,FilterMode.Trilinear);
    }
    
    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        ref CameraData cameraData = ref renderingData.cameraData;
        Camera camera = cameraData.camera;
        var source = cameraData.renderer.cameraColorTargetHandle;

        if (!cameraData.postProcessEnabled) return;
        if (!cameraData.isSceneViewCamera && camera.name != "Main Camera") return;   //如果场景中的camera名称不是Main Camera，则在Game视图不显示
        
        CommandBuffer cmd = CommandBufferPool.Get();
        using (new ProfilingScope(cmd,new ProfilingSampler(ProfilerTag)))
        {
            var shaderTagId = new ShaderTagId("EnemyEdgeDetect");
            var sortFlags = renderingData.cameraData.defaultOpaqueSortFlags;
            var drawSettings = CreateDrawingSettings(shaderTagId, ref renderingData, sortFlags);
            drawSettings.overrideMaterial = _material;
            drawSettings.perObjectData = PerObjectData.None;
            
            if (_volume.IsActive())
            {
                _material.SetKeyword(new LocalKeyword(_settings.shader, "_UseEdgeDetect"), _volume.useEdgeDetect.value);
                _material.SetKeyword(new LocalKeyword(_settings.shader, "_UseDepthNormal"), _volume.useDepthNormal.value);
                // _material.SetKeyword(new LocalKeyword(_settings.shader, "_UseDecodeDepthNormal"), _volume.useDecodeDepthNormal.value);
                _material.SetColor("_EdgeColor", _volume.edgeColor.value);
                _material.SetColor("_BackgroundColor", _volume.backgroundColor.value);
                _material.SetFloat("_EdgeOnly", _volume.edgeOnly.value);
                _material.SetFloat("_SampleDistance",_volume.sampleDistance.value);
            }
            
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            context.DrawRenderers(renderingData.cullResults, ref drawSettings, ref _filteringSettings);
            cmd.Blit(source,temp,_material,0);
            cmd.Blit(temp,source);
        }
        
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
        CommandBufferPool.Release(cmd);
    }
    
    public override void FrameCleanup(CommandBuffer cmd)
    {
        cmd.ReleaseTemporaryRT(tempID);
    }
}
